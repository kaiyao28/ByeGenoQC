# Alternatives: How ByeGenoQC Compares

This document explains why you might choose ByeGenoQC over other quality control tools and what trade-offs exist.

---

## Quick Comparison Table

| Feature | ByeGenoQC | GATK Best Practices | bcftools | Hail | Plink2 QC |
|---------|-----------|-------------------|----------|------|-----------|
| **SNP Array QC** | ✓ | ✗ | ✓ (partial) | ✓ | ✓ |
| **WGS/WES QC** | ✓ | ✓ | ✓ (partial) | ✓ | ✗ |
| **Reproducible (Docker)** | ✓ | ✓ (partial) | ✓ | ✗ | ✗ |
| **HPC ready** | ✓ | ✓ | ✓ | ✓ | ✗ |
| **All-in-one workflow** | ✓ | ✗ | ✗ | ✓ | ✗ |
| **HTML reports** | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Inspect/threshold discovery** | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Configurable thresholds** | ✓ | Partial | Partial | ✓ | ✓ |
| **Learning curve** | Low | Medium | Low | High | Low |

---

## ByeGenoQC vs. GATK Best Practices

**GATK Best Practices** is the gold standard for variant QC, especially in large consortia. Use GATK if:
- You need **maximum compatibility** with published analyses
- You're working with **large callsets** (1000s of samples)
- You have **VQSR training resources** (HapMap, Omni, 1000G, dbSNP)
- You need **exact reproducibility** of established pipelines

Choose **ByeGenoQC** if:
- You want a **complete SNP array + WGS/WES pipeline in one tool**
- You prefer **hard filtering** over VQSR (simpler, faster for small cohorts)
- You want **instant visual reports** without post-processing
- You like **configurable thresholds** without rewriting scripts
- You're on an **HPC without internet** (manual tool installation works)

**Trade-off:** GATK is more conservative and validated; ByeGenoQC is faster and more integrated.

---

## ByeGenoQC vs. bcftools

**bcftools** is lightweight and powerful for VCF manipulation. Use bcftools if:
- You're doing **ad-hoc filtering** or **one-off transformations**
- You want **minimal dependencies** (single binary, fast)
- You're comfortable **chaining shell commands**

Choose **ByeGenoQC** if:
- You want a **complete, reproducible workflow** (not manual command piping)
- You need **SNP array QC** (bcftools doesn't support PLINK binary)
- You want **unified sample + variant QC** in one pass
- You prefer **reports over TSV files** for stakeholder communication
- You need **HPC scheduler integration** (SLURM, LSF)

**Trade-off:** bcftools is surgical (you control every step); ByeGenoQC is integrated (pre-designed workflow).

---

## ByeGenoQC vs. Hail

**Hail** is a scalable platform for genetic data analysis. Use Hail if:
- You're working with **very large cohorts** (100K+ samples)
- You need **complex statistical QC** (kinship, association testing, etc.)
- You're comfortable with **Python and distributed computing** (Spark)
- You want **cloud deployment** (Google Cloud, AWS)

Choose **ByeGenoQC** if:
- You're working with **typical cohorts** (100–10K samples)
- You prefer **workflow automation** over coding QC logic
- You want **simple local/HPC execution**
- You don't need distributed computing
- You want **instant Docker deployment** (no Spark overhead)

**Trade-off:** Hail is powerful and flexible; ByeGenoQC is purpose-built and immediate.

---

## ByeGenoQC vs. Plink2 QC

**Plink2** has native QC commands (`--hardy`, `--freq`, `--het`, etc.). Use Plink2 if:
- You only have **SNP array data**
- You like **minimal dependencies**
- You're comfortable **writing QC scripts** in R or Python
- You work primarily **locally** (single machine)

Choose **ByeGenoQC** if:
- You want **both SNP array and WGS/WES workflows** in one tool
- You want a **full pipeline** (not individual QC commands)
- You need **HPC scheduling** integration
- You want **visual reports** automatically generated
- You want **Docker reproducibility**

**Trade-off:** Plink2 is lightweight; ByeGenoQC is integrated.

---

## ByeGenoQC vs. nf-core/sarek

**nf-core/sarek** is a comprehensive variant calling and QC pipeline. Use sarek if:
- You're doing **variant calling from FASTQ**
- You need **nf-core standards** (community validation)
- You want **modular, reusable components**

Choose **ByeGenoQC** if:
- You have **pre-aligned BAM or VCF** (variant calling already done)
- You want a **focused QC-only workflow** (not calling)
- You prefer **simpler, faster execution** than the full sarek pipeline
- You need **SNP array support** (sarek is sequencing-only)

**Trade-off:** Sarek is comprehensive; ByeGenoQC is focused.

---

## Key Advantages of ByeGenoQC

### 1. All-in-One for SNP Arrays + Sequencing
Most tools excel at one or the other. ByeGenoQC handles both workflows with consistent design patterns.

### 2. Threshold Discovery (Inspect Workflow)
Unique feature: run `inspect.nf` first to see your data distributions, then automatically generate a template parameter file. Other tools force you to decide thresholds blindly.

### 3. Self-Contained HTML Reports
Instant stakeholder communication. No need for manual visualization scripts or R notebooks. Reports are methods-section ready.

### 4. Reproducible Docker + HPC
Works on laptop and cluster without code changes. Same `docker`, `singularity`, or `manual_paths` profile.

### 5. Sensible Defaults, Fully Configurable
Run with defaults; tweak any threshold on the command line. No rewriting config files.

---

## Key Limitations

### 1. Smaller Community
ByeGenoQC is newer. GATK and Hail have larger communities, more tutorials, more troubleshooting help online.

### 2. Hard Filtering Only (for sequencing)
No VQSR. If you need variant recalibration, use GATK.

### 3. Limited to Diploid Autosomes
No polyploid or sex chromosome handling yet. If you need this, use Hail or custom scripts.

### 4. No Variant Calling
Starts with aligned BAM or VCF. If you have FASTQ, align first (or use sarek).

### 5. No Association Testing or Annotation
Pure QC pipeline. If you need downstream analysis (GWAS, annotation), pair with other tools.

---

## Recommended Hybrid Approaches

### Scenario 1: Large consortium with strict reproducibility needs
```
GATK Best Practices (variant calling) 
  ↓
ByeGenoQC (QC reports + filtering)
  ↓
Hail (cohort analysis, GWAS)
```

### Scenario 2: Quick WES QC without deep customization
```
ByeGenoQC (one command, get report)
  ↓
Custom R script (downstream analysis)
```

### Scenario 3: SNP array GWAS
```
ByeGenoQC inspect (understand thresholds)
  ↓
ByeGenoQC main (filter)
  ↓
Plink2 (association testing)
```

---

## Why We Built ByeGenoQC

1. **No single tool combined SNP array + WGS/WES QC well.** You had to learn two separate workflows.
2. **Manual QC scripts are hard to reproduce.** Docker + Nextflow makes it instant.
3. **Reports are crucial for communication.** HTML reports are standard in industry; rare in academic bioinformatics.
4. **Threshold discovery should be automated.** The inspect workflow is our unique contribution.
5. **HPC without internet happens.** Manual tool installation support matters.

---

## Should You Use ByeGenoQC?

**Yes, if you:**
- Want a **complete, ready-to-run SNP array + sequencing QC pipeline**
- Value **reproducibility** (Docker, Nextflow, tracked versions)
- Like **visual reports** for stakeholder communication
- Work on **HPC clusters** and want simple scheduler integration
- Prefer **sensible defaults** you can customize as needed

**No, if you:**
- Need **VQSR** (use GATK)
- Work with **100K+ samples** (use Hail)
- Only have **SNP array data** and prefer lightweight tools (use Plink2)
- Need **variant calling** (use Sarek or GATK)
- Want **maximum established best-practices compliance** (use GATK)

---

## Getting Started After Choosing ByeGenoQC

See [Setup Guide](setup.md) and [Example Outputs](example_outputs.md) to get started in 30 minutes.

Questions? Open an [issue](https://github.com/kaiyao28/ByeGenoQC/issues) or check [CONTRIBUTING.md](../CONTRIBUTING.md).
