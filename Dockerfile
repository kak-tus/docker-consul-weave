FROM consul:v0.6.4

COPY pre-entrypoint.sh /bin/pre-entrypoint.sh

ENV DC=
ENV DCS=

RUN apk add --no-cache drill

ENTRYPOINT ["/bin/pre-entrypoint.sh"]
