#!/bin/bash
 
RubyVERSION=""

if [ -z "$3" ]; then
NUMERAL=`echo $4 | cut -c1-1`
DECIMAL=`echo $4 | cut -c3-3`

if ((NUMERAL >= 1)); then
    if ((NUMERAL <= 2)); then
        RubyVERSION="1.8.6"
    fi
fi
if [[ "$NUMERAL" = "2" ]]; then
    if [[ "$DECIMAL" = "2" ]]; then
        RubyVERSION="1.8.7"
    fi
fi
if [[ "$NUMERAL" = "2" ]]; then
    if [[ "$DECIMAL" = "3" ]]; then
        RubyVERSION="1.9.3"
    fi
fi
if ((NUMERAL >= 3)); then
    RubyVERSION="2.1.0"
fi
else
	RubyVERSION=$3
fi
if [[ "$RubyVERSION" = "2.0.0" ]]; then
	rvm install $RubyVERSION --disable-binary
else
	rvm install $RubyVERSION
fi
source ~/.rvm/scripts/rvm
type rvm | head -n 1
a=$1; a="${a#*/}";a="${a#*/}";a="${a#*/}";a="${a#*/}"
if [[ ${a%.*} = "whitehall" ]]; then
rvm use "2.1.4"
else
  if [[ ${a%.*} = "RapidFTR" ]]; then
    rvm use "2.1.2"
  else
    rvm use $RubyVERSION
  fi
fi

sudo su -c '/etc/init.d/postgresql restart'
sudo su -c '/etc/init.d/mysql restart'

cd "${a%.*}"

if [[ ${a%.*} = "WebsiteOne" ]]; then
  wget https://github.com/AgileVentures/setup-scripts/raw/develop/scripts/rails_setup.sh
HEADLESS=true WITH_PHANTOMJS=true REQUIRED_RUBY=2.1.1 source rails_setup.sh

else
  if [[ ${a%.*} = "otwarchive" || ${a%.*} = "WebsiteOne" ]]; then
    gem install bundler
  fi
  if [[ ${a%.*} = "RapidFTR" ]]; then
    rake sunspot:solr:start
    rake app:reset
  fi

  if [[ ${a%.*} = "otwarchive" ]]; then
    RAILS_ENV=test bundle exec rake db:drop db:setup db:migrate
  fi

  if [[ ${a%.*} = "one-click-orgs" ]]; then 
    bundle exec rake oco:generate_config
  fi

  bundle install
  if [[ ${a%.*} = "whitehall" ]]; then
    RAILS_ENV=test bundle exec rake db:setup
  else
    if [[ ${a%.*} != "otwarchive" ]]; then
      if [[ ${a%.*} != "RapidFTR" ]]; then
        RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
      fi
    fi
  fi
fi
RAILS_ENV=test bundle exec cucumber --tags @cin_ufpe_tan
