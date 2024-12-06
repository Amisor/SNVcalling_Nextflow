process DownloadFastq {

    /* 
    Memory issues in docker, cant't run this part of the script in docker 
    because downloading the files uses more memory that the one allowed in docker
    I can run this process in my local computer without the container because I have enough memory 
    (I can run it for at least 2 regions until I run out of memory)
    Container works well for smaller fastq files, however it takes a while. 
    */
    
    // Save fastq files in data/FASTQ
    publishDir "${params.outDir}/FASTQ"

    input:
    // Each region with its SRA number correspond to each row of the .tsv file
    tuple val(region), val(sra_num)

    output: 
    // Obtain compressed fastq files for all regions (2 files per region)
    path('*.fastq.gz')

    script:
    """
    # Download the FASTQ files
    fasterq-dump ${sra_num}
    
    # Compress each of the files 
    gzip ${sra_num}_1.fastq
    gzip ${sra_num}_2.fastq
    
    # Rename them such that their names include their region
    mv ${sra_num}_1.fastq.gz ${region}_${sra_num}_1.fastq.gz
    mv ${sra_num}_2.fastq.gz ${region}_${sra_num}_2.fastq.gz
    """
}
