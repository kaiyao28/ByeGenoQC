# ByeGenoQC

A reproducible Nextflow DSL2 pipeline for SNP-array and sequencing quality control, designed for research-scale genomic workflows.

[![CI Smoke Tests](https://img.shields.io/github/actions/workflow/status/kaiyao28/ByeGenoQC/ci-smoke-tests.yml?branch=main&label=CI&logo=github)](https://github.com/kaiyao28/ByeGenoQC/actions/workflows/ci-smoke-tests.yml)
[![Docker Image](https://img.shields.io/badge/Docker-ghcr.io%2Fkaiyao28%2Fgenetic--qc%3A1.1-blue?logo=docker)](https://github.com/kaiyao28/ByeGenoQC/pkgs/container/genetic-qc)
[![Nextflow DSL2](https://img.shields.io/badge/Nextflow-DSL2-brightgreen?logo=nextflow)](https://www.nextflow.io/)
[![License MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Version 0.1.0](https://img.shields.io/badge/Version-0.1.0-blue)](CHANGELOG.md)

---

## Contents

- [What it does](#what-it-does)
- [Quick start](#quick-start-30-seconds)
- [Real-world examples](#real-world-examples)
- [Output reports](#output-reports)
- [Which workflow should I run?](#which-workflow-should-i-run)
- [Supported platforms](#supported-platforms)
- [Key configurable thresholds](#key-configurable-thresholds)
- [Inspect before filtering](#inspect-before-filtering)
- [Documentation](#documentation)
- [Limitations and assumptions](#limitations-and-assumptions)
- [Citation](#citation)

---

## What it does

ByeGenoQC implements industry-standard QC workflows for two common genomic data types:

| Input | Workflow | Key Steps |
|-------|----------|-----------|
| **PLINK binary** (`.bed/.bim/.fam`) | SNP array QC | Missingness, HWE, MAF, sex check, heterozygosity, relatedness, ancestry PCA |
| **FASTQ/BAM/CRAM/VCF** | WGS/WES QC | Coverage, contamination, duplication rate, variant-level QC, genotype filtering, ancestry PCA |

All tools (PLINK, PLINK2, bcftools, samtools, GATK, FastQC, mosdepth, etc.) are pre-installed in a single Docker image. Every QC threshold is configurable, and the pipeline resumes from where it left off if interrupted.

**Output:** A report with full attrition table, QC metrics, and exact thresholds used — ready to paste into methods sections. SNP array QC produces a PDF report; WGS/WES QC produces a self-contained HTML report.

---

## Quick start (30 seconds)

```bash
git clone https://github.com/kaiyao28/ByeGenoQC.git
cd ByeGenoQC
bash test_data/run_smoke_tests.sh              # run both pipelines
bash test_data/run_smoke_tests.sh --test snp_array   # SNP array only
bash test_data/run_smoke_tests.sh --test wgs_wes     # WGS/WES only
```

The smoke tests run synthetic toy data in Docker in a few minutes and write reports to `results/`. No manual setup required.

---

## Real-world examples

### SNP Array QC

**Step 1 — Inspect your data first (recommended):**

```bash
nextflow run snp_array_qc/inspect.nf \
  --bfile data/raw/genotypes \
  --outdir results/inspect \
  -profile docker
```

This generates `results/inspect/inspect_report.html` showing QC metric distributions on your data and `results/inspect/params_template.yaml` with suggested thresholds.

**Step 2 — Run full QC:**

```bash
nextflow run snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --run_variant_qc true \
  --run_sample_qc true \
  --chroms 1-22 \
  --outdir results/snp_array_qc \
  -profile docker
```

Add a reference panel for ancestry PCA:

```bash
  --reference_panel data/1000G/1000G_hg38
```

Full parameters: [SNP Array Manual](docs/snp_array_qc_manual.md)

### WGS / WES QC

**BAM/CRAM input (WES):**

```bash
nextflow run wgs_wes_qc/main.nf \
  --input_type bam \
  --samplesheet samplesheet.csv \
  --reference_fasta /data/reference/GRCh38.fa \
  --target_intervals /data/reference/exome_targets.bed \
  --mode wes \
  --outdir results/wgs_wes_qc \
  -profile docker
```

**VCF input (variant QC only):**

```bash
nextflow run wgs_wes_qc/main.nf \
  --input_type vcf \
  --samplesheet samplesheet.csv \
  --reference_fasta /data/reference/GRCh38.fa \
  --mode wgs \
  --run_variant_qc true \
  --run_sample_qc false \
  --outdir results/vcf_qc \
  -profile docker
```

Full parameters: [WGS/WES Manual](docs/wgs_wes_qc_manual.md)

---

## Output reports

The two pipelines produce different report formats:

- **SNP Array QC** → `qc_report.pdf` (PDF, via R Markdown)
- **WGS/WES QC** → `wgs_wes_final_report.html` (self-contained HTML, no dependencies)

**SNP Array report** shows:
- Final sample and variant counts
- Per-step attrition (samples and variants removed at each filter)
- All QC metrics and thresholds used

**WGS/WES report** shows:
- Input validation status
- Variant-level QC (Ts/Tv ratio, SNP/indel counts)
- Sample-level QC (coverage, contamination, duplication)
- Genotype filtering applied
- Whether sample-level QC is final or provisional

**See [Example Outputs](docs/example_outputs.md)** for detailed descriptions of what each report contains and how to interpret the results.

---

## Which workflow should I run?

See [decision tree](docs/setup.md#which-workflow-should-i-run) in the setup guide to choose the right command for your data and platform.

---

## Supported platforms

- **Local:** Docker (macOS, Linux, Windows + WSL)
- **HPC:** Singularity/Apptainer, SLURM, LSF
- **No containers:** Manual tool installation with `setup_hpc_manual.sh`

All platform-specific instructions: [Setup Guide](docs/setup.md)

---

## Key configurable thresholds

All thresholds have sensible defaults and can be overridden:

```bash
# SNP array
--maf 0.05  --hwe_p 1e-4  --sample_missingness 0.05

# WGS/WES
--min_mean_depth_wgs 30  --max_contamination 0.02  --min_gq 30
```

See manuals for the full list.

---

## Inspect before filtering

The SNP array pipeline includes an optional `inspect.nf` step that computes QC metric distributions on your data and generates a template parameter file. Use this to understand your dataset before applying hard filters:

```bash
nextflow run snp_array_qc/inspect.nf \
  --bfile data/raw/genotypes \
  --outdir results/inspect
```

This generates `params_template.yaml` with suggested thresholds based on your data. Review it, adjust, then run `main.nf`.

---

## Documentation

- [Setup Guide](docs/setup.md) — Windows, macOS, Linux, HPC, troubleshooting
- [Tutorial](docs/TUTORIAL.md) — step-by-step end-to-end example
- [Example Outputs](docs/example_outputs.md) — detailed report descriptions and metric interpretation
- [Input Validation](docs/INPUT_VALIDATION.md) — file format specifications and validation
- [Benchmarks](docs/BENCHMARKS.md) — runtime and memory estimates
- [Alternatives](docs/ALTERNATIVES.md) — comparison with other tools
- [SNP Array QC Manual](docs/snp_array_qc_manual.md) — full workflow and parameters
- [WGS/WES QC Manual](docs/wgs_wes_qc_manual.md) — full workflow and parameters
- [References](docs/references.md) — tool citations and default parameter rationale
- [Test Data](test_data/README.md) — how smoke test data were generated

---

## Limitations and assumptions

- Sample-level QC results are **provisional** if fewer than all 22 autosomes are analysed (reports will flag this)
- The pipeline assumes **diploid autosomes**; sex chromosomes and polyploid genomes are not explicitly handled
- VCF-only input skips sample-level QC steps that require BAM/CRAM (coverage, contamination, duplication)
- Reference panel for PCA is optional; if not provided, PCA uses only study samples

---

## Citation

If you use ByeGenoQC in published research, please cite:

```bibtex
@software{ByeGenoQC,
  title={ByeGenoQC: A Nextflow DSL2 Pipeline for Genetic Quality Control},
  author={Yao, Kai},
  year={2024},
  url={https://github.com/kaiyao28/ByeGenoQC}
}
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contributing

We welcome bug reports, feature requests, and pull requests. Please see [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## Questions or issues?

- Check the [Setup Guide](docs/setup.md) troubleshooting section
- Review the manual for your workflow
- See [Benchmarks](docs/BENCHMARKS.md) for performance expectations
- Open an [issue](https://github.com/kaiyao28/ByeGenoQC/issues) on GitHub
