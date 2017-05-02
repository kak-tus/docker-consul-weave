#!/usr/bin/env sh

if [ -z "$CONSUL_WEAVE_IP" ]; then
  CONSUL_WEAVE_IP=$( hostname -i | awk '{print $1}' )
fi

if [ -z "${CONSUL_WEAVE_JOIN}${CONSUL_WEAVE_JOIN_WAN}" ]; then
  DC_LIST=$( echo $DCS | tr "," "\n" )

  for i in $DC_LIST
  do
    if [ $i == $DC ]; then
      CONSUL_WEAVE_JOIN=$( drill $i.consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $CONSUL_WEAVE_IP | awk '{print $5}' | grep -E -o '^[0-9\.]+$' | tr "\n" "," | sed 's/,$//' )
    else
      IPS=$( drill $i.consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $CONSUL_WEAVE_IP | awk '{print $5}' | grep -E -o '^[0-9\.]+$' | tr "\n" "," | sed 's/,$//' )
      if [ -n "$IPS" ]; then
        CONSUL_WEAVE_JOIN_WAN=$( echo "$IPS,$CONSUL_WEAVE_JOIN_WAN" | sed 's/,$//')
      fi
    fi
  done
fi

bootstrap=""

if [ -n "$CONSUL_WEAVE_JOIN" ]; then
  CONSUL_WEAVE_JOIN=$( echo $CONSUL_WEAVE_JOIN | tr "," "\n" | sed 's/^/-retry-join /' | tr "\n" " " | sed 's/,$//' )
else
  bootstrap="-bootstrap"
fi

if [ -n "$CONSUL_WEAVE_JOIN_WAN" ]; then
  CONSUL_WEAVE_JOIN_WAN=$( echo $CONSUL_WEAVE_JOIN_WAN | tr "," "\n" | sed 's/^/-retry-join-wan /' | tr "\n" " " | sed 's/,$//' )
fi

docker-entrypoint.sh agent $bootstrap -advertise $CONSUL_WEAVE_IP -retry-max 5 -retry-max-wan 5 $CONSUL_WEAVE_JOIN $CONSUL_WEAVE_JOIN_WAN $@ &
child=$!

trap "kill $child" SIGTERM SIGINT
wait "$child"
