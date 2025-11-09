# Operations Guide
## Day-to-Day Operations and Runbooks

This guide provides operational procedures, incident response runbooks, and maintenance procedures for the cloud-native architecture template.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Day-to-Day Operations](#2-day-to-day-operations)
3. [Monitoring and Alerting](#3-monitoring-and-alerting)
4. [Incident Response](#4-incident-response)
5. [Maintenance Procedures](#5-maintenance-procedures)
6. [Health Checks](#6-health-checks)
7. [Log Management](#7-log-management)
8. [Performance Monitoring](#8-performance-monitoring)
9. [Backup and Recovery](#9-backup-and-recovery)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Overview

### Purpose
This operations guide provides procedures for:
- Day-to-day operations and monitoring
- Incident response and resolution
- Maintenance and updates
- Health monitoring and alerting
- Backup and recovery procedures

### Audience
- DevOps engineers
- Site reliability engineers (SRE)
- Operations team members
- On-call engineers

### Key Resources
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture overview
- [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Implementation details
- [GLOSSARY.md](./GLOSSARY.md) - Technical terms and acronyms

---

## 2. Day-to-Day Operations

### 2.1 Daily Checks

**Morning Routine (9:00 AM)**
1. Review overnight alerts and incidents
2. Check system health dashboards
3. Review application performance metrics
4. Check database performance and storage
5. Review CI/CD pipeline status
6. Check security alerts

**Commands:**
```bash
# Check AKS cluster status
az aks show --resource-group rg-your-project --name aks-your-project --query "powerState.code" -o tsv

# Check pod status
kubectl get pods --all-namespaces

# Check node status
kubectl get nodes

# Check service health
kubectl get svc --all-namespaces
```

### 2.2 Weekly Operations

**Weekly Tasks (Every Monday)**
1. Review weekly performance reports
2. Check resource utilization trends
3. Review cost optimization opportunities
4. Update documentation if needed
5. Review security patches and updates
6. Plan maintenance windows

### 2.3 Monthly Operations

**Monthly Tasks (First Monday of Month)**
1. Review monthly performance reports
2. Conduct capacity planning review
3. Review and update disaster recovery procedures
4. Review security compliance status
5. Update runbooks based on incidents
6. Review and optimize costs

---

## 3. Monitoring and Alerting

### 3.1 Monitoring Tools

**Azure Monitor**
- Infrastructure metrics
- Application metrics
- Log aggregation
- Alert management

**Application Insights**
- Application performance monitoring (APM)
- Distributed tracing
- Exception tracking
- User analytics

**Kubernetes Dashboard**
- Pod status and health
- Resource utilization
- Node status
- Service endpoints

### 3.2 Key Metrics to Monitor

**Infrastructure Metrics**
- CPU utilization
- Memory utilization
- Disk I/O
- Network traffic
- Pod restart count
- Node availability

**Application Metrics**
- Request rate
- Response time (p50, p95, p99)
- Error rate
- Availability
- Throughput
- Database query performance

**Business Metrics**
- API usage
- User activity
- Transaction volume
- Business KPI

### 3.3 Alerting Rules

**Critical Alerts (Immediate Response)**
- Service unavailable (availability < 99%)
- High error rate (> 5%)
- Database connection failures
- Storage capacity > 90%
- Pod crash loops
- Security breaches

**Warning Alerts (Monitor Closely)**
- High response time (p95 > 1s)
- Increased error rate (2-5%)
- Resource utilization > 80%
- Disk space > 80%
- Slow database queries

**Info Alerts (Review)**
- Deployment completions
- Scaling events
- Backup completions
- Certificate expirations (30 days)

### 3.4 Setting Up Alerts

**Azure Monitor Alerts**
```bash
# Create metric alert
az monitor metrics alert create \
  --name "High CPU Usage" \
  --resource-group rg-your-project \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/Microsoft.ContainerService/managedClusters/aks-your-project \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/microsoft.insights/actionGroups/oncall-team
```

**Application Insights Alerts**
```bash
# Create availability alert
az monitor metrics alert create \
  --name "Service Unavailable" \
  --resource-group rg-your-project \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/microsoft.insights/components/app-insights-your-project \
  --condition "avg availabilityResults/availabilityPercentage < 99" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### 3.5 Dashboard Configuration

**Recommended Dashboards**
1. **Infrastructure Dashboard**
   - Cluster health
   - Node status
   - Resource utilization
   - Pod status

2. **Application Dashboard**
   - Request rate
   - Response time
   - Error rate
   - Availability

3. **Database Dashboard**
   - Connection count
   - Query performance
   - Storage usage
   - Replication lag

4. **Security Dashboard**
   - Failed authentication attempts
   - Security alerts
   - Certificate expiration
   - Access logs

---

## 4. Incident Response

### 4.1 Incident Severity Levels

**Severity 1 (Critical) - Immediate Response**
- Complete service outage
- Data breach or security incident
- Data loss
- Payment processing failure
- Response Time: < 15 minutes

**Severity 2 (High) - Urgent Response**
- Partial service degradation
- High error rate
- Performance degradation
- Database issues
- Response Time: < 1 hour

**Severity 3 (Medium) - Standard Response**
- Minor performance issues
- Non-critical feature failures
- Monitoring gaps
- Response Time: < 4 hours

**Severity 4 (Low) - Scheduled Response**
- Documentation issues
- Minor bugs
- Enhancement requests
- Response Time: < 24 hours

### 4.2 Incident Response Process

**1. Detection**
- Monitor alerts and dashboards
- User reports
- Automated monitoring
- Security alerts

**2. Triage**
- Assess severity
- Identify affected services
- Gather initial information
- Assign incident owner

**3. Investigation**
- Review logs and metrics
- Check recent deployments
- Identify root cause
- Document findings

**4. Resolution**
- Implement fix
- Verify resolution
- Monitor for stability
- Communicate status

**5. Post-Incident**
- Conduct post-mortem
- Update runbooks
- Implement preventive measures
- Document lessons learned

### 4.3 Common Incident Runbooks

#### Runbook 1: Service Unavailable

**Symptoms:**
- HTTP 503 errors
- Service health checks failing
- High error rate

**Investigation Steps:**
```bash
# Check pod status
kubectl get pods -n production

# Check service status
kubectl get svc -n production

# Check ingress status
kubectl get ingress -n production

# Check pod logs
kubectl logs -f deployment/example-service -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'
```

**Resolution Steps:**
1. Check if pods are running
2. Check if service is healthy
3. Check if ingress is configured correctly
4. Check if database is accessible
5. Check if dependencies are available
6. Scale up if needed
7. Restart pods if needed

#### Runbook 2: High Error Rate

**Symptoms:**
- Error rate > 5%
- Increased 4xx/5xx responses
- User complaints

**Investigation Steps:**
```bash
# Check error logs
kubectl logs -f deployment/example-service -n production | grep -i error

# Check Application Insights
# Navigate to Azure Portal → Application Insights → Failures

# Check database connections
az postgres flexible-server show --resource-group rg-your-project --name psql-your-project

# Check service dependencies
kubectl get endpoints -n production
```

**Resolution Steps:**
1. Identify error patterns
2. Check recent deployments
3. Check database connectivity
4. Check external service dependencies
5. Check configuration changes
6. Rollback if needed
7. Scale resources if needed

#### Runbook 3: Database Issues

**Symptoms:**
- Database connection failures
- Slow queries
- High connection count
- Storage full

**Investigation Steps:**
```bash
# Check database status
az postgres flexible-server show --resource-group rg-your-project --name psql-your-project

# Check database metrics
az monitor metrics list --resource /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-your-project

# Check connection count
# Connect to database and run:
SELECT count(*) FROM pg_stat_activity;

# Check slow queries
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;
```

**Resolution Steps:**
1. Check database health
2. Check connection pool settings
3. Check for long-running queries
4. Scale database if needed
5. Kill blocking queries if needed
6. Increase connection limit if needed

#### Runbook 4: High Resource Utilization

**Symptoms:**
- CPU > 80%
- Memory > 80%
- Disk > 80%
- Pod evictions

**Investigation Steps:**
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n production

# Check HPA status
kubectl get hpa -n production

# Check cluster autoscaler
kubectl get nodes
```

**Resolution Steps:**
1. Check resource requests and limits
2. Scale up pods if needed
3. Scale up cluster if needed
4. Optimize resource usage
5. Check for memory leaks
6. Check for CPU-intensive processes

#### Runbook 5: Security Incident

**Symptoms:**
- Failed authentication attempts
- Unauthorized access attempts
- Security alerts
- Suspicious activity

**Investigation Steps:**
```bash
# Check security alerts
az security alert list --resource-group rg-your-project

# Check audit logs
az monitor activity-log list --resource-group rg-your-project

# Check Key Vault access logs
az keyvault show --name kv-your-project --resource-group rg-your-project

# Check AKS audit logs
az aks show --resource-group rg-your-project --name aks-your-project
```

**Resolution Steps:**
1. Assess severity
2. Isolate affected resources
3. Revoke compromised credentials
4. Update security policies
5. Notify security team
6. Document incident
7. Implement preventive measures

---

## 5. Maintenance Procedures

### 5.1 Regular Maintenance

**Weekly Maintenance**
- Review and apply security patches
- Update dependencies
- Clean up old logs
- Review and optimize costs
- Update documentation

**Monthly Maintenance**
- Apply OS updates
- Update Kubernetes version
- Update Azure service versions
- Review and update certificates
- Conduct disaster recovery testing

**Quarterly Maintenance**
- Review and update architecture
- Conduct security audit
- Review and update runbooks
- Plan capacity upgrades
- Review and update compliance

### 5.2 Deployment Maintenance

**Pre-Deployment Checklist**
- [ ] Review change request
- [ ] Test in staging environment
- [ ] Review rollback plan
- [ ] Notify stakeholders
- [ ] Schedule maintenance window if needed
- [ ] Backup database
- [ ] Review monitoring setup

**Post-Deployment Checklist**
- [ ] Verify deployment success
- [ ] Check health endpoints
- [ ] Monitor metrics for 30 minutes
- [ ] Verify functionality
- [ ] Update documentation
- [ ] Communicate completion

### 5.3 Database Maintenance

**Weekly Tasks**
- Run VACUUM ANALYZE
- Check database size
- Review slow queries
- Check connection count
- Review backup status

**Monthly Tasks**
- Review and optimize indexes
- Check for table bloat
- Review replication lag
- Update statistics
- Review security patches

**Commands:**
```bash
# Connect to database
az postgres flexible-server connect --name psql-your-project --resource-group rg-your-project

# Run VACUUM ANALYZE
VACUUM ANALYZE;

# Check database size
SELECT pg_size_pretty(pg_database_size('your_database'));

# Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 5.4 Certificate Management

**Certificate Rotation**
1. Generate new certificate
2. Update in Azure Key Vault
3. Update application configuration
4. Restart services
5. Verify certificate
6. Delete old certificate

**Certificate Expiration Monitoring**
- Set up alerts for 30 days before expiration
- Set up alerts for 7 days before expiration
- Automate certificate renewal if possible

**Commands:**
```bash
# Check certificate expiration
az keyvault certificate show --vault-name kv-your-project --name your-certificate --query "attributes.expires" -o tsv

# List certificates
az keyvault certificate list --vault-name kv-your-project
```

---

## 6. Health Checks

### 6.1 Application Health Checks

**Liveness Probe**
- Checks if application is running
- Failure results in pod restart
- Usually checks a simple endpoint

**Readiness Probe**
- Checks if application is ready to serve traffic
- Failure results in removal from service
- Usually checks dependencies

**Startup Probe**
- Checks if application has started
- Useful for slow-starting applications
- Prevents premature liveness failures

**Example Configuration:**
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

startupProbe:
  httpGet:
    path: /actuator/health/startup
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 30
```

### 6.2 Infrastructure Health Checks

**Cluster Health**
```bash
# Check cluster status
az aks show --resource-group rg-your-project --name aks-your-project --query "powerState.code" -o tsv

# Check node status
kubectl get nodes

# Check node conditions
kubectl describe node <node-name>
```

**Service Health**
```bash
# Check service endpoints
kubectl get endpoints -n production

# Check service status
kubectl get svc -n production

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://example-service:8080/actuator/health
```

### 6.3 Database Health Checks

**Connection Health**
```bash
# Check database connectivity
az postgres flexible-server show --resource-group rg-your-project --name psql-your-project

# Test database connection
psql -h psql-your-project.postgres.database.azure.com -U admin -d postgres -c "SELECT 1;"
```

**Performance Health**
```sql
-- Check connection count
SELECT count(*) FROM pg_stat_activity;

-- Check slow queries
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;

-- Check database size
SELECT pg_size_pretty(pg_database_size('your_database'));

-- Check table bloat
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## 7. Log Management

### 7.1 Log Collection

**Application Logs**
- Collected via Application Insights
- Sent to Log Analytics workspace
- Retained for 90 days (configurable)

**Infrastructure Logs**
- Collected via Azure Monitor
- Sent to Log Analytics workspace
- Retained for 90 days (configurable)

**Kubernetes Logs**
- Collected via Container Insights
- Sent to Log Analytics workspace
- Retained for 30 days (configurable)

### 7.2 Log Analysis

**Querying Logs**
```kusto
// Application Insights query
requests
| where timestamp > ago(1h)
| summarize count() by bin(timestamp, 5m), resultCode
| render timechart

// Log Analytics query
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error"
| project TimeGenerated, LogEntry, PodName
| order by TimeGenerated desc
```

### 7.3 Log Retention

**Retention Policies**
- Application logs: 90 days
- Infrastructure logs: 90 days
- Kubernetes logs: 30 days
- Audit logs: 1 year
- Security logs: 1 year

**Cost Optimization**
- Archive old logs to Azure Blob Storage
- Use log filtering to reduce volume
- Set up log retention policies
- Monitor log ingestion costs

---

## 8. Performance Monitoring

### 8.1 Key Performance Indicators (KPIs)

**Application KPIs**
- Response time (p50, p95, p99)
- Throughput (requests per second)
- Error rate
- Availability (uptime %)

**Infrastructure KPIs**
- CPU utilization
- Memory utilization
- Network throughput
- Disk I/O

**Database KPIs**
- Query performance
- Connection count
- Storage usage
- Replication lag

### 8.2 Performance Baselines

**Establish Baselines**
- Measure during normal operation
- Document peak and average values
- Set alert thresholds
- Review and update regularly

**Performance Targets**
- API response time: < 200ms (p95)
- Frontend load time: < 2s
- Database query time: < 100ms (p95)
- Availability: 99.9%

### 8.3 Performance Optimization

**Application Optimization**
- Optimize database queries
- Implement caching
- Use CDN for static assets
- Optimize API responses
- Implement pagination

**Infrastructure Optimization**
- Right-size resources
- Implement autoscaling
- Use read replicas
- Optimize network configuration
- Use premium storage for databases

---

## 9. Backup and Recovery

### 9.1 Backup Procedures

**Database Backups**
- Automated daily backups
- Point-in-time recovery (PITR)
- Geo-redundant backups
- Retention: 35 days

**Configuration Backups**
- Infrastructure as Code (Git)
- Kubernetes manifests (Git)
- Helm charts (Git)
- Configuration files (Git)

**Application Backups**
- Container images (ACR)
- Application code (Git)
- Configuration (Git)
- Secrets (Key Vault)

### 9.2 Recovery Procedures

**Database Recovery**
```bash
# Restore from backup
az postgres flexible-server restore \
  --resource-group rg-your-project \
  --name psql-your-project-restored \
  --source-server psql-your-project \
  --restore-time 2024-01-15T10:30:00Z
```

**Application Recovery**
- Redeploy from Git
- Restore from container registry
- Restore configuration from Git
- Restore secrets from Key Vault

**Infrastructure Recovery**
- Redeploy from Infrastructure as Code
- Restore from backup
- Restore configuration
- Verify connectivity

### 9.3 Disaster Recovery Testing

**Quarterly DR Tests**
- Test database restore
- Test application redeployment
- Test infrastructure recovery
- Document results
- Update procedures

---

## 10. Troubleshooting

### 10.1 Common Issues

**Issue: Pods Not Starting**
- Check resource requests/limits
- Check image availability
- Check configuration
- Check dependencies
- Check events

**Issue: Service Not Accessible**
- Check service configuration
- Check ingress configuration
- Check network policies
- Check firewall rules
- Check DNS resolution

**Issue: High Latency**
- Check database performance
- Check network latency
- Check resource utilization
- Check external dependencies
- Check caching

**Issue: Memory Leaks**
- Check application logs
- Check memory usage trends
- Check for memory leaks in code
- Check garbage collection
- Check resource limits

### 10.2 Diagnostic Commands

**Kubernetes Diagnostics**
```bash
# Describe pod
kubectl describe pod <pod-name> -n production

# Check pod logs
kubectl logs <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pod <pod-name> -n production

# Check service endpoints
kubectl get endpoints <service-name> -n production
```

**Azure Diagnostics**
```bash
# Check resource health
az resource show --id /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/Microsoft.ContainerService/managedClusters/aks-your-project

# Check metrics
az monitor metrics list --resource /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/Microsoft.ContainerService/managedClusters/aks-your-project

# Check logs
az monitor log-analytics query --workspace <workspace-id> --analytics-query "ContainerLog | where TimeGenerated > ago(1h)"
```

---

## Related Documents

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture overview
- [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Implementation details
- [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Testing guidelines
- [GLOSSARY.md](./GLOSSARY.md) - Technical terms

---

**Last Updated**: November 9, 2025

