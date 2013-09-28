#!/bin/bash
LOGSTASH_VERSION=1.1.13

RESTORE='\033[0m'
RED='\033[00;31m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

BOLD=`tput bold`
NORMAL=`tput sgr0`

handle_error() {
  echo "FAILED: line $1, exit code $2"
  cleanup
  exit 1
}

handle_ctrl_c() {
  echo "Installation INTERRUPTED!"
  cleanup
  exit 1
}

print_title()
{
  echo -e "${BLUE}${BOLD}$1${RESTORE}${NORMAL}"
}

print_action()
{
  echo -e "${RED}${BOLD}$1${RESTORE}${NORMAL}"
}

print_success()
{
  echo -e "${GREEN}${BOLD}$1${RESTORE}${NORMAL}"
}

cleanup()
{
  print_action "Cleaning up"
  rm -rf $LOGSTASH_TMP_DIR
  rm -rf $ELASTICSEARCH_TMP_DIR
  rm -rf $KIBANA_TMP_DIR
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   usage
   exit 1
fi

trap 'handle_error $LINENO $?' ERR
trap 'handle_ctrl_c' INT

print_title "Installing Logstash server"

print_action "Upgrading Debian system"
apt-get -y update
apt-get -y upgrade

print_action "Installing Java"
apt-get -y install default-jre

print_action "Installing ElasticSearch"
ELASTICSEARCH_TMP_DIR=`mktemp -d elasticsearch.XXXXXX`
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.1.deb -O $ELASTICSEARCH_TMP_DIR/elasticsearch.deb
sudo dpkg -i $ELASTICSEARCH_TMP_DIR/elasticsearch.deb

print_action "Installing Git and Rubygems"
apt-get -y install git rubygems
gem install fpm

print_action "Creating Logstash package"
LOGSTASH_TMP_DIR=`mktemp -d logstash.XXXXXX`
git clone https://github.com/rdcastro/logstash-packaging.git $LOGSTASH_TMP_DIR/logstash --depth=1
( cd "$LOGSTASH_TMP_DIR" && ./logstash/package-common.sh -f )
( cd "$LOGSTASH_TMP_DIR" && ./logstash/package-server.sh -f )

print_action "Installing Logstash package"
sudo dpkg -i $LOGSTASH_TMP_DIR/logstash-common_${LOGSTASH_VERSION}_all.deb
sudo dpkg -i $LOGSTASH_TMP_DIR/logstash-server_${LOGSTASH_VERSION}_all.deb

print_action "Starting Logstash"
service logstash restart

print_action "Installing Kibana"
KIBANA_TMP_DIR=`mktemp -d kibana.XXXXXX`
sudo apt-get -y install ruby-tzinfo ruby-daemons ruby-sinatra libjs-jquery ruby-rack ruby-tilt ruby-rack-protection ruby-fastercsv
wget http://blog.calhariz.com/public/sft/kibana/kibana_0.2.0_35_g40f2512_6-2_all.deb -O $KIBANA_TMP_DIR/kibana.deb
sudo dpkg -i $KIBANA_TMP_DIR/kibana.deb
sudo sed -i "s/KibanaHost = '127.0.0.1'/KibanaHost = '0.0.0.0'/" /etc/kibana/KibanaConfig.rb

print_action "Restarting Kibana"
sudo service kibana restart

print_action "Installing and Configuring Redis"
sudo apt-get install -y redis-server
sudo sed -i "s/bind 127.0.0.1/bind 0.0.0.0/" /etc/redis/redis.conf

print_action "Starting Redis"
sudo service redis-server restart

cleanup

print_success "Logstash server installed successfully"