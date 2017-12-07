Supported tags and respective `Dockerfile` links:

・latest ([docker/Dockerfile](https://github.com/pottava/fargate-shell/blob/master/serverless-bastion/docker/Dockerfile))  
・1.0 ([docker/Dockerfile](https://github.com/pottava/fargate-shell/blob/master/serverless-bastion/docker/Dockerfile))  

## Usage

### Launch a SSH server

```
$ docker run --rm -i -p 2222:22 -e SSH_PASSWORD=passw0rd \
    -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
    pottava/fargate-shell
```

### SSH

```
$ ssh -p 2222 fargate@localhost
```
