#!/usr/bin/env sh

WEAVE_IP=$( hostname -i | awk '{print $1}' )

DC_LIST=$( echo $DCS | tr "," "\n" )
JOIN=""
JOIN_WAN=""

for i in $DC_LIST
do
  if [ $i == $DC ]; then
    JOIN=$( drill $i.consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $WEAVE_IP | awk '{print $5}' | tr "\n" "," | sed 's/,$/\n/' )
  else
    IPS=$( drill $i.consul.weave.local | fgrep IN | fgrep -v ';' | fgrep -v $WEAVE_IP | awk '{print $5}' | tr "\n" "," | sed 's/,$/\n/' )
    JOIN_WAN=$( echo "$IPS,$JOIN_WAN" | sed 's/,$/\n/')
  fi
done

if [ -n "$JOIN" ]; then
  JOIN=$( echo $JOIN | tr "," "\n" | sed 's/^/-retry-join /' | tr "\n" " " | sed 's/,$/\n/' )
fi

if [ -n "$JOIN_WAN" ]; then
  JOIN_WAN=$( echo $JOIN_WAN | tr "," "\n" | sed 's/^/-retry-join-wan /' | tr "\n" " " | sed 's/,$/\n/' )
fi

echo "docker-entrypoint.sh agent -advertise $WEAVE_IP -retry-max 5 -retry-max-wan 5 $JOIN $JOIN_WAN $@"
