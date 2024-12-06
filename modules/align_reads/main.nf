process AlignReads {

    // Save aligned reads in data/Alignment
    publishDir "${params.outDir}/Alignment" 

    input:
    // Each of the region is associated to its SRA number and its fastq files
    // For each region associate the reference genome and files after indexing it - same for all regions
    tuple (val(region), val(sra_num), path(r1), path(r2), path(reference), 
    path(refindx1), path(refindx2), path(refindx3),path(refindx4), path(refindx5))

    output:
    // Obtain sam file for the pair alignment
    tuple val(region), path('*.sam')

    script:

    """
    # Pair alignment for each region using the same reference genome and changing the fastq files
    bwa mem $reference $r1 $r2 > aligned_${region}.sam
    """
}
