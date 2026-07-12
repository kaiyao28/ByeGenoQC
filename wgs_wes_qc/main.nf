#!/usr/bin/env nextflow
/*
================================================================================
  Sequencing QC entry points - main.nf
================================================================================
  Workflow phases:
    01  Input validation
    02  VCF-level QC       (chromosome-scoped QC/filtering for called variants)
    03  Input-specific QC  (FASTQ read QC, BAM/CRAM sample QC, or VCF genotype QC)
    04  Final report
================================================================================
*/

nextflow.enable.dsl = 2

include { CHECK_VERSIONS        } from '../modules/check_versions'
include { INPUT_CHECK           } from './modules/input_check'
include { FASTQC                } from './modules/fastqc'
include { ALIGNMENT_METRICS     } from './modules/alignment_metrics'
include { DUPLICATE_METRICS     } from './modules/duplicate_metrics'
include { COVERAGE_QC           } from './modules/coverage_qc'
include { CONTAMINATION_CHECK   } from './modules/contamination_check'
include { SEX_CHECK             } from './modules/sex_check'
include { VARIANT_CALLING_QC    } from './modules/variant_calling_qc'
include { VARIANT_FILTERING     } from './modules/variant_filtering'
include { SELECT_CHROMOSOME     } from './modules/select_chromosome'
include { INDEX_CHROM_VCF       } from './modules/index_chrom_vcf'
include { INDEX_INPUT_VCF       } from './modules/index_input_vcf'
include { SAMPLE_VARIANT_COUNTS } from './modules/sample_variant_counts'
include { RELATEDNESS           } from './modules/relatedness'
include { PCA_VARIANT_SELECTION } from './modules/pca_variant_selection'
include { ANCESTRY_PCA          } from './modules/ancestry_pca'
include { MERGE_CHROMOSOMES     } from './modules/merge_chromosomes'
include { FINAL_REPORT          } from './modules/final_report'

def parseChroms(chrom_param) {
    def param = chrom_param.toString()
    if (param == "all") return (1..22).collect { it.toString() }
    if (param =~ /^\d+-\d+$/) {
        def (s, e) = param.split('-').collect { it.toInteger() }
        return (s..e).collect { it.toString() }
    }
    if (param =~ /,/) return param.split(',')*.trim()
    return [param.trim()]
}

def effectiveScope(chrom_param, declared_scope) {
    if (declared_scope != "auto") return declared_scope
    def chroms = parseChroms(chrom_param)
    def all22 = (1..22).every { n -> chroms.contains(n.toString()) || chroms.contains("chr${n}") }
    return all22 ? "genome_wide" : "provisional"
}

def validateParams() {
    if (!params.samplesheet) error "ERROR: --samplesheet is required."
    if (!params.reference_fasta) error "ERROR: --reference_fasta is required."
    if (params.mode == "wes" && !params.target_intervals) {
        error "ERROR: --target_intervals is required when --mode wes"
    }
    if (!["fastq","bam","cram","vcf"].contains(params.input_type)) {
        error "ERROR: --input_type must be one of: fastq, bam, cram, vcf"
    }
    if (!["auto","genome_wide","provisional","skip"].contains(params.sample_qc_scope)) {
        error "ERROR: --sample_qc_scope must be one of: auto, genome_wide, provisional, skip"
    }
    if (!file(params.samplesheet).exists()) {
        error "ERROR: samplesheet does not exist: ${params.samplesheet}"
    }
    if (!file(params.samplesheet).text.trim()) {
        error "ERROR: samplesheet is empty: ${params.samplesheet}"
    }
}

def cell(row, col) {
    return row.containsKey(col) && row[col] != null ? row[col].toString().trim() : ""
}

def populated(row, cols) {
    return cols.findAll { col -> cell(row, col) }
}

def chooseOne(row, cols, label, row_number) {
    def present = populated(row, cols)
    if (!present) return ""

    def values = present.collect { col -> cell(row, col) }.unique()
    if (values.size() > 1) {
        error "ERROR: samplesheet row ${row_number} has ambiguous ${label} columns (${present.join(', ')}). Use only one of: ${cols.join(', ')}"
    }
    return values[0]
}

def requireExistingFile(path_value, label, row_number) {
    if (!path_value) {
        error "ERROR: samplesheet row ${row_number} is missing ${label}"
    }
    if (!file(path_value).exists()) {
        error "ERROR: samplesheet row ${row_number} ${label} does not exist: ${path_value}"
    }
    return path_value
}

def inferAlignmentIndex(alignment_path, input_type, row_number) {
    def candidates = []
    if (input_type == "bam") {
        candidates = [
            "${alignment_path}.bai",
            alignment_path.toString().replaceFirst(/\.bam$/, ".bai")
        ]
    } else {
        candidates = [
            "${alignment_path}.crai",
            alignment_path.toString().replaceFirst(/\.cram$/, ".crai")
        ]
    }

    def index_path = candidates.find { candidate -> file(candidate).exists() }
    if (!index_path) {
        error "ERROR: samplesheet row ${row_number} ${input_type.toUpperCase()} index does not exist. Checked: ${candidates.unique().join(', ')}"
    }
    return index_path
}

def failIfOtherInputColumnsPopulated(row, allowed_cols, input_type, row_number) {
    def input_cols = ["file1", "file2", "fastq1", "fastq2", "bam", "cram", "vcf", "index", "bai", "crai"]
    def disallowed = input_cols.findAll { col -> !allowed_cols.contains(col) && cell(row, col) }
    if (disallowed) {
        error "ERROR: samplesheet row ${row_number} contains columns for another input type while --input_type ${input_type}: ${disallowed.join(', ')}"
    }
}

def validateSamplesheetRows(rows, input_type, samplesheet_path) {
    if (!rows || rows.isEmpty()) {
        error "ERROR: samplesheet has no data rows: ${samplesheet_path}"
    }

    if (rows.any { row -> row.containsKey(null) || row.containsKey("") }) {
        error "ERROR: samplesheet has malformed rows or blank column names: ${samplesheet_path}"
    }

    def header = rows.collectMany { row -> row.keySet() }
        .collect { col -> col.toString().trim() }
        .findAll { col -> col }
        .toSet()
    if (!header.contains("sample")) {
        error "ERROR: samplesheet is missing required column: sample"
    }

    def required_any = [
        fastq: ["file1", "fastq1"],
        bam  : ["file1", "bam"],
        cram : ["file1", "cram", "bam"],
        vcf  : ["file1", "vcf"]
    ][input_type]
    if (!required_any.any { col -> header.contains(col) }) {
        error "ERROR: samplesheet for --input_type ${input_type} must include one of these columns: ${required_any.join(', ')}"
    }

    def seen = [] as Set
    def normalized = []

    rows.eachWithIndex { row, idx ->
        def row_number = idx + 2
        def sample_id = cell(row, "sample")
        if (!sample_id) {
            error "ERROR: samplesheet row ${row_number} has an empty sample ID"
        }
        if (seen.contains(sample_id)) {
            error "ERROR: samplesheet contains duplicate sample ID: ${sample_id}"
        }
        seen << sample_id

        if (input_type == "fastq") {
            failIfOtherInputColumnsPopulated(row, ["file1", "file2", "fastq1", "fastq2"], input_type, row_number)
            def r1 = chooseOne(row, ["file1", "fastq1"], "FASTQ R1", row_number)
            def r2 = chooseOne(row, ["file2", "fastq2"], "FASTQ R2", row_number)
            requireExistingFile(r1, "FASTQ R1", row_number)
            if (r2) requireExistingFile(r2, "FASTQ R2", row_number)
            normalized << [sample: sample_id, file1: r1, file2: r2]
        } else if (input_type in ["bam", "cram"]) {
            def alignment_cols = input_type == "bam" ? ["file1", "bam"] : ["file1", "cram", "bam"]
            def index_cols = ["file2", "index", "bai", "crai"]
            failIfOtherInputColumnsPopulated(row, (alignment_cols + index_cols), input_type, row_number)
            def alignment = chooseOne(row, alignment_cols, "${input_type.toUpperCase()} input", row_number)
            requireExistingFile(alignment, "${input_type.toUpperCase()} input", row_number)
            def explicit_index = chooseOne(row, index_cols, "${input_type.toUpperCase()} index", row_number)
            def index_path = explicit_index ? requireExistingFile(explicit_index, "${input_type.toUpperCase()} index", row_number) : inferAlignmentIndex(alignment, input_type, row_number)
            normalized << [sample: sample_id, file1: alignment, file2: index_path]
        } else {
            failIfOtherInputColumnsPopulated(row, ["file1", "vcf"], input_type, row_number)
            def vcf = chooseOne(row, ["file1", "vcf"], "VCF input", row_number)
            requireExistingFile(vcf, "VCF input", row_number)
            normalized << [sample: sample_id, file1: vcf]
        }
    }

    return normalized
}

workflow {
    validateParams()

    def chrom_list = parseChroms(params.chroms)
    def scope = effectiveScope(params.chroms, params.sample_qc_scope)

    ch_samples = Channel
        .fromPath(params.samplesheet, checkIfExists: true)
        .splitCsv(header: true, strip: true)
        .filter { row -> row.values().any { value -> value != null && value.toString().trim() } }
        .collect()
        .map { rows -> validateSamplesheetRows(rows, params.input_type, params.samplesheet) }

    CHECK_VERSIONS()

    log.info """
    ================================================================
    Sequencing QC entry points
    ================================================================
    Mode              : ${params.mode.toUpperCase()}
    Input type        : ${params.input_type}
    Samplesheet       : ${params.samplesheet}
    Reference FASTA   : ${params.reference_fasta}
    Target intervals  : ${params.target_intervals ?: 'N/A'}
    Output dir        : ${params.outdir}
    Chromosomes       : ${params.chroms}
    ----------------------------------------------------------------
    Phase switches
      VCF-level QC        : ${params.run_variant_qc}
      Input-specific QC   : ${params.run_sample_qc}
      Sample QC scope     : ${scope}${scope == 'provisional' ? '  *** PROVISIONAL - not all autosomes ***' : ''}
    ----------------------------------------------------------------
    Variant-level modules
      Variant calling QC  : ${params.run_variant_calling_qc}
      Variant filtering   : ${params.run_variant_filtering}
    ----------------------------------------------------------------
    Sample-level modules
      FastQC              : ${params.run_fastqc}
      Alignment metrics   : ${params.run_alignment_metrics}
      Duplicate metrics   : ${params.run_duplicate_metrics}
      Coverage QC         : ${params.run_coverage_qc}
      Contamination       : ${params.run_contamination}
      Sex check           : ${params.run_sex_check_wgs}
      Sample counts       : ${params.run_sample_variant_counts}
      Relatedness         : ${params.run_relatedness_wgs}
      Ancestry PCA        : ${params.run_ancestry_pca_wgs}
    ================================================================
    """.stripIndent()

    ch_fasta = Channel.value(file(params.reference_fasta))
    ch_intervals = params.target_intervals ? Channel.value(file(params.target_intervals)) : Channel.value([])
    ch_ref_panel = params.reference_panel ? Channel.value(params.reference_panel) : Channel.value([])

    ch_bam = Channel.empty()
    ch_fastq = Channel.empty()
    ch_vcf = Channel.empty()
    ch_input_check = Channel.empty()

    if (params.input_type in ["bam","cram"]) {
        ch_bam = ch_samples.flatMap { rows -> rows }.map { row ->
            def meta = [id: row.sample, input_type: params.input_type, mode: params.mode]
            [meta, file(row.file1), file(row.file2)]
        }
        ch_input_check = ch_bam
    } else if (params.input_type == "fastq") {
        ch_fastq = ch_samples.flatMap { rows -> rows }.map { row ->
            def meta = [id: row.sample, input_type: params.input_type, mode: params.mode]
            def r1 = file(row.file1)
            def r2 = row.file2 ? file(row.file2) : []
            [meta, r1, r2]
        }
        ch_input_check = ch_fastq
    } else {
        ch_vcf = ch_samples.flatMap { rows -> rows }.map { row ->
            def meta = [id: row.sample, input_type: params.input_type, mode: params.mode]
            [meta, file(row.file1)]
        }
        ch_input_check = ch_vcf.map { meta, vcf -> [meta, vcf, []] }
    }

    ch_qc_summaries = Channel.empty()
    ch_merged_vcf = Channel.empty()

    // PHASE 1 - Input validation
    INPUT_CHECK(ch_input_check, ch_fasta, ch_intervals)
    ch_qc_summaries = ch_qc_summaries.mix(INPUT_CHECK.out.summary)

    // PHASE 2 - Variant-level QC
    if (params.run_variant_qc && params.input_type == "vcf") {
        ch_vcf_by_chrom = ch_vcf.combine(Channel.fromList(chrom_list))
                            .map { meta, vcf, chrom -> [meta, vcf, chrom] }

        SELECT_CHROMOSOME(ch_vcf_by_chrom)
        ch_variant_working = SELECT_CHROMOSOME.out.vcf
            .map { m, chr, vcf -> [m + [id: "${m.id}.chr${chr}", chrom: chr], vcf] }

        if (params.run_variant_calling_qc) {
            VARIANT_CALLING_QC(ch_variant_working, ch_fasta)
            ch_qc_summaries = ch_qc_summaries.mix(VARIANT_CALLING_QC.out.summary)
        } else {
            log.warn "SKIPPING: Variant calling QC (run_variant_calling_qc = false)"
        }

        if (params.run_variant_filtering) {
            VARIANT_FILTERING(ch_variant_working, ch_fasta)
            ch_variant_for_merge = VARIANT_FILTERING.out.vcf.map { meta, vcf, tbi -> vcf }
            ch_qc_summaries = ch_qc_summaries.mix(VARIANT_FILTERING.out.summary)
        } else {
            INDEX_CHROM_VCF(ch_variant_working)
            ch_variant_for_merge = INDEX_CHROM_VCF.out.vcf.map { meta, vcf, tbi -> vcf }
            ch_qc_summaries = ch_qc_summaries.mix(INDEX_CHROM_VCF.out.summary)
        }

        def merged_meta = [id: "merged", input_type: params.input_type, mode: params.mode]
        MERGE_CHROMOSOMES(ch_variant_for_merge.collect(), Channel.value(merged_meta))
        ch_merged_vcf = MERGE_CHROMOSOMES.out.vcf
        ch_qc_summaries = ch_qc_summaries.mix(MERGE_CHROMOSOMES.out.summary)
    } else {
        log.warn "SKIPPING: Variant-level QC phase (requires VCF input and run_variant_qc = true)"
        if (params.input_type == "vcf") {
            INDEX_INPUT_VCF(ch_vcf)
            ch_merged_vcf = INDEX_INPUT_VCF.out.vcf
            ch_qc_summaries = ch_qc_summaries.mix(INDEX_INPUT_VCF.out.summary)
        }
    }

    // PHASE 3 - Sample-level QC
    if (params.run_sample_qc && scope != "skip") {
        if (scope == "provisional") {
            log.warn """
            *** PROVISIONAL SAMPLE QC ***
            Chromosomes processed: ${params.chroms}
            Sample-level QC is not suitable for final filtering unless all
            autosomes are present. Re-run with --chroms 1-22 for production.
            """.stripIndent()
        }

        if (params.run_fastqc && params.input_type == "fastq") {
            FASTQC(ch_fastq)
            ch_qc_summaries = ch_qc_summaries.mix(FASTQC.out.summary)
        }

        if (params.run_alignment_metrics && params.input_type in ["bam","cram"]) {
            ALIGNMENT_METRICS(ch_bam, ch_fasta)
            ch_qc_summaries = ch_qc_summaries.mix(ALIGNMENT_METRICS.out.summary)
        }

        if (params.run_duplicate_metrics && params.input_type in ["bam","cram"]) {
            DUPLICATE_METRICS(ch_bam)
            ch_qc_summaries = ch_qc_summaries.mix(DUPLICATE_METRICS.out.summary)
        }

        if (params.run_coverage_qc && params.input_type in ["bam","cram"]) {
            COVERAGE_QC(ch_bam, ch_fasta, ch_intervals)
            ch_qc_summaries = ch_qc_summaries.mix(COVERAGE_QC.out.summary)
        }

        if (params.run_contamination && params.input_type in ["bam","cram"]) {
            CONTAMINATION_CHECK(ch_bam, ch_fasta)
            ch_qc_summaries = ch_qc_summaries.mix(CONTAMINATION_CHECK.out.summary)
        }

        if (params.run_sex_check_wgs && params.input_type in ["bam","cram"]) {
            SEX_CHECK(ch_bam, ch_fasta)
            ch_qc_summaries = ch_qc_summaries.mix(SEX_CHECK.out.summary)
        }

        if (params.input_type == "vcf") {
            if (params.run_sample_variant_counts) {
                SAMPLE_VARIANT_COUNTS(ch_merged_vcf)
                ch_qc_summaries = ch_qc_summaries.mix(SAMPLE_VARIANT_COUNTS.out.summary)
            }

            if (params.run_relatedness_wgs) {
                RELATEDNESS(ch_merged_vcf)
                ch_qc_summaries = ch_qc_summaries.mix(RELATEDNESS.out.summary)
            }

            if (params.run_ancestry_pca_wgs) {
                PCA_VARIANT_SELECTION(ch_merged_vcf)
                ch_qc_summaries = ch_qc_summaries.mix(PCA_VARIANT_SELECTION.out.summary)

                ANCESTRY_PCA(PCA_VARIANT_SELECTION.out.vcf, ch_ref_panel)
                ch_qc_summaries = ch_qc_summaries.mix(ANCESTRY_PCA.out.summary)
            }
        }
    } else {
        log.warn "SKIPPING: Sample-level QC phase"
    }

    // PHASE 4 - Final report
    if (params.run_final_report) {
        FINAL_REPORT(ch_qc_summaries.collect())
    }
}
