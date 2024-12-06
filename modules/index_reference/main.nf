process IndexReference {

    // Save the output in data/Reference_Genome
    publishDir "${params.outDir}/ReferenceGenome" 

    input:
    // The reference genome to be indexed
    path(referenceGenome) 

    output:
    // Save the reference genome and all the files created after indexing (.ann, bwt, etc.)
    tuple(path(referenceGenome), path("${referenceGenome.baseName}.*"))

    script:
    """
    # Index reference genome
    bwa index ${referenceGenome}
     """
}
