---
name: aws-architecture-patterns
description: AWS service selection, well-architected lens, cost patterns
---

# AWS Architecture Patterns

## Service Selection Heuristics

### Compute

| Need | Service | Avoid if |
|------|---------|----------|
| Stateless API / microservice | **Lambda** (if <15min) or **ECS Fargate** | Cold starts are unacceptable (Lambda) |
| Long-running / stateful workload | **ECS Fargate** or **EC2 Auto Scaling** | You don't want to manage infra (EC2) |
| Kubernetes required | **EKS** | Team has no K8s experience |
| Batch / data processing | **AWS Batch** or **Lambda + SQS** | |
| Background jobs, workers | **ECS + SQS** | |
| Simple scheduled tasks | **EventBridge + Lambda** | |

**Rule of thumb:** Lambda first → ECS Fargate if Lambda won't fit → EKS only if K8s is a hard requirement.

### Database

| Need | Service | Notes |
|------|---------|-------|
| Relational, OLTP | **RDS Aurora PostgreSQL** | Serverless v2 for variable load |
| Key-value, low latency | **DynamoDB** | Requires careful access pattern design upfront |
| Cache / session | **ElastiCache (Redis)** | |
| Full-text search | **OpenSearch** | Expensive to run; consider Typesense on EC2 |
| Time-series | **Timestream** or **InfluxDB on EC2** | |
| Data warehouse / analytics | **Redshift** or **Athena** (if data is in S3) | |
| Graph | **Neptune** | Niche; only if graph traversal is core |

**Aurora Serverless v2** is often the right default for new relational workloads — scales to zero on dev, handles spiky production traffic.

### Messaging & Queues

| Pattern | Service |
|---------|---------|
| Task queue, background jobs | **SQS** (Standard or FIFO) |
| Fan-out / pub-sub | **SNS → SQS** |
| Real-time event streaming | **Kinesis Data Streams** or **MSK (Kafka)** |
| Event bus between services | **EventBridge** |
| Websockets / real-time push | **API Gateway WebSocket** or **AppSync Subscriptions** |

### Storage

| Need | Service |
|------|---------|
| Object / blob storage | **S3** |
| CDN / static assets | **CloudFront + S3** |
| Shared filesystem (ECS, EC2) | **EFS** |
| Block storage (EC2) | **EBS gp3** |

## Cost Patterns

- **Egress is the hidden cost.** Data leaving AWS (to internet or cross-region) costs ~$0.09/GB. Design to minimize cross-region calls.
- **NAT Gateway** is expensive at scale (~$0.045/GB processed). Consider VPC endpoints for S3/DynamoDB to avoid it.
- **RDS** always has at least one standby in Multi-AZ — account for 2x instance costs in production.
- **CloudWatch Logs** ingestion costs accumulate fast. Set retention policies and filter before sending to Logs.
- **Data Transfer Accelerator / Global Accelerator** only worth it for latency-sensitive global apps.

## Well-Architected Lens Quick Checks

Before finalizing an AWS architecture, ask:

1. **Reliability:** Is there a Multi-AZ deployment? What's the RTO/RPO?
2. **Security:** Are all S3 buckets private by default? Is IAM following least privilege? Is data encrypted at rest and in transit?
3. **Performance:** Are you in the right region for your users? Is caching in place for repeated reads?
4. **Cost:** Are dev/staging environments using auto-shutdown or Serverless? Are Reserved Instances / Savings Plans applied to stable workloads?
5. **Operational Excellence:** Is there centralized logging (CloudWatch / OpenSearch)? Are alerts configured on error rates and latency P99?
6. **Sustainability:** Are idle resources (dev DBs, unused EC2s) scheduled to stop outside business hours?

## Common Anti-patterns

- **Lambda for everything** — Websockets, large file processing, and CPU-heavy tasks are poor fits.
- **RDS for high-throughput key-value** — Use DynamoDB or ElastiCache instead.
- **Single-AZ in production** — Never. Even for non-critical apps, the cost delta is small.
- **Hardcoded credentials** — Always use IAM roles + Secrets Manager.
- **Skipping VPC** — Even serverless workloads that need RDS access need VPC configuration.
