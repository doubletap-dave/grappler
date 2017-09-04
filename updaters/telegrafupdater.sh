#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

timestamper() {
	date +"%Y-%m-%d_%H-%M-%S"
}
timestamper

echo "Stopping telegraf Container"
docker stop telegraf

echo "Pulling Latest from telegraf"
docker pull telegraf

echo "Backing up old telegraf Container to telegraf_$(timestamp)"
docker rename telegraf telegraf_$(timestamp)

echo "Creating and starting new telegraf Server"
docker run --name telegraf --restart=always --net=container:influxdb -v /docker/containers/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro telegraf

docker start telegraf