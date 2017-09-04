#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

# Pre-PHASE 3: INFLUXDB: Get a name for the InfluxDB database
influxdbSetDbName() {
	echo -e "Please enter a name for your InfluxDB database name: "
	read -p ">>> " influxDbName
	clear
}

# PHASE 3a: INFLUXDB: Create InfluxDB persistent data
influxdbCreatePersistentStorage() {
	sudo mkdir -p /docker/containers/influxdb/conf/ > /dev/null 2>&1 >> dgc_install.log
	sudo mkdir -p /docker/containers/influxdb/db/ > /dev/null 2>&1 >> dgc_install.log
	checkOwner
}

# PHASE 3b: INFLUXDB: Generate InfluxDB default configuration
influxdbGenerateDefaultConfig() {
	docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf
}

# PHASE 3b: INFLUXDB: Create InfluxDB container
influxdbCreateContainer() {
	docker create --name influxdb --restart always -e PUID=1000 -e PGID=1000 -p 8083:8083 -p 8086:8086 \
    -v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
	-v /docker/containers/influxdb/db:/var/lib/influxdb influxdb -config /etc/influxdb/influxdb.conf \
    > /dev/null 2>&1 >> dgc_install.log;
}

# PHASE 3c: INFLUXDB: Start and enable the InfluxDB container
influxdbStartEnable() {
	docker start influxdb
	sudo systemctl enable influxdb.service
	sudo systemctl start influxdb
}

# PHASE 3d: INFLUXDB: Create initial InfluxDB database
influxdbCreateDb() {
	sudo curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE ${influxDbName}" # Will spit out a deprecation error... disregard
}

# PHASE 3e: INFLUXDB: Create InfluxDB update scripts and make it executable
grafanaCreateUpdateScript() {
	sudo wget -O $HOME/grappler/updaters/influxdbupdater.sh https://raw.githubusercontent.com/topiaryx/grappler/master/updaters/influxdbupdater.sh
	sudo chmod +x $HOME/grappler/updaters/influxdbupdater.sh
}

influxdb() {
	influxdbSetDbName
	echo -e "Creating persistent storage for InfluxDB...\n" && influxdbCreatePersistentStorage
	echo -e "Generating default configuration for InfluxDB...\n" && influxdbGenerateDefaultConfig
	echo -e "Creating Docker container for InfluxDB...\n" && influxdbCreateContainer
	echo -e "Starting and enabling InfluxDB...\n" && influxdbStartEnable
	echo -e "Creating initial InfluxDB database\n" && influxdbCreateDb
	echo -e "\nPhase 1, 2, and 3 complete, beginning Phase 4" && clear
}