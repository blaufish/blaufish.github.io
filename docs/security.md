---
layout: page
title: Security
permalink: /security/
---

Published security research:

## 2025

* 2025 [ClassLoader manipulation](/security/research/2025/01/21/classloader-manipluation.html)
  ClassLoader manipulation (also known as pollution, or poisoning)
  is an group of exploit chains against Java environments that
  insecurely expose access to ClassLoader.
* 2025 [Stripes CryptoUtil vulnerability](/security/research/2025/01/12/stripes-cryptutil.html)
  Revisiting Stripes Framework STS-934 CryptoUtil vulnerability from 2010/2015.

## 2023 Zabbix Agent Security

[assured.se/posts/zabbix-agent-security](https://www.assured.se/posts/zabbix-agent-security)

> _Zabbix is a fairly popular monitoring tool used in many different organizations._
> _Zabbix deployments range from client/endpoint monitoring to high end data centers, and everything in between._
> _Being very powerful and easily misconfigured, Zabbix should be an interesting target in penetration tests and security audits._
> _An adversary may utilize Zabbix to enable lateral movement, privilege escalation and other attack tactics._

## 2018 Path Length Constraint

[github.com/blaufish/openssl-pathlen](https://github.com/blaufish/openssl-pathlen)

* Path Length Constraint checks in openssl was buggy in 2018.
  You could construct invalid paths that would incorrectly pass verification.
* [RFC5280](https://datatracker.ietf.org/doc/html/rfc5280)
  Self-Issued loop hole.
  An attacker that has temporarily gained control over an issuer,
  can bypass path length constraint by issuing a new certificate
  with same name as issuer.
* Path Length Constraint is kind of pointless in many attack
  scenarios, at least when used without Certificate Transparency.
  Implementations are not well verified, and self-issued loophole
  standardize how to bypass it. Constraint alone is insufficient
  from preventing attackers from persisting issuer compromise.

## 2015 Stripes Framework CryptoUtil vulnerability

[github.com/blaufish/stipesframework\_STS-934-CryptoUtil](https://github.com/blaufish/stipesframework_STS-934-CryptoUtil/blob/master/README.md)

* Stripes framework `CryptoUtil` was using a novel and unusual
  cryptographic composition.
* Several different attacks were possible, enabling
  integrity check bypass and ciphertext modification with some
  level of attacker control.

## 2014 Apache Struts 2 ClassLoader manipulation 

[Apache Struts Security Bulletin S2-020](https://cwiki.apache.org/confluence/display/WW/S2-020)
`CVE-2014-0094` (ClassLoader manipulation)
