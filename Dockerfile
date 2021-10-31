FROM rclone/rclone

RUN apk --update add --no-cache postgresql-client bash

COPY ./backup-db ./backup-service /usr/local/bin/

CMD [ "backup-service" ]
