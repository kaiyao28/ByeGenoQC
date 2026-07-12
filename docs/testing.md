# Testing Status

Back to the [documentation index](index.md) or main [README](../README.md).

ByeGenoQC includes lightweight CI checks and toy-data smoke tests intended to catch common regressions in workflow wiring, parser behaviour, expected output generation, and selected QC triggers.

Current automated checks cover:

- Bash syntax, high-confidence ShellCheck findings, GitHub Actions YAML parsing, and lightweight Nextflow config/workflow previews.
- SNP-array variant-only smoke testing on synthetic PLINK data.
- SNP-array sample + variant QC smoke testing on synthetic data with designed triggers for missingness, relatedness, and sex-check discordance, plus heterozygosity summary validation.
- Sequencing VCF-mode smoke testing on a tiny chromosome 22 VCF, including checks for core VCF outputs, reports, and summary files.
- A negative WGS/WES samplesheet parser regression check for duplicate sample IDs.

These tests are useful for development and CI regression detection, but they are not clinical, regulatory, or dataset-wide validation. Users should validate thresholds, reference data, and outputs for their own cohort and analysis context.

Run all smoke tests:

```bash
bash test_data/run_smoke_tests.sh
```

Run one mode:

```bash
bash test_data/run_smoke_tests.sh --test snp_array
bash test_data/run_smoke_tests.sh --test snp_full
bash test_data/run_smoke_tests.sh --test wgs_wes
```
