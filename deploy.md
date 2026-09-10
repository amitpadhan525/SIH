# 🚀 Production Deployment Guide (100% Free Forever)
### SIH Problem Statement 90: AI-Powered Digital Business Platform for Artisans

This document provides complete, step-by-step instructions for deploying the entire **Artisan AI** stack (FastAPI Backend, AI Whisper Engine, Image Studio, PostgreSQL Database, and Nginx Reverse Proxy) on **Oracle Cloud "Always Free" Tier (4 ARM vCPUs, 24 GB RAM, 200 GB Storage, ₹0/month)**.

---

## 🏗️ Architecture Overview

```
                        📱 Mobile App (Flutter Client)
                                      │
                                      ▼ (HTTP/HTTPS Port 80/443)
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ORACLE CLOUD ALWAYS FREE VM                           │
│                     (4 vCPUs • 24 GB RAM • 200 GB SSD)                      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        Nginx Reverse Proxy                          │   │
│   │               (Gzip, Caching, 50MB Media Uploads)                   │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │ (Internal Network)                   │
│                                      ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                       FastAPI Backend Container                     │   │
│   │   • faster-whisper Speech-to-Text (Odia, Hindi, English)            │   │
│   │   • Dynamic Pricing Engine (Living Wage Benchmarking)               │   │
│   │   • Multimodal Catalog Generator & rembg Image Processing           │   │
│   │   • REST APIs: /products, /marketplace, /catalog, /pricing, /auth   │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │ (Internal Port 5432)                 │
│                                      ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                     PostgreSQL 16 Database                          │   │
│   │             (Persistent Docker Volume: pgdata)                      │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites
- An Oracle Cloud account: Sign up for free at **[cloud.oracle.com/free](https://www.oracle.com/cloud/free/)** (Requires standard debit/credit card verification, ₹0 is charged).
- Terminal with `ssh` client installed.

---

## 🌐 Step 1: Provision the Free Oracle Cloud VM

1. Log in to the **Oracle Cloud Console**.
2. Navigate to **Compute $\to$ Instances** and click **Create Instance**.
3. Configure the VM settings:
   - **Name**: `artisan-ai-server`
   - **Placement**: Default AD.
   - **Image**: Click *Change Image* $\to$ Choose **Ubuntu 22.04 LTS** or **Ubuntu 24.04 LTS**.
   - **Shape**: Click *Change Shape* $\to$ Select **Ampere (ARM-based)**:
     - **Number of OCPUs**: `4` *(Always Free Eligible)*
     - **Amount of Memory**: `24 GB` *(Always Free Eligible)*
   - **Networking**:
     - Create new Virtual Cloud Network (VCN)
     - Select **Assign a public IPv4 address**.
   - **Save Private Key**: Click **Save Private Key** to download `ssh-key.key` to your computer.
4. Click **Create** and wait 60 seconds for the instance status to turn **Running** (Green).
5. Copy your **Public IPv4 Address** (e.g. `129.154.xxx.xxx`).

---

## 🔓 Step 2: Open Ingress Firewall Ports

### 2.1 Oracle Cloud VCN Security Rules
1. In Oracle Cloud Console, navigate to **Networking $\to$ Virtual Cloud Networks**.
2. Click your VCN name $\to$ Click **Security Lists** $\to$ **Default Security List for...**
3. Click **Add Ingress Rules**:
   - **Source Type**: `CIDR`
   - **Source CIDR**: `0.0.0.0/0`
   - **IP Protocol**: `TCP`
   - **Destination Port Range**: `80, 443, 8000`
   - **Description**: `Allow Web HTTP, HTTPS, and API traffic`
4. Click **Add Ingress Rules**.

### 2.2 Host-level Firewall (Ubuntu `iptables`)
Oracle Ubuntu images have default `iptables` rules that block inbound HTTP traffic. We will open them when we SSH in.

---

## ⚡ Step 3: Connect & Run 1-Click Deployment

### 3.1 SSH into your VM
On your local machine, open terminal:
```bash
chmod 400 /path/to/ssh-key.key
ssh -i /path/to/ssh-key.key ubuntu@<YOUR_VM_PUBLIC_IP>
```

### 3.2 Unblock Ubuntu host firewall
Run inside the VM:
```bash
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8000 -j ACCEPT
sudo netfilter-persistent save || true
```

### 3.3 Clone Repository & Execute Deployment Script
```bash
# 1. Clone the project
git clone https://github.com/amitpadhan525/SIH.git
cd SIH

# 2. Run the automated deployment script
./deploy.sh
```

The script will automatically:
- Install Docker Engine & Docker Compose plugin
- Build the optimized Docker container for FastAPI & AI models
- Start PostgreSQL 16 database with persistent storage
- Configure Nginx reverse proxy with 50MB upload limits
- Perform automated health check verification

---

## 🧪 Step 4: Verify Your Deployment

Once `deploy.sh` finishes, verify your live services in any browser or terminal:

| Service | URL | Expected Response |
| :--- | :--- | :--- |
| **Liveness Health Check** | `http://<YOUR_VM_PUBLIC_IP>/health` | `{"status":"healthy","service":"Artisan AI Backend"}` |
| **Database Connection** | `http://<YOUR_VM_PUBLIC_IP>/health/db` | `{"database":"connected","detail":null}` |
| **Interactive Swagger API Docs** | `http://<YOUR_VM_PUBLIC_IP>/docs` | Full interactive OpenAPI dashboard |
| **Public Marketplace Feed** | `http://<YOUR_VM_PUBLIC_IP>/marketplace/products` | `[]` (Empty clean catalog ready for artisan posts) |

---

## 📱 Step 5: Connect Flutter Mobile App to Your Cloud Server

1. On your local development machine, open `mobile/lib/core/constants/api_constants.dart`.
2. Update the `_prodBaseUrl` with your VM's public IP:
   ```dart
   static const String _prodBaseUrl = 'http://<YOUR_VM_PUBLIC_IP>';
   ```
3. Build the production Android APK:
   ```bash
   cd mobile
   flutter build apk --release
   ```
4. Install the new APK on any phone:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🔒 Step 6 (Optional): Custom Domain & Free SSL with Let's Encrypt

If you have a custom domain name (e.g. `api.myartisanapp.com`):

1. Add an **A Record** in your DNS provider pointing to `<YOUR_VM_PUBLIC_IP>`.
2. Install Certbot on the VM:
   ```bash
   sudo apt-get install -y certbot python3-certbot-nginx
   ```
3. Generate your free SSL certificate:
   ```bash
   sudo certbot --nginx -d api.myartisanapp.com
   ```
4. Update `mobile/lib/core/constants/api_constants.dart` to `https://api.myartisanapp.com`.

---

## 🛠️ Step 7: Useful Management Commands

Run these inside `~/SIH` on your VM whenever needed:

```bash
# View live backend application logs (Whisper STT, Pricing, Requests)
sudo docker compose -f docker-compose.prod.yml logs -f backend

# Restart all services
sudo docker compose -f docker-compose.prod.yml restart

# Pull the latest code and rebuild
git pull origin main
sudo docker compose -f docker-compose.prod.yml up -d --build

# Stop all containers
sudo docker compose -f docker-compose.prod.yml down
```

---

## 🛡️ Security & Zero Cost Guarantee
- **₹0 Incurred**: All selected hardware resources (4 OCPUs, 24 GB RAM, 200 GB Disk) are strictly within the **Always Free** tier limits.
- **Data Persistence**: All uploaded photos and database entries are stored in Docker volumes (`pgdata` and `media_uploads`) and survive container updates or VM reboots.
