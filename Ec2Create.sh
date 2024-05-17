#!/bin/bash -ex
### Create EC2 instances
source Used_ID.sh


EC2_ID=$(aws ec2 run-instances \
    --image-id ami-080e1f13689e07408  \
    --count 1 \
    --instance-type t2.micro \
    --key-name DevOpsEC2_smartcode1 \
    --security-group-ids $Sec_Group\
    --subnet-id $SUBNET1 \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Instans1}]" \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":8,"VolumeType":"gp2"}}]' \
    --query 'Instances[0].ImageId' \
    --output text
)

echo "$EC2_ID"
echo "EC2_ID=$EC2_ID" >> Used_ID.sh
