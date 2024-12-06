process DownloadFastqExample {

    /* 
    This process is specifically designed for the FASTQ example files. 
    The Docker image can download these files because they are smaller than the original dataset used in the pipeline. 
    The process does not save the downloaded files in the publishDir (wich it's the only difference between this process and DownloadFastq) directory 
    to prevent further processing of the example files, as their sole purpose is to demonstrate that the DownloadFastq process works. 
    The example FASTQ files are from the Bordetella hinzii bacterium.
    */
    

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
