#!/bin/sh

env | grep AWS_ >> /home/fargate/.ssh/environment

if [ "x${SSH_AUTHKEYS_S3_BUCKET}" != "x" ] ; then
  if [ "x${SSH_AUTHKEYS_S3_KEY}" = "x" ] ; then
    echo "'SSH_AUTHKEYS_S3_KEY' should be specified." 1>&2
    exit 1
  fi
  aws sts get-caller-identity
  aws s3api get-object --bucket ${SSH_AUTHKEYS_S3_BUCKET} \
      --key ${SSH_AUTHKEYS_S3_KEY} /home/fargate/.ssh/authorized_keys \
      > /dev/null
  chown fargate:fargate /home/fargate/.ssh/authorized_keys
  chmod 600 /home/fargate/.ssh/authorized_keys
  cat /home/fargate/.ssh/authorized_keys

  passwd -u fargate
  sed -i s/#RSAAuthentication.*/RSAAuthentication\ yes/ /etc/ssh/sshd_config
  sed -i s/#PubkeyAuthentication.*/PubkeyAuthentication\ yes/ /etc/ssh/sshd_config
  sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ no/ /etc/ssh/sshd_config
  sed -i s/#ChallengeResponse.*/ChallengeResponseAuthentication\ no/ /etc/ssh/sshd_config
fi

# generate host keys if not present
ssh-keygen -A

if [ "x${SSH_AUTHKEYS_S3_BUCKET}" = "x" ] ; then
  if [ "x${SSH_PASSWORD}" = "x" ] ; then
    echo "'SSH_PASSWORD' should be specified." 1>&2
    exit 1
  fi
  echo "fargate:${SSH_PASSWORD}" | chpasswd
  sed -i s/#PermitEmptyPasswords.*/PermitEmptyPasswords\ no/ /etc/ssh/sshd_config
  sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ yes/ /etc/ssh/sshd_config
fi

if [ "${ENABLE_SUDO}" = "1" ] ; then
  echo 'Defaults visiblepw' >> /etc/sudoers
  echo 'fargate ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
fi

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e "$@"
