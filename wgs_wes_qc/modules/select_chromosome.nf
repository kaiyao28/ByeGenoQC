process SELECT_CHROMOSOME {
    label 'process_low'
    publishDir "${params.outdir}/variant_qc/chromosomes", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(vcf), val(chrom)

    output:
    tuple val(meta), val(chrom), path("${meta.id}.chr${chrom}.vcf.gz"), emit: vcf

    script:
    """
    if [[ "${vcf}" == *.vcf.gz ]]; then
        cp ${vcf} input.vcf.gz
    else
        bgzip -c ${vcf} > input.vcf.gz
    fi
    bcftools index --tbi --force --threads ${task.cpus} input.vcf.gz

    region1="${chrom}"
    region2="chr${chrom}"

    if bcftools view --regions "\${region1}" --no-header input.vcf.gz | head -n 1 | grep -q .; then
        region="\${region1}"
    else
        region="\${region2}"
    fi

    bcftools view --threads ${task.cpus} --regions "\${region}" input.vcf.gz -O z -o ${meta.id}.chr${chrom}.vcf.gz
    bcftools index --tbi --threads ${task.cpus} ${meta.id}.chr${chrom}.vcf.gz
    """
}
