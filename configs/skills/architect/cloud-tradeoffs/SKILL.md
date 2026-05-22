---
name: cloud-tradeoffs
description: Managed vs self-hosted, multi-cloud, egress costs
---

# Cloud Architecture Tradeoffs

## Managed vs Self-Hosted

The single most common architecture decision. Apply this heuristic:

**Self-host when:**
- The managed version costs >3x self-hosted at your scale
- You have the ops expertise to run it well
- Compliance/data residency requires it
- The tool is a core competency (you build on top of it)

**Use managed when:**
- The ops burden of self-hosting would distract from product work
- The team doesn't have deep expertise in that system
- You're pre-scale and need to move fast
- The managed version has SLAs you can't match yourself

| Tool | Managed | Self-Hosted |
|------|---------|-------------|
| PostgreSQL | RDS Aurora, Supabase, Neon | EC2 + pgBackup, Railway |
| Redis | ElastiCache, Upstash | EC2, Fly.io |
| Kafka | MSK, Confluent Cloud | EC2 cluster, Redpanda |
| Elasticsearch | OpenSearch Service | EC2, Hetzner |
| Kubernetes | EKS, GKE, AKS | k3s on EC2/Hetzner |
| Object Storage | S3, GCS | MinIO |
| Auth | Cognito, Auth0, Clerk | Keycloak, Ory Hydra |

## Multi-Cloud vs Single Cloud

**Verdict: Single cloud for 95% of teams.**

Multi-cloud sounds good but the hidden costs are real:
- Egress fees when data crosses clouds ($0.08–0.12/GB)
- Each cloud has different IAM, networking, monitoring — ops complexity doubles
- You lose cloud-native integrations (e.g., Lambda → SQS → DynamoDB is much tighter than cross-cloud)
- "Avoiding vendor lock-in" is often theoretical — you're already locked into your own architecture

**When multi-cloud is legitimate:**
- Regulatory requirement to have data in specific jurisdictions
- Disaster recovery across independent failure domains
- Specific services only available on one cloud (e.g., Azure OpenAI, GCP BigQuery)

## Cloud Provider Selection

| Strength | Provider |
|----------|----------|
| Broadest service catalog, market leader | **AWS** |
| AI/ML workloads, BigQuery, GKE | **GCP** |
| Enterprise, Microsoft ecosystem, OpenAI | **Azure** |
| Simplicity, predictable pricing, small teams | **DigitalOcean / Fly.io / Railway** |
| Cost-efficient raw compute (Europe-heavy) | **Hetzner** |
| Edge compute, CDN-first | **Cloudflare Workers** |

**For most startups:** AWS or GCP. AWS if you want the most hiring pool and tooling. GCP if ML/data is core.

## Egress Cost Trap

Egress (data leaving a cloud provider) is the hidden tax of cloud:

| Provider | Egress cost (approx) |
|----------|---------------------|
| AWS | ~$0.09/GB to internet |
| GCP | ~$0.08/GB to internet |
| Azure | ~$0.087/GB to internet |
| Cloudflare R2 | **$0/GB** (zero egress) |
| Hetzner | ~€0.01/GB (very cheap) |

**Decisions affected by egress:**
- Video / media delivery → use CDN (CloudFront, Cloudflare) to avoid repeated origin egress
- Cross-region replication → quantify the egress cost before designing multi-region
- Object storage for large files → consider Cloudflare R2 if you serve assets directly

## Serverless vs Always-On

| Factor | Serverless (Lambda, Cloud Run) | Always-On (ECS, K8s) |
|--------|-------------------------------|----------------------|
| Traffic pattern | Spiky or unpredictable | Steady / predictable |
| Cold start tolerance | Yes | No |
| Max execution time | 15 min (Lambda) | Unlimited |
| Stateful workloads | No | Yes |
| Cost at low traffic | Very cheap (pay per request) | Fixed cost regardless |
| Cost at high traffic | Can exceed always-on | Cheaper per request |
| Ops burden | Very low | Higher |

**Breakeven rule of thumb:** If your Lambda functions run more than ~50% of the time, EC2/Fargate is cheaper.

## Infrastructure as Code: Tool Selection

| Tool | When to use |
|------|-------------|
| **Terraform / OpenTofu** | Multi-cloud, team already knows HCL, most common |
| **Pulumi** | Prefer real languages (TypeScript, Python, Go) over HCL |
| **AWS CDK** | AWS-only, team is TypeScript/Python native |
| **Ansible** | Configuration management, not infra provisioning |
| **Helm** | Kubernetes application packaging |
| **Crossplane** | K8s-native IaC, control plane for cloud resources |

**Default:** Terraform (OpenTofu if you want truly open-source). Switch to Pulumi if the team struggles with HCL or needs complex logic.

## Cost Optimization Patterns

1. **Right-size before you reserve.** Run on on-demand for 1–2 months, analyze actual utilization, then buy Reserved Instances / Savings Plans.
2. **Spot instances for fault-tolerant workloads.** 60–90% cheaper. Use for batch jobs, workers, CI runners — not stateful services.
3. **Auto-scaling over over-provisioning.** CPU/memory-based scaling for ECS/EC2; DynamoDB on-demand for spiky DB traffic.
4. **S3 Intelligent-Tiering for data you don't access frequently.** Automatic cost reduction, no retrieval penalties for Frequent and Infrequent tiers.
5. **Delete what you don't use.** Unattached EBS volumes, unused Elastic IPs, old snapshots, and forgotten load balancers silently accumulate cost.
