# Example Outputs

Back to the [documentation index](../index.md) or main [README](../../README.md).

ByeGenoQC smoke tests write small synthetic outputs under `results/`. These are useful for checking the shape of reports and tables without committing generated result directories to Git.

| Output | Smoke-test path | Notes |
|--------|-----------------|-------|
| SNP-array QC PDF report | `results/test_snp_full/06_report/qc_report.pdf` | Final report with attrition, thresholds, and QC summaries. |
| SNP attrition table | `results/test_snp_full/06_report/qc_attrition_table.tsv` | Per-step sample and variant retention/removal counts. |
| SNP thresholds table | `results/test_snp_full/06_report/qc_thresholds.tsv` | Parameters and thresholds used in the run. |
| WGS/WES HTML report | `results/test_vcf_variant_only/wgs_wes_final_report.html` | Sequencing entry-point report for VCF-mode toy data. |
| WGS/WES summary TSV | `results/test_vcf_variant_only/wgs_wes_qc_summary.tsv` | Machine-readable summary metrics from the VCF smoke test. |

To generate these files locally:

```bash
bash test_data/run_smoke_tests.sh
```

The smoke-test outputs are intentionally tiny and synthetic. They check that reports and core output files are produced, but they are not representative biological examples.
