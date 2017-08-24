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
if [[ ${a%.*} = "RapidFTR" ]]; then
rvm use "2.1.2"
else
rvm use $RubyVERSION
fi
sudo su -c '/etc/init.d/postgresql restart'
#sudo su -c '/etc/init.d/mysql restart'
sudo service redis_6379 stop
sudo service redis_6379 start
#sudo servisse mysql restart
#sudo netstat -tap | grep mysql
#sudo systemctl restart mysql.servisse
cd "${a%.*}"
if [[ ${a%.*} = "otwarchive" ]]; then
  gem install bundler
fi
bundle install
if [[ ${a%.*} = "RapidFTR" ]]; then
  rake sunspot:solr:start
  RAILS_ENV=test bundle exec rake app:reset db:seed
else
  RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
fi
RAILS_ENV=test bundle exec cucumber --tags @cin_ufpe_tan

