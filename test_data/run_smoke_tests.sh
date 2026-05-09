#!/usr/bin/env bash
# =============================================================================
#  run_smoke_tests.sh — run both workflows on small toy data
# =============================================================================
#  Usage:
#    bash test_data/run_smoke_tests.sh                     # Docker (default)
#    bash test_data/run_smoke_tests.sh --profile manual_paths
#    bash test_data/run_smoke_tests.sh --profile slurm,manual_paths
#    bash test_data/run_smoke_tests.sh --profile singularity
#
#  Environment overrides:
#    GENETIC_QC_DOCKER_IMAGE=my-image:tag   # use a local Docker image
#    GENETIC_QC_FORCE_PULL=true             # force re-pull of Docker image
# =============================================================================
set -euo pipefail

IMAGE="${GENETIC_QC_DOCKER_IMAGE:-ghcr.io/kaiyao28/genetic-qc:1.0}"
FORCE_PULL="${GENETIC_QC_FORCE_PULL:-false}"
PROFILE="docker"
TEST=""   # empty = run both; "snp_array" or "wgs_wes" = run one

# ── Parse arguments ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --test)    TEST="$2";    shift 2 ;;
        *) echo "Unknown argument: $1"
           echo "Usage: bash run_smoke_tests.sh [--profile PROFILE] [--test snp_array|snp_full|wgs_wes]"
           exit 1 ;;
    esac
done

echo "Genetic QC smoke tests"
echo "Profile : ${PROFILE}"
echo "Running : ${TEST:-snp_array + snp_full + wgs_wes}"
if [[ "$PROFILE" == *"docker"* ]]; then
    echo "Image   : ${IMAGE}"
fi
echo

if [ ! -f "nextflow.config" ]; then
    echo "ERROR: run this script from the repository root:"
    echo "  bash test_data/run_smoke_tests.sh"
    exit 1
fi

# ── Nextflow check ─────────────────────────────────────────────────────────────
if ! command -v nextflow >/dev/null 2>&1; then
    echo "ERROR: nextflow is not available on PATH."
    echo "Run setup_hpc_manual.sh first, then add \$TOOL_DIR/bin to PATH."
    exit 1
fi

# ── Docker-specific checks ────────────────────────────────────────────────────
if [[ "$PROFILE" == *"docker"* ]]; then
    if ! command -v docker >/dev/null 2>&1; then
        echo "ERROR: docker is not available on PATH."
        echo "For HPC without Docker, run with:  --profile manual_paths"
        exit 1
    fi

    echo "Docker storage summary:"
    docker system df || true
    echo

    print_docker_recovery_help() {
        cat << EOF

Docker could not pull/extract the image.

This is usually a Docker Desktop / WSL storage problem, not a pipeline problem.
Common causes are:
  - Docker Desktop virtual disk is full
  - a previous failed pull left a partial/broken image layer
  - Docker Desktop needs a restart

Try these steps, then re-run:

  docker image rm ${IMAGE}
  docker builder prune
  docker system prune

If Docker still reports input/output error, restart Docker Desktop.
If it still fails after restart, open Docker Desktop:

  Settings -> Resources -> Advanced -> increase disk image size

or:

  Troubleshoot -> Clean / Purge data

Warning: Docker Desktop purge removes local Docker images and containers, but
not your Git repository files.
EOF
    }

    echo "Checking Docker image..."
    if docker image inspect "${IMAGE}" >/dev/null 2>&1 && [ "${FORCE_PULL}" != "true" ]; then
        echo "Image already exists locally; skipping docker pull."
        echo "Set GENETIC_QC_FORCE_PULL=true to force a fresh pull."
    else
        if ! docker pull "${IMAGE}"; then
            print_docker_recovery_help
            exit 1
        fi
    fi
    echo
fi

# ── Verify SNP-array PLINK binary test data ────────────────────────────────────
# Pre-generated files are committed to the repository — no conversion needed.
# To regenerate: python3 test_data/generate_test_data.py
echo "Checking SNP-array PLINK binary test data..."
for f in test_data/snp_array/toy.bed test_data/snp_array/toy.bim test_data/snp_array/toy.fam; do
    if [ ! -f "$f" ]; then
        echo "ERROR: missing $f"
        echo "Regenerate with:  python3 test_data/generate_test_data.py"
        exit 1
    fi
done
echo "SNP-array binary files present."
echo

# ── WGS/WES VCF smoke test ────────────────────────────────────────────────────
if [[ -z "$TEST" || "$TEST" == "wgs_wes" ]]; then
    echo "Running WGS/WES VCF variant-only smoke test..."
    nextflow run wgs_wes_qc/main.nf \
      --input_type vcf \
      --samplesheet test_data/wgs_wes/samplesheet_vcf.csv \
      --reference_fasta test_data/reference/mini.fa \
      --mode wgs \
      --chroms 22 \
      --run_variant_qc true \
      --run_variant_filtering false \
      --run_sample_qc false \
      --run_final_report true \
      --outdir results/test_vcf_variant_only \
      --docker_image "${IMAGE}" \
      -profile "${PROFILE}" \
      -ansi-log false \
      -with-dag assets/wgs_dag.png \
      -resume
    echo
fi

# ── SNP-array variant-only smoke test ────────────────────────────────────────
if [[ -z "$TEST" || "$TEST" == "snp_array" ]]; then
    echo "Running SNP-array variant-only smoke test..."
    nextflow run snp_array_qc/main.nf \
      --bfile test_data/snp_array/toy \
      --run_variant_qc true \
      --run_sample_qc false \
      --run_final_report true \
      --outdir results/test_snp_variant_only \
      --docker_image "${IMAGE}" \
      -profile "${PROFILE}" \
      -ansi-log false \
      -with-dag assets/snp_array_dag.png \
      -resume
    echo
fi

# ── SNP-array full QC smoke test (sample + variant QC) ───────────────────────
# Tests all sample-level modules: callrate, sex check, heterozygosity,
# relatedness, and ancestry PCA — each module has a designed QC trigger in
# the toy data (S01=missingness, S02/S03=related, S07=het outlier,
# S09=sex discordant).
# n_pcs=5 and n_pcs_covariates=5 avoid PLINK PCA warnings with 15 samples.
if [[ -z "$TEST" || "$TEST" == "snp_full" ]]; then
    echo "Running SNP-array full QC smoke test (sample + variant)..."
    nextflow run snp_array_qc/main.nf \
      --bfile test_data/snp_array/toy \
      --run_variant_qc true \
      --run_sample_qc true \
      --run_final_report true \
      --n_pcs 5 \
      --n_pcs_covariates 5 \
      --outdir results/test_snp_full \
      --docker_image "${IMAGE}" \
      -profile "${PROFILE}" \
      -ansi-log false \
      -resume
    echo
fi

echo "Smoke tests finished."
[[ -z "$TEST" || "$TEST" == "wgs_wes"    ]] && echo "  results/test_vcf_variant_only"
[[ -z "$TEST" || "$TEST" == "snp_array"  ]] && echo "  results/test_snp_variant_only"
[[ -z "$TEST" || "$TEST" == "snp_full"   ]] && echo "  results/test_snp_full"
