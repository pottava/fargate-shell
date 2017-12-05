FROM alpine:3.6

# Python 2.7 & Node.js 7.10
RUN apk --no-cache add python2=2.7.13-r1 nodejs-current=7.10.1-r0

# AWS-CLI 1.14
RUN apk --no-cache add less groff jq
RUN apk --no-cache add --virtual build-dependencies py2-pip \
    && pip install 'awscli == 1.14.3' \
    && apk del --purge -r build-dependencies

# OpenSSH server & client
RUN apk --no-cache add openssh-server openssh tini \
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ no/ /etc/ssh/sshd_config \
    && sed -i s/#PermitUserEnvironment.*/PermitUserEnvironment\ yes/ /etc/ssh/sshd_config

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN addgroup fargate && adduser -s /bin/sh -D -G fargate fargate
ADD environment /home/fargate/.ssh/environment
WORKDIR /home/fargate/

EXPOSE 22

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
