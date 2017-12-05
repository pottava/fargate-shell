#!/bin/sh

env > /tmp/env.txt
env | grep AWS_ >> /home/cloud9/.ssh/environment

ssh_password=${SSH_PASSWORD:-password}

# generate host keys if not present
ssh-keygen -A

echo "cloud9:${ssh_password}" | chpasswd

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -d -D -e "$@"
