# Privacy and Publishing

This repository is intentionally separated from the internal experiment archive.

Included:

- Public model and software version pins
- Parameterized Kubernetes templates
- Shape-only workload data
- Aggregate performance results
- Portable automation and analysis code

Excluded:

- Cluster, subscription, namespace, and user-specific identifiers
- Node, pod, Deployment, and DGD UIDs
- Private service addresses and IPs
- Local filesystem paths
- Secret names from the reference cluster and all secret values
- Raw HTTP headers, request IDs, pod logs, and operational transcripts

Before publishing:

```bash
./scripts/validate-repository.sh
git status --short
git grep -nE 'REPLACE_ME|HF_TOKEN=' -- ':!config/experiment.env.example' ':!docs/reproduction.md'
```

The validator checks for known reference-environment identifiers and common secret patterns. It does not replace human review of newly added artifacts.
