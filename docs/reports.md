# Reports

Back to the [documentation index](index.md) or main [README](../README.md). See [example outputs](example_outputs/README.md) for smoke-test report and table paths.

## SNP Array Report

**File:** `06_report/qc_report.pdf`

| Metric | Value |
|--------|-------|
| Final samples | 950 |
| Final variants | 487 203 |
| Excluded samples | 12 |
| Excluded variants | 4 891 |

The report includes a per-step attrition table showing variants and samples removed at each QC filter, including duplicate checks, missingness, HWE, MAF, sex check, heterozygosity, relatedness, and PCA. It also records the thresholds used in the run.

## Sequencing QC Report

**File:** `wgs_wes_final_report.html`

| Phase | Step | Metric | Value |
|-------|------|--------|-------|
| input_check | input_check | status | PASS |
| variant_level_qc | variant_calling_qc | ts_tv_ratio | 2.07 |
| variant_level_qc | variant_calling_qc | n_snps | 4 812 301 |
| variant_level_qc | variant_calling_qc | n_indels | 891 204 |
| variant_level_qc | merge_chromosomes | n_variants | 5 703 505 |
| sample_level_qc | coverage_qc | mean_depth | 34.2 |
| sample_level_qc | contamination | freemix | 0.009 |

The report records which phases ran and which were skipped. Available rows depend on `--input_type`: FASTQ reports raw-read QC, BAM/CRAM reports aligned-read sample QC, and VCF reports variant/genotype QC.
