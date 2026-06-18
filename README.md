# ByeGenoQC

<<<<<<< HEAD
Everything you need for production-grade genetic QC, batteries included. Clone the repo, run one command, get a clean dataset and a PDF report — no manual tool installation, no custom scripts.

The pipeline covers the full QC stack for two data types:

| Workflow | Input | Use case |
|----------|-------|----------|
| `snp_array_qc/` | PLINK binary (`.bed/.bim/.fam`) | SNP arrays, GWAS datasets |
| `wgs_wes_qc/` | FASTQ, BAM/CRAM, or VCF | Whole-genome or whole-exome sequencing |

Every QC step — variant missingness, HWE, MAF, sex check, heterozygosity, relatedness, ancestry PCA, contamination, coverage, duplicate rate — runs in the right order, with the right tools, all pre-installed in a single Docker image. Each step can be toggled on or off independently, and every threshold has a sensible default that can be overridden from the command line. The pipeline resumes from where it left off if anything fails.

For SNP array data, the recommended workflow has two stages: **inspect first, then filter**. The inspection step (`inspect.nf`) computes all metric distributions on unfiltered data and produces an annotated `params_template.yaml` so you can choose appropriate thresholds for your specific dataset before anything is removed. The QC step (`main.nf`) then applies those thresholds. Both steps are fast; running them sequentially takes little more time than running QC directly, and it eliminates the risk of applying the wrong threshold to your data.

At the end you get a PDF report with the full attrition table, all metrics, and the exact thresholds used — ready to paste into a methods section.

---

## Pipeline Overview

<!-- DAG diagrams generated with: nextflow run <workflow> -with-dag assets/<name>_dag.png -preview -->

| Workflow | DAG |
|----------|-----|
| SNP Array QC | [snp_array_dag.png](assets/snp_array_dag.png) |
| WGS / WES QC | [wgs_dag.png](assets/wgs_dag.png) |

To regenerate the diagrams:

```bash
# SNP array
nextflow run snp_array_qc/main.nf \
  --bfile test_data/snp_array/toy \
  --run_variant_qc true \
  --run_sample_qc true \
  --run_final_report true \
  --outdir results/dag_test \
  -profile docker \
  -with-dag assets/snp_array_dag.png \
  -preview

# WGS / WES
nextflow run wgs_wes_qc/main.nf \
  --input_type vcf \
  --samplesheet test_data/wgs_wes/samplesheet_vcf.csv \
  --reference_fasta test_data/reference/mini.fa \
  --mode wgs \
  --chroms 22 \
  --run_variant_qc true \
  --run_sample_qc false \
  --run_final_report true \
  --outdir results/dag_test \
  -profile docker \
  -with-dag assets/wgs_dag.png \
  -preview
```
=======
A reproducible Nextflow DSL2 pipeline for SNP-array and sequencing quality control, designed for research-scale genomic workflows.

[![CI Smoke Tests](https://img.shields.io/github/actions/workflow/status/kaiyao28/ByeGenoQC/ci-smoke-tests.yml?branch=main&label=CI&logo=github)](https://github.com/kaiyao28/ByeGenoQC/actions/workflows/ci-smoke-tests.yml)
[![Docker Image](https://img.shields.io/badge/Docker-ghcr.io%2Fkaiyao28%2Fgenetic--qc%3A1.1-blue?logo=docker)](https://github.com/kaiyao28/ByeGenoQC/pkgs/container/genetic-qc)
[![Nextflow DSL2](https://img.shields.io/badge/Nextflow-DSL2-brightgreen?logo=nextflow)](https://www.nextflow.io/)
[![License MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Version 0.1.0](https://img.shields.io/badge/Version-0.1.0-blue)](CHANGELOG.md)
>>>>>>> 175231b (Systematic improvements)

---

## What it does

ByeGenoQC implements industry-standard QC workflows for two common genomic data types:

| Input | Workflow | Key Steps |
|-------|----------|-----------|
| **PLINK binary** (`.bed/.bim/.fam`) | SNP array QC | Missingness, HWE, MAF, sex check, heterozygosity, relatedness, ancestry PCA |
| **FASTQ/BAM/CRAM/VCF** | WGS/WES QC | Coverage, contamination, duplication rate, variant-level QC, genotype filtering, ancestry PCA |

All tools (PLINK, PLINK2, bcftools, samtools, GATK, FastQC, mosdepth, etc.) are pre-installed in a single Docker image. Every QC threshold is configurable, and the pipeline resumes from where it left off if interrupted.

**Output:** Self-contained HTML report with full attrition table, QC metrics, and exact thresholds used — ready to paste into methods sections.

---

## Quick start (30 seconds)

```bash
<<<<<<< HEAD
git clone https://github.com/kaiyao28/GeneticQC.git
cd GeneticQC
bash test_data/run_smoke_tests.sh                    # all three tests
bash test_data/run_smoke_tests.sh --test snp_array   # SNP array: variant QC only
bash test_data/run_smoke_tests.sh --test snp_full    # SNP array: full QC (variant + sample)
bash test_data/run_smoke_tests.sh --test wgs_wes     # WGS/WES only
```

The smoke test script checks Docker and Nextflow, pulls the image, and runs the selected workflow(s) on synthetic toy data in `test_data/`. All tests should complete in a few minutes and write reports to `results/`.

For HPC without Docker or Singularity, use `--profile manual_paths` instead (see [Setup Guide](docs/setup.md)).

For platform-specific setup (Windows/WSL, Linux, macOS, HPC), see [Setup Guide](docs/setup.md).
=======
git clone https://github.com/kaiyao28/ByeGenoQC.git
cd ByeGenoQC
bash test_data/run_smoke_tests.sh              # run both pipelines
bash test_data/run_smoke_tests.sh --test snp_array   # SNP array only
bash test_data/run_smoke_tests.sh --test wgs_wes     # WGS/WES only
```

The smoke tests run synthetic toy data in Docker in a few minutes and write reports to `results/`. No manual setup required.
>>>>>>> 175231b (Systematic improvements)

---

## Real-world examples

### SNP Array QC

### Step 1 — Inspect your data first

```bash
nextflow run snp_array_qc/inspect.nf \
  --bfile data/raw/genotypes \
  --outdir results/inspect \
  -profile docker
```

<<<<<<< HEAD
Open `results/inspect/inspect_report.html` in a browser. It shows the full distribution of every QC metric — missingness, MAF, HWE p-values, heterozygosity, pairwise IBD, and PCA — with the default thresholds marked. The file `results/inspect/params_template.yaml` is pre-filled with all parameters and annotated with the observed statistics from your dataset:

```yaml
sample_missingness: 0.02  # observed 95th pct=0.003, max=0.018 — very clean; could tighten to 0.01
hwe_p: 1.0e-6             # observed min p (autosomes)=3.2e-12, variants below 1e-6: 125
relatedness_pi_hat: 0.1875
# IBD pairs > 0.1875 (default):  12
# IBD duplicates/MZ twins:        1
```

Edit any threshold that looks wrong for your data, then fill in optional inputs:

```yaml
reference_panel: data/1000G/1000G_hg38   # for ancestry-labelled PCA
ld_regions: data/high_ld_hg19.txt        # recommended: exclude MHC and inversions
```

### Step 2 — Run QC
=======
Add a reference panel for ancestry PCA:
>>>>>>> 175231b (Systematic improvements)

```bash
nextflow run snp_array_qc/main.nf \
  -params-file results/inspect/params_template.yaml \
  -profile docker
```

If you are confident the defaults are appropriate and want to skip the inspection step:

```bash
nextflow run snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --outdir results/snp_array_qc \
  -profile docker
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

<<<<<<< HEAD
**SNP Array report** (`06_report/qc_report.pdf`):
=======
Both pipelines produce a self-contained HTML report.

**SNP Array report** shows:
- Final sample and variant counts
- Per-step attrition (samples and variants removed at each filter)
- All QC metrics and thresholds used
>>>>>>> 175231b (Systematic improvements)

**WGS/WES report** shows:
- Input validation status
- Variant-level QC (Ts/Tv ratio, SNP/indel counts)
- Sample-level QC (coverage, contamination, duplication)
- Genotype filtering applied
- Whether sample-level QC is final or provisional

**See [Example Outputs](docs/example_outputs.md)** for detailed descriptions of what each report contains and how to interpret the results.

---

## Which workflow should I run?

<<<<<<< HEAD
| Profile | When to use |
|---------|-------------|
| `docker` | Laptop or workstation with Docker Desktop |
| `slurm,singularity` | HPC cluster with SLURM + Apptainer/Singularity |
| `lsf,singularity` | HPC cluster with LSF + Apptainer/Singularity |
| `slurm,manual_paths` | HPC with no container engine; tools installed manually |

On HPC, always pair the scheduler profile (`slurm`, `lsf`) with the container profile (`singularity`). `-profile singularity` alone runs on the login node. Use absolute paths for `--bfile` and `--outdir` on clusters — relative paths can fail silently on compute nodes.

If no container engine is available, run `bash setup_hpc_manual.sh` first to download all tools. See [Setup Guide](docs/setup.md) for full cluster instructions.
=======
See [decision tree](docs/setup.md#which-workflow-should-i-run) in the setup guide to choose the right command for your data and platform.
>>>>>>> 175231b (Systematic improvements)

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
- [Example Outputs](docs/example_outputs.md) — detailed report descriptions and metric interpretation
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

We welcome bug reports, feature requests, and pull requests. Please open an issue on [GitHub](https://github.com/kaiyao28/ByeGenoQC/issues).

---

## Questions or issues?

- Check the [Setup Guide](docs/setup.md) troubleshooting section
- Review the manual for your workflow
- Open an [issue](https://github.com/kaiyao28/ByeGenoQC/issues) on GitHub
