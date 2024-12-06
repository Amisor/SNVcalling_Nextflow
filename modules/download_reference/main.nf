process DownloadReference {

    input:
    // Receive the url where the reference genome is
    tuple val(url), val(name)

    output:
    // Save the descompressed reference genome
    path('*.fna')

    script:
    """
    # Download reference genome
    wget ${url} -O ${name}.fna.gz

    # Descompress the reference genome
    gunzip ${name}.fna.gz
    """
}
