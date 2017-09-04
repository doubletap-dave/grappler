#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

# Pre-PHASE 3: INFLUXDB: Create a systemd startup scripts
influxdbService() {
	sudo wget -O /lib/systemd/system/influxdb.service http://linktogithub/grappler/grapplerhelpers
}

# Pre-PHASE 3: INFLUXDB: Get a name for the InfluxDB database
influxdbSetDbName() {
	echo -e "Please enter a name for your InfluxDB database name:"
	read -p ">>> " influxDbName
	clear
}

# PHASE 3a: INFLUXDB: Create InfluxDB persistent data
influxdbCreatePersistentData() {
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
influxdbStartEnableContainer() {
	docker start influxdb
	sudo systemctl enable influxdb.service
	sudo systemctl start influxdb
}

# PHASE 3d: INFLUXDB: Create initial InfluxDB database
influxdbCreateDb() {
	sudo curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE ${influxDbName}"
}

# PHASE 3e: INFLUXDB: Create InfluxDB update scripts and make it executable
grafanaCreateUpdateScript() {
	sudo wget -O $HOME/grapplerupdaters/influxdbupdater.sh # add link after upload
	sudo chmod +x $HOME/grapplerupdaters/influxdbupdater.sh
}
