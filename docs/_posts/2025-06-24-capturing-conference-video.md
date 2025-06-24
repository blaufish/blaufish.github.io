---
layout: post
title:  "Capturing and streaming conferences: audio, video and more"
date:   2025-06-24 11:39:00 +0200
categories: "security conference"
---

Capturing a large conference is an interesting challenge.

I currently do [Security Fest](https://securityfest.com/)
video/streaming by myself with some support and care
from other crew/goons.
The results can be viewed at
[Security Fest 2025 - All videos released!](../../../2025/06/18/securityfest-2025-all-videos-released.html)
or
[youtube.com/@securityfest](https://www.youtube.com/@securityfest).

This post attempts to establish:

**Priorities**,
  what is most important to Security Fest and me.
**Venue**
  is the building we operate in,
  what is provided by the building and its staff.
**Responsibilities**
  is how different teams split the workload.
  Different split of the responsibilities could drastically affect
  how much work is required of a streaming/video team.
**Deliveries**
  is what the streaming/video team delivers.
  A basic live stream with moderate quality and production value.
  High quality 4K YouTube videos with nice video thumbnails.
**Live is hard**
  is about the various things that can make live video production in
  a Venue challenging.
**Steaming/Video Setup**
  is about how the various things we bring to make the video
  productions happen.

**Table of Contents**

* [Priorities](#priorities)
  * [Local audiences first!](#local-audiences-first)
  * [Great video](#great-video)
  * [Stream: Good enough, basic](#stream-good-enough-basic)
  * [Simple workflows](#simple-workflows)
  * [Simple workflows: Pointing and calling checklist](#simple-workflows-pointing-and-calling-checklist)
  * [Simple workflows: Multiple units of same gear](#simple-workflows-multiple-units-of-same-gear)
  * [Simple workflows: Test setup ahead of time](#simple-workflows-test-setup-ahead-of-time)
  * [Simple workflows: Small data sizes](#simple-workflows-small-data-sizes)
  * [Simple workflows: Timecode](#simple-workflows-timecode)
* [Venue overview](#venue-overview)
* [Responsibilities](#responsibilities)
  * [Venue](#venue)
  * [Sound/Stage Professionals](#soundstage-professionals)
  * [Stream/Video crew](#streamvideo-crew)
* [Deliveries](#deliveries)
  * [Deliveries: Stream](#deliveries-stream)
  * [Deliveries: Videos](#deliveries-videos)
  * [Not delivered: local cable or local stream](#not-delivered-local-cable-or-local-stream)
* [Live is hard](#live-is-hard)
  * [Power: one reason live is hard](#power-one-reason-live-is-hard)
  * [Media: one reason live is hard](#media-one-reason-live-is-hard)
  * [Flicker: one reason live is hard](#flicker-one-reason-live-is-hard)
  * [HDMI: some reasons why live is hard](#hdmi-some-reasons-why-live-is-hard)
  * [Computers: many reasons why live is hard](#computers-many-reasons-why-live-is-hard)
* [Steaming/Video Setup](#steamingvideo-setup)
  * [Cameras](#cameras)
  * [Lenses](#lenses)
  * [Video Recorders](#video-recorders)
  * [Audio Recorder](#audio-recorder)
  * [Video Switcher](#video-switcher)
  * [Multi Viewer](#multi-viewer)
  * [Laptop](#laptop)
  * [Cables](#cables)
  * [Backup gear](#backup-gear)

## Priorities

### Local audiences first!

At most conferences have the following priority:
* **Local audiences** are most important.
  These are the people who paid to see the conference.
* Everything else is a bonus.

So, the effort has to fit the room.
This is very different from professional Television,
  where remote audiences often are prioritized above local audiences.

### Great video

Great video in the end is very important to me.

Security Fest videos are delivered as
`4K` (`2160p25`)
with one `1080p25` image shown at `150%`
and one `1080p25` image shown at `50%`.
Remaining areas used for logos/branding.

``` plain
+----------+------+
|          |      |
|   150%   | Logo |
|          |      |
+----------+------+
|  Logo    | 50%  |
+----------+------+
```

### Stream: Good enough, basic

A moderately watchable stream in the end is nice.

If you compare to some other conferences,
for example [SEC-T](https://sec-t.org/),
they put a lot more effort into the stream;
having crews professionally operating a video switcher.

### Simple workflows

Simplicity is a must!
Need to reduce chance of mistakes.
I do this rarely, once a year.
Live is hard: need to solve any problem ASAP, as fast as possible.

Examples of simple workflows used includes:
* Pointing and calling checklist
* Multiple units of same gear
* Test setup ahead of time
* Small data sizes
* Timecode

### Simple workflows: Pointing and calling checklist

I've tried to apply
[Pointing and calling](https://en.wikipedia.org/wiki/Pointing_and_calling)
checklist approach.

I write down a simple check list on paper:
* Audio recorder should be recording
* Video Recorders should be recording
* Mixer should have Mic 1 enabled
* Streamer software should be in main view

Point to the device/button,
say expected state e.g. "_Audio recorder should be recording_",
  look at the device,
  set state if incorrect,
  confirm state okay.

This makes it pretty hard to mess up things
  that are on the checklist.

### Simple workflows: Multiple units of same gear

It is easy to get saturated and confused when too much
  different gear.
Early Security Fest had a couple of mistakes primarily
  originating from operating three different cameras
  became too hard.

Today:
* I carry three cameras of same type.
* I carry prime lenses from same set.
  All behave similarly.
  Primes have two gear rings instead of three,
  one less thing to think about or mess up.
* I carry two camera tripods of the same type.
* I carry four video recorders of same type.

So a strong focus on commonality and simplicty
 to reduce the amount of different things to
 manage during live production.

Basically make your life and brain work as simple as possible.

### Simple workflows: Test setup ahead of time

In an ideal world, you would just enter with a well tested ready
built flypack rack.
Everything should just be in one unit ready to go.

We are like 70-80% there.
There's still a ton of setup to do at event,
  still some necessary equipment not racked up,
  but it has been cut down and trained over the years.

### Simple workflows: Small data sizes

Data reduction & ease of working/editing also strongly informs
my workflows:
* `1080p` workflow with eventual `4K` delivery. \
  This reduces data sizes to `25%` compared to a native 4K delivery.
* `p25` (25 frames per second, progressive) workflow. \
  This reducezs data sizes to `41%` compared to a `p60` workflow.
* `Apple ProRes 422 LT` codec for good enough optical quality while
  reducing file sizes and editing butter smooth.
* Fast SD-cards
  _(SDR2V6/256GB Kingston Canvas React Plus V60 SD - 280MB/s)_
  for fast offloading.

Those choices reduces time spent on data wrangling,
and makes editing videos easier.

### Simple workflows: Timecode

Timecode / synchornized recording is important.

First off, timecode can turn on recording on all slave
  recorders.
The less button pressing the better if you are a small team.

Secondary, editing Multi-Camera video is so much easier
if the clips are synchronized by timecode.
You do not want to waste time on synchroninzing two days
of multi-camera clips.

## Venue overview

Venue when fully built out consists of:

**Front of house**

* **Projectors** (3x) _(part of Venue)_
* **HDMI-input** _(part of Venue)_
* **Stage** _(built by Sound/Stage Professionals)_
  * **Podium** _(Security Fest's own)_
  * **HDMI-mixer** _(provided by Sound/Stage Professionals)_
  * **Security Fest's PC** _(Security Fest's own)_

**Back of house**
 * **Audio/Video gear booth** controlling projectors, providing SDI/HDMI out _(part of Venue)_
 * **Mic/sound mixer table** _(provided by provided by Sound/Stage Professionals)_
 * **Stream/Video gear and setup** _(my stuff)_

``` plain
Front of house

Projector   Projector   Projector
^  _________^           ^
| /                     |
| |  __________________/
| | /
| | |  +-----------+
| | |  | Stage,    |                Security
| | |  | Presenter -----> HDMI <--- Fest PC
| | |  | laptops   |      mixer
| | |  +-----------+       |
| | |                      |
 \|/    (Audience)         |
  |                        |
  A/V/gear <---------------/
      /  \______
     /          \
SDI |           |
    |    XLR    |
 Stream <----- Sound <-- Wireless lavalier Mic
 Video         Stage
 Crew          Professionals
    |
     \
      ----> Internet

Back of house
```


## Responsibilities

Overall we have three main groups involved in the setup:
* Venue
* Sound/Stage Professionals
* Stream/Video crew

Notably the other teams offloads the Stream/Video crew a lot.
We do not need to build out the venue ourselves,
we do not need to provide and tape down several long cables.

The **Stream/Video crew** depends on the other teams for:
  * SDI, preferably `1080p25` `3G-SDI`.
  * XLR, audio mix of speaker microphones, computer audio, etc.
  * Internet/TP/RJ45 cable.

**Stream/Video crew** provides:
  * Cameras
  * Recording gear
  * Streaming gear

**Venue** provides:
  * Projectors
  * HDMI-in near stage
  * Audio/Video gear booth ablue to control projectors and tap signals.
  * Internet (RJ45 wired twisted paair ethernet)

**Sound/Stage Professionals** provides:
  * Manage live experience (stage, loudspeakers, lights, Wireless lavalier Mics, ...)
  * Video mixer at front of house (switches between presenter laptop and Security Fest PC)
  * Provide XLR to Stream/Video crew
  * Provide down-converted `1080p25` `3G-SDI` to Stream/Video crew

Additionally, **Security Fest crew** at front of house/stage provide:
  * Security Fest PC with Security Fest Logo,
    shown on projectors when presenter's computers are not shown.

### Venue

The venue Elite Plaza Hotel, Gothenburg comes with a couple of nice
services;

* Front of house has three projectors.
* Front of house has a HDMI input.
* Back of house has a audio/video gear booth.
  * Receives HDMI from front of house.
  * Able to simultanously control all projectors.
  * Able to tap HDMI/laptop image, audio to various destinations.
  * Able to tap HDMI/laptop to `SDI` and `HDMI` out.

The supported video tap from the audio/video gear booth is:
* `2160p60` (`SDI`)
* `2160p60` (`HDMI`)
* `1080p60` (`HDMI`)

> *We prefer a* **down-converter** inbetween us and the Venue gear.
>
> If your HDMI equipment supports `4K`/`2160p`
> you seem to get this high resolution from the gear.
> And I prefer working in `p25`, not `p60`.
> Down-converter is great for getting `1080p25`.
>
> At least it is **not trivial** or obvious how to get other
> resolutions from Venue equipemnt.

Basically this is the venue's main room before built out:

``` plain
Front of house

Projector Projector Projector  HDMI
    ^         ^         ^       |
    |         |         |       |
    |         |         |       |
    |______   |    _____|       |
           \  |   /             |
           |  |  |             /
      Audio/Video/gear <-------

Back of house
```

### Sound/Stage Professionals

The Sound/Stage professionals performs:
* Configuration of venue equipment.
* Build stage, install loud speakers
* Mic speakers
* Mix audio
* Light configuration
* Audio mix out to Streaming/Video crew. \
  Balanced `XLR` audio cable.
  Presenter mics audio and PC/laptop audio in one cable.
* `3G-SDI` `1080p25` Down conversion of PC/laptop video. \
  Basically they put a `Decimator MD-CROSS-V2` in between Venue
  and Stream/Video streaming crew.

### Stream/Video crew

Mostly me and other volunteers.

* Capture camera (close-up on presenter)
* Capture camera (wide-shot of stage)
* Capture `3G-SDI` `1080p25` of presenter laptop.

## Deliveries

Deliveries from the Security Fest video/streaming includes:

* Stream (YouTube)
* Videos (YouTube)

Things not delivered:
* Local cable or local stream

### Deliveries: Stream

Streaming enables a bunch of things:

* Easy cable free distribution to far away rooms in the venue.
* Local audiences who takes a break from socializing can still
  enjoy from their hotel rooms.
* People who could not attend the event can get a bit of the
  experience.
* Some random folks on the internet finds the stream and enjoys it.

### Deliveries: Videos

Video delivers:
* A nice 4K two-image video
* Professional well made cuts
* Well mixed audio (limiters, compressors)
* Well made presentation (thumbnails etc.)

Works as a great marketing material for the conference,
and something cool for the speakers to post to their socials.

[Editing conference video and audio](../../../2025/06/18/conference-video-editing.html)
covers this mostly.

### Not delivered: local cable or local stream

Local cable or local stream is something we do not perform in our
setup.

Basically it is a time / resource / management hog that is nice but
adds work and needs more people to collaborate.
Scoping this out is one way of reducing the demands on the video
team.

Impact:

* "_Do not record / stream_" talk cannot be shown in other
  conference rooms.
* Quality of experience in other rooms are reduced to YouTube stream
  quality, which may be significantly worse than an uncompressed live
  experience.
* Latency in other rooms is reduced to YouTube stream latency,
  meaning it is a bunch of seconds behind.
  This typically does not matter much... our conference has no time
  sensitive voting or such.

## Live is hard

Everythin live is a potential challenge.
There is a reason no one happily screams:
[We'll Do It LIVE!](https://www.youtube.com/watch?v=vu2NK5REvWM)

You always have to be ready to do problem solving and making quick
decisions.
Everything is about reducing problems while live and being able to
deal with them if they happen;
For example:

* Where you set up
* What gear you choose
* Wow you tape down cables to floor/wall
* etc.

### Power: one reason live is hard

**Power** challenges:
Let's say you are filming on a battery powered camera.
Your battery is low.
Do you **replace the battery now** or do you
  **hope the camera stays alive** until
  the end of presentation?

Or alternatively if you run on `AC` power:
what do you do if a conference organizer takes a clever
shortcut and stumbles into your power cable?

### Media: one reason live is hard

You don't want to need to do emergency SD-cards exchanges
  because a card ran out.
And off course a card that worked perfectly when tested at home
  refuses to operate minutes before you go live...

Ideally you'd also want someone doing media wrangling,
  moving files to SSDs/backups.

### Flicker: one reason live is hard

If a projector, light or such is in a venue;
  it might refresh at any awful rate.
Your image is just flickering or rolling when the projector is
  in the image...

Maybe it has an American 60Hz refresh rate that is incompatible
  with an European 25p/50p camera.
Maybe it has an European 50Hz refresh rate that is incompatible
  with an American 30p/60p camera.
Maybe it has some even more stupid refresh rate.

You just try different shutter angles / shutter speed
  until the image looks good, and then stick to that shutter.

At the Security Fest 2025 venue (Elite Hotel Plaza) the following
  settings are compatible with the projector:

* Frame rate: 25p (25 pictures per second)
* Shutter degree: 150
* Shutter speed: 1/60 (`150/360/25 = 1/60`)

### HDMI: some reasons why live is hard

HDMI is generally not loved by video folks for a couple of reasons:

**Long HDMI cable runs are unpredictable.**
Some transmitter/receiver pairing do great over long runs.
Others may have issues if cable is greater than 5 meter.

**HDMI: too many variants.**
There are two big subsets of HDMI transmission standards;
* Television SMTPE HDMI standards used by video gear.
* VESA (Video Equipment Suppliers Association) standards used by
  computers and consumer equipment.

A rare problem is that VESA gear may be unable to display SMTPE
  signals.
For example, at one old Security Fest the crew was supposed to
  provide the monitor streaming crew.
Which they did.
Only this stupid monitor could not display SMTPE HDMI video,
  it just went black...

The reverse problem is more common, that VESA HDMI gear cannot be
displayed by video gear.
This is often worked around by putting a VESA capable down-converter
  like **Decimator Design MD-CROSS-V2** in front of video gear.

### Computers: many reasons why live is hard

A big computer/hacker conference with all kinds of computers on stage
will strain any equipment.

It is very good if presenters can test through all unusual aspects of
their setup ahead of time.

Here's a few things that can happen:

**Computer drops HDMI for a second when switching modes**.
Many laptops has a low power integrated `iGPU` graphics for light
loads, and a high power discrete `dGPU` graphics for heavy loads.
Switching between graphics modes can cause temporary video issues.

Speakers may note this happening for example when jumping from
normal modes to virtual machines.

**Obscure machines may ignore HDMI restrictions**.
Typically computers listens to HDMI receivers and if the receiver
  says _"I can only do 1080p25"_ virtually all computers obeys this.

Some unsual configurations are much less well behaved,
  and may ignore what the receiver supports.
  For example:
  * Virtual Machines
  * CubeOS, Linux etc. with advanced manual configuration / overrides.

Speakers may look confused and wonder why projectors go black and on
  their screens there is some super-high resolution image
  that:
  Video gear will not support,
  and will not look great at a presentation.
  If the VM looks high-resolution, there's no way audiences in the
  back can make out the details.

**Video gear will not show copy-protected materials**.
High-bandwidth Digital Content Protection (HDCP) and similar signals
typically results in no image, or a black or green screen.
Unless presenter has some gear to disable HDCP,
  it will not be possible to present in a conference.

## Steaming/Video Setup

My setup for Security Fest looks as follows:
* Streaming Rack. _Gator GRR-8L 8U Audio Rack; Rolling._
  * SDI monitor.
  * Recorders (4).
* Video switcher
* Audio mixer
* Multi Viewer
* Streaming laptop

``` plain
                 Streaming Rack
                 +------------+
                 |    SDI     | <------ Recorder D
                 |   monitor  | <------
                 +------------+        \
Presenter PC --> | Recorder A | ---> +----------+      +-----------+
Camera A ------> | Recorder B | ---> |  Video   | ---> | Streaming |
Camera B ------> | Recorder C | ---> | switcher |      |   Laptop  |
                 | Recorder D | <--- +----------+      +-----------+
                 +------------+          ^  ^
                                         |  |
                 +-------+              /    \    +--------+
XLR Audio -----> | Audio | -------------      --- | Multi  | <--- Recorder A
                 | Mixer |                        | Viewer | <--- Recorder C
                 +-------+                        +--------+
```

### Cameras

**BMPCC Black Magic Design Pocket Cinema Camera** (3x)
* Camera A: tight shot on speaker
* Camera B: wide shot covering entire stage
* Camera C: backup in case a camera breaks or something
* Feature: low-latency HDMI output, 1080p
* Feature: AC / wall powered
* Feature: Battery backup, can remain on during intermittent wall
  power issues.
* Feature: Super16 2.88x crop factor
* Feature: Small, easy to pack several in a bag

Power:
* AC / wall power as primary power source
* Battery as secondary backup power source

### Lenses

**Meike MK MFT cine-style primes**
* I have more or less a full set of these primes.
* Feature: Very cheap
* Feature: Easy to operate
* Feature: All lenses identical

Focal length / lens choice is very Venue / distance specific;
these are great for our Venue:

**Meike MK 35mm (MFT)**
* **100 mm** full frame equivalent at **2.88X BMPCC crop**
* Used for wide shot capturing almost the entire stage

**Meike MK 85mm (MFT)**
* **245 mm** full frame equivalent at **2.88X BMPCC crop**
* Used for capturing close-up of presenter
* Replaced 65mm used at Security Fest 2024,
  the 85mm looked a little bit better with this venue in
  my opinion.

### Video Recorders

**Black Magic Design HyperDeck Studio HD Plus** (4x)
* HDMI/SDI recorders with timecode support

Setup:
* Recorder A captures SDI-in (Presenter PC).
* Recorder B captures HDMI, Camera A.
* Recorder C captures HDMI, Camera B.
* Recorder D captures SDI-out from Atem mini.

Timecode:
* Recorder A is source of timecode.
* Daisy chained timecode (A `->` B `->` C `->` D)
* B, C, D set to start recording on timecode running;
  single button to start all recorders.

Configuration:
* Codec: `Apple ProRes 422 LT`
* Media: Recording to SD-cards. \
  `SDR2V6/256GB`
  Kingston Canvas React Plus V60 SD - 280MB/s - 256GB.

> One **Kingston Canvas React Plus V60 SD** card suffered issues on
> Security Fest 2025 right before start of event.
> Have not yet investigated if the card is okay,
> has a file system issue or completely broken...
> Aside from potential unreliability, I like that these cards are
> crazy fast when offloading media...

### Audio Recorder

**Sound Devices MixPre-6 II**.

Used for two purposes;
* Backup recording of audio in 32bit float, in case something went wrong.
* Converting XLR balanced audio to short 3.5mm stereo cable.

### Video Switcher

**Blackmagic Design ATEM SDI Pro ISO**

* Enables us to switch between different sources, cameras.
* Enables us to input 3.5mm stereo cable as microphone.
* USB-C web cam output.
* Has a beautiful Multiview

### Multi Viewer

**Decimator DMON-QUAD**.

Used to generate a 1080p25 iamge with `75%` and `25%`
  images at the same time.

``` plain
+----------+------+
|          |      |
|    75%   |      |
|          |      |
+----------+------+
|          | 25%  |
+----------+------+
```

This is what was shown most of the time during
Security Fest 2025,
with some overlays added ontop in the streaming
software.

### Laptop

The streaming laptop is some small toy I bought so many
years ago for Security Fest and SEC-T related affairs.

It's basically crumbling over operating system upgrades,
  insufficient RAM,
  and what not.
  Will need to be replaced to next year!

### Cables

**SDI**

* Switched to SDI setup because Security Fest... 2023? had weird occational HDMI issues.
* Honestly any cable seems to work when working with short
 `3G-SDI` connections. \
  Some of my cables are serious and custom cut. \
  Some of my cables are only rated for word clock, not SDI...

**3.5mm stereo audio**

* `MixPre` to `Blackmagic Design ATEM SDI Pro ISO` 3.5mm cable
  is **very prone** to **noise/interference issues**.
* Cable very important; wrong cable breaks setup!!!
* I **do not understand** at all what cables work and what does not. \
  Some very cheap looking cables **may work great**. \
  Some expensive looksing cables **do not work**. \
  At Security Fest 2023 I know I kept on using a cable
    literally breaking appart
    because a great looking sturdy reserve cable
    introduced too much noise.
* **Known good cable**:
  * **pro snake BJJ 301-1** with transformer to eliminate noise.
    Verified good at Security Fest 2024, 2025.
* **Known problematic** cables that does not work well
  for this use-case:
    * **Teenage Engineering Field Audio Cable**.
      Did not work at Security Fest 2024.

### Backup gear

Well... my back pack is big and contain some emergency
gear for working around unexpected problems.
