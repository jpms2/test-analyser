#!/bin/bash
git clone $1
a=$1; a="${a#*/}";a="${a#*/}";a="${a#*/}";a="${a#*/}"
cd "${a%.*}"
git stash
git checkout $2
if [[ ${a%.*} != "otwarchive" ]]; then
  gem install bundler
fi
