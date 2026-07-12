# Sequencing Entry-Point Examples

Back to [Examples](README.md), the [documentation index](../index.md), or the main [README](../../README.md).

## FASTQ Input: Raw-Read QC Only

FASTQ mode validates input files and runs FastQC when `--run_sample_qc true`. It does not align reads or call variants.

```bash
nextflow run wgs_wes_qc/main.nf \
  --input_type fastq \
  --samplesheet samplesheet.csv \
  --reference_fasta /data/reference/GRCh38.fa \
  --mode wgs \
  --outdir results/fastq_qc \
  -profile docker
```

## BAM/CRAM Input: Aligned-Read Sample QC

BAM/CRAM mode expects already aligned and indexed files. It can run alignment metrics, duplicate metrics, coverage QC, contamination estimation, and sex check. It does not call variants.

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

## VCF Input: Variant And Genotype QC

VCF mode expects called variants. It can run variant statistics/filtering, merge chromosome-scoped VCFs, sample genotype counts, relatedness, and ancestry PCA. It does not perform read-level QC.

```bash
nextflow run wgs_wes_qc/main.nf \
  --input_type vcf \
  --samplesheet samplesheet.csv \
  --reference_fasta /data/reference/GRCh38.fa \
  --mode wgs \
  --run_variant_qc true \
  --outdir results/vcf_qc \
  -profile docker
```

## Samplesheet Columns

All WGS/WES entry points use CSV samplesheets with a required unique, non-empty `sample` column. Quoted CSV fields are supported.

| `--input_type` | Accepted input columns |
|----------------|------------------------|
| `fastq` | `file1` or `fastq1`; optional read 2 in `file2` or `fastq2` |
| `bam` | `file1` or `bam`; optional index in `file2`, `index`, or `bai` |
| `cram` | `file1`, `cram`, or legacy `bam`; optional index in `file2`, `index`, or `crai` |
| `vcf` | `file1` or `vcf` |

BAM/CRAM indexes are required. If no explicit index column is provided, the workflow checks standard `.bai` or `.crai` paths next to the alignment file. Rows with columns populated for a different `--input_type` fail validation to avoid ambiguous interpretation.

Full parameter reference: [WGS/WES QC Manual](../wgs_wes_qc_manual.md).
