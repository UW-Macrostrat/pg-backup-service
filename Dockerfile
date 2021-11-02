FROM rclone/rclone

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

ENV S3_ENDPOINT ""
ENV S3_ACCESS_KEY ""
ENV S3_SECRET_KEY ""

# Set RClone configuration values
ENV RCLONE_CONFIG_REMOTE_TYPE=s3
ENV RCLONE_CONFIG_REMOTE_ENDPOINT=$S3_ENDPOINT
ENV RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID=$S3_ACCESS_KEY
ENV RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY=$S3_SECRET_KEY

# Override the typical Rclone entrypoint to a harmless alternative
ENTRYPOINT [ "/usr/bin/env" ]

CMD [ "backup-service" ]
