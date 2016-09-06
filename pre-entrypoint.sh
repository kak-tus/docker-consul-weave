#!/bin/sh

WEAVE_IP=$( hostname -i | awk '{print $1}' )

JOIN_WAN=$( drill consul.weave.local | fgrep IN | fgrep -v ';' | awk '{print $5}' | sed 's/^/-join-wan /' | tr '\n' ' ' | sed 's/,$/\n/' )

echo "Start: docker-entrypoint.sh agent -advertise $WEAVE_IP -advertise-wan $WEAVE_IP $JOIN_WAN $@"

docker-entrypoint.sh agent -advertise $WEAVE_IP -advertise-wan $WEAVE_IP $JOIN_WAN $@
