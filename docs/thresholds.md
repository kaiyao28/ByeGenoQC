# Thresholds

Back to the [documentation index](index.md) or main [README](../README.md).

All thresholds have defaults and can be overridden on the command line or in a params file.

```bash
# SNP array
--maf 0.05  --hwe_p 1e-4  --sample_missingness 0.05

# Sequencing QC
--min_mean_depth_wgs 30  --max_contamination 0.02  --min_gq 30
```

For SNP arrays, the recommended workflow is inspect first, then filter:

```bash
nextflow run snp_array_qc/inspect.nf \
  --bfile data/raw/genotypes \
  --outdir results/inspect \
  -profile docker
```

Review `results/inspect/inspect_report.html` and edit `results/inspect/params_template.yaml` before running the full QC workflow. Thresholds should be reviewed in the context of study design, assay type, ancestry composition, and downstream analysis.

Detailed parameter descriptions are in the [SNP Array QC Manual](snp_array_qc_manual.md) and [WGS/WES QC Manual](wgs_wes_qc_manual.md).
