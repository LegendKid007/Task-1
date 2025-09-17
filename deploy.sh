#!/bin/bash
# Deployment script for Spring Boot app

EC2_USER="ec2-user"
EC2_HOST=$1
APP_DIR="/home/ec2-user/app"
KEY_PATH=$EC2_KEY   # Jenkins sets this
LOCAL_JAR_PATH="target/app.jar"
REMOTE_JAR_NAME="app.jar"
PORT=9091

if [ -z "$EC2_HOST" ]; then
  echo "Usage: $0 <EC2_HOST>"
  exit 1
fi

if [ ! -f "$LOCAL_JAR_PATH" ]; then
  echo "Error: $LOCAL_JAR_PATH not found. Run 'mvn clean package' first."
  exit 1
fi

echo ">>> Deploying to $EC2_HOST ..."
TIMESTAMP=$(date +%Y%m%d%H%M%S)

ssh -o StrictHostKeyChecking=no -i $KEY_PATH $EC2_USER@$EC2_HOST "
  mkdir -p $APP_DIR
  if [ -f $APP_DIR/$REMOTE_JAR_NAME ]; then
      mv $APP_DIR/$REMOTE_JAR_NAME $APP_DIR/${REMOTE_JAR_NAME%.jar}_backup_$TIMESTAMP.jar
  fi
"

scp -i $KEY_PATH $LOCAL_JAR_PATH $EC2_USER@$EC2_HOST:$APP_DIR/$REMOTE_JAR_NAME

ssh -i $KEY_PATH $EC2_USER@$EC2_HOST "
  pkill -f 'java -jar $APP_DIR/$REMOTE_JAR_NAME' || echo 'No previous process found'
  cd $APP_DIR
  nohup java -jar $REMOTE_JAR_NAME --server.port=$PORT > app.log 2>&1 &
"

echo ">>> Done! App running at: http://$EC2_HOST:$PORT/hello"
