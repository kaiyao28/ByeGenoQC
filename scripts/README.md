# Helper Scripts

These scripts support setup, environment checks, and release packaging. They are not Nextflow workflow entry points.

| Script | Purpose |
|--------|---------|
| `setup.sh` | Local setup helper for common workstation dependencies. |
| `setup_hpc_manual.sh` | Manual HPC tool setup when Docker or Singularity/Apptainer is not available. |
| `test_env.sh` | Environment check script for Docker, Singularity, and manually installed tools. |
| `create_release.sh` | Release helper for publishing GitHub release notes. |

Run scripts from the repository root, for example:

```bash
bash scripts/test_env.sh docker
```
