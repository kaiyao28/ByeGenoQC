# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-01

### Added
- Initial public release
- SNP array QC workflow (`snp_array_qc/`)
  - Variant-level QC: missingness, HWE, MAF filtering
  - Sample-level QC: sex check, heterozygosity, relatedness, PCA
  - Inspect workflow for threshold discovery
  - Configurable thresholds and module toggles
- WGS/WES QC workflow (`wgs_wes_qc/`)
  - Support for FASTQ, BAM, CRAM, and VCF input
  - Coverage and contamination analysis
  - Variant-level and genotype filtering
  - Ancestry PCA
- Docker container with all pre-installed tools
- Nextflow DSL2 pipeline with support for:
  - Local execution (Docker, Conda)
  - HPC execution (SLURM, LSF with Singularity/Apptainer)
  - Manual tool installation fallback
- Comprehensive documentation and setup guides
- GitHub Actions CI for automated smoke testing
- HTML report generation for both workflows
- Smoke test suite with synthetic toy data

### Documentation
- README with quick start and examples
- Setup guide for all platforms (Windows, macOS, Linux, HPC)
- SNP array QC manual with parameter reference
- WGS/WES QC manual with parameter reference
- References document with tool citations

---

## Unreleased

### Planned
- Support for polyploid organisms
- Sex chromosome QC modules
- Integration with common GWAS tools
- Batch effect detection modules
- Interactive report features
