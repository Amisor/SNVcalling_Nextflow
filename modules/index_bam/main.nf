process IndexBAM{

    // Save the files in data/IndexBAM
    publishDir "${params.outDir}/IndexBAM"

    input:
    // Region name and .bam file without PCR duplicates
    tuple val(region), path("aligned_${region}_final.bam")

    output:
    // Indexed bam file (.bai)
    path("*.bai")

    script:
    """
    # Index bam files for IGV visualization
    samtools index aligned_${region}_final.bam
    """
}
