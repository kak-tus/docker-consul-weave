FROM consul:0.7.5

RUN \
  apk add --no-cache drill

COPY pre-entrypoint.sh /bin/pre-entrypoint.sh

ENV DC=
ENV DCS=

ENTRYPOINT ["/bin/pre-entrypoint.sh"]
