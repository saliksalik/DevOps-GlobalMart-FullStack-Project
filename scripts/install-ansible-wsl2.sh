#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# File: scripts/install-ansible-wsl2.sh
# Purpose: Install Ansible inside WSL2 on Windows.
#
# HOW TO USE:
#   1. Open Windows Terminal
#   2. Launch WSL2: wsl
#   3. Copy this file into WSL2, then run:
#      chmod +x install-ansible-wsl2.sh && ./install-ansible-wsl2.sh
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

echo "=== Installing Ansible on WSL2 (Ubuntu) ==="

# ── Step 1: Update APT ────────────────────────────────────────────────────
echo "[1/6] Updating package cache..."
sudo apt-get update -y

# ── Step 2: Install prerequisites ─────────────────────────────────────────
echo "[2/6] Installing prerequisites..."
sudo apt-get install -y \
  software-properties-common \
  python3 \
  python3-pip \
  python3-venv \
  sshpass \
  openssh-client

# ── Step 3: Add Ansible PPA ────────────────────────────────────────────────
echo "[3/6] Adding Ansible PPA..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

# ── Step 4: Install Ansible ────────────────────────────────────────────────
echo "[4/6] Installing Ansible..."
sudo apt-get install -y ansible

# ── Step 5: Verify installation ───────────────────────────────────────────
echo "[5/6] Verifying installation..."
ansible --version
ansible-playbook --version

# ── Step 6: Install useful Ansible collections ────────────────────────────
echo "[6/6] Installing Ansible Galaxy collections..."
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general

echo ""
echo "✅ Ansible installed successfully in WSL2!"
echo ""
echo "Quick test — ping localhost:"
echo '  ansible localhost -m ping -c local'
echo ""
echo "Run the GlobalMart setup playbook:"
echo "  cd /path/to/project-phoenix"
echo "  ansible-playbook -i ansible/inventory.ini ansible/setup.yml --ask-become-pass"
echo ""
echo "NOTE: To SSH from WSL2 to remote servers, your private key must be in WSL2's"
echo "  filesystem (e.g., ~/.ssh/globalmart.pem) with chmod 600 permissions."
echo "  To copy from Windows: cp /mnt/c/Users/YourName/.ssh/globalmart.pem ~/.ssh/"
echo "  chmod 600 ~/.ssh/globalmart.pem"
