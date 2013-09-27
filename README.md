## Logstash Installation

Scripts to install [Logstash](http://logstash.net) on Google Compute Engine instances.

This repository provides scripts for Log server and shipper installation.

Author: Rodrigo De Castro <rdc@google.com>

## Project setup, installation, and configuration

1. Spin up a new Debian-7 GCE instance for your development and log into the system via SSH

2. sudo apt-get -y install git

   Install git

3. git clone https://github.com/GoogleCloudPlatform/compute-logstash-install-shell.git

   This command clones repository locally.

If provisioning a Log server:

4. sudo ./compute-logstash-install-shell/install-logstash-server-debian7.sh

   It installs all the dependencies, creates required Logstash Debian packages, and starts services.

5. Point browser to http://[server-external-ip]:5601

If provisioning a Log shipper:

4. Find internal and external IPs of Logstash server

5. sudo ./compute-logstash-install-shell/install-logstash-shipper-debian7.sh <server-internal-ip>

6. Point browser to http://[server-external-ip]:5601

## Contributing changes

* See [CONTRIB.md](CONTRIB.md)

## Licensing

* See [LICENSE](LICENSE)
