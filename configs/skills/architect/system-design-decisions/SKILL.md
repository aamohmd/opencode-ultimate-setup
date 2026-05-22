---
name: system-design-decisions
description: Scalability patterns, CAP theorem, database selection, caching
---

# System Design Decisions

## Database Selection

### The Core Question: What are your access patterns?

Define your access patterns FIRST. Every database decision flows from this.

| Pattern | Right DB type |
|---------|--------------|
| Look up by primary key, high throughput | Key-value (DynamoDB, Redis) |
| Complex queries, joins, ACID transactions | Relational (PostgreSQL, MySQL) |
| Flexible schema, document storage | Document (MongoDB, Firestore) |
| Full-text search | Search engine (Elasticsearch, Typesense, Meilisearch) |
| Time-series metrics | Time-series (InfluxDB, TimescaleDB, Prometheus) |
| Graph relationships | Graph (Neo4j, Amazon Neptune) |
| Analytics / OLAP | Columnar (ClickHouse, BigQuery, Redshift) |

**Default to PostgreSQL** unless you have a specific reason not to. It handles relational, JSON (JSONB), full-text search, and time-series adequately at most scales.

### Scaling Thresholds (rough guidelines)

- **< 10M rows, < 1K QPS** — Single Postgres instance, no drama
- **10M–100M rows, 1K–10K QPS** — Read replicas + connection pooling (PgBouncer)
- **> 100M rows or > 10K QPS** — Partitioning, sharding strategy, or move to DynamoDB/Cassandra for hot paths
- **> 1TB of data for analytics** — Move OLAP queries to columnar store (ClickHouse/BigQuery)

## CAP Theorem in Practice

In real systems, the choice is usually **CP vs AP**, not about ignoring partition tolerance:

- **CP (Consistency + Partition Tolerance):** PostgreSQL, HBase, ZooKeeper. Choose when wrong data is worse than no data (banking, inventory).
- **AP (Availability + Partition Tolerance):** DynamoDB, Cassandra, CouchDB. Choose when availability matters more than perfect consistency (social feeds, analytics, shopping carts).

**Eventual consistency is fine** for most read-heavy features. Use strong consistency only where the business actually requires it.

## Caching Strategy

### When to cache

- Read-to-write ratio > 10:1
- Computation is expensive and result is reusable
- External API calls that are rate-limited or slow

### Cache levels

1. **CDN (CloudFront, Cloudflare)** — Static assets, public API responses
2. **Application-level (in-memory)** — Per-instance cache for small hot datasets
3. **Distributed cache (Redis, Memcached)** — Shared across instances, session data, rate limiting
4. **DB query cache** — Use sparingly; invalidation is hard

### Cache invalidation patterns

- **TTL-based** — Simple, good default for data that changes predictably
- **Write-through** — Update cache on every write; keeps cache fresh but adds write latency
- **Cache-aside (lazy loading)** — Only populate on cache miss; simplest pattern
- **Event-driven invalidation** — Invalidate on domain events; complex but precise

## Scalability Patterns

### Horizontal vs Vertical Scaling

- **Vertical (scale up):** Simple, no code changes, hits a ceiling, single point of failure. Good for databases.
- **Horizontal (scale out):** No ceiling, requires stateless services or distributed state, more complex. Required beyond a point.

**Design services to be stateless from day 1.** Move state to Redis/DB. This makes horizontal scaling trivial later.

### Load Balancing

- **Round-robin** — Good default for stateless services
- **Least connections** — Better for variable-latency backends
- **Sticky sessions** — Avoid if possible; breaks horizontal scaling. Use Redis for shared session state instead.

### Async vs Sync

| Use sync when | Use async (queues) when |
|--------------|------------------------|
| Response needed immediately | Response can be delivered later |
| Operation is fast (< 1s) | Operation is slow (email, ML inference, video processing) |
| Strong consistency required | Eventual consistency is acceptable |

**Queue everything that doesn't need an immediate response.** This decouples services and absorbs load spikes.

## Microservices vs Monolith

### Start with a Monolith if:
- Team < 10 engineers
- Domain boundaries aren't clear yet
- Startup / early product (speed > scalability)
- No demonstrated scaling bottleneck

### Move to Microservices when:
- Different parts of the system need different scaling profiles
- Teams are large enough to own independent services (2-pizza rule)
- Deploy independence is blocking velocity
- A clear bounded context has emerged from the monolith

**Modular Monolith first** — keep modules decoupled inside one deployment. Extract to services only when you have a concrete reason.

## API Design Decisions

| Need | Approach |
|------|----------|
| Standard CRUD / REST | REST + OpenAPI spec |
| Complex queries / flexible client needs | GraphQL |
| Real-time, bidirectional | WebSockets or SSE |
| High-throughput internal services | gRPC |
| Event-driven between services | AsyncAPI + message broker |

**REST is the right default.** GraphQL has real value for product APIs with many consumers. gRPC shines for internal service-to-service calls.
