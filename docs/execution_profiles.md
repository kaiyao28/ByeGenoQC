# Execution Profiles

Back to the [documentation index](index.md) or main [README](../README.md).

| Profile | When to use |
|---------|-------------|
| `docker` | Laptop or workstation with Docker Desktop |
| `slurm,singularity` | HPC cluster with SLURM + Apptainer/Singularity |
| `lsf,singularity` | HPC cluster with LSF + Apptainer/Singularity |
| `slurm,manual_paths` | HPC with no container engine; tools installed manually |

On HPC, always pair the scheduler profile (`slurm`, `lsf`) with the container profile (`singularity`). `-profile singularity` alone runs on the login node. Use absolute paths for `--bfile` and `--outdir` on clusters; relative paths can fail silently on compute nodes.

If no container engine is available, run `bash scripts/setup_hpc_manual.sh` first to download all tools. See the [Setup Guide](setup.md) for full cluster instructions.
