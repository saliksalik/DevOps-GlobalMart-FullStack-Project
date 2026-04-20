# 🚀 Project Phoenix — GlobalMart DevOps Transformation

Project Phoenix is a full-stack DevOps implementation of a fictional but realistic e-commerce company called GlobalMart.
The goal of this project is simple: move from fragile, manual delivery to a reliable, observable, and repeatable production workflow.

This repository demonstrates how modern DevOps practices work together end-to-end:

- CI/CD with quality gates (Jenkins)
- Reproducible containers (Docker)
- Declarative infrastructure (Terraform)
- Server bootstrap and state enforcement (Ansible + Puppet)
- Zero-downtime release strategy (Kubernetes Blue-Green)
- Monitoring, alerting, and centralized logs (Prometheus, Grafana, ELK)

If you are a student, interviewer, hiring manager, or engineer evaluating this repository, you can treat it as a practical reference implementation for a production-minded DevOps pipeline.

---

## 🌍 Why This Project Exists

Most teams do not fail because they cannot write code.
They fail because releases are risky, environments drift, and issues are found too late.

Project Phoenix addresses those real-world pain points by focusing on:

- fast feedback after every commit
- immutable deployments instead of manual patching
- rollback safety during production releases
- measurable system health with actionable alerts

In short: this is not just "tools in one repo". It is an opinionated delivery system designed to reduce change failure rate and improve deployment confidence.

---

## 🎯 What You Can Expect

By running this project, you can:

- ship code through an automated pipeline with tests and artifacts
- build and run the app consistently across local and cloud environments
- provision infrastructure from code and tear it down safely
- observe application behavior with dashboards and logs
- perform blue-green releases with minimal downtime risk

---

## 🧾 Repository Description (Suggested for GitHub)

**Short description:**
Production-grade DevOps capstone for a GlobalMart e-commerce API using Jenkins, Docker, Kubernetes, Terraform, Ansible, Puppet, Prometheus, Grafana, and ELK.

**Topics/tags suggestion:**
`devops`, `jenkins`, `docker`, `kubernetes`, `terraform`, `ansible`, `puppet`, `prometheus`, `grafana`, `elk`, `cicd`, `blue-green-deployment`, `nodejs`

---

## 📋 Table of Contents

1. [DevOps Culture & Principles](#-devops-culture--principles)
2. [Problem vs. Solution](#-problem-vs-solution)
3. [Architecture Diagram](#-architecture-diagram)
4. [Tech Stack](#-tech-stack)
5. [Project Structure](#-project-structure)
6. [Quick Start Guide (Windows)](#-quick-start-guide-windows)
7. [Phase-by-Phase Breakdown](#-phase-by-phase-breakdown)
8. [Continuous Improvement](#-continuous-improvement)
9. [Syllabus Coverage Checklist](#-syllabus-coverage-checklist)

---
## 🖼️ Execution Proof

This repository includes evidence of the full deployment and validation workflow from local app testing through CNCF-style Kubernetes blue-green release.

### Screenshots

- [App health and API validation](Screenshots/API Health Status 200.png)
- [Invalid request handled correctly](Screenshots/invalid request handled perfectly.png)
- [CI pipeline build success](Screenshots/CI Pipeline Build Success.png)
- [Jenkins dashboard and job creation](Screenshots/jenkins-dashboard.png)
- [Prometheus UI confirmed](Screenshots/Prometheous Check 200.png)
- [Grafana UI confirmed](Screenshots/Grafana Check 200.png)
- [Kibana UI confirmed](Screenshots/Kibana Check 200.png)
- [Kubernetes enabled and cluster running](Screenshots/Kubernetes Enabled.png)
- [Blue deployment running 3 pods](Screenshots/Blue deployment is running 3 pods..png)
- [Green deployment running 3 pods](Screenshots/Green Deplyment running three PODS.png)
- [Service selector is green after blue-green switch](Screenshots/Service slot is green..png)
- [All pods healthy after cleanup](Screenshots/All Pods are Healthy.png)

---
## 🧠 DevOps Culture & Principles

### What is DevOps Culture?
DevOps is not a tool — it is a **cultural philosophy** that breaks down the wall between Development (who wants to ship fast) and Operations (who wants stability). It promotes:

- **Collaboration over Silos:** Dev, QA, and Ops share responsibility for the full software lifecycle.
- **Automation First:** Every repetitive manual task is a bug waiting to happen. Automate it.
- **Shift Left:** Catch defects, security issues, and misconfigurations *early* (in dev/CI), not in production.
- **Fail Fast, Learn Faster:** Small, frequent releases reduce blast radius. Failures become learning opportunities.
- **Shared Ownership:** The team that builds it, runs it. No more "throwing code over the wall."

### Continuous Improvement Principles Applied in This Project

| Principle | Implementation in Project Phoenix |
|---|---|
| **CALMS** (Culture, Automation, Lean, Measurement, Sharing) | Each phase maps to one pillar of CALMS |
| **The Three Ways** (Flow, Feedback, Continuous Learning) | Jenkins pipeline = Flow; Prometheus/Kibana = Feedback; Post-mortems = Learning |
| **Kaizen** (Small, continuous improvements) | Every merge to `develop` triggers the pipeline, surfacing issues immediately |
| **Blameless Post-Mortems** | Alert rules are written to capture *what* failed, not *who* failed |

---

## ⚔️ Problem vs. Solution

| # | Problem (Before Phoenix) | Solution (After Phoenix) | Tool Used |
|---|---|---|---|
| 1 | Manual, error-prone deployments via SSH and copy-paste | Fully automated CI/CD pipeline triggered on every git push | Jenkins + Jenkinsfile |
| 2 | "Works on my machine" — inconsistent environments | Immutable Docker containers built from a versioned Dockerfile | Docker (Multi-stage) |
| 3 | No visibility into application health or errors | Real-time dashboards with P95 latency, error rates, and CPU/RAM | Prometheus + Grafana |
| 4 | Logs scattered across 12 servers, impossible to search | Centralized log aggregation with full-text search and visualization | ELK Stack + Filebeat |
| 5 | Server configuration drift — every server slightly different | Idempotent Puppet manifests enforce desired state every 30 minutes | Puppet |
| 6 | New servers take days to provision manually | One-command server bootstrap with all required software | Ansible Playbook |
| 7 | Deployments require 30-minute downtime windows | Zero-downtime Blue-Green deployments with instant rollback | Kubernetes + Shell Script |
| 8 | Infrastructure created by clicking in the AWS console | All infrastructure defined as code, version-controlled, and reproducible | Terraform |
| 9 | No rollback strategy — a bad deploy means a crisis | Blue-Green keeps the old slot live for 5 minutes post-switch | Blue-Green Strategy |
| 10 | Single point of failure — one server, no redundancy | K8s deployment with 3 replicas spread across nodes via anti-affinity | Kubernetes Scheduler |

---

## 🏗️ Architecture Diagram

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                        PROJECT PHOENIX — GLOBALMART                              ║
║                     Complete DevOps Architecture                                 ║
╚══════════════════════════════════════════════════════════════════════════════════╝

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                         DEVELOPER WORKSTATION (Windows)                     │
  │                                                                             │
  │   Code Editor  →  git push  →  GitHub/GitLab                                │
  │                               (main / develop / feature/*)                  │
  └──────────────────────────────────┬──────────────────────────────────────────┘
                                     │ Webhook / Poll SCM
                                     ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │                    CI/CD LAYER  (Jenkins — Docker)                           │
  │                                                                              │
  │  ┌─────────────────┐        JNLP :50000        ┌──────────────────────────┐  │
  │  │  Jenkins Master │ ◄────────────────────────►│  Jenkins Agent (Slave)   │  │
  │  │  :8080          │                           │  docker-agent-01         │  │
  │  └─────────────────┘                           └──────────────────────────┘  │
  │                                                                              │
  │  Pipeline Stages:  Checkout → Build → Test → Docker Build → Push → Deploy    │
  └──────────────────────────────────┬───────────────────────────────────────────┘
                                     │
               ┌─────────────────────┼──────────────────────┐
               ▼                     ▼                       ▼
  ┌────────────────────┐  ┌───────────────────┐  ┌──────────────────────────┐
  │  ARTIFACT REGISTRY │  │   TERRAFORM (IaC)  │  │  ANSIBLE (Config Mgmt)  │
  │  Docker Hub        │  │   AWS EC2 + VPC    │  │  Install Docker + Java  │
  │  globalmart-api:v1 │  │   ALB + SG + Subnets│  │  setup.yml playbook    │
  └────────────────────┘  └───────────────────┘  └──────────────────────────┘
               │                     │
               ▼                     ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │               KUBERNETES CLUSTER  (Production Namespace)                     │
  │                                                                              │
  │  Ingress (nginx) → api.globalmart.com                                        │
  │       │                                                                      │
  │       ▼                                                                      │
  │  ┌───────────────────────────────────────────────────────────────────────┐   │
  │  │                    Service: globalmart-service                        │   │
  │  │              (selector: slot=blue  OR  slot=green)                    │   │
  │  └────────────────────────┬──────────────────────┬───────────────────────┘   │
  │                           ▼                      ▼                           │
  │              ┌─────────────────────┐  ┌─────────────────────┐                │
  │              │  BLUE  Deployment   │  │  GREEN Deployment   │                │
  │              │  (v1 — 3 Replicas)  │  │  (v2 — 3 Replicas)  │                │
  │              │  Pod1 Pod2 Pod3     │  │  Pod4 Pod5 Pod6     │                │
  │              │  ← LIVE TRAFFIC     │  │  ← IDLE / STAGING   │                │
  │              └─────────────────────┘  └─────────────────────┘                │
  │                                                                              │
  │  ── RollingUpdate strategy: maxSurge=1, maxUnavailable=1 ──────────────────  │
  │  ── PodAntiAffinity: pods spread across nodes ────────────────────────────   │
  └──────────────────────────┬───────────────────────────────────────────────────┘
                             │  /metrics endpoint
              ┌──────────────┼──────────────────┐
              ▼              ▼                  ▼
  ┌──────────────────┐  ┌──────────┐  ┌───────────────────────────────────────┐
  │  PROMETHEUS      │  │ GRAFANA  │  │         ELK STACK                     │
  │  Scrape :9090    │  │ :3002    │  │                                       │
  │  • App metrics   │◄─►│Dashboards│  │ Filebeat → Logstash → Elasticsearch  │
  │  • Node metrics  │  │Alerts    │  │                    → Kibana :5601     │
  │  • cAdvisor      │  │          │  │                                       │
  │  Alert Rules     │  │          │  │  Index: globalmart-logs-YYYY.MM.DD    │
  └──────────────────┘  └──────────┘  └───────────────────────────────────────┘
              │
              ▼
  ┌──────────────────────────────┐
  │   ALERTMANAGER  :9093        │
  │   → Email: devops-team       │
  └──────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  STATE MANAGEMENT LAYER (Puppet — runs every 30 min on all nodes)            │
  │  • /etc/globalmart/app.conf  — enforced content                              │
  │  • nginx config              — enforced                                      │
  │  • Services (nginx, globalmart, postgresql) — enforced running               │
  │  • Package versions          — pinned and enforced                           │
  └──────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Category | Technology | Version | Purpose |
|---|---|---|---|
| **Application** | Node.js + Express | 20 LTS | GlobalMart REST API |
| **Testing** | Jest + Supertest | 29.x | Unit & integration tests |
| **Source Control** | Git | Latest | Branching strategy |
| **CI/CD** | Jenkins | LTS | Pipeline automation |
| **Containerization** | Docker | 24.x | Multi-stage image builds |
| **Orchestration** | Kubernetes | 1.28+ | Production deployment |
| **IaC** | Terraform | 1.6+ | AWS infrastructure provisioning |
| **Config Mgmt (Push)** | Ansible | 2.15+ | Server bootstrap (procedural) |
| **Config Mgmt (Pull)** | Puppet | 8.x | State enforcement (declarative) |
| **Monitoring** | Prometheus + Grafana | 2.49 / 10.3 | Metrics & dashboards |
| **Logging** | ELK Stack + Filebeat | 8.12 | Log aggregation & search |
| **Cloud** | AWS (EC2, ALB, VPC) | — | Hosting infrastructure |

---

## 📁 Project Structure

```
project-phoenix/
│
├── 📄 README.md                    ← You are here
├── 📄 Jenkinsfile                  ← Declarative CI/CD pipeline
├── 📄 docker-compose.yml           ← Full local dev stack
│
├── 📁 app/                         ← GlobalMart Node.js Application
│   ├── src/server.js               ← Express API (products, cart, orders)
│   ├── tests/server.test.js        ← Jest unit tests (100% route coverage)
│   ├── Dockerfile                  ← Multi-stage (builder + production)
│   └── package.json
│
├── 📁 jenkins/
│   └── docker-compose.yml          ← Jenkins Master + 2 Agents
│
├── 📁 ansible/
│   ├── setup.yml                   ← Install Docker + Java + configure servers
│   └── inventory.ini               ← Target server list
│
├── 📁 puppet/
│   └── manifests/site.pp           ← State enforcement manifests
│
├── 📁 kubernetes/
│   ├── deployment.yaml             ← RollingUpdate deployment (3 replicas)
│   ├── service-ingress.yaml        ← Service + Ingress + Namespaces
│   └── blue-green.yaml             ← Blue + Green deployments
│
├── 📁 terraform/
│   ├── main.tf                     ← AWS EC2 + VPC + ALB + SG
│   └── terraform.tfvars            ← Variable values
│
├── 📁 monitoring/
│   ├── prometheus.yml              ← Scrape configs + K8s SD
│   ├── alertmanager.yml            ← Email alert routing
│   ├── rules/globalmart_alerts.yml ← Alert rules (down, 5xx, latency)
│   └── docker-compose.yml          ← Prometheus + Grafana + Exporters
│
├── 📁 elk/
│   ├── docker-compose.yml          ← ES + Logstash + Kibana + Filebeat
│   ├── logstash/pipeline/globalmart.conf  ← Ingest, parse, enrich pipeline
│   ├── logstash/config/logstash.yml
│   └── filebeat/filebeat.yml       ← Docker log shipping
│
└── 📁 scripts/
    ├── init-repo.ps1               ← PowerShell: Git branch setup
    ├── install-ansible-wsl2.sh     ← WSL2 Ansible installation
    └── blue-green-deploy.sh        ← Automated Blue-Green switch script
```

---

## ⚡ Quick Start Guide (Windows)

### Prerequisites
- Docker Desktop (with WSL2 backend enabled)
- Git for Windows
- kubectl + Helm (for K8s steps)
- Terraform CLI
- VS Code

### Step 1 — Initialize Git Repository
```powershell
# In PowerShell (project root)
.\scripts\init-repo.ps1
```

### Step 2 — Start Jenkins Master + Agents
```powershell
cd jenkins
docker-compose up -d
# Access: http://localhost:8080
# Get initial admin password:
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 3 — Start Full Application Stack Locally
```powershell
# From project root
docker-compose up -d

# Test the API:
curl http://localhost:3000/health
curl http://localhost:3000/api/products
```

### Step 4 — Install Ansible (WSL2)
```bash
# Open WSL2 terminal, navigate to project, then:
chmod +x scripts/install-ansible-wsl2.sh
./scripts/install-ansible-wsl2.sh

# Run the setup playbook:
ansible-playbook -i ansible/inventory.ini ansible/setup.yml --ask-become-pass
```

### Step 5 — Provision AWS Infrastructure
```powershell
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Step 6 — Deploy to Kubernetes
```powershell
kubectl apply -f kubernetes/service-ingress.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl get pods -n production -w
```

### Step 7 — Execute Blue-Green Deployment
```bash
export DOCKER_IMAGE="globalmart/globalmart-api"
export GIT_COMMIT_SHORT="abc1234"
bash scripts/blue-green-deploy.sh
```

### Step 8 — Start Monitoring Stack
```powershell
cd monitoring
docker-compose up -d
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3001  (admin/admin)
```

### Step 9 — Start ELK Stack
```powershell
# ⚠ Windows: Run this first in WSL2 or Docker Desktop terminal:
# sysctl -w vm.max_map_count=262144

cd elk
docker-compose up -d
# Kibana: http://localhost:5601
# Create index pattern: globalmart-logs-*
```

---

## 📦 Phase-by-Phase Breakdown

### Phase 1 — Foundations & CI
The pipeline starts at every `git push`. Jenkins Master delegates the build job to `docker-agent-01` via the JNLP protocol on port 50000. The Jenkinsfile runs 8 stages: Checkout → Build → Test → Docker Build → Push → Archive → Dev Deploy → Prod Deploy (with manual approval gate on `main`).

### Phase 2 — Configuration & Containers
**Ansible** (procedural): Runs tasks top-to-bottom to bootstrap a brand-new server. Run once or re-run idempotently.
**Puppet** (declarative): Agents pull the catalog from the Puppet Master every 30 minutes. If anyone manually edits `/etc/globalmart/app.conf`, Puppet reverts it. This is the key difference from Ansible.

The **Dockerfile** uses a two-stage build: `builder` installs all dev dependencies and runs tests, then `production` copies only the compiled source into a clean Alpine image — resulting in a ~150MB image vs ~600MB single-stage.

### Phase 3 — Operations & Cloud
**Terraform** provisions the entire AWS environment (VPC, subnets, SG, EC2 × 2, ALB) from scratch. `terraform destroy` tears it all down. Zero manual console clicks.

**Blue-Green**: The script detects the live slot, deploys to the idle slot, health-checks it, then patches the K8s Service selector (an instant atomic operation) to flip all traffic. The old slot stays running for 5 minutes as a rollback window, then scales to 0.

---

## 🔄 Continuous Improvement

The feedback loop is the beating heart of DevOps. Here's how Project Phoenix implements it:

```
Code → Commit → CI Pipeline → Automated Tests → Docker Build
  ↑                                                        ↓
Metrics ← Grafana Dashboards ← Prometheus ← Running App in K8s
  ↑                                                        ↓
Alert ← Alertmanager ← Threshold Breached         ELK Log Analysis
  ↑                                                        ↓
Post-Mortem → Fix → Commit  ←───────────────────── Kibana Insights
```

**Feedback loops implemented:**
1. **Immediate (< 5 min):** Test failures break the Jenkins build. Developer knows within minutes.
2. **Short (< 15 min):** Prometheus detects a spike in 5xx errors and fires an alert to the team email.
3. **Medium (same day):** Kibana log analysis reveals the root cause of user-facing errors.
4. **Long (sprint retrospective):** Grafana trends show if P95 latency is increasing over weeks — triggering a performance investigation.

**Metrics that drive decisions:**

| Metric | Alert Threshold | Action |
|---|---|---|
| API availability | < 100% for 1 min | Page on-call engineer |
| 5xx error rate | > 5% for 2 min | Investigate logs in Kibana |
| P95 response time | > 1 second | Profile app, check DB |
| Host memory | > 85% | Scale horizontally via K8s |
| Disk space | < 15% free | Add EBS volume via Terraform |

---

## ✅ Syllabus Coverage Checklist

| Topic | Status | File |
|---|---|---|
| DevOps Culture & Principles | ✅ | README.md |
| Git Branching Strategy | ✅ | `scripts/init-repo.ps1` |
| Jenkins Master-Slave Architecture | ✅ | `jenkins/docker-compose.yml` |
| Declarative Jenkinsfile Pipeline | ✅ | `Jenkinsfile` |
| Ansible (WSL2 install + playbook) | ✅ | `ansible/setup.yml` |
| Puppet State Management | ✅ | `puppet/manifests/site.pp` |
| Multi-stage Dockerfile | ✅ | `app/Dockerfile` |
| Kubernetes Deployment (RollingUpdate) | ✅ | `kubernetes/deployment.yaml` |
| Kubernetes Service + Ingress | ✅ | `kubernetes/service-ingress.yaml` |
| Terraform (AWS provisioning) | ✅ | `terraform/main.tf` |
| Blue-Green Deployment | ✅ | `scripts/blue-green-deploy.sh` |
| Prometheus Monitoring | ✅ | `monitoring/prometheus.yml` |
| Grafana Dashboards | ✅ | `monitoring/docker-compose.yml` |
| ELK Stack (Logging) | ✅ | `elk/docker-compose.yml` |
| Logstash Pipeline (parse/enrich) | ✅ | `elk/logstash/pipeline/globalmart.conf` |
| Alert Rules | ✅ | `monitoring/rules/globalmart_alerts.yml` |
| E-Commerce Application | ✅ | `app/src/server.js` |
| Unit Tests | ✅ | `app/tests/server.test.js` |

---

*Built with ❤️ as a DevOps Enthusiast :))
