FROM amazonlinux:2017.09.0.20170930

# AWS-CLI 1.14
RUN yum install -y python27-pip groff \
    && pip install 'awscli == 1.14.7' \
    && yum remove -y python27-pip

# Node 7.10
RUN yum install -y epel-release \
    && yum install -y --enablerepo=epel nodejs npm

# for Cloud9
RUN yum install -y glibc-static ncurses-devel which sudo git \
    && echo 'Defaults visiblepw' >> /etc/sudoers

# tini
RUN curl -o /tini.asc -sL https://github.com/krallin/tini/releases/download/v0.16.1/tini.asc \
    && curl -o /tini -sL https://github.com/krallin/tini/releases/download/v0.16.1/tini \
    && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 \
           --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && gpg --verify /tini.asc \
    && chmod +x /tini

# OpenSSH server
RUN yum install -y openssh-server \
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ no/ /etc/ssh/sshd_config \
    && sed -i s/#PermitUserEnvironment.*/PermitUserEnvironment\ yes/ /etc/ssh/sshd_config \
    && sed -i s/#PubkeyAuthentication.*/PubkeyAuthentication\ yes/ /etc/ssh/sshd_config \
    && sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ no/ /etc/ssh/sshd_config \
    && sed -i s/#ChallengeResponse.*/ChallengeResponseAuthentication\ no/ /etc/ssh/sshd_config

RUN groupadd -g 1000 fargate \
    && useradd -g fargate -u 1000 -m -d /home/fargate -s /bin/bash fargate \
    && chmod 755 /home/fargate
ADD environment /home/fargate/.ssh/environment
WORKDIR /home/fargate/

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ADD motd /etc/motd

EXPOSE 22

ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
