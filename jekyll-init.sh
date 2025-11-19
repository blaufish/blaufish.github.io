#!/bin/bash

# sudo apt-get update
# sudo apt install jekyll
# sudo apt install ruby-dev

export BUNDLE_PATH="$PWD/.gems"

verify_gem() {
	local regexp="$1"
	local file="$2"
	echo -n "Verify $file matches $regexp..."
	egrep -q -- "$regexp" "$file"
	case "$?" in
		0)
			echo " OK!"
			;;
		*)
			echo "Failed! ($?), Please fix!"
			exit 1
	esac
}

if [[ ! -d .git ]]
then
	git init .
fi
if [[ ! -d docs ]]
then
	mkdir -p -- docs
	jekyll new --skip-bundle docs
fi

verify_gem '^# gem "jekyll",' docs/Gemfile
verify_gem '^gem "github-pages",' docs/Gemfile

if [[ ! -d "$BUNDLE_PATH" ]]
then
	mkdir -p -- "$BUNDLE_PATH"
	( cd docs && bundle install --no-cache )
fi

if [[ ! -f .gitignore ]]
then
	cat > .gitignore <<EOF
.gem
docs/Gemfile.lock
EOF
fi

verify_gem '^docs/Gemfile.lock' .gitignore
echo "-----------------------"
egrep '^(title|e-mail|description|url|[a-z]_username):' docs/_config.yml
echo "-----------------------"

( cd docs && bundle exec jekyll serve )
