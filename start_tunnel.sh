#!/usr/bin/env bash
# Script to launch the static tunnel using ngrok / pinggy

DOMAIN="plaza-effort-trailside.ngrok-free.dev"
PORT="8000"

echo "================================================="
echo "🏺 Starting Artisan AI Cloud Tunnel"
echo "🌐 Static Domain: https://$DOMAIN"
echo "🔌 Forwarding to: http://localhost:$PORT"
echo "================================================="

ngrok http --url="$DOMAIN" "$PORT"
