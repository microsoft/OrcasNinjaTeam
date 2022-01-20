FROM alpine:3.9

RUN apk add --no-cache mysql-client
ENTRYPOINT ["crond", "-f"]