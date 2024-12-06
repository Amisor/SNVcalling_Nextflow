process RunFastQC {

    // Save FastQC files in data/FastQC
    publishDir "${params.outDir}/FastQC" 

    input:
    // All of the input files
    path(fastq_file)

    output:
    // zip and html files for quality control
    path("*.{zip,html}")

    script:
    """
    # Use fastqc to do the quality control analysis of the fastq files
    fastqc ${fastq_file}
    """
}
