# Base image
FROM alpine:latest

# installes required packages for our script
RUN apk add --no-cache --volume $SSH_AUTH_SOCK:/ssh-agent --env SSH_AUTH_SOCK=/ssh-agent bash ca-certificates rsync openssh ssh-add

# Copies your code file repository to the filesystem
COPY entrypoint.sh /entrypoint.sh

# change permission to execute the script and
RUN chmod +x /entrypoint.sh

# file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]