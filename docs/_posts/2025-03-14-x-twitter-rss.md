---
layout: post
title:  "X/Twitter RSS announcer"
date:   2025-03-14 14:30:00 +0100
categories: development
---

[twitter-announce-from-rss](https://github.com/blaufish/twitter-announce-from-rss)
is a X/Twitter fork of the
[bluesky-announce-from-rss](https://github.com/blaufish/bluesky-announce-from-rss)
that I announced earlier.
The twitter specific coding was largely inspired by
[Medium/Nikhil C: Posting to twitter with Python — The experience and code](https://medium.com/@cn.april/posting-to-twitter-with-python-the-experience-and-code-fe62418e5af1).

Script is:
Consuming and parsing an [RSS](https://en.wikipedia.org/wiki/RSS) web feed.
Posting to twitter using [tweepy](https://pypi.org/project/tweepy/),
appending link to the last part of the tweet.
Other dependencies includes
[feedparser](https://pypi.org/project/feedparser/) and
[requests](https://pypi.org/project/requests/).

So a blog, podcast provider or similar may set up a
`cron` job (or workflow, action or similar)
that routinely tells their followers if there are news to consume!

A reasonable effort is made to avoid spamming;
will not post anything recently posted,
will not post old RSS entries,
will not post more posts than configured,
will only post if `--no-dry-run` is configured.

Quick and dirty hack, but does what I want it to do :)

**Table of Contents:**

* [Usage](#usage)
* [Twitter developer settings and considerations](#twitter-developer-settings-and-considerations)
* [Secrets Management](#secrets-management)
* [Login](#login)
* [Lookup my user identity](#lookup-my-user-identity)
* [List recent posts](#list-recent-posts)
* [Decode short URL](#decode-short-url)
* [Tweeting an RSS entry](#tweeting-an-rss-entry)
* [RSS retrieval and parsing](#rss-retrieval-and-parsing)
* [Posting new announcements](#posting-new-announcements)
* [Dependencies](#dependencies)

## Usage

`./twitter-rss-bot.py -h`

``` plain
usage: twitter-rss-bot.py [-h] --url URL --access-token ACCESS_TOKEN
                          --access-token-secret ACCESS_TOKEN_SECRET
                          --consumer-key CONSUMER_KEY
                          --consumer-secret CONSUMER_SECRET
                          --bearer-token BEARER_TOKEN
                          --secret-type {arg,env,file}
                          [--dry-run | --no-dry-run]
                          [--loglevel {DEBUG,INFO,WARNING,ERROR,CRITICAL}]
                          [--days DAYS] [--posts POSTS]
                          [--test-tweet TEST_TWEET]

x/twitter bot

options:
  -h, --help            show this help message and exit
  --url URL             URL to lib-syn RSS feed, e.g. https://sakerhetspodcasten.se/index.xml
  --access-token ACCESS_TOKEN
                        x/twitter secret
  --access-token-secret ACCESS_TOKEN_SECRET
                        x/twitter secret
  --consumer-key CONSUMER_KEY
                        x/twitter secret
  --consumer-secret CONSUMER_SECRET
                        x/twitter secret
  --bearer-token BEARER_TOKEN
                        x/twitter secret
  --secret-type {arg,env,file}
                        secret type/source
  --dry-run, --no-dry-run
                        dry-run inhibits posting
  --loglevel {DEBUG,INFO,WARNING,ERROR,CRITICAL}
  --days DAYS           Maximum days back in RSS history to announce
  --posts POSTS         Maximum posts to emit, avoid spamming
  --test-tweet TEST_TWEET
                        A test tweet, e.g. "hello world testing API"

Hope this help was helpful! :-)
```

Example usage:

``` bash
./venv.sh

.venv/bin/python3 twitter-rss-bot.py \
 --url https://blaufish.github.io/feed.xml \
 --access-token secrets/blaush_access_token \
 --access-token-secret secrets/blaufish_access_token_secret \
 --consumer-key secrets/blaufish_consumer_key \
 --consumer-secret secrets/blaufish_consumer_secret \
 --bearer-token secrets/blaufish_bearer_token \
 --secret-type file \
 --days 30
```

Example output:
``` plain
2025-03-13 22:39:15,836 INFO Request feed from https://blaufish.github.io/feed.xml
2025-03-13 22:39:15,969 INFO RSS candidate: Path Length constraint limitations and bypasses
2025-03-13 22:39:18,186 INFO X/Twitter username: blaufish_
2025-03-13 22:39:18,186 INFO X/Twitter name: @blaufish_
2025-03-13 22:39:18,186 INFO X/Twitter id: 77535685
2025-03-13 22:39:22,362 INFO Disregard already published: https://blaufish.github.io/security/research/2025/02/15/path-length-constraint.html
2025-03-13 22:39:22,362 INFO Terminating normally. Thanks for All the Fish!
```

## Twitter developer settings and considerations

When configuring your application in
[developer.x.com](https://developer.x.com/),
it is important to consider:

* `User authentication settings` -> `App permissions`
  should be set to `Read and write`.
  Otherwise your bot will fail to tweet.
* `Keys and tokens` -> `Access Token and Secret`
  should say `Created with Read and Write permissions`.
  Otherwise your bot will fail to tweet.
  Regenerate token if it only has `Read` permission.

Also beware of that **Free tier** is very restrictive, see
[developer.x.com/en/portal/products](https://developer.x.com/en/portal/products).

Basically it is a good idea to wait 15 - 30 minutes between
each invocation of the bot, as you otherwise
`429 Too Many Requests` error is to be expected.

Also I add a bunch of `time.sleep(2)` at random places just in
case it makes X/Twitter less angry with my free tier usage.
I'm not in a hurry :)

Code only used API 2.0, avoiding the older API 1.1 that may become
deprecated earlier.

## Secrets Management

X/Twitter requires many secrets to operate;
and I did not want to hard code how this secret is obtained.
What is most convenient may depend on user taste
and deployment environment.

The command line usage help includes;

``` plain
--access-token ACCESS_TOKEN
--access-token-secret ACCESS_TOKEN_SECRET
--consumer-key CONSUMER_KEY
--consumer-secret CONSUMER_SECRET
--bearer-token BEARER_TOKEN
--secret-type {arg,env,file}
```

Adding options to the python command line argument parser is easy:

``` python
parser.add_argument('--secret-type',
        dest = 'secret_type',
        required = True,
        choices = ['arg', 'env', 'file'],
        help = 'secret type source')
```

Secrets are then consumed using `read_secret`

``` python
access_token = read_secret(args.access_token, args.secret_type)
access_token_secret = read_secret(args.access_token_secret, args.secret_type)
bearer_token = read_secret(args.bearer_token, args.secret_type)
consumer_key = read_secret(args.consumer_key, args.secret_type)
consumer_secret = read_secret(args.consumer_secret, args.secret_type)
```

`read_secret` implementing multiple different possible sources of
secrets like this:

``` python
def read_secret(secret_argument, secret_type):
    if secret_argument == '-':
        return None
    secret = None
    match secret_type:
        case "arg":
            content = secret_argument
            secret = content.strip()
        case "env":
            content = os.environ[secret_argument]
            secret = content.strip()
        case "file":
            with open(secret_argument, "r") as f:
                content = f.read();
                secret = content.strip()
        case "_":
            logger.error(f"TODO implement! Unknown secret_type: {secret_type}")
            return
    return secret
```

## Login

Login to X/Twitter is performed using `tweepy.Client`,
which is of the API 2.0 suite.

``` python
api2 = tweepy.Client(
    access_token=access_token,
    access_token_secret=access_token_secret,
    bearer_token=bearer_token,
    consumer_key=consumer_key,
    consumer_secret=consumer_secret
)
```

## Lookup my user identity

The bot will need to know who it is,
getting `user.data.id` from `user = api2.get_me()`.
Might as well print something nice in the log while you are at it;

``` python
user = api2.get_me()
logger.info(f'X/Twitter username: {user.data.username}')
logger.info(f'X/Twitter name: {user.data.name}')
logger.info(f'X/Twitter id: {user.data.id}')
```

## List recent posts

We only want to announce new content,
not something we have already tweeted/posted about.

Basically we need to;

1. `posts = api2.get_users_tweets(id = user_id)`
   to get recent posts / tweets.
2. `.split()` to convert a post into words
3. Loop over all words
4. Extract all `http://` and `https://` links

We look up recently posted/tweeted URLs like this:

``` python
urls = xtwitter_list_posted_urls(api2, user.data.id)
```

And inside `xtwitter_list_posted_urls` we extract the links:

``` python
def xtwitter_list_posted_urls(api2, user_id):
    posts = None
    time.sleep(2) # 429 Too Many Requests
    try:
        posts = api2.get_users_tweets(id = user_id)
    except Exception as e:
        logger.error(f"api2.get_users_tweets(...): {e}")
        return None
    urls = []
    for post in posts.data:
        #time.sleep(2) # 429 Too Many Requests
        strpost = str(post)
        words = strpost.split()
        for word in words:
            if word.startswith('https://'):
                pass
            elif word.startswith('http://'):
                pass
            else:
                continue
            if word in urls:
                continue
            urls.append(word)
    return urls
```

## Decode short URL

X/Twitter converts all URLs to `https://t.co/` links
which needs to be decoded...
So some helper methods are needed to convert shortened
URLs to long plaintext URLs;

``` python
tweeted = xtwitter_decode_urls(urls)
```

``` python
def xtwitter_decode_urls(urls):
    urls2 = []
    for url in urls:
        decoded_url = xtwitter_decode_url(url)
        if decoded_url in urls2:
            continue
        urls2.append(decoded_url)
        logger.debug(f'X/Twitter URL {url}: {decoded_url}')
    return urls2

def xtwitter_decode_url(url):
    if url.startswith('http://t.co/'):
        pass
    elif url.startswith('https://t.co/'):
        pass
    else:
        return url
    r = requests.get(url, allow_redirects=False)
    if 'Location' not in r.headers:
        return url
    decoded_url = r.headers['Location']
    return decoded_url
```

## Tweeting an RSS entry

Tweeting is super simple;

``` python
api2.create_tweet(text=text)
```

It is nice to have a bit a logging around the output,
so lets put some meat around the bones:

``` python
def xtwitter_post_raw(api2, text):
    time.sleep(2)
    out = api2.create_tweet(text=text)
    logger.info(f"Tweet errors: {out.errors}")
    logger.info(f"Tweet id: {out.data['id']}")
    logger.info(f"Tweet text: {out.data['text']}")
```

We need to convert `RSS`/`feedparser`
dictionaries to tweets;
implemented in `xtwitter_post(...)`:

``` python
def xtwitter_post(api2, candidate, dryrun):
    c_title = candidate.title
    c_description = candidate.description

    # this is very particular my specific needs ;-)
    c_desc = re.sub(r"Lyssna mp3, längd: ", "", c_description)
    c_desc = re.sub(r" Innehåll ", " ", c_desc)

    c_uri = candidate.link
    logger.debug(f"c_title: {c_title}")
    logger.debug(f"c_description: {c_description}")
    logger.debug(f"c_desc: {c_desc}")
    logger.debug(f"c_uri: {c_uri}")

    text = "📣 " + c_title + " 📣 " + c_desc

    c_uri_len = len(c_uri)
    if c_uri_len > 200:
        logger.error(f'Insanely long URI causing error: {c_uri}')
        return

    truncated_len = 240 - 1 - c_uri_len
    text_truncate = truncate( text, truncated_len )
    text_final = text_truncate + '\n' + c_uri

    if dryrun:
        logger.info(f"Dry-run post: {c_uri}")
    else:
        logger.info(f"Post: {c_uri}")
        xtwitter_post_raw(api2, text_final)

def truncate( text, maxlen ):
    if len(text) < maxlen:
        return text
    idx = text.rfind(" ", 0, maxlen-3)
    return text[:idx] + "..."
```

## RSS retrieval and parsing

> **NOTE** This code is largely identical to the Bluesky bot.
> You can ignore this section if you read my earlier code / post!)

The first step is to identify RSS items that are candidates for X/Twitter announcement.

We establish a `threshold`, i.e. candidates posted `args.days` ago or later;

``` python
threshold = None

def main():
    global threshold
#...
    # Consume RSS
    threshold = datetime.now() - timedelta(days=args.days)
    candidates = process_rss(args.url)
    if len(candidates) < 1:
        logger.info(f'No new RSS entries within the last {args.days} day(s), exiting!')
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

## Posting new announcements

Now, it is time to loop through all `candidates` that met the
threshold.

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
        xtwitter_post(api2, candidate, args.dryrun)
        posts = posts + 1

logger.info("Terminating normally. Thanks for All the Fish!")
```

## Dependencies

* [feedparser](https://pypi.org/project/feedparser/).
  Used to consumes RSS.
* [requests](https://pypi.org/project/requests/).
  HTTP/HTTPS API.
  Used to retrieves real world URLs from `https://t.co/`.
* [tweepy](https://pypi.org/project/tweepy/).
  X/Twitter 2.0 API.
