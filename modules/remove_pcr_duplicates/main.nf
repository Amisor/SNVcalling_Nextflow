process RemovePCRDuplicates {
    
    // Save the files in data/BAM
    publishDir "${params.outDir}/BAM" 

    input:
    // Each of the region is associated to its SRA number and its fastq files
    // In addition, for each region also associate the reference genome with it - same for all regions
    tuple val(region), path(samfile)
    
    output:
    // Region and its new bam file after removing pcr duplicates
    tuple val(region), path("aligned_${region}_final.bam")

    script:
    """
    # Convert sam file to binary bam file - compressed version
    samtools view -h -b ${samfile} -o aligned_${region}.bam

    # Correct mate-pair information ensuring consistency for paired-end reads
    samtools fixmate -m aligned_${region}.bam aligned_${region}.fixmate.bam

    # Sort bam file by genomic coordinates
    samtools sort aligned_${region}.fixmate.bam -o aligned_${region}.fixmate.sort.bam

    # Mark and remove duplicate reads
    samtools markdup -r aligned_${region}.fixmate.sort.bam aligned_${region}.fixmate.sort.markdup.bam

    # Sort again by genomic coordinates
    samtools sort aligned_${region}.fixmate.sort.markdup.bam -o aligned_${region}_final.bam
    """
}
