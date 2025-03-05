yum update -y
yum install -y aws-cli
yum install -y amazon-cloudwatch-agent
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
yum install -y git nodejs npm
export LIBRE_DIR=/etc/LibreChat
export LIBRE_USER=LibreChat
sudo adduser $LIBRE_USER && sudo usermod -aG wheel $LIBRE_USER
mkdir -p $LIBRE_DIR
chown -R $LIBRE_USER:wheel $LIBRE_DIR
sudo -u LibreChat git clone https://github.com/danny-avila/LibreChat.git $LIBRE_DIR/
export SNSTOPIC=$(aws ssm get-parameter --name /userDataTopicArn --query Parameter.Value --with-decryption --output text)
echo "SNSTOPIC: $SNSTOPIC"
aws sns publish --topic-arn $SNSTOPIC --message 'User data script completed'
cd $LIBRE_DIR
sudo -u LibreChat cp $LIBRE_DIR/.env.example $LIBRE_DIR/.env
sudo chown $LIBRE_USER:wheel $LIBRE_DIR/.env
export MONGODB_URI=$(aws ssm get-parameter --name /docdb/connection-string --query Parameter.Value --with-decryption --output text)
export MONGODB_PASS=$(aws secretsmanager get-secret-value --secret-id /docdb/master-password --query SecretString --output text | jq -r .password)
export MONGODB_USER=$(aws secretsmanager get-secret-value --secret-id /docdb/master-password --query SecretString --output text | jq -r .username)
export BEDROCK_AWS_DEFAULT_REGION=us-east-1
export BEDROCK_AWS_MODELS=anthropic.claude-3-5-sonnet-20240620-v1:0,meta.llama3-1-8b-instruct-v1:0
export MONGODB_CONNECTION_STRING=mongodb://$MONGODB_USER:$MONGODB_PASS@$MONGODB_URI
sudo -u LibreChat sed -i "s#^MONGO_URI=.*#MONGO_URI=$MONGODB_CONNECTION_STRING#" $LIBRE_DIR/.env
sudo -u LibreChat echo "BEDROCK_AWS_DEFAULT_REGION=$BEDROCK_AWS_DEFAULT_REGION" >> $LIBRE_DIR/.env
sudo -u LibreChat npm --prefix $LIBRE_DIR install $LIBRE_DIR/package.json
sudo -u LibreChat npm --prefix $LIBRE_DIR ci
sudo -u LibreChat npm --prefix $LIBRE_DIR run frontend
