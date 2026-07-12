#!/usr/bin/env bash
# =============================================================================
#  run_smoke_tests.sh — run both workflows on small toy data
# =============================================================================
#  Usage:
#    bash test_data/run_smoke_tests.sh                     # Docker (default)
#    bash test_data/run_smoke_tests.sh --profile manual_paths
#    bash test_data/run_smoke_tests.sh --profile slurm,manual_paths
#    bash test_data/run_smoke_tests.sh --profile singularity
#    bash test_data/run_smoke_tests.sh --resume            # opt in to Nextflow resume
#
#  Environment overrides:
#    GENETIC_QC_DOCKER_IMAGE=my-image:tag   # use a local Docker image
#    GENETIC_QC_FORCE_PULL=true             # force re-pull of Docker image
#    GENETIC_QC_RESUME=true                 # pass -resume to Nextflow
# =============================================================================
set -euo pipefail

IMAGE="${GENETIC_QC_DOCKER_IMAGE:-ghcr.io/kaiyao28/byegenoqc:1.1.0}"
FORCE_PULL="${GENETIC_QC_FORCE_PULL:-false}"
RESUME="${GENETIC_QC_RESUME:-false}"
PROFILE="docker"
TEST=""   # empty = run all; "snp_array", "snp_full", or "wgs_wes" = run one

usage() {
    cat << EOF
Usage: bash test_data/run_smoke_tests.sh [--profile PROFILE] [--test snp_array|snp_full|wgs_wes] [--resume]

Options:
  --profile PROFILE    Nextflow profile to use (default: docker)
  --test TEST          Run one test: snp_array, snp_full, or wgs_wes
  --resume             Pass -resume to Nextflow for local debugging
  -h, --help           Show this help

Environment:
  GENETIC_QC_DOCKER_IMAGE  Docker image to use
  GENETIC_QC_FORCE_PULL    Set true to force docker pull
  GENETIC_QC_RESUME        Set true to pass -resume to Nextflow
EOF
}

# ── Parse arguments ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --test)    TEST="$2";    shift 2 ;;
        --resume)  RESUME="true"; shift ;;
        -h|--help)  usage; exit 0 ;;
        *) echo "Unknown argument: $1"
           usage
           exit 1 ;;
    esac
done

case "$TEST" in
    ""|snp_array|snp_full|wgs_wes) ;;
    *)
        echo "ERROR: unknown smoke test: $TEST"
        usage
        exit 1
        ;;
esac

case "$RESUME" in
    true|false) ;;
    *)
        echo "ERROR: GENETIC_QC_RESUME must be true or false, got: $RESUME"
        exit 1
        ;;
esac

RESUME_ARGS=()
if [[ "$RESUME" == "true" ]]; then
    RESUME_ARGS=(-resume)
fi

echo "ByeGenoQC smoke tests"
echo "Profile : ${PROFILE}"
echo "Running : ${TEST:-snp_array + snp_full + wgs_wes}"
echo "Resume  : ${RESUME}"
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
    echo "Run scripts/setup_hpc_manual.sh first, then add \$TOOL_DIR/bin to PATH."
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
fail_assertion() {
    echo "ASSERTION FAILED: $*" >&2
    return 1
}

assert_file_exists() {
    local path="$1"
    [[ -f "$path" ]] || fail_assertion "expected file to exist: $path"
}

assert_file_nonempty() {
    local path="$1"
    assert_file_exists "$path" || return 1
    [[ -s "$path" ]] || fail_assertion "expected file to be non-empty: $path"
}

assert_dir_exists() {
    local path="$1"
    [[ -d "$path" ]] || fail_assertion "expected directory to exist: $path"
}

assert_contains() {
    local path="$1"
    local pattern="$2"
    assert_file_exists "$path" || return 1
    grep -Eq "$pattern" "$path" || fail_assertion "expected file to contain pattern '$pattern': $path"
}

assert_not_empty_glob() {
    local pattern="$1"
    local matches=()

    shopt -s nullglob
    matches=( $pattern )
    shopt -u nullglob

    [[ "${#matches[@]}" -gt 0 ]] || fail_assertion "expected at least one match for pattern: $pattern"
}

assert_nonempty_glob() {
    local pattern="$1"
    local matches=()
    local match

    shopt -s nullglob
    matches=( $pattern )
    shopt -u nullglob

    [[ "${#matches[@]}" -gt 0 ]] || fail_assertion "expected at least one match for pattern: $pattern"
    for match in "${matches[@]}"; do
        [[ -s "$match" ]] || fail_assertion "expected glob match to be non-empty: $match (pattern: $pattern)" || return 1
    done
}

assert_cleaned_plink_outputs() {
    local outdir="$1"
    local prefix="$2"
    assert_dir_exists "$outdir/05_cleaned_data" || return 1
    assert_file_nonempty "$outdir/05_cleaned_data/${prefix}_final.bed" || return 1
    assert_file_nonempty "$outdir/05_cleaned_data/${prefix}_final.bim" || return 1
    assert_file_nonempty "$outdir/05_cleaned_data/${prefix}_final.fam" || return 1
}

assert_snp_common_outputs() {
    local outdir="$1"
    local prefix="$2"
    assert_cleaned_plink_outputs "$outdir" "$prefix" || return 1
    assert_file_nonempty "$outdir/06_report/qc_report.pdf" || return 1
    assert_file_nonempty "$outdir/06_report/qc_attrition_table.tsv" || return 1
    assert_file_nonempty "$outdir/06_report/qc_thresholds.tsv" || return 1
    assert_file_exists "$outdir/05_cleaned_data/exclusion_lists/all_excluded_samples.txt" || return 1
    assert_file_exists "$outdir/05_cleaned_data/exclusion_lists/all_excluded_variants.txt" || return 1
}

validate_snp_array_outputs() {
    local outdir="results/test_snp_variant_only"
    echo "Validating SNP-array variant-only outputs..."
    assert_snp_common_outputs "$outdir" "toy" || return 1
    assert_nonempty_glob "$outdir/04_variant_qc/tables/*summary.txt" || return 1
}

validate_snp_full_outputs() {
    local outdir="results/test_snp_full"
    echo "Validating SNP-array full QC outputs..."
    assert_snp_common_outputs "$outdir" "toy" || return 1
    assert_file_nonempty "$outdir/06_report/qc_per_sample.tsv" || return 1
    assert_file_nonempty "$outdir/03_sample_qc/tables/sample_callrate_removed.txt" || return 1
    assert_file_nonempty "$outdir/03_sample_qc/tables/relatedness_remove.txt" || return 1
    assert_file_exists "$outdir/03_sample_qc/tables/heterozygosity_outliers.txt" || return 1
    assert_file_nonempty "$outdir/03_sample_qc/tables/heterozygosity_summary.txt" || return 1
    assert_file_nonempty "$outdir/03_sample_qc/tables/sex_discordant.txt" || return 1
    assert_contains "$outdir/03_sample_qc/tables/sample_callrate_removed.txt" '(^|[[:space:]])S01($|[[:space:]])' || return 1
    assert_contains "$outdir/03_sample_qc/tables/relatedness_remove.txt" '(^|[[:space:]])S0[23]($|[[:space:]])' || return 1
    assert_contains "$outdir/03_sample_qc/tables/heterozygosity_summary.txt" '^step=heterozygosity$' || return 1
    assert_contains "$outdir/03_sample_qc/tables/heterozygosity_summary.txt" '^n_samples=' || return 1
    assert_contains "$outdir/03_sample_qc/tables/heterozygosity_summary.txt" '^n_outliers_removed=' || return 1
    assert_contains "$outdir/03_sample_qc/tables/sex_discordant.txt" '(^|[[:space:]])S09($|[[:space:]])' || return 1
    assert_contains "$outdir/05_cleaned_data/exclusion_lists/all_excluded_samples.txt" '(^|[[:space:]])S01($|[[:space:]])' || return 1
    assert_contains "$outdir/05_cleaned_data/exclusion_lists/all_excluded_samples.txt" '(^|[[:space:]])S0[23]($|[[:space:]])' || return 1
    assert_contains "$outdir/05_cleaned_data/exclusion_lists/all_excluded_samples.txt" '(^|[[:space:]])S09($|[[:space:]])' || return 1
}

validate_wgs_wes_outputs() {
    local outdir="results/test_vcf_variant_only"
    echo "Validating WGS/WES VCF outputs..."
    assert_file_nonempty "$outdir/cleaned_data/merged.vcf.gz" || return 1
    assert_file_nonempty "$outdir/cleaned_data/merged.vcf.gz.tbi" || return 1
    assert_file_nonempty "$outdir/cleaned_data/merge_chromosomes_summary.txt" || return 1
    assert_file_nonempty "$outdir/wgs_wes_final_report.html" || return 1
    assert_file_nonempty "$outdir/wgs_wes_qc_summary.tsv" || return 1
    assert_file_nonempty "$outdir/wgs_wes_thresholds.tsv" || return 1
    assert_nonempty_glob "$outdir/variant_qc/chromosomes/*.vcf.gz" || return 1
    assert_nonempty_glob "$outdir/variant_calling_qc/*summary.txt" || return 1
}

validate_wgs_wes_invalid_samplesheet() {
    local log_file="results/test_vcf_invalid_samplesheet.log"
    mkdir -p results

    echo "Validating WGS/WES samplesheet parser rejects duplicate sample IDs..."
    set +e
    nextflow run wgs_wes_qc/main.nf \
      --input_type vcf \
      --samplesheet test_data/wgs_wes/samplesheet_vcf_duplicate_sample.csv \
      --reference_fasta test_data/reference/mini.fa \
      --mode wgs \
      --chroms 22 \
      --run_variant_qc false \
      --run_sample_qc false \
      --run_final_report false \
      --outdir results/test_vcf_invalid_samplesheet \
      --docker_image "${IMAGE}" \
      -profile "${PROFILE}" \
      -ansi-log false \
      "${RESUME_ARGS[@]}" > "${log_file}" 2>&1
    local status=$?
    set -e

    if [[ "$status" -eq 0 ]]; then
        cat "${log_file}"
        fail_assertion "invalid duplicate-sample WGS/WES samplesheet unexpectedly passed"
        return 1
    fi
    assert_contains "${log_file}" 'duplicate sample ID: toy_cohort' || {
        cat "${log_file}"
        return 1
    }
}

TEST_LABELS=()
TEST_STATUS=()
TEST_OUTDIRS=()

run_test() {
    local label="$1"
    local outdir="$2"
    local command_name="$3"
    local status

    echo "================================================================"
    echo "$label"
    echo "================================================================"

    set +e
    "$command_name"
    status=$?
    set -e

    TEST_LABELS+=("$label")
    TEST_OUTDIRS+=("$outdir")
    if [[ "$status" -eq 0 ]]; then
        TEST_STATUS+=("PASS")
        echo "Result: PASS - $label"
    else
        TEST_STATUS+=("FAIL")
        echo "Result: FAIL - $label (exit $status)"
    fi
    echo
}

run_wgs_wes() {
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
      "${RESUME_ARGS[@]}"
    local status=$?
    echo
    [[ "$status" -eq 0 ]] || return "$status"
    validate_wgs_wes_outputs || return 1
    validate_wgs_wes_invalid_samplesheet || return 1
    return "$status"
}

# ── SNP-array variant-only smoke test ────────────────────────────────────────
run_snp_array() {
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
      "${RESUME_ARGS[@]}"
    local status=$?
    echo
    [[ "$status" -eq 0 ]] || return "$status"
    validate_snp_array_outputs || return 1
    return "$status"
}

# ── SNP-array full QC smoke test (sample + variant QC) ───────────────────────
# Tests all sample-level modules: callrate, sex check, heterozygosity,
# relatedness, and ancestry PCA. The toy data has stable triggers for
# S01=missingness, S02/S03=relatedness, and S09=sex discordance; heterozygosity
# is validated through its summary because outlier status depends on the
# current threshold and toy-data distribution.
# n_pcs=5 and n_pcs_covariates=5 avoid PLINK PCA warnings with 15 samples.
run_snp_full() {
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
      "${RESUME_ARGS[@]}"
    local status=$?
    echo
    [[ "$status" -eq 0 ]] || return "$status"
    validate_snp_full_outputs || return 1
    return "$status"
}

if [[ -z "$TEST" || "$TEST" == "snp_array" ]]; then
    run_test "SNP array variant-only" "results/test_snp_variant_only" run_snp_array
fi
if [[ -z "$TEST" || "$TEST" == "snp_full" ]]; then
    run_test "SNP array full QC" "results/test_snp_full" run_snp_full
fi
if [[ -z "$TEST" || "$TEST" == "wgs_wes" ]]; then
    run_test "WGS/WES VCF" "results/test_vcf_variant_only" run_wgs_wes
fi

echo "Smoke tests finished."
echo
echo "Summary:"
any_failed=0
for i in "${!TEST_LABELS[@]}"; do
    printf "  %-24s %s\n" "${TEST_LABELS[$i]}:" "${TEST_STATUS[$i]}"
    printf "  %-24s %s\n" "Output:" "${TEST_OUTDIRS[$i]}"
    if [[ "${TEST_STATUS[$i]}" == "FAIL" ]]; then
        any_failed=1
    fi
done

if [[ "$any_failed" -ne 0 ]]; then
    exit 1
fi
exit 0
