#!/bin/sh

env | grep AWS_ >> .ssh/environment

if [ "x${SSH_AUTHKEYS_S3_BUCKET}" != "x" ]; then
  if [ "x${SSH_AUTHKEYS_S3_KEY}" = "x" ]; then
    echo "'SSH_AUTHKEYS_S3_KEY' should be specified." 1>&2
    exit 1
  fi

  aws s3api get-object --bucket ${SSH_AUTHKEYS_S3_BUCKET} \
      --key ${SSH_AUTHKEYS_S3_KEY} .ssh/authorized_keys
  chown fargate:fargate .ssh/authorized_keys
  chmod 600 .ssh/authorized_keys

  passwd -u fargate
  sed -i s/#RSAAuthentication.*/RSAAuthentication\ yes/ /etc/ssh/sshd_config
  sed -i s/#PubkeyAuthentication.*/PubkeyAuthentication\ yes/ /etc/ssh/sshd_config
  sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ no/ /etc/ssh/sshd_config
  sed -i s/#ChallengeResponse.*/ChallengeResponseAuthentication\ no/ /etc/ssh/sshd_config
fi

# generate host keys if not present
ssh-keygen -A

if [ "x${SSH_AUTHKEYS_S3_BUCKET}" = "x" ]; then
  if [ "x${SSH_PASSWORD}" = "x" ]; then
    echo "'SSH_PASSWORD' should be specified." 1>&2
    exit 1
  fi
  echo "fargate:${SSH_PASSWORD}" | chpasswd
  sed -i s/#PermitEmptyPasswords.*/PermitEmptyPasswords\ no/ /etc/ssh/sshd_config
  sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ yes/ /etc/ssh/sshd_config
fi

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -d -D -e "$@"
