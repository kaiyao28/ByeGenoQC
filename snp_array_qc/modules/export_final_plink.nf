process EXPORT_FINAL_PLINK {
    label 'process_low'
    publishDir "${params.outdir}/05_cleaned_data", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(bed), path(bim), path(fam)

    output:
    tuple val(meta), path("${meta.id}_final.bed"),
                     path("${meta.id}_final.bim"),
                     path("${meta.id}_final.fam"), emit: plink

    script:
    """
    cp ${bed} ${meta.id}_final.bed
    cp ${bim} ${meta.id}_final.bim
    cp ${fam} ${meta.id}_final.fam
    """
}
