#!/bin/bash
EC2_IP=$1
PEM_FILE=$2
APP_NAME="app.jar"
APP_PORT=9091
REMOTE_JAR="/home/ec2-user/$APP_NAME"

echo ">>> Deploying to $EC2_IP ..."

# Wait for SSH
for i in {1..12}; do
  if ssh -o StrictHostKeyChecking=no -i "$PEM_FILE" ec2-user@$EC2_IP "echo 'SSH ready'" 2>/dev/null; then
    echo "✅ SSH is ready"
    break
  fi
  echo "⏳ Still waiting for SSH..."
  sleep 5
done

# Copy JAR
scp -o StrictHostKeyChecking=no -i "$PEM_FILE" target/app.jar ec2-user@$EC2_IP:$REMOTE_JAR

# Deploy app
ssh -o StrictHostKeyChecking=no -i "$PEM_FILE" ec2-user@$EC2_IP <<EOF
  set -e

  # Ensure Java is installed
  if ! command -v java &> /dev/null; then
    echo ">>> Installing Java..."
    sudo yum update -y
    sudo amazon-linux-extras enable corretto17
    sudo yum install -y java-17-amazon-corretto
  fi

  echo ">>> Stopping any running app..."
  pkill -f "$APP_NAME" || true

  echo ">>> Starting new app on port $APP_PORT..."
  nohup java -jar $REMOTE_JAR --server.port=$APP_PORT --server.address=0.0.0.0 > app.log 2>&1 &

  echo ">>> Waiting for app to start..."
  for i in {1..12}; do
    sleep 5
    if curl -s http://localhost:$APP_PORT/hello >/dev/null; then
      echo "✅ App is UP"
      exit 0
    fi
  done

  echo "❌ App failed to start"
  tail -n 50 app.log
  exit 1
EOF
