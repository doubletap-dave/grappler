#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

# PHASE 5a: GRAPHITE: Create Graphite container
graphiteCreateContainer() {
  docker run -d --name graphite --restart always -p 80:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 \
 	-p 8125:8125/udp -p 8126:8126 hopsoft/graphite-statsd > /dev/null 2>&1 >> dgc_install.log;
}

graphite() {
	echo -e "Creating Docker container for Graphite...\n" && graphiteCreateContainer
	echo -e "\nALL PHASES COMPLETE!"
}