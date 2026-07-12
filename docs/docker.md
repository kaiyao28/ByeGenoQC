# Docker Images

Back to the [documentation index](index.md) or main [README](../README.md).

The default release image is pinned in `nextflow.config`:

```text
ghcr.io/kaiyao28/byegenoqc:1.1.0
```

For strict reproducibility, record the image tag or digest used with each run. To use a CI image built from a specific commit, pass its SHA tag:

```bash
nextflow run snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --docker_image ghcr.io/kaiyao28/byegenoqc:sha-<git-sha> \
  -profile docker
```

To test a local image:

```bash
docker build -t byegenoqc:local -f containers/Dockerfile .
GENETIC_QC_DOCKER_IMAGE=byegenoqc:local bash test_data/run_smoke_tests.sh --profile docker --test snp_array
```

The legacy image name `ghcr.io/kaiyao28/genetic-qc` is still published for compatibility, but new commands should use `ghcr.io/kaiyao28/byegenoqc`.
