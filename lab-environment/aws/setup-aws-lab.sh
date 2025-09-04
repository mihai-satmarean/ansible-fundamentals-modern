#!/bin/bash

# 🚀 Secure AWS Lab Environment Setup
# Replaces the insecure prepare_lab.yml with modern best practices

set -e

echo "🔧 Setting up Secure AWS Ansible Training Environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_REGION="eu-west-1"
INSTANCE_TYPE="t3.micro"
AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2 (update as needed)

# Security: NO HARDCODED CREDENTIALS!
if [ -z "$AWS_PROFILE" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${RED}❌ Error: AWS credentials not configured${NC}"
    echo "Please configure AWS credentials using one of:"
    echo "  1. aws configure"
    echo "  2. AWS_PROFILE environment variable"
    echo "  3. IAM role (if running on EC2)"
    exit 1
fi

# Check if required tools are installed
command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI not installed${NC}"; exit 1; }
command -v ansible-playbook >/dev/null 2>&1 || { echo -e "${RED}❌ Ansible not installed${NC}"; exit 1; }

# Get user input for training session
echo -e "${BLUE}📋 Training Session Configuration${NC}"
read -p "Training session name (default: ansible-fundamentals): " SESSION_NAME
SESSION_NAME=${SESSION_NAME:-ansible-fundamentals}

read -p "AWS Region (default: $DEFAULT_REGION): " AWS_REGION
AWS_REGION=${AWS_REGION:-$DEFAULT_REGION}

read -p "Number of participants (default: 8): " PARTICIPANT_COUNT
PARTICIPANT_COUNT=${PARTICIPANT_COUNT:-8}

# Generate unique session ID
SESSION_ID=$(date +%Y%m%d-%H%M%S)
STACK_NAME="ansible-training-${SESSION_NAME}-${SESSION_ID}"

echo -e "${YELLOW}📊 Session Details:${NC}"
echo "  Session: $SESSION_NAME"
echo "  Region: $AWS_REGION"
echo "  Participants: $PARTICIPANT_COUNT"
echo "  Stack: $STACK_NAME"
echo ""

# Create CloudFormation template
cat > /tmp/ansible-training-stack.yml << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Secure Ansible Training Environment'

Parameters:
  ParticipantCount:
    Type: Number
    Default: 8
    MinValue: 1
    MaxValue: 20
    Description: Number of training participants
    
  InstanceType:
    Type: String
    Default: t3.micro
    Description: EC2 instance type
    
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access
    
  SessionName:
    Type: String
    Default: ansible-fundamentals
    Description: Training session identifier

Resources:
  # VPC for isolated training environment
  TrainingVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${SessionName}-vpc'
        - Key: Purpose
          Value: AnsibleTraining

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '${SessionName}-igw'

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref TrainingVPC
      InternetGatewayId: !Ref InternetGateway

  # Public Subnet
  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref TrainingVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${SessionName}-public-subnet'

  # Route Table
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref TrainingVPC
      Tags:
        - Key: Name
          Value: !Sub '${SessionName}-public-rt'

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  SubnetRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet
      RouteTableId: !Ref PublicRouteTable

  # Security Group
  TrainingSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Ansible training
      VpcId: !Ref TrainingVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
          Description: SSH access
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
          Description: HTTP access
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
          Description: HTTPS access
        - IpProtocol: -1
          SourceSecurityGroupId: !Ref TrainingSecurityGroup
          Description: All traffic within security group
      Tags:
        - Key: Name
          Value: !Sub '${SessionName}-sg'

  # Launch Template
  TrainingLaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: !Sub '${SessionName}-template'
      LaunchTemplateData:
        ImageId: ami-0c02fb55956c7d316  # Amazon Linux 2
        InstanceType: !Ref InstanceType
        KeyName: !Ref KeyPairName
        SecurityGroupIds:
          - !Ref TrainingSecurityGroup
        SubnetId: !Ref PublicSubnet
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            yum update -y
            yum install -y python3 python3-pip
            pip3 install ansible
            
            # Create training user
            useradd -m -s /bin/bash ansible-user
            echo 'ansible-user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
            
            # Setup SSH for training
            mkdir -p /home/ansible-user/.ssh
            chown ansible-user:ansible-user /home/ansible-user/.ssh
            chmod 700 /home/ansible-user/.ssh

Outputs:
  VPCId:
    Description: VPC ID for the training environment
    Value: !Ref TrainingVPC
    Export:
      Name: !Sub '${SessionName}-VPC-ID'
      
  SecurityGroupId:
    Description: Security Group ID
    Value: !Ref TrainingSecurityGroup
    Export:
      Name: !Sub '${SessionName}-SG-ID'
      
  SubnetId:
    Description: Public Subnet ID
    Value: !Ref PublicSubnet
    Export:
      Name: !Sub '${SessionName}-Subnet-ID'
EOF

# Check for existing key pair
echo -e "${BLUE}🔑 Checking SSH Key Pair...${NC}"
KEY_NAME="ansible-training-${SESSION_ID}"

if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Creating new key pair: $KEY_NAME"
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --region "$AWS_REGION" \
        --query 'KeyMaterial' \
        --output text > "${KEY_NAME}.pem"
    chmod 600 "${KEY_NAME}.pem"
    echo -e "${GREEN}✅ Key pair created: ${KEY_NAME}.pem${NC}"
else
    echo -e "${YELLOW}⚠️ Key pair already exists: $KEY_NAME${NC}"
fi

# Deploy CloudFormation stack
echo -e "${BLUE}🚀 Deploying AWS Infrastructure...${NC}"
aws cloudformation deploy \
    --template-file /tmp/ansible-training-stack.yml \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --parameter-overrides \
        ParticipantCount="$PARTICIPANT_COUNT" \
        InstanceType="$INSTANCE_TYPE" \
        KeyPairName="$KEY_NAME" \
        SessionName="$SESSION_NAME" \
    --capabilities CAPABILITY_IAM

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
else
    echo -e "${RED}❌ Infrastructure deployment failed${NC}"
    exit 1
fi

# Get stack outputs
VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' \
    --output text)

SUBNET_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue' \
    --output text)

SECURITY_GROUP_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`SecurityGroupId`].OutputValue' \
    --output text)

# Create instances for participants
echo -e "${BLUE}🖥️ Creating training instances...${NC}"

# Create Ansible control node
echo "Creating Ansible control node..."
CONTROL_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --subnet-id "$SUBNET_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${SESSION_NAME}-control},{Key=Role,Value=control},{Key=Session,Value=${SESSION_ID}}]" \
    --region "$AWS_REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

# Create managed nodes
MANAGED_INSTANCES=()
for i in $(seq 1 $PARTICIPANT_COUNT); do
    echo "Creating managed node $i..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --count 1 \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SECURITY_GROUP_ID" \
        --subnet-id "$SUBNET_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${SESSION_NAME}-node-${i}},{Key=Role,Value=managed},{Key=Session,Value=${SESSION_ID}}]" \
        --region "$AWS_REGION" \
        --query 'Instances[0].InstanceId' \
        --output text)
    MANAGED_INSTANCES+=("$INSTANCE_ID")
done

echo -e "${YELLOW}⏳ Waiting for instances to be ready...${NC}"
aws ec2 wait instance-running --instance-ids "$CONTROL_INSTANCE" "${MANAGED_INSTANCES[@]}" --region "$AWS_REGION"

# Get public IPs
echo -e "${BLUE}📊 Retrieving instance information...${NC}"
CONTROL_IP=$(aws ec2 describe-instances \
    --instance-ids "$CONTROL_INSTANCE" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

# Create inventory file
echo -e "${BLUE}📝 Creating Ansible inventory...${NC}"
cat > inventory/aws-hosts.yml << EOF
---
all:
  children:
    control:
      hosts:
        control-node:
          ansible_host: $CONTROL_IP
          ansible_user: ec2-user
          ansible_ssh_private_key_file: ${KEY_NAME}.pem
    managed:
      hosts:
EOF

# Add managed nodes to inventory
for i in "${!MANAGED_INSTANCES[@]}"; do
    INSTANCE_ID="${MANAGED_INSTANCES[$i]}"
    NODE_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    echo "        node-$((i+1)):" >> inventory/aws-hosts.yml
    echo "          ansible_host: $NODE_IP" >> inventory/aws-hosts.yml
    echo "          ansible_user: ec2-user" >> inventory/aws-hosts.yml
    echo "          ansible_ssh_private_key_file: ${KEY_NAME}.pem" >> inventory/aws-hosts.yml
done

cat >> inventory/aws-hosts.yml << EOF
  vars:
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_python_interpreter: /usr/bin/python3
EOF

# Create session info file
cat > session-info.txt << EOF
🚀 Ansible Training Session Information

Session ID: $SESSION_ID
Stack Name: $STACK_NAME
Region: $AWS_REGION
Key Pair: $KEY_NAME

📊 Infrastructure:
VPC ID: $VPC_ID
Subnet ID: $SUBNET_ID
Security Group: $SECURITY_GROUP_ID

🖥️ Control Node:
Instance ID: $CONTROL_INSTANCE
Public IP: $CONTROL_IP
SSH Command: ssh -i ${KEY_NAME}.pem ec2-user@$CONTROL_IP

🔧 Lab Commands:
# Test connectivity
ansible all -i inventory/aws-hosts.yml -m ping

# Run sample playbook
ansible-playbook -i inventory/aws-hosts.yml playbooks/test-connection.yml

💰 Cleanup:
# Delete stack when training is complete
aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_REGION

# Delete key pair
aws ec2 delete-key-pair --key-name $KEY_NAME --region $AWS_REGION
rm ${KEY_NAME}.pem
EOF

echo -e "${GREEN}✅ AWS Lab Environment Ready!${NC}"
echo ""
echo -e "${BLUE}📋 Session Summary:${NC}"
cat session-info.txt
echo ""
echo -e "${YELLOW}⚠️ Important: Save the session-info.txt file for cleanup instructions${NC}"
echo -e "${GREEN}🎓 Ready to start Ansible training!${NC}"

