#!/usr/bin/env bash
set -e

echo "=================================================="
echo "🚀 Deploying Artisan AI Production Stack (Oracle Free Tier)"
echo "=================================================="

# 1. Update system & install Docker + Compose if not installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker & Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
fi

# 2. Build & Launch Containers
echo "🏗️ Building and starting production containers..."
sudo docker compose -f docker-compose.prod.yml up -d --build

# 3. Wait for Backend Healthcheck
echo "⏳ Waiting for backend to become healthy..."
sleep 5
for i in {1..30}; do
    if curl -s http://localhost/health | grep -q "healthy"; then
        echo "✅ Artisan AI Backend is LIVE and HEALTHY!"
        break
    fi
    echo "Waiting for services... ($i/30)"
    sleep 3
done

# 4. Show public status
PUBLIC_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo ""
echo "=================================================="
echo "🎉 DEPLOYMENT SUCCESSFUL!"
echo "=================================================="
echo "API Endpoint: http://${PUBLIC_IP}"
echo "API Docs:     http://${PUBLIC_IP}/docs"
echo "Health Check: http://${PUBLIC_IP}/health"
echo "Marketplace:  http://${PUBLIC_IP}/marketplace/products"
echo "=================================================="
