## ByeGenoQC v0.1.0

Initial public release of ByeGenoQC — a reproducible Nextflow DSL2 pipeline for SNP-array and sequencing quality control.

### ✨ Features

#### SNP Array QC Workflow
- Variant-level QC: missingness, HWE, MAF filtering
- Sample-level QC: sex check, heterozygosity, relatedness, PCA
- Inspect workflow for threshold discovery on your data
- Fully configurable thresholds and module toggles
- Comprehensive HTML report with attrition tables and metrics

#### WGS/WES QC Workflow
- Support for FASTQ, BAM, CRAM, and VCF input
- Coverage and contamination analysis (VerifyBamID2, GATK)
- Variant-level filtering with configurable GATK hard filters
- Sample-level QC with ancestry PCA
- Self-contained HTML reports with per-sample metrics

#### Infrastructure & Reproducibility
- **Docker container** with all pre-installed tools (PLINK, PLINK2, bcftools, samtools, GATK, FastQC, mosdepth, Python, R)
- **Nextflow DSL2** with support for:
  - Local execution (Docker, Conda)
  - HPC clusters (SLURM, LSF with Singularity/Apptainer)
  - Manual tool installation fallback (no containers)
- GitHub Actions CI for automated smoke testing
- Comprehensive documentation (setup guide, parameter manuals, example outputs)

### 📋 Included in v0.1.0

- Complete SNP array QC pipeline
- Complete WGS/WES QC pipeline (BAM/CRAM/VCF input)
- Smoke test suite with synthetic toy data
- Docker image (`ghcr.io/kaiyao28/genetic-qc:1.1`)
- Setup guides for Windows, macOS, Linux, HPC
- HTML report generation for both workflows
- Inspect workflow (SNP array only)
- Professional repository hygiene (LICENSE, CITATION, CHANGELOG, CONTRIBUTING)
- CI smoke tests on PR and push

### 🚀 Getting Started

```bash
git clone https://github.com/kaiyao28/ByeGenoQC.git
cd ByeGenoQC
bash test_data/run_smoke_tests.sh
```

See [README](https://github.com/kaiyao28/ByeGenoQC#readme) and [Setup Guide](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/setup.md) for complete instructions.

### 📚 Documentation

- [README](https://github.com/kaiyao28/ByeGenoQC#readme)
- [Setup Guide](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/setup.md)
- [SNP Array QC Manual](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/snp_array_qc_manual.md)
- [WGS/WES QC Manual](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/wgs_wes_qc_manual.md)
- [Example Outputs](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/example_outputs/README.md)
- [Input Validation](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/INPUT_VALIDATION.md)
- [Alternatives](https://github.com/kaiyao28/ByeGenoQC/blob/main/docs/ALTERNATIVES.md)

### ✅ Tested Platforms

- macOS (Intel, Apple Silicon) with Docker Desktop
- Linux (Ubuntu 20.04+, CentOS 7+) with Docker
- Windows 11 with WSL2 and Docker Desktop
- HPC clusters with Singularity/Apptainer (SLURM, LSF)

### 📦 Container Image

```bash
docker pull ghcr.io/kaiyao28/genetic-qc:1.1
```

### 🤝 Contributing

We welcome bug reports, feature requests, and contributions. See [CONTRIBUTING.md](https://github.com/kaiyao28/ByeGenoQC/blob/main/.github/CONTRIBUTING.md).

### 📄 Citation

If you use ByeGenoQC in published research:

```bibtex
@software{ByeGenoQC,
  title={ByeGenoQC: A Nextflow DSL2 Pipeline for Genetic Quality Control},
  author={Yao, Kai},
  year={2024},
  url={https://github.com/kaiyao28/ByeGenoQC}
}
```

### 📝 License

MIT License — see [LICENSE](https://github.com/kaiyao28/ByeGenoQC/blob/main/LICENSE)

---

**Thank you for using ByeGenoQC!** For questions or issues, please open an [issue](https://github.com/kaiyao28/ByeGenoQC/issues) or contact the maintainers.
