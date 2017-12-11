Cloud9 with go1.9.2
---

```
$ S3_BUCKET=
$ S3_KEY=
$ ECS_CLUSTER=
$ FAGATE_SUBNET=
$ FAGATE_SECURITYGROUP=
$ FAGATE_EXEC_ROLEARN=
$ FAGATE_TASK_ROLEARN=
```

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
$ aws s3api put-object --bucket ${S3_BUCKET} --key ${S3_KEY} \
    --body id_rsa.pub
```

## Register a task definition with the FARGATE compatibility

```
$ sed -e 's/@S3_BUCKET/'${S3_BUCKET}'/' task-def.json.template > task-def.json
$ sed -i -e 's/@S3_KEY/'${S3_KEY}'/' task-def.json
$ aws --region us-east-1 ecs register-task-definition \
    --family fagate-go19 \
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
    --task-definition fagate-go19 \
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

## Configure Cloud9 again

Set $public_ip as a Coud9 remote host.  
Click the `Next step` button to complete the process!
