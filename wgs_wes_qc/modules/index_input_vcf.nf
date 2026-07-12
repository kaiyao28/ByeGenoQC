process INDEX_INPUT_VCF {
    label 'process_low'

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("${meta.id}.indexed.vcf.gz"), path("${meta.id}.indexed.vcf.gz.tbi"), emit: vcf
    path "index_input_vcf_summary.txt", emit: summary

    script:
    """
    bcftools view --threads ${task.cpus} ${vcf} -O z -o ${meta.id}.indexed.vcf.gz
    bcftools index --tbi --threads ${task.cpus} ${meta.id}.indexed.vcf.gz

    cat > index_input_vcf_summary.txt << EOF
step=index_input_vcf
dataset=${meta.id}
n_variants=\$(bcftools view --no-header ${meta.id}.indexed.vcf.gz | wc -l)
EOF
    """
}
