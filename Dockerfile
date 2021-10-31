FROM rclone/rclone

RUN apk --update add --no-cache postgresql-client bash

COPY ./backup-db ./backup-service /usr/local/bin/

# Override the typical Rclone entrypoint to a harmless alternative
ENTRYPOINT [ "/usr/bin/env" ]

CMD [ "backup-service" ]
