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
}

usage()
{
cat <<EOF
usage: $0 <logstash-server-ip-address>
EOF
}

if [ $# -eq 0 ]
  then
    usage
    exit 1
fi

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   usage
   exit 1
fi

trap 'handle_error $LINENO $?' ERR

print_title "Installing Logstash shipper"

print_action "Upgrading Debian system"
apt-get -y update
apt-get -y upgrade

print_action "Installing Java"
apt-get -y install default-jre

print_action "Installing Git and Rubygems"
apt-get -y install git rubygems
gem install fpm

print_action "Creating Logstash package"
LOGSTASH_TMP_DIR=`mktemp -d logstash.XXXXXX`
git clone https://github.com/rdcastro/logstash-packaging.git $LOGSTASH_TMP_DIR/logstash --depth=1
( cd "$LOGSTASH_TMP_DIR" && ./logstash/package-common.sh -f )
( cd "$LOGSTASH_TMP_DIR" && ./logstash/package-shipper.sh -f )

print_action "Installing Logstash package"
sudo dpkg -i $LOGSTASH_TMP_DIR/logstash-common_${LOGSTASH_VERSION}_all.deb
sudo dpkg -i $LOGSTASH_TMP_DIR/logstash-shipper_${LOGSTASH_VERSION}_all.deb

print_action "Configuring Logstash to send data to $1"
sed -i "s/127.0.0.1/$1/" /etc/logstash/syslog-shipper.conf

print_action "Restarting Logstash"
service logstash restart

cleanup

print_success "Logstash shipper installed successfully"