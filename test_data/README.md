# Test Data

Small synthetic files for smoke-testing pipeline wiring and QC filter logic.
These files are intentionally tiny — biological interpretation of results is meaningless.

## Regenerating Test Data

If the test data files are missing or you want to reset them:

```bash
python3 test_data/generate_test_data.py
```

## Running Smoke Tests

```bash
# Run all three tests (default)
bash test_data/run_smoke_tests.sh

# Run one test at a time
bash test_data/run_smoke_tests.sh --test snp_array   # SNP array: variant QC only
bash test_data/run_smoke_tests.sh --test snp_full    # SNP array: variant + sample QC
bash test_data/run_smoke_tests.sh --test wgs_wes     # sequencing VCF variant QC

# Profiles
bash test_data/run_smoke_tests.sh --profile docker
bash test_data/run_smoke_tests.sh --profile singularity
bash test_data/run_smoke_tests.sh --profile manual_paths

# Reuse cached Nextflow work when debugging locally
bash test_data/run_smoke_tests.sh --resume
GENETIC_QC_RESUME=true bash test_data/run_smoke_tests.sh --test snp_array
```

Smoke tests run fresh by default. CI intentionally does not pass `-resume`, so
each run exercises the current source and Docker image rather than cached
Nextflow work.

## What Each Test Exercises

### SNP Array variant-only (`--test snp_array`)

Input: `test_data/snp_array/toy.bed/.bim/.fam` (PLINK binary format)

```text
15 samples  (S01–S15):  7 male / 8 female,  8 cases / 7 controls
235 variants:
  v001–200   chr22   normal genotypes (MAF 0.10–0.40, HWE-compliant)
  v201–210   chr22   ~35% missing calls → fail variant callrate filter (>2%)
  v211–213   chr22   monomorphic (MAF=0) → fail MAF filter (<0.01)
  v214–215   chr22   all-heterozygous   → fail HWE filter
  v216–235   chr23 (X)                 → enables PLINK sex check
```

Run command:

```bash
nextflow run snp_array_qc/main.nf \
  --bfile test_data/snp_array/toy \
  --run_variant_qc true \
  --run_sample_qc false \
  --run_final_report true \
  --outdir results/test_snp_variant_only \
  -profile docker
```

---

### SNP Array full QC (`--test snp_full`)

Same input as above, with all sample-level modules enabled. Each module has a
designed trigger in the toy data:

```text
S01  ~25% of autosomal calls missing     → fails sample callrate filter (>2%)
S02  identical genotypes to S03          → relatedness filter (PI_HAT ≈ 1.0)
S03  identical genotypes to S02          → relatedness filter (PI_HAT ≈ 1.0)
S07  70% of autosomal calls heterozygous → heterozygosity outlier
S09  PEDSEX=female, all chrX hom calls   → sex check discordant
```

Run command (`--n_pcs 5` avoids PLINK PCA warnings with 15 samples):

```bash
nextflow run snp_array_qc/main.nf \
  --bfile test_data/snp_array/toy \
  --run_variant_qc true \
  --run_sample_qc true \
  --run_final_report true \
  --n_pcs 5 \
  --n_pcs_covariates 5 \
  --outdir results/test_snp_full \
  -profile docker
```

---

### Sequencing VCF (`--test wgs_wes`)

Parser regression fixtures in `test_data/wgs_wes/`:

- `samplesheet_vcf_duplicate_sample.csv`: duplicate `sample` IDs.
- `samplesheet_vcf_missing_file.csv`: referenced VCF does not exist.
- `samplesheet_fastq_ambiguous.csv`: columns populated for incompatible input interpretations.

Input: `test_data/wgs_wes/toy_chr22.vcf` (VCF mode, variant QC only)

```text
5 samples  (SAMPLE1–5)
20 variants on chr22:
  18 SNPs:  13 transitions + 5 transversions → Ti/Tv ≈ 2.6
  2 indels  (1 deletion, 1 insertion)
  rs013 (pos 325): FAIL site filter — QD < 2.0
  rs015 (pos 375): FAIL site filter — FS > 60.0
  rs013 + rs018:   low DP/GQ genotype-level filter demo
```

Reference: `test_data/reference/mini.fa` — 500 bp deterministic chr22 (ATCGATCG repeating).
REF alleles in the VCF are verified against this reference at each position.

Run command:

```bash
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
  -profile docker
```
