---
layout: post
title:  "Git Octopus Merge with Unrelated histories"
date:   2025-03-19 16:00:00 +0100
categories: development
---

Merging multiple different feature / product repositories into one
monorepo, you will need to deal with _Unrelated histories_.
Gits that share no common history.
Git defaults are not a fan of this, as this is normally an indication
that the user is doing something wrong.

But, lets **celebrate being wrong** and create **one happy merge**
where our new child has **several different parent branches**!

`TL;DR:`

* `git merge --allow-unrelated-histories branch` allows merging one
  branch.
* `git merge branch1 branch2 ... branchN` will enable `-s octopus`
  by default, but does not support unrelated histories.
* `git merge --allow-unrelated-histories branch1 branch2 ... branchN`
  will start a failing merge;
  _Unable to find common commit with ...
  Automatic merge failed;
  fix conflicts and then commit the result_
  but there is a workaround:
  [Stackoverflow: Git octopus merge with unrelated repositories](https://stackoverflow.com/questions/10874149/git-octopus-merge-with-unrelated-repositories)
  * `git read-tree branch1 branch2 ... branchN`
  * `git merge --continue`
  * `git reset --hard`

Octopus strategy creates histories like this:

``` plain
 a1 -> a2 --\
 b1 -> b2 ---> M
 c1 -> c2 --/
```

Merging the branches individually create histories like this:

``` plain
 a1 -> a2 --\
 b1 -> b2 ---> M1 --> M2
        c1 -> c2 --/
```

Clearly, any sane person will spend time getting an octopus with
unrelated history working.
The peace of mind of preserving all history and having a cool
multi-history commit is incredible.

**Table of Contents**:
* [Preparing a git test repository](#preparing-a-git-test-repository)
* [Creating temporary branches](#creating-temporary-branches)
* [Octopus merge multiple branches](#octopus-merge-multiple-branches)
* [Normal merge multiple branches](#normal-merge-multiple-branches)


## Preparing a git test repository

First, create and initialize a local git repository:

``` bash
mkdir test
cd test/

git init .
# hint: Using 'master' as the name for the initial branch. This default branch name
# hint: is subject to change. To configure the initial branch name to use in all
# hint: of your new repositories, which will suppress this warning, call:
# hint:
# hint:   git config --global init.defaultBranch <name>
# hint:
# hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
# hint: 'development'. The just-created branch can be renamed via this command:
# hint:
# hint:   git branch -m <name>
```

Second, add all the remotes git:


``` bash
git remote add \
 mastodon-announce-from-rss \
 https://github.com/blaufish/mastodon-announce-from-rss.git

git remote add \
 twitter-announce-from-rss \
 https://github.com/blaufish/twitter-announce-from-rss.git

git remote add \
 bluesky-announce-from-rss \
 https://github.com/blaufish/bluesky-announce-from-rss.git
```

Third, download all history:

``` bash
git fetch --all
# Fetching mastodon-announce-from-rss ...
# Fetching twitter-announce-from-rss ...
# Fetching bluesky-announce-from-rss ...
```

## Creating temporary branches

Fix any unnecessary merge preventing issues before you try to merge.
For example, you don't want three different `README.md` to be merged
into one document...

Create the branches:

``` bash
git branch tmp-mastodon-announce-from-rss mastodon-announce-from-rss/master
# branch 'tmp-mastodon-announce-from-rss' set up to track 'mastodon-announce-from-rss/master'.

git branch tmp-twitter-announce-from-rss twitter-announce-from-rss/master
# branch 'tmp-twitter-announce-from-rss' set up to track 'twitter-announce-from-rss/master'.

git branch tmp-bluesky-announce-from-rss bluesky-announce-from-rss/master
# branch 'tmp-bluesky-announce-from-rss' set up to track 'bluesky-announce-from-rss/master'.
```

Switch to one of the branches you want to make ready to merge:

``` bash
git switch tmp-mastodon-announce-from-rss
# Switched to branch 'tmp-mastodon-announce-from-rss'
# Your branch is up to date with 'mastodon-announce-from-rss/master'.
```

Move files into a subdirectory that can be merged into the shared
branch (repository):

``` bash
mkdir mastodon-announce-from-rss
git mv .gitattributes .gitignore README.md mastodon-rss-bot.py requirements.in requirements.txt spellcheck.sh venv.sh mastodon-announce-from-rss

git commit -m "Prepare branch for merge"
# [tmp-mastodon-announce-from-rss 3189918] Prepare branch for merge
#  8 files changed, 0 insertions(+), 0 deletions(-)
# rename .gitattributes => mastodon-announce-from-rss/.gitattributes (100%)
# rename .gitignore => mastodon-announce-from-rss/.gitignore (100%)
# rename README.md => mastodon-announce-from-rss/README.md (100%)
# rename mastodon-rss-bot.py => mastodon-announce-from-rss/mastodon-rss-bot.py (100%)
# rename requirements.in => mastodon-announce-from-rss/requirements.in (100%)
# rename requirements.txt => mastodon-announce-from-rss/requirements.txt (100%)
# rename spellcheck.sh => mastodon-announce-from-rss/spellcheck.sh (100%)
# rename venv.sh => mastodon-announce-from-rss/venv.sh (100%)
```

Fix your other branches, `tmp-twitter-announce-from-rss` and
`tmp-bluesky-announce-from-rss` in a similar fashion.

## Octopus merge multiple branches

Now, lets create a new master branch:

``` bash
git switch master
# hint: If you meant to check out a remote tracking branch on, e.g. 'origin',
# hint: you can do so by fully qualifying the name with the --track option:
# hint:
# hint:     git checkout --track origin/<name>
# hint:
# hint: If you'd like to always have checkouts of an ambiguous <name> prefer
# hint: one remote, e.g. the 'origin' remote, consider setting
# hint: checkout.defaultRemote=origin in your config.
# fatal: 'master' matched multiple (3) remote tracking branches
```

Okay, that was ambiguous and git gave up.

Lets clarify we wanted a new empty master branch:

``` bash
git switch --orphan master
# Switched to a new branch 'master'
```

Now lets try octopus merge:

``` bash
git merge \
 -m "Octopus merge all feature-repos into one mono-repo" \
 tmp-mastodon-announce-from-rss \
 tmp-twitter-announce-from-rss \
 tmp-bluesky-announce-from-rss
# fatal: Can merge only exactly one commit into empty head
```

Octopus merge does not want to start in an _empty head_.
You wither need to do this in an **existing branch**,
or alternatively, create an **empty commit**:

``` bash
git commit --allow-empty -m "Empty root"
# [master (root-commit) 552dc6b] Empty root
```

If you try again you will hit the _unrelated histories_ error:

``` bash
git merge \
 -m "Octopus merge all feature-repos into one mono-repo" \
 tmp-mastodon-announce-from-rss \
 tmp-twitter-announce-from-rss \
 tmp-bluesky-announce-from-rss
# fatal: refusing to merge unrelated histories
```

Now lets tell it that yes, we do want to merge unrelated histories:

``` bash
git merge \
 -m "Octopus merge all feature-repos into one mono-repo" \
 --allow-unrelated-histories \
 tmp-mastodon-announce-from-rss \
 tmp-twitter-announce-from-rss \
 tmp-bluesky-announce-from-rss
# Unable to find common commit with tmp-mastodon-announce-from-rss
# Automatic merge failed; fix conflicts and then commit the result.
```

This is perfectly fine and not an error,
but remember that you can always `git merge --abort` if unsure.

To resolve the error, append the history/files and continue:

``` bash
git read-tree \
 tmp-mastodon-announce-from-rss \
 tmp-twitter-announce-from-rss \
 tmp-bluesky-announce-from-rss
```

Do note that if you had something important on `master` instead of
empty, you probably should `git read-tree` that branch as well.

Then continue the merge:

``` bash
git merge --continue
# [master 072e500] Octopus merge all feature-repos into one mono-repo
```

Lets inspect the resulted octopus merge:

``` bash
git log --graph --decorate --pretty=oneline --abbrev-commit
# *---.   072e500 (HEAD -> master) Octopus merge all feature-repos into one mono-repo
# |\ \ \
# | | | * 1ee7daa (tmp-bluesky-announce-from-rss) Prepare branch for merge
# | | | * ca2fba8 (bluesky-announce-from-rss/master) Convert entities, e.g. &amp; to &
# | | | * 323c282 Delete dead code: timestruct_to_isoformat
# | | | * 60781fa RSS to Bluesky announcer
# | | * 0b933b0 (tmp-twitter-announce-from-rss) Prepare branch for merge
# | | * e51817a (twitter-announce-from-rss/master) git repo setup: .gitattributes .gitignore
# | | * 6f82915 Lets remove the test snippet
# | | * 4caf445 Lets memorialize this little test snippet
# | | * 2b405e6 Documentation + spellchecker
# | | * 8b931c0 Virtual environment
# | | * d765612 Implement tweeting :)
# | | * 3e20c8c Check RSS first, exit early if possible
# | | * ac00dd0 Add a test-tweet feature
# | | * 0003816 Cleanup
# | | * 2600199 Initial draft code
# | * 3189918 (tmp-mastodon-announce-from-rss) Prepare branch for merge
# | * f9a051f (mastodon-announce-from-rss/master) Remove dead code, tweak formatting
# | * c185fa9 Remove dead code
# | * 22ce4bb README.md
# | * 4689448 Well. This seems to be working.
# | * a462751 Mastadonifying code a bit more
# | * c5e6cef Mastodonify a bit more
# | * fe5043a Begin mastodonify code
# | * 763a3bd Begin mastodonifying code base
# | * 723cd82 Squash twitter-announce-from-rss/master
# * 552dc6b Empty root
```

Effectively we merged our current empty branch with three branches.

Fiddling around with merge errors and `read-tree` can cause your
local checked out files to be in an inconsistent state.

So `reset` local directory to return to a consistent state:

``` bash
git reset --hard
HEAD is now at 072e500 Octopus merge all feature-repos into one mono-repo
```

Use `git reset 552dc6b` or `git rebase -i --root`
if you want to undo the merges.

## Normal merge multiple branches

Normal merge is easier and may be preferred by some..

Checkout the master:

``` bash
git switch --orphan master
# Switched to a new branch 'master'
```

Merge the the branches:

``` bash
git merge \
 -m "Merge" \
 --allow-unrelated-histories \
 tmp-mastodon-announce-from-rss
# Merge made by the 'ort' strategy.
#  mastodon-announce-from-rss/.gitattributes      |   5 ++++
#  mastodon-announce-from-rss/.gitignore          |   4 +++
#  mastodon-announce-from-rss/README.md           |  80 ++++++++++++++++++++++++++++++++++++++++++++++++++++
#  mastodon-announce-from-rss/mastodon-rss-bot.py | 257 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  mastodon-announce-from-rss/requirements.in     |   2 ++
#  mastodon-announce-from-rss/requirements.txt    |  13 +++++++++
#  mastodon-announce-from-rss/spellcheck.sh       |  17 +++++++++++
#  mastodon-announce-from-rss/venv.sh             |  19 +++++++++++++
#  8 files changed, 397 insertions(+)
#  create mode 100644 mastodon-announce-from-rss/.gitattributes
#  create mode 100644 mastodon-announce-from-rss/.gitignore
#  create mode 100644 mastodon-announce-from-rss/README.md
#  create mode 100755 mastodon-announce-from-rss/mastodon-rss-bot.py
#  create mode 100644 mastodon-announce-from-rss/requirements.in
#  create mode 100644 mastodon-announce-from-rss/requirements.txt
#  create mode 100755 mastodon-announce-from-rss/spellcheck.sh
#  create mode 100755 mastodon-announce-from-rss/venv.sh

git merge \
 -m "Merge" \
 --allow-unrelated-histories \
 tmp-twitter-announce-from-rss
# ...

git merge \
 -m "Merge" \
 --allow-unrelated-histories \
 tmp-bluesky-announce-from-rss
# ...
```

Lets inspect the results!

``` bash
ls
# bluesky-announce-from-rss  mastodon-announce-from-rss  twitter-announce-from-rss

git log --graph --decorate --pretty=oneline --abbrev-commit
# *   d87ae98 (HEAD -> master) Merge
# |\
# | * 1ee7daa (tmp-bluesky-announce-from-rss) Prepare branch for merge
# | * ca2fba8 (bluesky-announce-from-rss/master) Convert entities, e.g. &amp; to &
# | * 323c282 Delete dead code: timestruct_to_isoformat
# | * 60781fa RSS to Bluesky announcer
# *   6e5f8a6 Merge
# |\
# | * 0b933b0 (tmp-twitter-announce-from-rss) Prepare branch for merge
# | * e51817a (twitter-announce-from-rss/master) git repo setup: .gitattributes .gitignore
# | * 6f82915 Lets remove the test snippet
# | * 4caf445 Lets memorialize this little test snippet
# | * 2b405e6 Documentation + spellchecker
# | * 8b931c0 Virtual environment
# | * d765612 Implement tweeting :)
# | * 3e20c8c Check RSS first, exit early if possible
# | * ac00dd0 Add a test-tweet feature
# | * 0003816 Cleanup
# | * 2600199 Initial draft code
# *   3b583e1 Merge
# |\
# | * 3189918 (tmp-mastodon-announce-from-rss) Prepare branch for merge
# | * f9a051f (mastodon-announce-from-rss/master) Remove dead code, tweak formatting
# | * c185fa9 Remove dead code
# | * 22ce4bb README.md
# | * 4689448 Well. This seems to be working.
# | * a462751 Mastadonifying code a bit more
# | * c5e6cef Mastodonify a bit more
# | * fe5043a Begin mastodonify code
# | * 763a3bd Begin mastodonifying code base
# | * 723cd82 Squash twitter-announce-from-rss/master
# * 552dc6b Empty root
```

Well. That works and what was easy.
If you can live with having multiple merges, this is fine.

Use `git reset 552dc6b` or `git rebase -i --root`
if you want to undo merges.

