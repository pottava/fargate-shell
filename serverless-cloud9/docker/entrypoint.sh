#!/bin/bash

env | grep AWS_ >> .ssh/environment

if [ "x${SSH_AUTHKEYS_S3_BUCKET}" = "x" ] ; then
  echo "'SSH_AUTHKEYS_S3_BUCKET' should be specified." 1>&2
  exit 1
fi
if [ "x${SSH_AUTHKEYS_S3_KEY}" = "x" ] ; then
  echo "'SSH_AUTHKEYS_S3_KEY' should be specified." 1>&2
  exit 1
fi

aws sts get-caller-identity
aws s3api get-object --bucket ${SSH_AUTHKEYS_S3_BUCKET} \
    --key ${SSH_AUTHKEYS_S3_KEY} .ssh/authorized_keys \
    > /dev/null
chown fargate:fargate .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
cat .ssh/authorized_keys

# generate host keys if not present
ssh-keygen -A

if [ "x${USER_PASSWORD}" != "x" ] ; then
  echo "fargate:${USER_PASSWORD}" | chpasswd
  echo 'fargate ALL=(ALL) ALL' >> /etc/sudoers
else
  echo 'fargate ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
fi

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e "$@"
