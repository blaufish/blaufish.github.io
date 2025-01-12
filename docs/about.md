---
layout: page
title: About
permalink: /about/
---

Your Friendly Neighborhood Blaufish. Security professional. Podcaster. Audio, video editor.

Worked with security, software development, penetration testing since 2003.

## Security Research

Published security research:

* 2023 [assured.se/posts/zabbix-agent-security](https://www.assured.se/posts/zabbix-agent-security)
> Zabbix is a fairly popular monitoring tool used in many different organizations.
> Zabbix deployments range from client/endpoint monitoring to high end data centers, and everything in between.
> Being very powerful and easily misconfigured, Zabbix should be an interesting target in penetration tests and security audits.
> An adversary may utilize Zabbix to enable lateral movement, privilege escalation and other attack tactics.
* 2018 [github.com/blaufish/openssl-pathlen](https://github.com/blaufish/openssl-pathlen)
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
* 2015 [github.com/blaufish/stipesframework\_STS-934-CryptoUtil](https://github.com/blaufish/stipesframework_STS-934-CryptoUtil/blob/master/README.md)
   * Stripes framework `CryptoUtil` was using a novel and unusual
     cryptographic composition.
   * Several different attacks were possible, enabling
     integrity check bypass and ciphertext modification with some
     level of attacker control.

## Podcast

 * [Säkerhetspodcasten](https://sakerhetspodcasten.se/)
   A Swedish language podcast about Security, technology and various
   off-topic matters.
   * [github repos](https://github.com/sakerhetspodcasten/)
   * [github pages](https://sakerhetspodcasten.github.io/)

## Video

 * [owaspgbg](https://www.youtube.com/@owaspgbg)
   OWASP GBG is the home of OWASP Gothenburg (Göteborg) chapter.
   We talk about application security, software development,
   password security, hardware security, 2-factor security,
   incident handling and what not.
 * [securityfest](https://www.youtube.com/@securityfest)
   Security Fest is a security conference in Gothenburg Sweden.

## University projects

* [github.com/blaufish/xilinix\_soc\_masterthesis\_2003](https://github.com/blaufish/xilinix_soc_masterthesis_2003)
  _Master Thesis: Evaluating Xilinx MicroBlaze for Network SoC solutions_ (2004)
* [github.com/blaufish/transparent\_ethernet\_ipv4\_loadbalancer](https://github.com/blaufish/transparent_ethernet_ipv4_loadbalancer)
  _Transparent Ethernet/IPv4 Loadbalancer_ (2001)
