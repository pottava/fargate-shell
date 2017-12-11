FROM alpine:3.6

# Python 2.7
RUN apk --no-cache add python2=2.7.13-r1

# AWS-CLI 1.14
RUN apk --no-cache add less groff jq
RUN apk --no-cache add --virtual build-deps py2-pip \
    && pip install 'awscli == 1.14.7' \
    && apk del --purge -r build-deps

# OpenSSH server & client
RUN apk --no-cache add openssh \
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ no/ /etc/ssh/sshd_config \
    && sed -i s/#PermitUserEnvironment.*/PermitUserEnvironment\ yes/ /etc/ssh/sshd_config

# for better experience
RUN apk --no-cache add tini bash sudo

RUN addgroup fargate && adduser -s /bin/bash -D -G fargate fargate
ADD environment /home/fargate/.ssh/environment
WORKDIR /home/fargate/

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ADD motd /etc/motd

EXPOSE 22

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
