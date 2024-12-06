process CallVariants{

    // Save the files in data/SNV
    publishDir "${params.outDir}/SNV" 
    
    input:
    // Region name, bam file and reference channel - includes reference + index files
    tuple (val(region), val(final_bamfile), path(reference), 
    path(refindx1), path(refindx2), path(refindx3),path(refindx4), path(refindx5))
    
    output:
    path("*.vcf.gz")
    
    script:
    """
    bcftools mpileup -f ${reference} ${final_bamfile} | \
    bcftools call -m --variants-only --ploidy 1 --output-type z -o ${region}.vcf.gz
    """
}
