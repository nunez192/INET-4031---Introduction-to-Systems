# Cybersecurity & Governance — QA Report

## Test Information
- Environment: Local Ubuntu VM (individual project)
- Test author: Shanna
- Test executor: Shanna
- Status: Draft — Week 11

## QA Test Cases

### QA-01: Trivy Container Vulnerability Scan
- Purpose: Identify vulnerabilities in the Flask container image.
- Test: Run Trivy against the web application image.
- Expected result: Trivy produces a report listing vulnerabilities by severity.
- Current result: Completed. Initial image had 48 HIGH and 0 CRITICAL findings.
- Evidence: capstone/cybersecurity-governance/evidence/trivy-image-before.txt

### QA-02: Gitleaks Repository Scan
- Purpose: Identify possible secrets committed to Git history.
- Test: Run Gitleaks against the repository and its history.
- Expected result: Gitleaks produces a report identifying possible exposed secrets.
- Current result: Completed. One possible secret detected; review is required.
- Evidence: capstone/cybersecurity-governance/evidence/gitleaks-report.json

### QA-03: Checkov Infrastructure Scan
- Purpose: Identify security misconfigurations in Terraform/OpenTofu files.
- Test: Scan week-5 infrastructure configuration files.
- Expected result: Checkov produces a report with passed and failed checks.
- Current result: Completed. 65 passed and 24 failed.
- Evidence: capstone/cybersecurity-governance/evidence/checkov-initial.txt

### QA-04: kube-score Kubernetes Manifest Scan
- Purpose: Identify unsafe Kubernetes deployment settings.
- Test: Scan the web and database deployment manifests.
- Expected result: kube-score produces configuration recommendations.
- Current result: Completed. Database deployment has multiple critical findings.
- Evidence: capstone/cybersecurity-governance/evidence/kube-score-initial.txt

### QA-05: Kubernetes RBAC Permissions
- Purpose: Verify that service accounts have only necessary permissions.
- Test: Use kubectl auth can-i to test permitted and denied operations.
- Expected result: Unauthorized actions are denied.
- Current result: Not tested — planned for Week 12.
- Evidence: Pending.

### QA-06: Kubernetes NetworkPolicy Restrictions
- Purpose: Verify that unauthorized pods cannot access the database.
- Test: Attempt database connections from allowed and disallowed pods.
- Expected result: Allowed traffic succeeds and unauthorized traffic is blocked.
- Current result: Not tested — planned for Week 12.
- Evidence: Pending.

## Week 11 Summary

Initial security scanning is complete. Findings include container vulnerabilities,
a possible secret in Git history, Terraform configuration failures, and Kubernetes
configuration warnings. RBAC and NetworkPolicy tests are planned for Week 12.

## Individual QA Sign-Off
- Author: Shanna
- Tester: Shanna
- Final verification: Pending
