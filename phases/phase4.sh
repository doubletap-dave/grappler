#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

# PHASE 4a: TELEGRAF: Create Telegraf persistent data
telegrafCreatePersistentStorage() {
	sudo mkdir -p /docker/containers/telegraf/
}

# PHASE 4b: TELEGRAF: Create Telegraf default configuration
telegrafGenerateDefaultConfiguration() {
	docker run --rm telegraf -sample-config > /docker/containers/telegraf/conf/telegraf.conf
}

# PHASE 4c: TELEGRAF: Create telegraf update scripts and make it executable
telegrafCreateUpdateScript() {
	sudo wget -O $HOME/grappler/updaters/telegrafupdater.sh https://raw.githubusercontent.com/topiaryx/grappler/master/updaters/telegrafupdater.sh
	sudo chmod +x $HOME/grappler/updaters/telegrafupdater.sh
}

# PHASE 4e: TELEGRAF: Start and enable the Telegraf cotainer
telegrafStartEnable() {
	docker start influxdb
	sudo systemctl enable influxdb.service
	sudo systemctl start influxdb
}

telegraf() {
	echo -e "Creating Persistent storage for Telegraf...\n" && telegrafCreatePersistentStorage
	echo -e "Generating default configuration for Telegraf...\n" && telegrafGenerateDefaultConfiguration
	echo -e "Creating update scripts for Telegraf...\n" && telegrafCreateUpdateScript
	echo -e "Starting and enabling Telegraf...\n" && telegrafStartEnable
	echo -e "\nPhase 1, 2, 3, and 4 complete, beginning Phase 5" && clear
}