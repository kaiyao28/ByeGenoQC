# Input Validation Guide

This guide explains what valid input looks like for each ByeGenoQC workflow, including file formats, samplesheet specifications, and common pitfalls.

---

## SNP Array QC

### PLINK Binary Format

ByeGenoQC accepts PLINK 1.9 binary format (`.bed`, `.bim`, `.fam`).

**Required files:**
```
data/raw/genotypes.bed     # Binary genotype file (required)
data/raw/genotypes.bim     # SNP metadata (required)
data/raw/genotypes.fam     # Sample metadata (required)
```

**What is a valid PLINK binary?**

PLINK files must:
- Be in **little-endian binary format** (standard; use `plink --file text_data --make-bed` to convert)
- Have matching sample counts in `.fam` and `.bed`
- Have matching variant counts in `.bim` and `.bed`
- Use **biallelic SNPs only** (multiallelic sites will cause errors)
- Have valid chromosome codes (1-22, X, Y, MT; or chr1-chr22, chrX, chrY, chrMT)

**Checking your files:**
```bash
# List file sizes (bed should be ~nsamples*nvariants/4 bytes)
ls -lh genotypes.bed genotypes.bim genotypes.fam

# Check for invalid chromosomes
cut -f1 genotypes.bim | sort -u

# Count samples and variants
wc -l genotypes.fam genotypes.bim
```

### Input Parameters

```bash
nextflow run snp_array_qc/main.nf \
  --bfile data/raw/genotypes    # prefix (no extension)
  --chroms 1-22                 # optional; default: all in data
  --outdir results/snp_qc       # output directory
  -profile docker
```

**Parameters explained:**

| Parameter | Type | Example | Notes |
|-----------|------|---------|-------|
| `bfile` | string | `data/raw/genotypes` | Prefix only; no `.bed/.bim/.fam` extension |
| `chroms` | string | `1-22` or `1,2,22` | Subset chromosomes for faster testing; omit to use all |
| `pheno` | string (optional) | `data/phenotypes.tsv` | TSV with columns: FID, IID, pheno |
| `reference_panel` | string (optional) | `ref_panels/1000G/1000G_hg38` | For ancestry PCA |
| `sample_metadata` | string (optional) | `data/sample_info.tsv` | Reported sex, batch, center |

### Optional Inputs

**Phenotype file** (for covariate QC):
```
FID IID pheno
1   1_1 1
1   1_2 2
2   2_1 1
```

**Sample metadata file**:
```
FID IID reported_sex batch centre
1   1_1 F           batch1 center_a
1   1_2 M           batch1 center_a
2   2_1 F           batch2 center_b
```

**Reference panel** (for PCA):
- Same PLINK binary format as input
- Should contain many unrelated individuals from known populations
- Example: 1000 Genomes in GRCh38 coordinates
- Variants are merged with your data; must use same genome build

---

## WGS/WES QC

### Input Types

ByeGenoQC supports multiple input data types. Choose one:

#### 1. BAM/CRAM Files (Recommended for full QC)

**Required files:**
```
data/bam/sample_001.bam        # or .cram
data/bam/sample_001.bam.bai    # index (required)
data/bam/sample_002.bam
data/bam/sample_002.bam.bai
```

**Samplesheet format** (`samplesheet.csv`):
```csv
sample,file1
sample_001,data/bam/sample_001.bam
sample_002,data/bam/sample_002.bam
sample_003,data/bam/sample_003.cram
```

**Requirements:**
- BAM/CRAM **must be indexed** (`.bam.bai` or `.cram.crai`)
- **Coordinate-sorted** (not query-sorted)
- Must have **read groups** with sample information
- Can be **gzip-compressed** or uncompressed

**Checking your BAM files:**
```bash
# Check if indexed
samtools index -c sample_001.bam

# Check coordinate order
samtools view sample_001.bam | head -1

# Check read groups
samtools view -H sample_001.bam | grep "@RG"
```

#### 2. VCF Files (Variant QC only; skips sample-level metrics)

**Required files:**
```
data/vcf/cohort.vcf.gz      # bgzip-compressed VCF
data/vcf/cohort.vcf.gz.tbi  # tabix index (required)
```

**Samplesheet format**:
```csv
sample,file1
sample_001,data/vcf/cohort.vcf.gz
```

**Requirements:**
- **Must be bgzip-compressed** and **tabix-indexed**
- **Biallelic sites only** (split multiallelic with bcftools)
- Samples must match column headers in VCF
- Variants should be **normalized** (e.g., `bcftools norm`)

**Preparing a VCF:**
```bash
# Split multiallelic sites
bcftools norm -m -any -o cohort_split.vcf.gz cohort.vcf.gz

# Index
tabix -p vcf cohort_split.vcf.gz

# Normalize
bcftools norm -f ref.fa -o cohort_norm.vcf.gz cohort_split.vcf.gz
tabix -p vcf cohort_norm.vcf.gz
```

#### 3. FASTQ Files (Full pipeline; alignment required)

**Not yet supported**. ByeGenoQC currently requires pre-aligned BAM/CRAM. If you have FASTQ:
1. Align to reference (BWA, Bowtie2, etc.)
2. Sort and index BAM
3. Use BAM as input

---

### Samplesheet Format

**For BAM/CRAM input:**
```csv
sample,file1
SAMPLE_001,/absolute/path/to/sample_001.bam
SAMPLE_002,/absolute/path/to/sample_002.bam
```

**For VCF input:**
```csv
sample,file1
cohort,/absolute/path/to/cohort.vcf.gz
```

**Rules:**
- Column headers must be exactly `sample,file1`
- Use **absolute paths** (not relative)
- Sample names must match VCF column headers (if using VCF)
- No spaces in sample names
- One sample per line (BAM/CRAM); one cohort per VCF

### Reference Genome

**Required for BAM/CRAM input:**
```bash
--reference_fasta /path/to/GRCh38.fa
```

Must include:
- FASTA file with complete genome sequence
- `.fai` index (create with `samtools faidx GRCh38.fa`)
- **Same genome build** as your BAM files (typically hg38/GRCh38)

**Example:**
```bash
# Prepare reference
curl -O ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.39_GRCh38.p13/GCA_000001405.39_GRCh38.p13_genome.fna.gz
gunzip GCA_000001405.39_GRCh38.p13_genome.fna.gz
samtools faidx GCA_000001405.39_GRCh38.p13_genome.fna

# Use in pipeline
nextflow run wgs_wes_qc/main.nf \
  --reference_fasta GCA_000001405.39_GRCh38.p13_genome.fna \
  ...
```

### Target Intervals (WES only)

**Required for WES; optional for WGS:**
```bash
--target_intervals /path/to/exome_targets.bed
```

BED format (0-based, half-open):
```
chr1	1000	2000
chr1	3000	4500
chr2	5000	8000
```

**Creating from capture kit coordinates:**
```bash
# Example: Agilent SureSelect
# Download from Agilent, convert if needed
bedtools merge -i agilent_targets.bed > exome_targets.bed
```

**Checking:**
```bash
# Count target bases
awk '{sum += $3-$2} END {print sum}' exome_targets.bed
# Should be ~30-100 Mb for typical exome
```

---

### WGS/WES Input Parameters

```bash
nextflow run wgs_wes_qc/main.nf \
  --input_type bam                    # bam | cram | vcf
  --samplesheet samplesheet.csv       # CSV with sample,file1
  --reference_fasta ref.fa            # with .fai index
  --target_intervals targets.bed      # WES only
  --mode wes                          # wes | wgs
  --chroms 1-22                       # optional subset
  --outdir results/wgs_wes_qc         # output directory
  -profile docker
```

**Parameters explained:**

| Parameter | Type | Required? | Example |
|-----------|------|-----------|---------|
| `input_type` | string | Yes | `bam`, `cram`, or `vcf` |
| `samplesheet` | string | Yes | `samplesheet.csv` |
| `reference_fasta` | string | Yes (BAM/CRAM) | `GRCh38.fa` |
| `target_intervals` | string | Yes (WES BAM/CRAM) | `exome_targets.bed` |
| `mode` | string | Yes | `wes` or `wgs` |
| `chroms` | string | No | `1-22` |
| `gene_bed` | string | No | `ensembl_genes.bed` |

---

## Common Errors and Fixes

### SNP Array

**Error: "genotypes.bed: No such file or directory"**
- Cause: You specified `--bfile genotypes.bed` instead of `--bfile genotypes`
- Fix: Use the **prefix only** (no extension)

**Error: "bed file has wrong number of variants"**
- Cause: `.bim` and `.bed` are out of sync
- Fix: Recreate from text format: `plink --file data --make-bed --out data_clean`

**Error: "Invalid chromosome code"**
- Cause: `.bim` has non-standard chromosome labels
- Fix: Recode: `plink --bfile data --make-bed --out data --chr-set 22`

### WGS/WES

**Error: "BAM/CRAM file is not indexed"**
- Cause: Missing `.bam.bai` or `.cram.crai` file
- Fix: `samtools index sample.bam` or `samtools index sample.cram`

**Error: "sample names in samplesheet do not match VCF"**
- Cause: Samplesheet `SAMPLE_001` doesn't match VCF column `sample_001`
- Fix: List VCF columns with `bcftools query -l cohort.vcf.gz`; ensure samplesheet matches exactly

**Error: "reference index not found"**
- Cause: Missing `.fai` file
- Fix: `samtools faidx GRCh38.fa` to create index

**Error: "target intervals file is empty or invalid"**
- Cause: BED format error (wrong delimiter, invalid coordinates)
- Fix: Check: `head targets.bed` and verify 3 columns, tab-delimited, 0-based

---

## Data Quality Expectations

**Typical SNP array:**
- 500K–2.5M variants
- 100–10,000 samples
- File size: ~50 MB per 1000 samples

**Typical WES:**
- 4–8M variants
- 50–1000 samples
- 30x mean coverage
- File size: ~10–50 GB per sample (BAM)

**Typical WGS:**
- 3–5M variants
- 10–100 samples
- 20–40x mean coverage
- File size: ~50–150 GB per sample (BAM)

If your data is much smaller or larger, double-check:
- Correct genome build?
- Correct input format?
- Did filtering already happen upstream?

---

## Next Steps

Once you've validated your input:

**SNP array:**
```bash
# First run inspect to see metric distributions
nextflow run snp_array_qc/inspect.nf --bfile data/genotypes --outdir results/inspect

# Review results/inspect/params_template.yaml
# Then run main workflow with adjusted thresholds if needed
nextflow run snp_array_qc/main.nf --bfile data/genotypes --outdir results/snp_qc -profile docker
```

**WGS/WES:**
```bash
# Run directly (no inspect workflow for sequencing)
nextflow run wgs_wes_qc/main.nf \
  --input_type bam \
  --samplesheet samplesheet.csv \
  --reference_fasta GRCh38.fa \
  --target_intervals targets.bed \
  --mode wes \
  --outdir results/wgs_wes_qc \
  -profile docker
```

For more details, see [SNP Array Manual](snp_array_qc_manual.md) or [WGS/WES Manual](wgs_wes_qc_manual.md).
