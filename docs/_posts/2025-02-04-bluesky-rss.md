---
layout: post
title:  "Bluesky RSS announcer"
date:   2025-02-04 21:00:00 +0100
categories: development
---

A [Bluesky announcement script](https://github.com/blaufish/bluesky-announce-from-rss)
that I wrote in `python`:

Consuming and parsing an [RSS](https://en.wikipedia.org/wiki/RSS) web feed.
Embed and post to Bluesky using [AT Protocol](https://en.wikipedia.org/wiki/AT_Protocol)
also known _Authenticated Transfer Protocol_ or _ATProto_.

So a blog, podcast provider or similar may set up a
`cron` job (or workflow, action or similar)
that routinely tells their followers if there are news to consume!

A reasonable effort is made to avoid spamming;
will not post anything recently posted,
will not post old RSS entries,
will not post more posts than configured,
will only post if `--no-dry-run` is configured.

Quick and dirty hack, but useful to us!

Index:

* [Usage](#usage)
* [Secrets Management](#secrets-management)
* [RSS](#rss)
* [Bluesky login](#bluesky-login)
* [Bluesky list recent posts](#bluesky-list-recent-posts)
* [Bluesky list embeds in recent posts](#bluesky-list-embeds-in-recent-posts)
* [Bluesky post new announcements](#bluesky-post-new-announcements)
* [Dependencies](#dependencies)

## Usage

`./bsky-rss-bot.py -h`

``` plain
usage: bsky-rss-bot.py [-h] --url URL --handle HANDLE --secret SECRET --secret-type {arg,env,file} [--dry-run | --no-dry-run] [--loglevel {DEBUG,INFO,WARNING,ERROR,CRITICAL}] [--days DAYS] [--posts POSTS]

bluesky bot

options:
  -h, --help            show this help message and exit
  --url URL             URL to lib-syn RSS feed, e.g. https://sakerhetspodcasten.se/index.xml
  --handle HANDLE       bluesky handle
  --secret SECRET       bluesky secret
  --secret-type {arg,env,file}
                        bluesky secret type
  --dry-run, --no-dry-run
                        dry-run inhibits posting (default: True)
  --loglevel {DEBUG,INFO,WARNING,ERROR,CRITICAL}
  --days DAYS           Maximum days back in RSS history to announce
  --posts POSTS         Maximum posts to emit, avoid spamming

Hope this help was helpful! :-)
```

Example:
``` bash
./bsky-rss-bot.py \
   --url https://sakerhetspodcasten.se/index.xml \
   --handle blaufish.bsky.social \
   --days 60 \
   --dry-run \
   --secret .bluesky2.secret \
   --secret-type file
```

Example output:
``` plain
2025-02-04 10:53:03,238 INFO Request feed from https://sakerhetspodcasten.se/index.xml
2025-02-04 10:53:03,277 INFO RSS candidate: Säkerhetspodcasten #275 - Ostukturerat V.6
2025-02-04 10:53:03,277 INFO RSS candidate: Säkerhetspodcasten #274 - Fyra fantastiska frågor
2025-02-04 10:53:03,277 INFO RSS candidate: Säkerhetspodcasten #273 - Ostrukturerat V.50
2025-02-04 10:53:03,607 INFO Bluesky lookup: blaufish.bsky.social=did:plc:y25e3xvbgsjuqcxjdybktovi
2025-02-04 10:53:04,886 INFO Disregard already published: https://sakerhetspodcasten.se/posts/sakerhetspodcasten_275_ostukturerat_v_6/
2025-02-04 10:53:04,886 INFO Disregard already published: https://sakerhetspodcasten.se/posts/sakerhetspodcasten_274_fyra_fantastiska_fragor/
2025-02-04 10:53:04,886 INFO Disregard already published: https://sakerhetspodcasten.se/posts/sakerhetspodcasten_273_ostrukturerat_v_50/
2025-02-04 10:53:04,886 INFO Terminating normally. Thanks for All the Fish!
```

## Secrets Management

The tool requires a single secret:
the Bluesky app login password.

I did not want to hard code how this secret is obtained.
What is most convenient may depend on user taste and
deployment environment.

The command line usage help includes;

``` plain
  --secret SECRET       bluesky secret
  --secret-type {arg,env,file}
                        bluesky secret type
```

Adding options to the python command line argument parser is easy:

``` python
    parser.add_argument('--secret-type',
            dest = 'secret_type',
            required = True,
            choices = ['arg', 'env', 'file'],
            help = 'bluesky secret type')
```

Implementing multiple different possible sources of secrets was also easy:

``` python
    secret = None
    match args.secret_type:
        case "arg":
            content = args.secret
            secret = content.strip()
        case "env":
            content = os.environ[args.secret]
            secret = content.strip()
        case "file":
            with open(args.secret, "r") as f:
                content = f.read();
                secret = content.strip()
        case "_":
            logger.error(f"TODO implement!")
            return
```

## RSS

The first step is to identify RSS items that are candidates for Bluesky announcement.

We establish a `threshold`, i.e. candidates posted `args.days` ago or later;

``` python
threshold = None

def main():
    global threshold
#...
    threshold = datetime.now() - timedelta(days=args.days)

    candidates = process_rss(args.url)

    if len(candidates) < 1:
        logger.info("No candiates, exiting")
        return
```

`process_rss(args.url)` will generate a list of RSS items that meet the threshold:

``` python
def process_rss(url):
    candidates = []
    logger.info(f"Request feed from {url}")
    rss = feedparser.parse(url)
    entries = rss['entries'];
    for entry in entries:
        candidate = process_entry(entry)
        if (candidate):
            candidates.append(entry)
    return candidates
```

Each RSS entry will be evaluated if it meets the threshold using `process_entry(entry)`:

``` python
def process_entry(e):
    link             = e['link']
    published_parsed = e['published_parsed']
    published        = e['published']
    title            = e['title']

    ts = time.mktime( published_parsed )
    dt = datetime.fromtimestamp(ts)

    if dt > threshold:
        logger.info(f"RSS candidate: {title}")
        return True
    else:
        logger.debug(f"RSS skipping old entry: {title}")
        return False
```

The `published_parsed` is a python-friendly version of RSS `item.pubDate`,
that reasonably easy can be converted to a `datetime` object and compared to `threshold`.

So, the rest of the code work with recent RSS entries only, nothing old will be processed
later on.

## Bluesky login

Login is pretty easy; you need to username/handle `args.handle`,
and the `secret` application password:

``` python
    client = atproto_client.client.client.Client()
    client.login(args.handle, secret)
```

## Bluesky list recent posts

We want to avoid re-posting / spamming the same entries again and again.
Therefor we will look up the recent posts from our announcement user:

``` python
    did = bsky_lookup(args.handle)
    logger.info(f"Bluesky lookup: {args.handle}={did}")

    posts = bsky_posts(client, did)
```

The user lookup is just a wafer-thin wrapper around `HandleResolver`:
``` python
def bsky_lookup(_id):
    resolver = atproto_identity.handle.resolver.HandleResolver()
    did = resolver.resolve(_id)
    return did
```

Similarly, the post lookup is just a wafer-thin wrapper around `client.get_author_feed()`:
``` python
def bsky_posts(client, did):
    responses = client.get_author_feed(
        actor=did,
        filter='posts_and_author_threads',
        limit=30
        )
    return responses
```

## Bluesky list embeds in recent posts

Now we create a simple list of all URIs that are included
in a recent `app.bsky.embed.external#view` embedding:

``` python
    tweeted = []
    for entry in posts.feed:
        post = entry.post
        record = post.record
        embed = post.embed
        if embed is None:
            continue
        if embed.py_type != 'app.bsky.embed.external#view':
            continue
        external = embed.external
        uri = external.uri
        tweeted.append(uri)
        logger.debug(f"Bluesky embeded: {uri}")
```

## Bluesky post new announcements

Now, it is time to loop through all `candidates` that met the threshold.

We will skip old `candidate.link` entries that are on the already tweeted/posted list.

``` python
    posts = 0
    for candidate in candidates:
        if posts >= args.posts:
            logger.info(f"Stopping posting after reaching post limit: {posts}")
            break
        announce = True
        for old in tweeted:
            if candidate.link == old:
                logger.info(f"Disregard already published: {old}")
                announce = False
                break
        if announce:
            logger.debug(f"Prepare post: {candidate.link}")
            bsky_post(client, candidate, args.dryrun)
            posts = posts + 1

    logger.info("Terminating normally. Thanks for All the Fish!")
```

Posting the announcement is rather easy using `client.send_post()`,
`AppBskyEmbedExternal.Main` and `AppBskyEmbedExternal.External`.

> **NOTE**:
> I did run into some complications with reading an outdated
> documentation somewhere, so I had a few `__pydantic_validator__`
> issues until I got the code correctly aligned with the current SDK)

``` python
def bsky_post(client, candidate, dryrun):
    c_title = candidate.title
    c_description = candidate.description
    c_uri = candidate.link

    #...specific to our podcast, ignore...
    c_desc = re.sub(r"Lyssna mp3, längd: ", "", c_description)
    c_desc = re.sub(r" Innehåll ", " ", c_desc)

    logger.debug(f"c_title: {c_title}")
    logger.debug(f"c_description: {c_description}")
    logger.debug(f"c_desc: {c_desc}")
    logger.debug(f"c_uri: {c_uri}")

    embed_external = models.AppBskyEmbedExternal.Main(
        external = models.AppBskyEmbedExternal.External(
            title = c_title,
            description = c_desc,
            uri = c_uri,
            )
    )
    text = "📣 " + c_title + " 📣 " + c_desc
    text300 = truncate( text, 300 )
    if dryrun:
        logger.info(f"Dry-run post: {c_uri}")
    else:
        logger.info(f"Post: {c_uri}")
        post = client.send_post( text=text300, embed=embed_external )
        logger.info(f"post.uri: {post.uri}")
        logger.info(f"post.cid: {post.cid}")
```

Truncating the text to the 300-limit is done as follows:

``` python
def truncate( text, maxlen ):
    if len(text) < maxlen:
        return text
    idx = text.rfind(" ", 0, maxlen-3)
    return text[:idx] + "..."
```

An observant code reviewer can easily come up with cases where
the truncation will break on evil input...
So room for future improvements!

## Dependencies

`feedparser`.
Consumes RSS using [feedparser](https://pypi.org/project/feedparser/).
This part was fairly easy as I have a bunch of earlier RSS processing projects,
parts of the code was just copy-paste similar code.

`atproto`.
Reads and Posts to Bluesky using [The AT Proto SDK for Python](https://atproto.blue/en/latest/).

