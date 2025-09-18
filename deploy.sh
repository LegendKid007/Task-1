#!/bin/bash
set -e

EC2_IP=$1
PEM_FILE=$2
APP_JAR="target/app.jar"

echo ">>> Deploying to ${EC2_IP} ..."

# Ensure SSH works
for i in {1..30}; do
  if ssh -o StrictHostKeyChecking=no -i ${PEM_FILE} ec2-user@${EC2_IP} "echo SSH ready"; then
    echo "✅ SSH is ready"
    break
  fi
  echo "⏳ Waiting for SSH..."
  sleep 10
done

echo ">>> Checking Java on EC2..."
for i in {1..30}; do
  if ssh -i ${PEM_FILE} ec2-user@${EC2_IP} "command -v java >/dev/null"; then
    echo "✅ Java is installed"
    ssh -i ${PEM_FILE} ec2-user@${EC2_IP} "java -version"
    break
  fi
  echo "⏳ Java not ready, retrying..."
  sleep 10
done

echo "📦 Copying JAR to EC2..."
scp -i ${PEM_FILE} ${APP_JAR} ec2-user@${EC2_IP}:/home/ec2-user/app.jar

echo ">>> Stopping any running app..."
ssh -i ${PEM_FILE} ec2-user@${EC2_IP} "pkill -f 'java -jar' || true"

echo ">>> Starting new app on port 9091..."
ssh -i ${PEM_FILE} ec2-user@${EC2_IP} "nohup java -jar /home/ec2-user/app.jar --server.port=9091 > app.log 2>&1 &"

echo ">>> Waiting for app to start..."
sleep 20
ssh -i ${PEM_FILE} ec2-user@${EC2_IP} "curl -s http://localhost:9091/hello || echo 'App not responding yet'"
