# Base image
FROM alpine:latest

# installes required packages for our script
RUN apk add --no-cache bash ca-certificates rsync openssh

RUN --volume $SSH_AUTH_SOCK:/ssh-agent --env SSH_AUTH_SOCK=/ssh-agent ubuntu ssh-add -l

# Copies your code file repository to the filesystem
COPY entrypoint.sh /entrypoint.sh

# change permission to execute the script and
RUN chmod +x /entrypoint.sh

# file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]