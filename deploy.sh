#!/bin/bash
# Deployment script for Spring Boot app with backup

EC2_USER="ec2-user"
EC2_HOST="54.174.128.187"   # your EC2 public IP
APP_DIR="/home/ec2-user/app"

# Pick the latest built JAR from target/ (no need to hardcode version)
LOCAL_JAR_PATH=$(ls -t target/*.jar | head -n 1)

REMOTE_JAR_NAME="app.jar"
KEY_PATH="/Users/komalsaiballa/Desktop/jenkins.pem"
PORT=9091

echo ">>> Starting deployment to $EC2_HOST ..."
echo ">>> Local JAR: $LOCAL_JAR_PATH"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Ensure app dir exists and backup old JAR
ssh -i $KEY_PATH $EC2_USER@$EC2_HOST "
  mkdir -p $APP_DIR
  if [ -f $APP_DIR/$REMOTE_JAR_NAME ]; then
      mv $APP_DIR/$REMOTE_JAR_NAME $APP_DIR/${REMOTE_JAR_NAME%.jar}_backup_$TIMESTAMP.jar
      echo 'Old JAR backed up as ${REMOTE_JAR_NAME%.jar}_backup_$TIMESTAMP.jar'
  else
      echo 'No existing JAR to backup'
  fi
"

# Copy the new JAR to EC2
scp -i $KEY_PATH $LOCAL_JAR_PATH $EC2_USER@$EC2_HOST:$APP_DIR/$REMOTE_JAR_NAME

# Stop any running app
ssh -i $KEY_PATH $EC2_USER@$EC2_HOST "
  pkill -f 'java -jar $APP_DIR/$REMOTE_JAR_NAME' || echo 'No previous process found'
"

# Start the new JAR in background
ssh -i $KEY_PATH $EC2_USER@$EC2_HOST "
  cd $APP_DIR
  nohup java -jar $REMOTE_JAR_NAME --server.port=$PORT > app.log 2>&1 &
"

echo ">>> Deployment complete. Access the app at: http://$EC2_HOST:$PORT/hello"
