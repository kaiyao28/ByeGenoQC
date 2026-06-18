---
name: Bug report
about: Report a bug or unexpected behavior
title: '[BUG] Brief description'
labels: bug
assignees: ''

---

## Description

A clear and concise description of the bug. What did you expect to happen, and what actually happened?

## Steps to Reproduce

Minimal steps to reproduce the issue:

1. ...
2. ...
3. ...

## Environment

- **OS:** (e.g., macOS 13, Ubuntu 22.04, Windows 11 with WSL)
- **Java version:** (output of `java -version`)
- **Nextflow version:** (output of `nextflow -version`)
- **Docker version:** (output of `docker --version`, or N/A if using Singularity)
- **Container engine:** (Docker / Singularity / Apptainer / None)
- **Pipeline version/commit:** (main branch or specific commit SHA)

## Input Data Summary

- **Pipeline:** (snp_array_qc or wgs_wes_qc)
- **Input file type:** (PLINK binary / VCF / BAM / CRAM / FASTQ)
- **Number of samples:** 
- **Number of variants/genomic positions:**
- **Approximate file size:**

## Actual Error Output

If the pipeline failed, please paste the error message and the relevant section of `.nextflow.log`:

```
[paste error message and log here]
```

## Nextflow Log

Please attach or paste the `.nextflow.log` file (truncate if very large):

```
[paste .nextflow.log here]
```

## Expected Behavior

What should happen instead?

## Additional Context

Any other context or screenshots that might help diagnose the issue?
