# Tutorial: End-to-End SNP Array QC Example

This tutorial walks through a complete SNP array quality control workflow using ByeGenoQC, from raw data to final report.

---

## Prerequisites

- ByeGenoQC installed (see [Setup Guide](setup.md))
- Docker running (or Singularity if on HPC)
- PLINK binary data (.bed/.bim/.fam files)
- ~30 minutes and 2 GB RAM

---

## Step 1: Prepare Your Data

Let's assume you have raw genotype data:

```bash
# Directory structure
my_project/
├── data/
│   └── raw/
│       ├── genotypes.bed
│       ├── genotypes.bim
│       └── genotypes.fam
├── reference/
│   └── 1000G_hg38/
│       ├── 1000G_hg38.bed
│       ├── 1000G_hg38.bim
│       └── 1000G_hg38.fam
└── results/
    └── (will be created by pipeline)
```

### Verify your PLINK files are valid

```bash
cd my_project/

# Check file sizes and counts
ls -lh data/raw/
# Output should show all 3 files exist

# Count samples and variants
wc -l data/raw/genotypes.fam data/raw/genotypes.bim
# fam: 1000 = 1000 samples
# bim: 500000 = 500,000 variants

# Check for multiallelic sites (not supported)
awk 'BEGIN {RS="\n"; count=0} {count++} END {print count}' data/raw/genotypes.bim
# Should match variant count
```

---

## Step 2: Run Inspect Workflow (Data Discovery)

The inspect workflow analyzes your data distributions **before** filtering, helping you choose appropriate thresholds.

```bash
nextflow run /path/to/ByeGenoQC/snp_array_qc/inspect.nf \
  --bfile data/raw/genotypes \
  --outdir results/inspect \
  -profile docker
```

**What happens:**
1. Computes QC metrics (missingness, HWE p-values, MAF, heterozygosity, etc.)
2. Generates distribution plots
3. Creates `results/inspect/params_template.yaml` with suggested thresholds

**Monitor progress:**
```bash
# In another terminal, watch the logs
tail -f .nextflow.log

# Or check Nextflow dashboard
open http://localhost:8080  # if using -with-weblog
```

**Expected output:**
```
results/inspect/
├── inspect_report.html          # Open in browser
├── params_template.yaml         # Suggested thresholds
├── metric_distributions.png     # Summary plots
└── logs/
```

### Review the Inspect Report

Open `results/inspect/inspect_report.html` in your browser:
- **Missingness plots** — see if any samples are outliers
- **Heterozygosity distribution** — identify potential contamination
- **Allele frequency spectrum** — check for rare variants
- **Relatedness matrix** — spot duplicates/relatives before filtering

### Check Suggested Thresholds

```bash
cat results/inspect/params_template.yaml
# Example output:
# sample_missingness: 0.05
# variant_missingness: 0.02
# hwe_p: 1e-6
# maf: 0.01
# heterozygosity_sd: 3
# relatedness_pi_hat: 0.1875
```

If these look reasonable, proceed to Step 3. If you want stricter filtering:

```bash
# Edit the parameters
cat results/inspect/params_template.yaml | sed 's/sample_missingness: 0.05/sample_missingness: 0.02/' > my_params.yaml
```

---

## Step 3: Run Main QC Workflow

Now run the full quality control with your chosen thresholds.

### Option A: Use default thresholds

```bash
nextflow run /path/to/ByeGenoQC/snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --run_variant_qc true \
  --run_sample_qc true \
  --chroms 1-22 \
  --outdir results/snp_array_qc \
  -profile docker
```

### Option B: Use custom thresholds from inspect

```bash
nextflow run /path/to/ByeGenoQC/snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --run_variant_qc true \
  --run_sample_qc true \
  --chroms 1-22 \
  --sample_missingness 0.05 \
  --variant_missingness 0.02 \
  --hwe_p 1e-6 \
  --maf 0.01 \
  --heterozygosity_sd 3 \
  --relatedness_pi_hat 0.1875 \
  --outdir results/snp_array_qc \
  -profile docker
```

### Option C: Variant-only QC (skip sample filtering)

Useful for QC of a reference panel:

```bash
nextflow run /path/to/ByeGenoQC/snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --run_variant_qc true \
  --run_sample_qc false \
  --chroms 1-22 \
  --outdir results/snp_array_qc_variants \
  -profile docker
```

**Monitoring the run:**

```bash
# Watch logs in real-time
tail -f .nextflow.log | grep -E "SUBMITTED|COMPLETED|ERROR"

# Check which processes have finished
nextflow log -f "{name}\t{status}\t{duration}"

# If you want to resume after interruption
nextflow run snp_array_qc/main.nf ... -resume
```

---

## Step 4: Add Ancestry Annotation (Optional)

If you have a reference panel (e.g., 1000 Genomes), re-run with PCA projection:

```bash
nextflow run /path/to/ByeGenoQC/snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --reference_panel reference/1000G_hg38 \
  --run_variant_qc true \
  --run_sample_qc true \
  --run_ancestry_pca true \
  --chroms 1-22 \
  --outdir results/snp_array_qc_with_ancestry \
  -profile docker
```

This adds:
- PCA projection onto study samples vs reference populations
- Ancestry outlier detection (>6 SD)
- Ancestry cluster assignments (optional visualization)

---

## Step 5: Review the Final Report

```bash
# Open in browser
open results/snp_array_qc/final_report.html

# Or serve locally if remote
python3 -m http.server 8000 --directory results/snp_array_qc
# Then navigate to http://localhost:8000/final_report.html
```

### Report sections:

1. **Executive Summary**
   - Initial vs final sample/variant counts
   - Overall attrition %

2. **Per-Step Attrition Table**
   - Exactly which samples/variants removed at each filter
   - Use this for methods section

3. **QC Plots**
   - Missingness distributions (before/after)
   - Heterozygosity (outliers flagged in red)
   - Allele frequency spectrum
   - PCA biplot (if ancestry was run)

4. **Thresholds Used**
   - Copy-paste into your manuscript methods
   - Matches what you specified on command line

5. **Notes**
   - Warnings if sample QC is provisional
   - Modules that were skipped

---

## Step 6: Extract Filtered Data

The pipeline outputs a filtered PLINK binary by default (if `--keep_intermediate false`, these are in the work directory).

To keep and use the filtered data:

```bash
# Option 1: Run with keep_intermediate=true
nextflow run snp_array_qc/main.nf \
  --bfile data/raw/genotypes \
  --keep_intermediate true \
  --outdir results/snp_array_qc_with_files \
  -profile docker
# Then use: results/snp_array_qc_with_files/plink_filtered.bed/bim/fam

# Option 2: Find filtered data in work directory
find .nextflow/work -name "*.bed" -o -name "*.bim" -o -name "*.fam" | head -5
# Copy the final ones to your results directory
```

Now you can use the filtered data for:
```bash
# Downstream analysis
plink --bfile results/snp_array_qc_with_files/plink_filtered \
  --assoc \
  --out results/gwas_results

# Or import to other tools
plink2 --bfile results/snp_array_qc_with_files/plink_filtered \
  --freq \
  --out results/allele_freqs
```

---

## Step 7: Document Your QC

Create a methods section for publication:

```markdown
## Genetic Quality Control

Quality control was performed using ByeGenoQC v0.1.0 
(https://github.com/kaiyao28/ByeGenoQC).

### Sample-level QC filters:
- Removed samples with >5% missing genotype calls
- Removed samples with heterozygosity >3 SD from mean
- Removed duplicates and first-degree relatives (π̂ > 0.1875)
- Sex check discordance flagged and removed

### Variant-level QC filters:
- Removed variants with >2% missing calls
- Removed variants departing Hardy-Weinberg equilibrium (p < 1e-6)
- Removed variants with minor allele frequency <1%

### Ancestry analysis:
- Projected study samples onto 1000 Genomes reference panel
- Removed samples >6 SD on any principal component (5 samples)

Final dataset: X samples, Y variants (Z% of original data retained).
See Supplementary Table 1 for per-step attrition.
```

Insert the attrition table from `results/snp_array_qc/qc_attrition_table.tsv` as Supplementary Table 1.

---

## Step 8: Common Next Steps

### GWAS
```bash
# Perform association testing
plink2 --bfile results/snp_array_qc/plink_filtered \
  --glm log10 \
  --covar phenotypes.txt \
  --out results/gwas_results
```

### Haplotype imputation
```bash
# Prepare for imputation (pre-phasing)
plink --bfile results/snp_array_qc/plink_filtered \
  --indep-pairwise 1500 150 0.2 \
  --out results/pruned

# Then send to imputation server (HRC, TOPMed, 1000G)
```

### PRS (Polygenic Risk Score)
```bash
# Clump summary statistics
plink --bfile results/snp_array_qc/plink_filtered \
  --clump summary_stats.txt \
  --out results/clumped

# Calculate PRS
plink --bfile results/snp_array_qc/plink_filtered \
  --score results/clumped.clumped 1 2 3 \
  --out results/prs_scores
```

---

## Troubleshooting

### Error: "genotypes.bed: No such file or directory"
**Cause:** You used `--bfile genotypes.bed` instead of `--bfile genotypes`

**Fix:** Specify prefix only (no extension)
```bash
--bfile data/raw/genotypes  # ✓ Correct
--bfile data/raw/genotypes.bed  # ✗ Wrong
```

### Error: "bed file has wrong number of variants"
**Cause:** `.bed` and `.bim` are out of sync (corrupted)

**Fix:** Regenerate from text format
```bash
# If you have .ped/.map files
plink --file data/raw/genotypes --make-bed --out data/raw/genotypes_clean

# Then re-run QC with genotypes_clean
```

### Pipeline runs slowly
See [BENCHMARKS.md](BENCHMARKS.md) for optimization tips. Quick checks:
```bash
# Use variant-only QC for testing
--run_sample_qc false

# Subset to specific chromosomes
--chroms 21,22

# Check disk I/O
iostat -xz 1
```

### Report doesn't display correctly
```bash
# Serve via HTTP server (avoids browser security restrictions)
python3 -m http.server 8000 --directory results/snp_array_qc
```

---

## Full Command Cheat Sheet

```bash
# Quick test (1 minute, no data needed)
cd /path/to/ByeGenoQC
bash test_data/run_smoke_tests.sh --test snp_array

# Inspect workflow on your data
nextflow run snp_array_qc/inspect.nf \
  --bfile my_data \
  --outdir results/inspect \
  -profile docker

# Full QC with default thresholds
nextflow run snp_array_qc/main.nf \
  --bfile my_data \
  --chroms 1-22 \
  --outdir results/qc \
  -profile docker

# Full QC with custom thresholds
nextflow run snp_array_qc/main.nf \
  --bfile my_data \
  --sample_missingness 0.02 \
  --maf 0.01 \
  --hwe_p 1e-6 \
  --chroms 1-22 \
  --outdir results/qc \
  -profile docker

# With ancestry annotation
nextflow run snp_array_qc/main.nf \
  --bfile my_data \
  --reference_panel 1000G_hg38 \
  --run_ancestry_pca true \
  --chroms 1-22 \
  --outdir results/qc \
  -profile docker

# On HPC with SLURM + Singularity
nextflow run snp_array_qc/main.nf \
  --bfile /shared/data/genotypes \
  --outdir /scratch/results/qc \
  -profile slurm,singularity \
  -resume
```

---

For more details, see:
- [Setup Guide](setup.md)
- [SNP Array Manual](snp_array_qc_manual.md)
- [Example Outputs](example_outputs.md)
- [Benchmarks](BENCHMARKS.md)
