#!/bin/bash -ex

# Create VPC
CIDR_BLOCK=10.0.0.0/16
echo "CIDR_BLOCK=10.0.0.0/16" >> Used_ID.sh
VPC_ID=$(aws ec2 create-vpc \
	--cidr-block $CIDR_BLOCK \
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MyVPC}]' \
	--query Vpc.VpcId \
	--output text)
echo "This is your vpc-id $VPC_ID and cidr block is $CIDR_BlOCK"
echo "VPC_ID=$VPC_ID" >> Used_ID.sh
# enable DNS hostnames
echo $(aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames)

# Create 2 subnet
SIDR_BLOCKS=("10.0.1.0/24" "10.0.2.0/24")
NUM=1
for SUB_SIDR_BLOCK in "${SIDR_BLOCKS[@]}"
do
    SUBNET=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=YourSubnetName'$NUM'}]' \
            --query 'Subnet.SubnetId' \
            --cidr-block $SUB_SIDR_BLOCK)
    # Remove quotes from SUBNET variable
    SUBNET="${SUBNET%\"}"
    SUBNET="${SUBNET#\"}"
    echo "SUBNET$NUM=$SUBNET" >> Used_ID.sh
    sleep 5
    aws ec2 modify-subnet-attribute --subnet-id $SUBNET --map-public-ip-on-launch

    NUM=$((NUM + 1))
done

# Create security group
Sec_Group=$(aws ec2 create-security-group \
          --group-name MySecurityGroup \
          --description "My security group" \
          --vpc-id $VPC_ID)
sg_id=$(echo "$Sec_Group" | jq -r '.GroupId')
echo "Sec_Group=$sg_id" >> Used_ID.sh
# authorize security group ingress
sleep 5
echo $(aws ec2 authorize-security-group-ingress \
	--group-id $sg_id \
        --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,Ipv6Ranges='[{CidrIpv6=::/0,Description="IPv6"}]')

echo $(aws ec2 authorize-security-group-ingress \
        --group-id $sg_id \
        --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=0.0.0.0/0,Description="IPv4"}]')


# Create internet gateway
INT_GATEWAY_ID=$(aws ec2 create-internet-gateway \
 	--query 'InternetGateway.InternetGatewayId' \
	--tag-specifications "ResourceType=internet-gateway, Tags=[{Key=Name, Value=GatewayName}]" \
	--output text)
echo "INT_GATEWAY_ID=$INT_GATEWAY_ID" >> Used_ID.sh
echo "This is your internet gateway ID $INT_GATEWAY_ID"
# Attach the internet gateway to your VPC
echo $(aws ec2 attach-internet-gateway \
	--vpc-id $VPC_ID \
	--internet-gateway-id $INT_GATEWAY_ID)
# Creat custom rout table
ROUTE_TABLE=$(aws ec2 create-route-table \
	--vpc-id $VPC_ID \
	--query 'RouteTable.RouteTableId' \
	--output text)
echo "This is your route table ID $ROUTE_TABLE"
echo "ROUTE_TABLE=$ROUTE_TABLE" >> Used_ID.sh
# Create a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway
echo $(aws ec2 create-route \
	--route-table-id $ROUTE_TABLE \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $INT_GATEWAY_ID)
# Associate it with a subnet in your previously created VPC
SUBNET_IDS=$(aws ec2 describe-subnets \
	--filters "Name=vpc-id, Values=$VPC_ID" \
	--query "Subnets[*].{ID:SubnetId}")
ids=($(echo "$SUBNET_IDS" | jq -r '.[] | .ID'))

for id in "${ids[@]}"
do
    echo $(aws ec2 associate-route-table \
	    --subnet-id ${id} \
	    --route-table-id $ROUTE_TABLE)
done

















