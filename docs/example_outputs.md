# Example Outputs

This page shows what to expect when ByeGenoQC completes successfully. Reports are self-contained HTML files ready to share or include in publications.

---

## SNP Array QC Report

**File:** `results/test_snp_variant_only/final_report.html`

The SNP array report summarizes variant-level and sample-level quality control on PLINK binary data.

### Report Sections

#### 1. Executive Summary

Shows the final count of:
- **Samples retained** and **samples excluded**
- **Variants retained** and **variants excluded**
- **Total attrition** (% of data removed)

Example:
```
Input:        1000 samples, 500,000 variants
Output:        950 samples, 487,203 variants
Attrition:      50 samples (5%), 12,797 variants (2.6%)
```

#### 2. Per-Step Attrition Table

A detailed breakdown of how many samples and variants were removed at each QC filter:

| Step | Samples Excluded | Variants Excluded | Reason |
|------|------------------|-------------------|--------|
| Duplicate check | 2 | 0 | Identical genotype calls |
| Missingness | 5 | 2,104 | >2% missing calls |
| HWE | 0 | 1,890 | p < 1e-6, control-sample departure |
| MAF | 0 | 8,803 | MAF < 0.01 |
| Sex check | 15 | 0 | Reported sex vs genotype mismatch |
| Heterozygosity | 20 | 0 | >3 SD from mean (potential contamination) |
| Relatedness | 8 | 0 | π̂ > 0.1875 (duplicates/relatives) |
| Ancestry PCA | 0 | 0 | Within 6 SD on all PCs |
| **Final** | **50** | **12,797** | |

This table shows exactly what your data quality is and where filtering is most aggressive.

#### 3. QC Metrics and Plots

Visual summaries of key QC metrics:
- **Missingness distribution** — per-sample and per-variant call rates
- **Heterozygosity distribution** — identifies potential contamination or sample swaps
- **Allele frequency spectrum** — MAF distribution before and after filtering
- **PCA biplot** — ancestry components (if reference panel provided)
- **Relatedness matrix** — kinship estimates between sample pairs

#### 4. Thresholds Used

A reference table recording every parameter that was applied:

```
Parameter              Value   Rationale
─────────────────────────────────────────
Variant missingness    0.02    >2% missing calls removed
HWE p-value            1e-6    Standard GWAS threshold
MAF threshold          0.01    Common-variant analysis
Heterozygosity SD      3       3σ outlier cutoff
Relatedness (π̂)       0.1875  Between 2nd and 3rd-degree relatives
Sample missingness     0.02    >2% per-sample missing calls
Sex check F bounds     [0.2, 0.8]  Female < 0.2, Male > 0.8
PCA outlier SD         6       6σ on any PC
```

This is copy-paste ready for your methods section.

#### 5. Notes

Flags any caveats:
- Whether sample-level QC is **final** (all 22 autosomes) or **provisional** (subset of chromosomes)
- Any modules that were skipped (e.g., `run_sex_check false`)

---

## WGS/WES QC Report

**File:** `results/test_vcf_variant_only/wgs_wes_final_report.html`

The WGS/WES report summarizes quality control on sequence data (BAM/CRAM/VCF).

### Report Structure

A phased view of the QC workflow, showing which steps ran and their results.

#### 1. Input Validation

```
Status: PASS
─────────────────────────────────────
Input type:     VCF
Reference:      GRCh38 (hg38)
Samples:        95
Variants:       5,712,341
Mean depth:     32.1x (WES: 34.2x on-target)
```

#### 2. Variant-Level QC Results

Per-variant filtering metrics:

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Ti/Tv ratio | 2.07 | >2.0 | PASS |
| SNPs | 4,812,301 | — | — |
| Indels | 891,204 | — | — |
| Singletons | 234,567 | — | — |
| Filter PASS | 4,893,105 | >85% | PASS |

Interpreting the metrics:
- **Ti/Tv = 2.07:** Transition/transversion ratio. For human exomes, 2.0–2.5 is normal. <2.0 suggests contamination; >3.0 suggests relaxed filtering.
- **PASS variants:** Fraction of variants not marked FILTER != PASS (low values suggest aggressive hard filtering).

#### 3. Sample-Level QC Metrics

Per-sample coverage, contamination, and duplication:

| Sample | Mean Depth | On-Target 20x | Contamination | Duplication | Call Rate | Status |
|--------|-----------|----------------|----------------|-------------|-----------|--------|
| SAMPLE_001 | 34.5 | 96.2% | 0.008 | 8.5% | 0.994 | PASS |
| SAMPLE_002 | 28.1 | 92.1% | 0.015 | 12.3% | 0.991 | PASS |
| SAMPLE_003 | 18.5 | 78.3% | 0.042 | 22.1% | 0.988 | WARN |
| ... | ... | ... | ... | ... | ... | ... |

**Interpreting columns:**
- **Mean Depth:** Coverage (WES: on-target; WGS: genome-wide). Low depth (<20x) may reduce variant calls.
- **On-Target 20x:** Fraction of target bases (WES) or genome (WGS) covered ≥20x. gnomAD uses this as a primary filter.
- **Contamination:** Cross-sample contamination (VerifyBamID2 or GATK). >0.03 warrants review.
- **Duplication:** PCR duplicate rate. >0.20 is high and reduces effective coverage.
- **Call Rate:** Fraction of genotypes passing quality filters. <0.95 is low.

#### 4. Genotype Filtering Details

Shows the QC applied to individual genotypes:

```
Genotype quality filter:  GQ >= 20
Genotype depth filter:    DP >= 10
Site-level QUAL filter:   QUAL >= 30
Result:  4,512,230 variants; 423 samples with ≥95% genotypes retained
```

#### 5. Thresholds Applied

All filtering thresholds used, ready to cite:

```
Parameter                Value    Source
──────────────────────────────────────────
Min mean depth (WES)     30x      gnomAD baseline
Min on-target coverage   80%      common practice
Max contamination        3%       gnomAD v4
Min call rate            95%      GATK Best Practices
Genotype GQ threshold    20       GATK Best Practices
Genotype DP threshold    10       GATK Best Practices
Variant QUAL threshold   30       GATK hard-filter mode
SNP filter thresholds:
  QD >= 2.0, FS < 60, MQ >= 40, etc.
```

#### 6. PCA Results

If ancestry PCA was run:
- **Samples by ancestry cluster** — projection onto PC1 and PC2
- **PCA outliers flagged** — samples >6 SD from the mean on any PC
- **Reference panel** — if included, shows study samples vs reference populations (e.g., 1000 Genomes)

#### 7. Sample-Level QC Status

```
Sample-level QC scope:   FINAL (all 22 autosomes analysed)
Samples for inclusion:   423 / 423 PASS
Samples flagged:         2 (high contamination)
```

Important: If fewer than all 22 autosomes were analysed, the report will mark sample-level QC as **PROVISIONAL** and recommend caution before using for downstream analysis.

---

## Inspect Workflow Report

**File:** `results/inspect/inspect_report.html` (SNP array only)

The inspect workflow runs on raw data to help you choose appropriate thresholds **before** filtering.

It generates:
- Distribution plots of each QC metric on your data
- A template parameter file (`params_template.yaml`) with suggested cutoffs
- Sample-level summaries showing which samples might be outliers

**Use case:** Run this first on your dataset, review the metrics, adjust thresholds if needed, then run `main.nf`.

---

## Output File Structure

### SNP Array QC

```
results/test_snp_variant_only/
├── final_report.html              # Main report (open in browser)
├── qc_attrition_table.tsv         # Machine-readable attrition summary
├── qc_thresholds.tsv              # Parameters used
├── plink_filtered.bed/bim/fam     # Filtered PLINK binary (if keep_intermediate=true)
└── logs/                          # Nextflow logs per process
```

### WGS/WES QC

```
results/test_vcf_variant_only/
├── wgs_wes_final_report.html      # Main report (open in browser)
├── wgs_wes_qc_summary.tsv         # Sample-level QC metrics
├── wgs_wes_thresholds.tsv         # Parameters used
├── filtered.vcf.gz                # Filtered VCF (if run_variant_filtering=true)
├── sample_qc_flags.tsv            # Per-sample QC status (PASS/FAIL)
└── logs/                          # Nextflow logs per process
```

---

## Tips for Using Reports

1. **Share the HTML reports** — they are self-contained and don't require internet
2. **Cite the thresholds section** — copy-paste directly into your methods
3. **Check the attrition table** — understand where your data quality is weakest
4. **Use inspect workflow first** — especially for large or unfamiliar datasets
5. **Review flags** — sample-level QC is provisional if not all autosomes were included
6. **Save as PDF** — print to PDF from your browser for archival

---

## Report Customization

All reports are generated in HTML with embedded CSS and can be customized. If you need to:
- **Change thresholds:** Update parameters and re-run (reports will regenerate)
- **Export data:** Download the `.tsv` files (attrition, thresholds, sample metrics)
- **Modify styling:** Edit the report template (contact maintainers)

---

## Troubleshooting

**Report not generated?**
- Check `--run_final_report true` is set
- Verify the workflow completed without errors (check `.nextflow.log`)
- Ensure `results/` directory has write permissions

**Report looks empty?**
- The pipeline may have failed before the report step; check the logs
- Verify your input data is valid

**Can't open HTML in browser?**
- Some browsers block local file access; use `python -m http.server 8000` to serve locally
- Or save the HTML to a web server

---

For questions, see the [SNP Array Manual](snp_array_qc_manual.md) or [WGS/WES Manual](wgs_wes_qc_manual.md).
