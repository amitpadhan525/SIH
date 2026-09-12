#!/usr/bin/env bash
# ==============================================================================
# 🏺 Artisan AI — Single Unified Startup Script
# Starts: PostgreSQL Database + FastAPI Backend + Static Cloud Tunnel (ngrok)
# ==============================================================================

set -e

DOMAIN="plaza-effort-trailside.ngrok-free.dev"
PORT="8000"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "============================================================"
echo "   🏺 Starting Artisan AI Full Stack Environment"
echo "=========================================================="
echo ""

# 1. Cleanup any dangling processes on port 8000 or existing ngrok
echo "🧹 Cleaning up any previous server instances..."
kill -9 $(lsof -ti:$PORT) 2>/dev/null || true
pkill -f "ngrok http" 2>/dev/null || true

# 2. Start PostgreSQL Database
echo "🐘 Starting PostgreSQL Database Container..."
docker compose up -d postgres

# 3. Start FastAPI Backend in background
echo "⚡ Starting FastAPI Backend on http://0.0.0.0:$PORT..."
PYTHONPATH=. "$PROJECT_DIR/backend/.venv/bin/uvicorn" backend.app.main:app --host 0.0.0.0 --port "$PORT" > /tmp/artisan_backend.log 2>&1 &
BACKEND_PID=$!

# Function to handle shutdown on Ctrl+C
cleanup() {
    echo ""
    echo "🛑 Shutting down Artisan AI stack..."
    kill $BACKEND_PID 2>/dev/null || true
    pkill -f "ngrok http" 2>/dev/null || true
    echo "👋 Shutdown complete."
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# 4. Wait for backend to be ready
echo "⏳ Waiting for backend to initialize..."
for i in {1..15}; do
    if curl -s "http://127.0.0.1:$PORT/health/db" | grep -q '"database":"connected"'; then
        echo "✅ Backend & Database are healthy and connected!"
        break
    fi
    sleep 1
done

echo ""
echo "============================================================"
echo "   🚀 Artisan AI is LIVE!"
echo "   🌐 Static Cloud URL : https://$DOMAIN"
echo "   💻 Local API Docs   : http://localhost:$PORT/docs"
echo "   📱 Mobile App       : Ready to connect automatically"
echo "============================================================"
echo "   (Press Ctrl+C anytime to stop everything)"
echo "============================================================"
echo ""

# 5. Start Ngrok Tunnel (foreground process)
ngrok http --url="$DOMAIN" "$PORT"
