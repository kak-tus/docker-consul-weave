#!/usr/bin/env sh

WEAVE_IP=$( hostname -i | awk '{print $1}' )

DC_LIST=$( echo $DCS | tr "," "\n" )
JOIN=""
JOIN_WAN=""

for i in $DC_LIST
do
  if [ $i == $DC ]; then
    JOIN=$( drill $i.consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $WEAVE_IP | awk '{print $5}' | grep -E -o '^[0-9\.]+$' | tr "\n" "," | sed 's/,$//' )
  else
    IPS=$( drill $i.consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $WEAVE_IP | awk '{print $5}' | grep -E -o '^[0-9\.]+$' | tr "\n" "," | sed 's/,$//' )
    if [ -n "$IPS" ]; then
      JOIN_WAN=$( echo "$IPS,$JOIN_WAN" | sed 's/,$//')
    fi
  fi
done

JOIN_WAN_COMPATIBLE=$( drill consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $WEAVE_IP | awk '{print $5}' | grep -E -o '^[0-9\.]+$' | tr "\n" "," | sed 's/,$//' )

if [ -n "$JOIN" ]; then
  JOIN=$( echo $JOIN | tr "," "\n" | sed 's/^/-retry-join /' | tr "\n" " " | sed 's/,$//' )
fi

if [ -n "$JOIN_WAN" ]; then
  JOIN_WAN=$( echo $JOIN_WAN | tr "," "\n" | sed 's/^/-retry-join-wan /' | tr "\n" " " | sed 's/,$//' )
fi

if [ -n "$JOIN_WAN_COMPATIBLE" ]; then
  JOIN_WAN_COMPATIBLE=$( echo $JOIN_WAN_COMPATIBLE | tr "," "\n" | sed 's/^/-retry-join-wan /' | tr "\n" " " | sed 's/,$//' )
fi

docker-entrypoint.sh agent -advertise $WEAVE_IP -retry-max 5 -retry-max-wan 5 $JOIN $JOIN_WAN $JOIN_WAN_COMPATIBLE $@ >/proc/1/fd/1 2>/proc/1/fd/2 &
child=$!

trap "kill $child" SIGTERM
wait "$child"

