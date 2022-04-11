FROM rclone/rclone:1.56

RUN apk --update add --no-cache postgresql-client bash jq curl
# install go-cron
# see https://github.com/schickling/dockerfiles/blob/master/postgres-backup-s3/install.sh
# and https://github.com/webwurst/docker-go-cron/blob/master/Dockerfile
RUN curl -SL https://github.com/odise/go-cron/releases/download/v0.0.7/go-cron-linux.gz \
  | zcat > /usr/local/bin/go-cron && \
  chmod +x /usr/local/bin/go-cron && \
  apk del curl

## Get rid of pesky stderr message
RUN mkdir -p /config/rclone && touch /config/rclone/rclone.conf

COPY ./bin/* /usr/local/bin/

# Override the typical Rclone entrypoint to a harmless alternative
ENTRYPOINT [ "/usr/bin/env" ]

CMD [ "backup-service" ]
