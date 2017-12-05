Serverless Bastion
---

# How to use

## Decide your SSH password

```
$ SSH_PASSWORD=
```

## Create a base stack & retrieve the outputs

```
$ aws --region us-east-1 cloudformation create-stack \
    --stack-name bastion --template-body file://cfn.yaml \
    --parameters ParameterKey=Password,ParameterValue="${SSH_PASSWORD}" \
    --capabilities CAPABILITY_IAM
$ aws --region us-east-1 cloudformation wait stack-create-complete \
    --stack-name bastion
$ outputs=$( aws --region us-east-1 cloudformation describe-stacks \
    --stack-name bastion | jq -r '.Stacks[0].Outputs[]' )
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
    --task-definition bastion \
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

## SSH

```
$ ssh fargate@${public_ip}
```
