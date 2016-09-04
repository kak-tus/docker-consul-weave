FROM consul:v0.6.4

COPY pre-entrypoint.sh /bin/pre-entrypoint.sh

RUN apk add --no-cache drill

ENTRYPOINT ["/bin/pre-entrypoint.sh"]
