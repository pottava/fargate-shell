FROM pottava/fargate-cloud9:1.0

ENV GOPATH=/home/fargate/go \
    PATH=/home/fargate/go/bin:/usr/local/go/bin:$PATH

# Install go 1.9
RUN yum install -y go wget \
    && GOLANG_VERSION=1.9.2 \
    && GOLANG_SRC_URL=https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz \
    && GOLANG_SRC_SHA256=665f184bf8ac89986cfd5a4460736976f60b57df6b320ad71ad4cef53bb143dc \
    && export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
    && wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
    && echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm -rf golang.tar.gz \
    && cd /usr/local/go/src \
    && ./make.bash \
    && mkdir -p $GOPATH \
    && chmod -R 777 $GOPATH \
    && echo "GOPATH=/home/fargate/go" >> /home/fargate/.ssh/environment \
    && echo "PATH=$GOPATH/bin:/usr/local/go/bin:$PATH" >> /home/fargate/.ssh/environment

# Install gometalinter (goimports, golint, govet, ..)
RUN go get github.com/alecthomas/gometalinter \
    && cd $GOPATH/src/github.com/alecthomas/gometalinter \
    && git checkout v2.0.2 \
    && go install github.com/alecthomas/gometalinter \
    && gometalinter --install \
    && chmod -R 777 $GOPATH
