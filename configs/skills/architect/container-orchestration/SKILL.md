---
name: container-orchestration
description: Docker, Kubernetes, ECS, Fly.io, Railway — when to use each
---

# Container Orchestration Decisions

## The Decision Tree

```
Do you need containers?
├── No → use serverless (Lambda, Cloud Run) or PaaS (Railway, Render, Fly.io)
└── Yes → Do you need Kubernetes specifically?
    ├── No → ECS Fargate (AWS) / Cloud Run (GCP) / Azure Container Apps
    └── Yes → Do you have K8s expertise on the team?
        ├── No → Managed K8s (EKS/GKE/AKS) + consider hiring or training first
        └── Yes → EKS / GKE / AKS, or self-hosted k3s for cost savings
```

## Platform Comparison

### PaaS / Simple Hosting (No container management)

| Platform | Best for | Pricing model |
|----------|----------|---------------|
| **Railway** | Small teams, fast deploys, monoliths | Per resource/hour |
| **Render** | Simple services, cron jobs, static sites | Per service/month |
| **Fly.io** | Edge-distributed, low-latency apps | Per VM/hour |
| **Heroku** | Legacy, easy but expensive at scale | Per dyno/month |

**When to use:** Team < 5 engineers, early product, no dedicated DevOps, speed is the priority.

### ECS Fargate (AWS)

Serverless containers — you define CPU/memory, AWS manages the hosts.

**Use ECS Fargate when:**
- You're on AWS and don't need Kubernetes
- Team is comfortable with AWS but not K8s
- You want container orchestration without cluster management
- Workloads are service-oriented (APIs, workers)

**Don't use when:**
- You need advanced scheduling (GPU nodes, spot fleets, custom schedulers)
- You need K8s-native tooling (Helm, Argo CD, KEDA)
- Multi-cloud is a requirement

**Cost note:** Fargate is ~20–30% more expensive than EC2-backed ECS for sustained workloads. EC2 Spot with ECS can be significantly cheaper for fault-tolerant workloads.

### Kubernetes (EKS / GKE / AKS / k3s)

**Use Kubernetes when:**
- Multiple teams deploying independent services
- Need advanced traffic management (Istio, Linkerd)
- GPU workloads or custom scheduling requirements
- Multi-tenant platform (internal developer platform)
- Ecosystem tooling matters (ArgoCD, Tekton, KEDA, Crossplane)

**Don't use when:**
- Team < 5 engineers with no K8s experience — the ops overhead will hurt velocity
- Simple CRUD app with predictable load — massive overkill
- Budget is tight and you can't afford a dedicated platform engineer

**Managed K8s comparison:**

| | EKS (AWS) | GKE (GCP) | AKS (Azure) |
|-|-----------|-----------|-------------|
| Control plane cost | $0.10/hr (~$73/mo) | Free (Autopilot: per pod) | Free |
| Maturity | High | Highest (K8s originated at Google) | High |
| Best ecosystem | AWS services integration | AI/ML, BigQuery | Microsoft/Azure services |
| Autopilot mode | Fargate profile | GKE Autopilot | Azure Container Apps |

### Self-Hosted Kubernetes (k3s / kubeadm)

**Use when:**
- Running on bare metal or Hetzner/OVH (significant cost savings)
- Air-gapped / on-prem environment
- Full control over the control plane is required (compliance)

**Don't use when:**
- You need enterprise SLAs on the control plane
- Team doesn't have someone who can maintain etcd, certificates, upgrades

**k3s** is the right default for self-hosted: lightweight, production-ready, single binary, great for Hetzner VMs.

## Docker: Key Decisions

### Image Size

- **Use multi-stage builds** — build in a fat image, copy artifacts to a minimal runtime image
- **Prefer distroless or Alpine base images** — reduces attack surface and pull time
- **Pin image versions** — `node:20-alpine` not `node:latest`

### Networking

- **Use Docker networks** for service-to-service communication inside Compose — don't expose unnecessary ports to the host
- **Never use `--network host`** in production unless you have a specific reason

### Volumes

- **Named volumes > bind mounts** for production data persistence
- **Bind mounts are fine for local dev** (hot reload, etc.)

## Kubernetes: Key Decisions

### When to use which resource type

| Need | Resource |
|------|----------|
| Stateless service | **Deployment** |
| Stateful app (DB, Kafka) | **StatefulSet** |
| Background worker | **Deployment** (with 0 replicas if event-driven) |
| Scheduled job | **CronJob** |
| One-off task | **Job** |
| DaemonSet (per-node agent) | **DaemonSet** |

### Resource Requests and Limits

**Always set both.** Without them:
- Scheduler can't make good placement decisions
- A runaway pod can OOM the entire node

Rule of thumb: set `requests` to typical usage, `limits` to 2–3x requests. Avoid CPU limits if possible (causes throttling even when nodes have spare capacity).

### Ingress vs Gateway API

- **Ingress** — Mature, widely supported, use for standard HTTP/HTTPS routing
- **Gateway API** — The future of K8s networking; more expressive, use if you're starting fresh and your ingress controller supports it (e.g., Cilium, Envoy Gateway)

### GitOps: ArgoCD vs Flux

| | ArgoCD | Flux |
|-|--------|------|
| UI | Rich web UI | CLI-focused |
| Multi-tenancy | Strong | Strong |
| Complexity | Higher | Lower |
| Community | Larger | Growing |

**Default to ArgoCD** if you want a UI and multi-app management. Flux if you prefer pure GitOps with minimal overhead.
