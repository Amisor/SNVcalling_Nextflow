/*
Welcome!
This is the main workflow. It calls all defined processes to identify SNVs and indels.
This main file doesn't download fastq files or performs fastqc analysis.
*/

// Include modules with the different processes
include { DownloadReference }           from "./modules/download_reference"
include { IndexReference }              from "./modules/index_reference"
include { DownloadFastq }               from "./modules/download_fastq"
include { DownloadFastqExample }        from "./modules/download_fastq_example"
include { RunFastQC }                   from "./modules/run_fastqc"
include { AlignReads }                  from "./modules/align_reads"
include { RemovePCRDuplicates }         from "./modules/remove_pcr_duplicates"
include { IndexBAM }                    from "./modules/index_bam"
include { CallVariants }                from "./modules/call_variants"
include { IndexVCF }                    from "./modules/index_vcf"

workflow {

    // 1. Download the reference genome
    def reference_url = file("${params.outDir}/reference_url.txt").text.trim() // Get reference URL from txt file
    download_channel = Channel.of( tuple(reference_url,"reference_genome")) // Reference URL and the name for the reference genome
    reference_channel = DownloadReference(download_channel) // Download the reference genome and assign output to a channel

    // 2. Index the reference genome
    ref_index_channel = IndexReference(reference_channel) // Index files and assign them to a channel

    // 3. Download FASTQ files and compress them
    /*
    Memory issues in Docker prevent this part of the script from running in a container, as downloading the files exceeds Docker's memory limits.
    However, this process can be run on a local computer without the container, provided there is sufficient memory.
    Refer to the Example Dataset section for the original file sizes, as these will be downloaded when the following line is executed. 
    The container works well for smaller FASTQ files, although it may take longer to complete. 
    */
    region_sra_channel = Channel.fromPath(params.regionFile)       // Use original file
                                .splitCsv(header: true, sep: '\t') // Split tsv file by spaces
                                .map { row -> [row.region, row.sra_num] } // Get region and sra_num to then download the files
    //download_fastq = DownloadFastq(region_sra_channel) 

    // EXAMPLE: Download FASTQ files and compress them
    /*
    region_sra_channel_example = Channel.fromPath(params.regionFileExample)        // Use example file
                                        .splitCsv(header: true, sep: '\t')         // Identify regions and sra_num
                                        .map { row -> [row.region, row.sra_num] } // Create channel with the region and sra_num to download
    download_fastq_example = DownloadFastqExample(region_sra_channel_example)     // Download fastq files and assign them to a channel
    println "FastQ download channel example" // Print to indicate the user that is going to see the fastq example files
    download_fastq_example.view()  // To visualize the channel with the downloaded fastq example files (but I'm not saving them in the output directory)
    */

    // EXAMPLE: FastQ channel containing example fastq files
    //fastq_channel_example = Channel.fromPath("${params.outDir}/FASTQFastQCExample/*.fastq.gz")
    
    // EXAMPLE: FastQC for the example fastq files
    //fastqc_channel_example = RunFastQC(fastq_channel_example)

    // 4. FastQ channel containing all fastq files
    fastq_channel = Channel.fromPath("${params.outDir}/FASTQ/*.fastq.gz")

    // 5. FastQC for all fastq files. 
    /*
    FastQC for all fastq files is not tested due to the long time it takes. 
    Even if I run it with docker it can take a while to create all the reports - MAYBE?
    */
    //fastqc_channel = RunFastQC(fastq_channel)

    // 6. Align fastq files to the reference genome
    paired_fastq_channel = fastq_channel // Create a channel that associated regions with its fastq files for alignment
        .map { file ->
            def (region, sra_num, _) = file.baseName.split('_')
            [region, sra_num, file]
        }
        .groupTuple() //Group FASTQ files by region and SRA number
        .map { group ->
            def (region, sra_num, files) = group
            files = files.sort { it.toString() } // Ensure consistent (region_sranumber_1.fastq and region_sranumber_2.fastq)
            [region, sra_num[0], files[0], files[1]] // Save them in order (region, sra_num, fastqfile_1.fastq.gz, fastqfile_1.fastq.gz)
        }    
    ref_index_channel = ref_index_channel // Transform the reference channel from a flatten the tuple into a single list
                        .map { referenceGenome, indexFiles -> [referenceGenome] + indexFiles} // This channel will be combined with the paired_fastq_chanel
    fastq_index_channel = paired_fastq_channel.combine(ref_index_channel) // Combine paired_fastq_channel with ref_index_channel to have a single tuple
    alignment_channel = AlignReads(fastq_index_channel) // Align paired-fastq files based on their region to the reference genome and assign them to a channel
    
     // 7. Remove PCR duplicates
    pcr_dup_channel = RemovePCRDuplicates(alignment_channel) // Indetify and remove PCR duplicates from all the aligned reads and assign them to a channel

    // 8. Index BAM files for IGV
    bam_index_channel = IndexBAM(pcr_dup_channel) // Index bam files without pcr duplicates to visualize the results in IGV, assign them to a channel

    // 9. Single Nucleotide Variant Calling and indels 
    variant_channel = pcr_dup_channel.combine(ref_index_channel) // Combine .bam files without pcr duplicates and the reference genome
    snv_chanel = CallVariants(variant_channel) // Detect SNV and indels, assign results to a channel

    // 10. Index VCF files for IGV
    vcf_index_chanel = IndexVCF(snv_chanel) // Index vcf files for IGV visualization
}
