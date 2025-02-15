---
layout: post
title:  "Path Length constraint limitations and bypasses"
date:   2025-02-15 08:00:00 +0100
categories: "security research"
---

Path Length Constraint offers **less security** than an naive reading
of its description implies, and it is not well suited to limit impact
of CA **key compromise** nor **key misuse**.

The Path Length Constraint
(_X.509 Basic constraints extension field_ `pathLenConstraint`),
for a CA certificate limits how many CA can be issued below it.
Standardized special case `self-issued` CA certificates bypass
the constraint, and limits the effectiveness of it.

There may also be a lack of testing / exploration of implementation
robustness, bugs, implementation defined behaviors and other quirks.

Potential mitigations includes CA/HSM log correlation, Certificate
Transparency and OCSP.

* [Threat model](#threat-model)
  * [Basic constraint and certificate chains](#basic-constraint-and-certificate-chains)
  * [Threat: Key compromise](#threat-key-compromise)
  * [Threat: Key misuse](#threat-key-misuse)
  * [Threat: pathLenConstraint bypass](#threat-pathlenconstraint-bypass)
  * [Threat: issuing certificates with old serial numbers](#threat-issuing-certificates-with-old-serial-numbers)
* [Self-issued certificates](#self-issued-certificates)
* [Self-signed certificates](#self-signed-certificates)
* [OpenSSL bug in 2018](#openssl-bug-in-2018)
* [Despair or Hope](#despair-or-hope)
* [Mitigations](#mitigations)
  * [CA/HSM log correlation as a mitigation](#cahsm-log-correlation-as-a-mitigation)
  * [Certificate Transparency as a mitigation](#certificate-transparency-as-a-mitigation)
  * [OCSP as a mitigation](#ocsp-as-a-mitigation)
* [References](#references)

## Threat model

Public Key Infrastructure (X.509), or `PKI` or `PKIX`
uses certificates and certificate chains to bind public keys to
securely enrolled End Entities.

A small threat model establish a small baseline of what threat
we see against `PKI` and `pathLenConstraint`.

### Basic constraint and certificate chains

Basic constraint is one of the primary constraints used to restrict
what different private key holders are allowed to do within the PKI.
* `cA=TRUE` gives key holders the permission to act as a Certificate
  Authority.
* `pathLenConstraint` affects how many levels of Certificate
  Authorities are allowed below the Certificate Authority.

A very basic PKI chain may look as follows:

``` plain
  +------+
  | Root | Self-signed. Basic: cA=TRUE
  +------+
      |
+-----------+
| Policy CA | Basic: cA=TRUE, pathLenConstraint=1
+-----------+
      |
+------------+
| Issuing CA | Basic: cA=TRUE, pathLenConstraint=0
+------------+
      |
+------------+
| End Entity | Basic: cA=FALSE
+------------+
```

So a chain has the following members;
* Root CA certificate.
  A **self-signed** `SS` CA certificate.
  Self-signed certificates are signed with their own private key,
  and has the same subject name as the issuer name,
  similar to self-issued certificates.
  Root certificates typically have very few constraints.
  Typically used as **Trust Anchor** by applications.
* Policy CA certificate is the first intermediate CA directly
  beneath the root certificate.
  It is typically here that PKI/PKIX designers start applying
  meaningful constraints restricting the PKI roles.
  For simple PKI `pathLenConstraint=1` would be expected here,
  though a more complex PKI may allow more levels, for example
  `pathLenConstraint=3`.
* _Optionally more intermediate levels of certificate authorities..._
* Issuing CA certificate is the CA that is in actual normal daily
  use, issuing new End Entity certificates.
  Issuing authorities typically has `pathLenConstraint=0` as there
  is normally no need for an issuing CA to create new authorities.
* **End Entity** certificates.
  Leaf certificates that are used by users, applications, clients,
  servers.
  End Entities are constrained and may not act as an certificate
  authority.

Aside from **self-signed** CA certificates, there are two more
special Certificate Authority variants;
* **Self-issued** `SI` CA certificates.
  An `SI` certificates assigns a new private key and new constraints
  to a certificate authority.
  An `SI` certificate has the same subject name as the issuer name.
  Very relevant to attacks against `pathLenConstraint`.
* **Cross-certificates**.
  An CA that has two certificates issued by two different PKIs,
  for the same public key.
  _Mostly Out of scope for this article, but mentioned for the sake
  of completeness_.

### Threat: Key compromise

A Certificate Authority (CA) can suffer a **key compromise**, in
which an attacker breaches the Certificate Authority and steals
the private key;

``` plain
+----+   +----------------+
| CA |---| CA Private Key |
+----+   +----------------+
```

A complete **key compromise** is largely unlikely if the CA stores
the key in a Hardware Security Module (HSM) that binds the key to
a specific hardware and disallows key export.

``` plain
+----+   +-----+   +----------------+
| CA |---| HSM |---| CA Private Key |
+----+   +-----+   +----------------+
```

HSMs may fail to protect against **key compromise** due to;
* Misconfiguration (keys marked exportable)
* Poor operating procedures.
* Hardware/software vulnerabilities in the HSM.

### Threat: Key misuse

Do keep in mind that **key misuse** remains a risk even with
HSMs protecting the CA Private Key from a complete
**key compromise**.

An attacker that has gained `user`/`application` control of the HSM
may still issue certificates.
Without being able to directly access the CA Private Key,
the attacker can perform key operations such as signing.

For all intent and purposes, we can consider a **key misuse** attack
to have very similar impact as a **key compromise**.
The only caveat is that **key missuses** does not require attacker to
break HSM security protections in order to exploit the PKI.

### Threat: pathLenConstraint bypass

`pathLenConstraint` is less resilient from bypass than many believe,
with **Self-issued** certificates being the primary attack vector.

This enables [persistence](https://attack.mitre.org/tactics/TA0003/),
escalating a **key misuse** to a persistent CA compromise.
Reducing time in the CA operating environment also reduces chance
of detection.

_This is the major point of this blog post, but I tend to ramble ;)_

### Threat: issuing certificates with old serial numbers

If an attacker has successfully compromised a certificate authority,
one way to try to reduce visibility could be to issue new
certificates with an old serial number.

This may reduce risk of victims issuing suspicious request to OCSP
servers, reducing CA / PKI operators ability to detect malicious
keys in use.

i.e. we can see this as one of the attackers options to try to
achieve [Defense Evasion](https://attack.mitre.org/tactics/TA0005/).
Avoid leaving traces that are easily found in an audit or OCSP logs.

## Self-issued certificates

[IETF RFC5280: Certificate and Certificate Revocation List (CRL) Profile](https://datatracker.ietf.org/doc/html/rfc5280)
describes Path Length constraint with a **big caveat** attached to it,
`pathLenConstraint` can be bypassed using `self-issued` (`SI`)
certificates.

> _In this case, it gives the maximum number of non-self-issued_
> _intermediate certificates that may follow this certificate in a_
> _valid certification path._
> [...]
> _A pathLenConstraint of zero indicates that no non-self-issued_
> _intermediate CA certificates may follow in a valid certification_
> _path._

So, what is `self-issued` (`SI`) certificate?

> _Self-issued certificates are CA certificates in which_
> _the issuer and subject are the same entity._ [...]
> _A certificate is self-issued if the same DN appears in the subject_
> _and issuer fields (the two DNs are the same if they match according_
> _to the rules specified in Section 7.1)._

Caveat being that `self-issued` (`SI`) certificates
are **exempt** from Path Length constraint check.


So, lets say attacker has compromised certificate authority `Issuing CA`:

``` plain
BasicConstraints: cA=TRUE, pathLenConstraint=0
Issuer: C = US, O = Foo, CN = Policy CA
Subject: C = US, O = Foo, CN = Issuing CA
```

Attacker can issue a new `self-issued` certificate:

``` plain
BasicConstraints: cA=TRUE, pathLenConstraint=0
Issuer: C = US, O = Foo, CN = Issuing CA
Subject: C = US, O = Foo, CN = Issuing CA
```

`RFC5280` **Security Considerations** describe how the feature
only deals with **non-compromised CA key pair**.

> _Self-issued certificates provide CAs with one automated mechanism
> to indicate changes in the CA's operations. In particular,
> self-issued certificates may be used to implement a graceful
> change-over from one **non-compromised CA key pair** to the next._

We have a potential mismatch of features and security expectations;

* `pathLenConstraint=0` leads many people to incorrectly believe that
   such a CA cannot issue new CA certificates.
* Path Length constraint will not take affect when `self-issued`
  flag is true.
* `Self-issue` certificates is trivial under CA **key compromise**
  or **key misuse** attack scenarios.
* `Self-issued` certificates can be issued by a compromised
   certificate authority; enabling **key misuse** to be escalated
   into a persistent compromise of the Certificate Authority.

## Self-signed certificates

Self-signed (root) certificates handling is unreliable and
**implementation defined**;

[RFC5280](https://datatracker.ietf.org/doc/html/rfc5280)
_Using the Path Validation Algorithm_:

> Where a CA distributes self-signed certificates to specify trust
> anchor information, certificate extensions can be used to specify
> recommended inputs to path validation.  For example, a policy
> constraints extension could be included in the self-signed
> certificate to indicate that paths beginning with this trust anchor
> should be trusted only for the specified policies.
> [...]
>
> Implementations that use self-signed certificates to specify trust
> anchor information are free to process or ignore such information.

In other words, "dragons be here".
It is unpredictable and implementation specific if it will do
anything.

So it is often a good idea to utilize the first intermediate CA,
or "Policy CA", if you want to be certain your constraints apply.
Unless you accept that your PKI depends on implementation specific
features that will be treated differently by different applications.

So, if you want to be certain your `pathLenConstraint` sticks,
do stamp it into intermediates, not only self-signed root.

## OpenSSL bug in 2018

When testing `pathLenConstraint` in OpenSSL back in 2018,
I ran into funny problems.

* [github.com/blaufish/openssl-pathlen](https://github.com/blaufish/openssl-pathlen)
* [github.com/openssl/openssl/pull/7353](https://github.com/openssl/openssl/pull/7353)

This certificate chain broken OpenSSL `pathLenConstraint` validation;

``` plain
+--------------+
|     root     | Basic: cA=TRUE, pathLenConstraint:1
+--------------+
       |
+--------------+
| Intermediate | Basic: cA=TRUE, pathLenConstraint:0
+--------------+
       |
+--------------+
|  EvilServer  | Basic: cA=TRUE
+--------------+
       |
+--------------+
|  EvilServer  | Basic: cA=FALSE
+--------------+
```

By self-issuing the end-entity,
the openssl variable `plen` got calculated wrong.
It appeared to be an off-by-1 bug.

While this issue is fixed, it is a very good question "who actually
verifies path length constraints?"

I found this because I started building simple test cases for
`pathLenConstraint`.
A customer wanted evaluation and proof of concept if
`pathLenConstraint` worked well in a specific application stack,
if it could prevent **key misuse** attacks abused for CA persistence.
And immediately got into weird special cases.

## Despair or Hope

**Despair:**
In 2018, me and my customer did conclude that the value of
`pathLenConstraint` was a bit limited with many caveats;

* We suspect no one is exploring or stress-testing
  `pathLenConstraint`.
  We were hitting too many limitations and bugs with little effort.
* The OpenSSL implementation had probably been buggy since forever,
  why are not other users finding this before us?
  _And supporting old OpenSSL versions was important for our
  use-case. If it did not work in old versions, less value for us._
* **Self-issued** `SI` CA introduces a big hole in
  `pathLenConstraint`.
* **Self-signed** `SS` CA processing is implementation defined.

So it is easy to feel discouraged and say
"`pathLenConstraint` _is broken beyond repair_".

**Hope:**
Reflecting back on this today, I think we are both right and wrong.

* CA/HSM log correlation may be able to detect **key misuse** events.
* Certificate Transparency (`CT`) seems to be a good mitigation.
  If you can enforce `CT` throughout your applications, an attacker
  bypassing `pathLenConstraint` in **key misuse** will render a big
  indisputable log history.
* Online Certificate Status Protocol (`OCSP`) may work as a
  mitigation in some situations, assuming attacker cannot control
  which OCSP server is used.
  If application only verifies towards the End Entity OCSP URL,
  that is under attacker control, well, then it does not add value.

Neither mitigation is perfect.
Ideally it would be nice to just have a flag:
"_disable self-issued certificates and remove all implementation
bugs_"

## Mitigations

So, there is at least two mitigations that partly can serve to
detect or prevent `pathLenConstraint` abuse.

### CA/HSM log correlation as a mitigation

CA's should record Issuance of Certificates.
Many HSMs can record tamper proof audit logs of asymmetric key usage,
and other events.

Certificate Authorities that has a good routine for correlating CA
logs towards HSM logs, may be able to detect **key misuse** or other
attacks;
CA key was used in HSM without a corresponding certificate generated
in CA logs may indicate key misuse.

A well executed `self-issue` attack should hopefully leave some
trace that the HSM and the CA logs are not matching, giving auditors
an heads up that something went wrong.

Other CA/HSM best-practices may help as well;
* disabling all HSM mechanisms not needed.
* disabling key export.
* ... and more :)

### Certificate Transparency as a mitigation

Enforcing [Certificate Transparency](https://en.wikipedia.org/wiki/Certificate_Transparency)
[IETF RFC9162](https://datatracker.ietf.org/doc/html/rfc9162)
is highly recommended.
If CA certificates without valid `Signed Certificate Timestamp`
(`SCT`) are rejected, attackers ability to **stealthily** perform
the attack is reduced.
Continuous monitoring of certificate transparency logs would enable
detection of e.g. `self-issued` abuse.

This does imply a few things;
* `Certificate Transparency` should be a consideration when
  designing PKI. While today primarily an internet technology,
  corporate / enterprise PKI should consider its pros and cons.
  Running without it removes one mitigation.
* `Certificate Transparency` support may be beneficial in a lot
  of software, not just web browsers.

### OCSP as a mitigation

[Online Certificate Status Protocol - OCSP](https://datatracker.ietf.org/doc/html/rfc6960)
**may or may not be** effective in dealing with compromised CAs.

An OCSP server picked from Access Method OCSP (Authority
Information Access) may never see any hint of the abusive
traffic.

This is what an OCSP server sees;

``` asn1
CertID          ::=     SEQUENCE {
    hashAlgorithm       AlgorithmIdentifier,
    issuerNameHash      OCTET STRING, -- Hash of issuer's DN
    issuerKeyHash       OCTET STRING, -- Hash of issuer's public key
    serialNumber        CertificateSerialNumber }
```

`serialNumber` thing about the subject provided to an OCSP server.
So an attacker that issues a new backdoor Certificate Authority
could re-use the `serialNumber` of a good certificate.

If you check all certificates with a hard coded OCSP server,
the OCSP server would report on `unknown` due to unrecognized issuer.
So OCSP check of the end-entity leaf certificate should highlight
the unknown issuer state, allowing abuse detection.

## References

**Great IETF PKI documents:**

* [IETF RFC5280 PKIX Certificate and Certificate Revocation List (CRL) Profile](https://datatracker.ietf.org/doc/html/rfc5280)
  _a great document about how PKI basics works in detail._
* [IETF RFC6960 PKIX Online Certificate Status Protocol - OCSP](https://datatracker.ietf.org/doc/html/rfc6960)
* [IETF RFC9162 Certificate Transparency Version 2.0](https://datatracker.ietf.org/doc/html/rfc9162)\
  Also, [Wikipedia: Certificate Transparency](https://en.wikipedia.org/wiki/Certificate_Transparency)
  presents CT in an easier to consume format.

**CA/Browser Forum**

* [CA/Browser Forum: Baseline Requirements (server certificates)](https://cabforum.org/working-groups/server/baseline-requirements/)
  _how Internet PKI works, what standards/baselines are applied to
  Internet certificate chains, including_ `pathLenConstraints` _etc._

**OpenSSL bug**, output from my `pathLenConstraint` testing in 2018:

* [github.com/blaufish/openssl-pathlen](https://github.com/blaufish/openssl-pathlen)
* [github.com/openssl/openssl/pull/7353](https://github.com/openssl/openssl/pull/7353)

**HSM vulnerabilities**
Example of HSMs / secure chip /... vulnerabilities,
that may enable key compromise:

* [ROCA vulnerability](https://en.wikipedia.org/wiki/ROCA_vulnerability), Return of Coppersmith's attack, `CVE-2017-15361`.
* [CVE-2015-5464 - Key extraction vulnerability(utimaco)](https://support.hsm.utimaco.com/support/security-advisories/-/blogs/cve-2015-5464-key-extraction-vulnerability)
  abusing `CKM_EXTRACT_KEY_FROM_KEY` to export key.
