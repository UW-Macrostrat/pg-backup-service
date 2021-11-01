FROM rclone/rclone

RUN apk --update add --no-cache postgresql-client bash jq

## Get rid of pesky stderr message
RUN mkdir -p /config/rclone && touch /config/rclone/rclone.conf

COPY ./bin/* /usr/local/bin/

# Override the typical Rclone entrypoint to a harmless alternative
ENTRYPOINT [ "/usr/bin/env" ]

CMD [ "backup-service" ]
