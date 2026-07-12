# SNP-Array Example

Back to [Examples](README.md), the [documentation index](../index.md), or the main [README](../../README.md).

## Step 1 - Inspect Your Data First

```bash
nextflow run snp_array_qc/inspect.nf \
  --bfile data/raw/genotypes \
  --outdir results/inspect \
  -profile docker
```

Open `results/inspect/inspect_report.html` in a browser. It shows the full distribution of every QC metric: missingness, MAF, HWE p-values, heterozygosity, pairwise IBD, and PCA, with the default thresholds marked.

The file `results/inspect/params_template.yaml` is pre-filled with all parameters and annotated with observed statistics from your dataset:

```yaml
sample_missingness: 0.02  # observed 95th pct=0.003, max=0.018; very clean; could tighten to 0.01
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

## Step 2 - Run QC

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

Full parameter reference: [SNP Array QC Manual](../snp_array_qc_manual.md).
