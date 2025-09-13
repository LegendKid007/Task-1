#!/bin/bash
# Deployment script for Spring Boot app

EC2_USER="ec2-user"
EC2_HOST="3.141.104.173"
APP_DIR="/home/ec2-user/app"
LOCAL_JAR_PATH="/Users/komalsaiballa/.jenkins/workspace/Task1.2_main/target/*.jar"
REMOTE_JAR_NAME="app.jar"
PORT=9091

echo "Starting deployment to $EC2_HOST ..."

# Copy the JAR to EC2
scp -i ~/Desktop/mykey.pem $LOCAL_JAR_PATH $EC2_USER@$EC2_HOST:$APP_DIR/$REMOTE_JAR_NAME

# Stop any existing app
ssh -i ~/Desktop/mykey.pem $EC2_USER@$EC2_HOST "pkill -f 'java -jar $APP_DIR/$REMOTE_JAR_NAME' || echo 'No previous process found'"

# Start the new JAR in the background
ssh -i ~/Desktop/mykey.pem $EC2_USER@$EC2_HOST "nohup java -jar $APP_DIR/$REMOTE_JAR_NAME > $APP_DIR/app.log 2>&1 &"

echo "Deployment complete. Access the app at: http://$EC2_HOST:$PORT/"
