# Base image
FROM alpine:latest

# installes required packages for our script
RUN apk update && \
      apk add --no-cache ca-certificates \
      openssh-client \
      sshpass \
      rsync \
      bash

# Copies your code file repository to the filesystem
COPY entrypoint.sh /entrypoint.sh

# change permission to execute the script and
RUN chmod +x /entrypoint.sh

# file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]