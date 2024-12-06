process IndexVCF{

    // Save the files in data/IndexBAM
    publishDir "${params.outDir}/IndexVCF"

    input:
    // VCF files with SNVs and indels
    path(vcf_file)

    output:
    // Indexed bam file (.bai)
    path("*.vcf.gz.tbi")

    script:
    """
    # Index vcf file for IGV visualization
    bcftools index -t ${vcf_file}
    """
}
