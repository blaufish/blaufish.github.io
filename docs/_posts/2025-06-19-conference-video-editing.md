---
layout: post
title:  "Editing conference video and audio"
date:   2025-06-18 15:57:00 +0200
categories: "security conference"
---

When I edit video for a large two day conference
like Security Fest, I set out with a couple of goals:

* The video should be what it says on the tin.
  The **thumbnail** should say what the video is.
  The **presentation** and the **presenter** should
  both be shown early in the video.
* The video should start when the presentation starts,
  like a cold opening.
  Cut long preamble / crowd-work before the presentation.
* Show both **presenter** and **presentation** all the time,
  two images per view.
  When presentation is small screen, it is still easy for
  audience to understand
  "_we are still on same slide, but we zoom in presenter now
  because you mostly want to look at them instead of a static
  slide_".
* Do a really simple multi-camera editing workflow, so you can
  easily edit several videos as fast as you can.
  Don't get stuck on technical details!

**Table of Contents**:

* [What it says on the tin](#what-it-says-on-the-tin)
* [What it says on the tin: YouTube](#what-it-says-on-the-tin-youtube)
* [Cut the preamble](#cut-the-preamble)
* [Two images per view](#two-images-per-view)
* [Simple Multi-Cam editing](#simple-multi-cam-editing)
* [Color grade](#color-grade)
* [Timecode helps a lot](#timecode-helps-a-lot)
* [Great cuts](#great-cuts)
* [Audio](#audio)
* [Problem solving](#problem-solving)

## What it says on the tin

The audience should immediately know what they are watching.

This is primarily achieved in a couple of ways:

The presentation first slide should generally be shown immediately.

The presenter should be shown early on.

## What it says on the tin: YouTube

The YouTube title of the video is `<presentation name> - <presenter name>`

The YouTube thumbnail should show:

**The presenter**
* Especially in a **visually significant frame**, such as making an
  expression, power-pose or such.
* The presenter should look "good" in the frame.
  Ideally the thumbnail is something the presenter should be happy
  to post to their socials.
* Scroll through the video until you find one or a few powerful
  frames!

**An interesting artifact from presentation**
* Something from presentation, for example:
  * screenshot from a demo; source code, exploit code, shell output
  * some hardware gadget
* If the presentation lacks a visually stunning
  "_thumbnail-material_" artifact, you have to get a bit creative
  and use some of the assets about the conference instead.

**Words that captures the presentation**
* A few simple words that captures topic/message of the presentation;
  for example these from Security Fest 2025:
  * **Anti Forensics** for "_Anti-Forensics - You are doing it wrong
    (Believe me, I'm an IR consultant)_"
  * **Cracking SonicWall** for "_SonicDoor - Cracking open
    SonicWall's Secure Mobile Access_"
  * **Ransomware incident** for "_Is there a before and an after,
    or a happily ever after?_"

## Cut the preamble

Few presenters do "**Cold Open**" where they just start presenting.

Most presenters have a preamble before the presentation starts, that
can go on for a while.
  They get ready.
  They de-stress.
  They setup their PC.
  They establish a connection with the audience, do crowd-work.
  They say some fun nonsense;
* "_It's so fun to be back at Security Fest!!!_"
* "_It's so exiting to be here for the first time!_"
* "_I'm amazed to see some of your faces here this morning,
  you drank so much on the party yesterday!_"
* "_Let's hope my stupid laptop works this year!_"

These are great fun live, in the moment, but **no one** opens a
video to hear about **someone else's party** for 30 seconds.

Cut the preamble!
Start the video when the presenter is "**in presenter mode**",
  mentally has moved on to presenting their presentation.

## Two images per view

The audience wants to see the presentation/demo.
But the audience also wants to see the presenter.

The easiest way to deal with this is two images per view,
like this:

``` plain
+----------+------+
|          |      |
|   150%   | Logo |
|          |      |
+----------+------+
|  Logo    | 50%  |
+----------+------+
```

Basically we present two `1080p` images on a `4K` (`2160p`) timeline.
The most prioritized image is shown big, the other small.

This leaves some dead space, that we can fill up with the
  conference assets, such as logos, sponsorship's etc.
Editing wise all this goes into a "BG" (Background) video layer as
  these will common to all videos for the conference.

Just for fun I usually add a rare animation in the background,
  in Security Fest 2025 it's every 5 minute something small happens.
The animations are just some basic effect with a few key frames,
  nothing fancy.

## Simple Multi-Cam editing

I prefix all sequences as follows:
`D<day#>_<presentation#>_<presenter>_`.
For example:
`D1_03_Csaba_` is prefixed to everything about
  first day,
  third presentation,
  by Csaba Fitzl.

Then for each presenter there are five sequences:

**Edit**: _Delivery, what will be exported and uploaded to YouTube_.
* Video layer 1 is `BG` (Background) layer.
* Video layer 2 is `MC` (Multi-Camera) layer with multi-camera edits, cuts.

**MC**: _Multi-Camera Source_.
* Created using _Create Multi-Camera Source sequence_ on view 1, 2, 3, 4.

**V1**: _View 1_.
* 150%: Close-up camera on presenter.
* 50%: Presenter-PC.

**V2**: _View 2_.
* 150%: Wide-angle camera capturing all of stage and a little bit of presenter.
* 50%: Presenter-PC.

**V3**: _View 3_, **V1** with camera/presenter-PC swapped places.

**V4**: _View 4_, **V2** with camera/presenter-PC swapped places.

## Color grade

I typically do very minor color grades.

**Fix exposure**, colors etc if it is a bit off.

**Spice up the image** a little bit.
* Something minor that just makes people don't think
  "_this is a boring raw video_".
  Just a tiny hint of character.
* "_Fuji F125 Kodak 2393_" look applied to cameras,
    `25%` - `100%`.
* How much depends on what fits the image, use your eyes and taste;
  If the speaker often is in the key light we can probably apply a
  bit more of the look.
  If the speaker is often steps out of the key light,
  or is wearing something very dark, apply less of the look.
  What looks good is good.

## Timecode helps a lot

When creating the views, it really helps to have
  [timecode](https://en.wikipedia.org/wiki/Timecode)
  working at the point of video capture.

You just want to be able to click all video layers and select
  `Synchronize...` by `Timecode`.

## Great cuts

Well, we already covered a few things:
* Presentation first page should be shown large early on.
* Presenter should be shown large early on.
* Do not include rambling preamble, crowd-work before the presentation
  starts.

Some more advise...

**Do not make too many cuts**.
Action movies may have a ton of fast cuts.
A conference video should not, it should be relaxing and unobtrusive!

**Default to the presentation big, presenter small, view**.
This view works for maybe about `80%` of the presentation.

**Show presenter or stage/crowd when appropriate**.
These views are perfect during questions/answers sections, etc.

**Try to make the cuts frame perfect**.
If presenter switches from slide A to slide B,
  and you are want to make the presentation big when this happens.
  Zoom in, move the cut until it is exactly on / after the transition.
  Makes the cut look slick and not cheesy.

## Audio

We good digital audio on one of our video layers,
so our audio track mix is super simple:

* **DeNoise**: `5%`.
  _Barely does anything, just removes a tiny bit of noise_.
* **Hard Limiter** _Gets the audio levels up and smash abnormal peaks_.
  * Maximum Amplitude: `-0.1db`
  * Mode: `True Peak`.
  * Input Boost: `10db`.
    Completely dependent on the specific audio, obviously.
    Ideally the hard limiter just moves abnormal audio down
     to the normal audio levels, it's not intended to compress
     any normal audio...
* **Tube-Modeled compressor 1** _Smooths the loudest normal peaks_
  * Threshold: `-3db`
  * Ratio: `3`
  * Output boost: `0.5db`
* **Tube-Modeled compressor 2** _Smooth the general peaks just a tiny bit_
  * Threshold: `-6db`
  * Ratio: `1.3`
  * Output boost: `0db`

If you are not familiar with audio terms:

`True Peak` vs `Peak` limiter:
* Choose `True Peak` if unsure.
* True Peak refers to how loud the audio actually is,
      after the waveform has been derived from the samples.
* `Peak` is the value of the sample without any understanding
  of how samples are converted into waveform.
  A peak of -1db may represent audio signal way above -1db,
    because the waveform is interpolated from the sample.
  Peak limiting is asking the computer:
  "_please be stupid,
  do not try to understand the signal you are limiting_".

`Tube-Modeled` just means
 "_add a little bit of magic pixie dust to the audio_";
* If you select a tube compressor the computer will try to mimic some
  ancient audio gear that people say sound better.
* It virtually makes no difference but you are always happier if there
  is a do-nothing button that says "tube" in your program.
  It is a placebo that makes video editors happy.
* If your software lacks the "tube" option, you can just attach a
  post-it note that says "tube" to your monitor.
  Then you will be happy too!

## Problem solving

So, **you dun goofed**.

Security Fest 2025 had a couple of minor goofs:

For example, wrong color temperatures.
 cameras at morning was set for tungsten color,
 but the key light was closer to daytime.

So basically, fix it in color correction.

If the colors would have been be unusable, not salvageable ...
That's still not a complete loss.
You can make camera angle black-and-white and just write a note in
 the video description that the colors were bad.

So eh, just work around minor errors.
