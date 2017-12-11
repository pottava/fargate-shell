Cloud9 with go1.8.4
---

```
$ SSH_AUTHKEYS_S3_BUCKET=
$ SSH_AUTHKEYS_S3_KEY=
$ ECS_CLUSTER=
$ FAGATE_SUBNET=
$ FAGATE_SECURITYGROUP=
$ FAGATE_EXEC_ROLEARN=
$ FAGATE_TASK_ROLEARN=
```

## Register a task definition with the FARGATE compatibility

```
$ sed -e 's/@S3_BUCKET/'${SSH_AUTHKEYS_S3_BUCKET}'/' task-def.json.template > task-def.json
$ sed -i -e 's/@S3_KEY/'${SSH_AUTHKEYS_S3_KEY}'/' task-def.json
$ aws --region us-east-1 ecs register-task-definition \
    --family fagate-go18 \
    --requires-compatibilities FARGATE \
    --execution-role-arn ${FAGATE_EXEC_ROLEARN} \
    --task-role-arn ${FAGATE_TASK_ROLEARN} \
    --network-mode awsvpc \
    --container-definitions "$( cat task-def.json )" \
    --cpu 256 --memory 512
```

## Run a fargate task & wait for its running

```
$ awsvpc='subnets=['${FAGATE_SUBNET}'],securityGroups=['${FAGATE_SECURITYGROUP}']'
$ runtask_result=$( aws --region us-east-1 ecs run-task \
    --cluster ${ECS_CLUSTER} \
    --task-definition fagate-go18 \
    --launch-type FARGATE \
    --network-configuration awsvpcConfiguration="{${awsvpc},assignPublicIp=ENABLED}" \
    --count 1 )
$ aws --region us-east-1 ecs wait tasks-running \
    --cluster ${ECS_CLUSTER} \
    --tasks $( echo ${runtask_result} | jq -r '.tasks[0].taskArn' )
```

## Retrieve its public IP address

```
$ eni_id=$( aws --region us-east-1 ecs describe-tasks \
    --cluster ${ECS_CLUSTER} \
    --tasks $( echo ${runtask_result} | jq -r '.tasks[0].taskArn' ) \
    | jq '.tasks[0].attachments[0].details[]' \
    | jq 'select( .name | contains("networkInterfaceId"))' \
    | jq -r '.value' )
$ public_ip=$( aws ec2 --region us-east-1 describe-network-interfaces \
    --network-interface-ids ${eni_id} \
    | jq -r '.NetworkInterfaces[].Association.PublicIp' ) \
    && echo ${public_ip}
```
