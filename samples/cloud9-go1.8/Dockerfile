FROM pottava/fargate-cloud9:1.0

ENV GOPATH=/home/fargate/go \
    PATH=/home/fargate/go/bin:/usr/local/go/bin:$PATH

# Install go 1.8
RUN yum install -y go wget \
    && mkdir -p $GOPATH \
    && chmod -R 777 $GOPATH \
    && echo "GOPATH=/home/fargate/go" >> /home/fargate/.ssh/environment \
    && echo "PATH=$GOPATH/bin:$PATH" >> /home/fargate/.ssh/environment

# Install gometalinter (goimports, golint, govet, ..)
RUN go get github.com/alecthomas/gometalinter \
    && cd $GOPATH/src/github.com/alecthomas/gometalinter \
    && git checkout v2.0.2 \
    && go install github.com/alecthomas/gometalinter \
    && gometalinter --install \
    && chmod -R 777 $GOPATH
