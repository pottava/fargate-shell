Serverless Cloud9
---

# How to use

## Configure Cloud9

```
$ open https://console.aws.amazon.com/cloud9/home/create
```

```
1. Click `Create environment` button
2. Input the environment name
3. Click `Next step` button
4. Select `Connect and run in remote server (SSH)` as your environment type
5. Save `public SSH key` to your local disk as a `id_rsa.pub`

* Do not click the `Next step` button for now
```

## Upload the key to S3

Set your S3 bucket name & key as environment variables

```
$ S3_BUCKET=
$ S3_KEY=
$ aws s3api put-object --bucket ${S3_BUCKET} --key ${S3_KEY} \
    --body id_rsa.pub
```

## Create a base stack & retrieve the outputs

```
$ aws --region us-east-1 cloudformation create-stack \
    --stack-name cloud9 --template-body file://cfn.yaml \
    --parameters ParameterKey=AuthKeysS3Bucket,ParameterValue="${S3_BUCKET}" \
                 ParameterKey=AuthKeysS3Key,ParameterValue="${S3_KEY}" \
    --capabilities CAPABILITY_IAM
$ aws --region us-east-1 cloudformation wait stack-create-complete \
    --stack-name cloud9
$ outputs=$( aws --region us-east-1 cloudformation describe-stacks \
    --stack-name cloud9 | jq -r '.Stacks[0].Outputs[]' )
$ cluster=$( echo ${outputs} | jq -r 'select(.OutputKey=="Cluster").OutputValue' )
$ subnet1=$( echo ${outputs} | jq -r 'select(.OutputKey=="PublicSubnet1").OutputValue' )
$ subnet2=$( echo ${outputs} | jq -r 'select(.OutputKey=="PublicSubnet2").OutputValue' )
$ secgrp=$( echo ${outputs} | jq -r 'select(.OutputKey=="SecurityGroup").OutputValue' )
$ awsvpc='subnets=['${subnet1}','${subnet2}'],securityGroups=['${secgrp}']'
```

## Run a fargate task & wait for its running

```
$ result=$( aws --region us-east-1 ecs run-task \
    --cluster ${cluster} \
    --task-definition cloud9 \
    --launch-type FARGATE \
    --network-configuration awsvpcConfiguration="{${awsvpc},assignPublicIp=ENABLED}" \
    --count 1 )
$ aws --region us-east-1 ecs wait tasks-running \
    --cluster ${cluster} \
    --tasks $( echo ${result} | jq -r '.tasks[0].taskArn' )
```

## Retrieve its public IP address

```
$ eni_id=$( aws --region us-east-1 ecs describe-tasks \
    --cluster ${cluster} \
    --tasks $( echo ${result} | jq -r '.tasks[0].taskArn' ) \
    | jq '.tasks[0].attachments[0].details[]' \
    | jq 'select( .name | contains("networkInterfaceId"))' \
    | jq -r '.value' )
$ public_ip=$( aws ec2 --region us-east-1 describe-network-interfaces \
    --network-interface-ids ${eni_id} \
    | jq -r '.NetworkInterfaces[].Association.PublicIp' ) \
    && echo ${public_ip}
```

## Configure Cloud9 again

Set $public_ip as a Coud9 remote host.  
Click the `Next step` button to complete the process!

# Notice

## You cannot install `c9.ide.lambda.docker` though..

AWS Fargate is based on docker container itself.  
It seems that we are not allowed to run `docker in docker` on AWS Fargate :(

# Don't forget to stop the container!!!

Not like a serverless-bastion container, servereless-cloud9 container has to be stopped manually.
