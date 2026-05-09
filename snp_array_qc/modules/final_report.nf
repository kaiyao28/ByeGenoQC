/*
================================================================================
  MODULE: FINAL_REPORT (SNP Array)
================================================================================
  Purpose:
    Aggregate per-step SNP-array QC summaries into one PDF report and TSVs.

  Approach:
    1. Write a small _params.R file with pipeline-specific values.
    2. Stage the R Markdown template (snp_array_qc_report.Rmd) into the
       work directory.
    3. Call rmarkdown::render() to knit the Rmd to a PDF.

  All data processing and report logic lives inside the Rmd — zero Groovy
  string escaping issues since the template is a static file.

  Requirements (Docker image or conda env):
    - R >= 4.2
    - r-rmarkdown, r-knitr
    - pandoc
    - tinytex (or any LaTeX distribution) for PDF output

  Output:
    - qc_report.pdf             : PDF report with tables and all QC plots
    - qc_attrition_table.tsv    : step-by-step variant/sample attrition
    - qc_thresholds.tsv         : all pipeline thresholds used
    - qc_per_sample.tsv         : per-sample QC flags (sample QC only)
    - qc_per_batch.tsv          : per-batch summary (sample QC only)
================================================================================
*/

process FINAL_REPORT {
    label 'process_report'
    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(bed), path(bim), path(fam)
    path summary_files
    path excluded_samples
    path excluded_variants
    path plot_files      // collected PNGs from all QC modules; may be empty list
    path qc_data_files   // raw per-sample QC data files (imiss/het/sexcheck/removal lists)
    val  qc_scope
    path report_rmd      // staged snp_array_qc_report.Rmd

    output:
    path "qc_report.pdf",          emit: report
    path "qc_attrition_table.tsv", emit: attrition
    path "qc_thresholds.tsv",      emit: thresholds
    path "qc_per_sample.tsv",      optional: true, emit: per_sample
    path "qc_per_batch.tsv",       optional: true, emit: per_batch

    script:
    """
    # ── Write pipeline parameters for the R Markdown template ──────────────────
    # Unquoted heredoc: Groovy interpolates \${...} before bash sees the block.
    # Keep values simple (no special chars) — all threshold params are numbers,
    # booleans, or short strings.
    cat > _params.R << EOF
dataset_id          <- "${meta.id}"
qc_scope            <- "${qc_scope}"
chroms              <- "${params.chroms}"
final_fam           <- "${fam}"
final_bim           <- "${bim}"
run_variant_qc      <- "${params.run_variant_qc}"
run_sample_qc       <- "${params.run_sample_qc}"
sample_missingness  <- ${params.sample_missingness}
variant_missingness <- ${params.variant_missingness}
hwe_p               <- ${params.hwe_p}
hwe_p_chrx          <- "${params.hwe_p_chrx}"
maf                 <- ${params.maf}
heterozygosity_sd   <- ${params.heterozygosity_sd}
relatedness_pi_hat  <- ${params.relatedness_pi_hat}
sex_f_female        <- ${params.sex_check_f_lower_female}
sex_f_male          <- ${params.sex_check_f_upper_male}
pca_outlier_sd      <- ${params.pca_outlier_sd}
cc_miss_p           <- "${params.cc_miss_p}"
ld_regions          <- "${params.ld_regions}"
reference_panel     <- "${params.reference_panel}"
EOF

    echo "Rendering QC PDF report for dataset: ${meta.id}"

    # ── Render R Markdown → PDF ─────────────────────────────────────────────────
    Rscript -e "
      rmarkdown::render(
        '${report_rmd}',
        output_file = 'qc_report.pdf',
        output_dir  = '.',
        quiet       = FALSE
      )
    "

    echo "PDF report written: qc_report.pdf"
    """
}
