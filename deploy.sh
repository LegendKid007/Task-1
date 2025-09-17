#!/bin/bash
set -e

EC2_IP=$1
PEM_FILE="$HOME/Desktop/$2"   # Jenkins passes .pem file path
APP_PORT=9091
APP_NAME="app.jar"
APP_DIR="/home/ec2-user"
REMOTE_JAR="$APP_DIR/$APP_NAME"

echo ">>> Deploying to $EC2_IP ..."

# 1. Copy JAR to EC2
scp -o StrictHostKeyChecking=no -i "$PEM_FILE" target/$APP_NAME ec2-user@$EC2_IP:$APP_DIR/

# 2. SSH into EC2 and deploy
ssh -o StrictHostKeyChecking=no -i "$PEM_FILE" ec2-user@$EC2_IP <<EOF
  set -e
  echo ">>> Stopping any running app..."
  pkill -f "$APP_NAME" || true

  echo ">>> Starting new app on port $APP_PORT..."
  nohup java -jar $REMOTE_JAR --server.port=$APP_PORT --server.address=0.0.0.0 > app.log 2>&1 &

  # Wait for startup
  echo ">>> Waiting for app to start..."
  for i in {1..10}; do
    sleep 5
    if curl -s http://localhost:$APP_PORT/hello >/dev/null; then
      echo ">>> App is UP ✅"
      exit 0
    fi
  done

  echo ">>> App failed to start ❌"
  tail -n 50 app.log
  exit 1
EOF

echo ">>> Done! App running at: http://$EC2_IP:$APP_PORT/hello"
