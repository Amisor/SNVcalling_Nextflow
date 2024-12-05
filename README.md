# SNVcalling_Nextflow

This Nextflow pipeline identifies single nucleotide variants (SNVs) and indels from paired-end FASTQ files of an organism of interest.

## Table of Contents
- [Workflow Overview](#workflow-overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Data](#data)
  - [Input](##input)
  - [Output](##output)
  - [Example Datasets](#example-datasets)
  - [IGV visualization](#igv-visualization)
- [Customize Pipeline](#customize-pipeline)
- [Comments](#comments)
  - [Input Requirements](#input-requirements)
- [References](#references)

# Workflow Overview

The workflow is designed to streamline the analysis and includes the following steps:
* Fetches the reference genome and indexes with BWA it for efficient alignment.
* Downloads short-read paired sequence data and aligns them to the reference genome with BWA.
* Performs quality control analysis on all paired FASTQ files with FastQC.
* Converts alignments (`.sam`) to compressed format (`.bam`) with samtools.
* Removes PCR duplicates with samtools to improve variant-calling accuracy.
* Identifies SNVs and indels with BCFtools from processed alignment data.
* Generates index files (`.bai`) with BCFtools for visualization of alignment and variant data in IGV (Integrative Genomics Viewer).

(A diagram providing the workflow )

Comment on key features of the pipeline, such as compatibility with different tools (e.g., samtools, bcftools) and modular design.

An advantage of the piepline is that if the user already ahve th fastq files i its computer and decides not to use the piple for not 
downlading them, it can diretly use this pieleien too, actually saving pipeline time. See [Customize Pipeline](#customize-pipeline)
# Requirements

The software dependencies in order to run this pipeline are the following:

```bash
# GNU Bash
bash 3.2.57

# OpenJDK (Java Runtime Environment)
openjdk 21.0.5

# Docker
Docker 27.2.0

# Nextflow
nextflow 24.10.1

# Git
git 2.15.0
```

The pipeline includes a "docker" profile that uses public Docker images, most of which are from **BioContainers**. A list of the Docker images used can be found in the [Nextflow configuration file](config/nextflow.config).

By default, no specific resource limits are assigned to Docker containers. This means they can use all available memory on the host system unless specific limits are set.

If you want to adjust the resource allocations for this pipeline, refer to the [Customize Pipeline](#customize-pipeline) section.


# Installation

Step-by-step instructions to set up the pipeline.Instructions for 
- cloning the repository and setting up the environment.

# Data
This section specifies the required input files and the expected output files for running the Nextflow pipeline.
## Input

All input files must be saved in the [data](data) directory.

- `reference_url.txt`: a text file containing the URL to download the reference genome.
- `sra_list_fastq.tsv`: A TSV file containing two columns:
  - **region**: The name of the regions, formatted without underscores or spaces.
  - **sra_num**: The SRA accession numbers for downloading the FASTQ files.

If the user does not wish to download the FASTQ files, only the `reference_url.txt` is required. 
Nevertheless, the alignment process relies on the assumption that the FASTQ file names are renamed during 
the downloading process (`DownloadFastq`) based on the TSV file. This renaming step associates each region with 
its corresponding paired FASTQ files based on the file names. Refer to [Customize Pipeline](#customize-pipeline) 
for details about running the pipeline without downloading the FASTQ files.

## Output 
The output files include:

- **Reference Genome and Index Files**: Stored in the [Reference_Genome](data/Reference_Genome) directory.
- **Downloaded FASTQ Files**: Stored in the [FASTQ](data/FASTQ) directory.
- **FastQC Analysis**: Quality control reports for FASTQ files are available in the [FastQC](data/FastQC) directory.
- **Alignment Files**: Intermediate `.sam` files, which are processed to remove PCR duplicates and generate the final BAM files, are stored in the [Alignment](data/Alignment) directory.
- **BAM Files**: Aligned FASTQ files to the reference genome, with PCR duplicates removed (`.bam`), are stored in the [BAM](data/BAM) directory.
- **SNVs and Indels**: Final variant call files (`.vcf.gz`) are stored in the [SNV](data/SNV) directory.

## Example Datasets 

For this project, Drosophila melanogaster (fruit fly) data was used for testing. 
The primary goal is to identify the genetic diversity within Drosophila melanogaster populations from different regions, 
including North America, South America, Africa, Asia, Oceania, and Europe.

The datasets were carefully selected from the NCBI Genome Database to ensure comparability. 
All samples consist of short-read paired-end sequences from Drosophila melanogaster in the adult stage. Sequencing was performed using the Illumina platform, with data generated on different platforms. 
If detailed information about the data is available, such as the specific country, it is stored in the region variable. However, if the data lacks such granularity, only the continent is stored.

Unfortunately, no short-read sequencing genomes generated on the Illumina platform were found for South America. 
The majority of datasets available from this region were produced using long-read sequencing technologies, 
such as the dataset from Peru (SRR7816670). Only one dataset from Chile (SRR21942766) was generated using the Illumina HiSeq 2500, 
but it is based on ATAC-seq rather than WGS, making it unsuitable for single nucleotide variant (SNV) calling.
ATAC-seq focuses on open chromatin regions, and while it may detect some SNV in these areas, 
the data is inherently biased and lacks comprehensive genome coverage. 
In contrast, WGS provides complete coverage of the genome, including both coding and non-coding regions, 
ensuring accurate detection of SNVs across the entire genome.

Table 1: Overview of datasets used in the pipeline, including region, sequencing details, and biosamples.

| Region          | SRA Accession Number | # of Spots   | # of Bases | Size | Published   | Instrument           | Strategy | Layout  | Development Stage | Biosample       |
|------------------|----------------------|--------------|------------|------|-------------|----------------------|----------|---------|-------------------|-----------------|
| USA             | SRR30674540          | 33,246,271   | 5G         | 3.1Gb| 2024-09-17  | Illumina HiSeq 2000 | WGS      | Paired  | adult             | SAMN43783121    |
| Australia       | SRR17978916          | 21,518,768   | 6.5G       | 1.9Gb| 2022-02-10  | Illumina NovaSeq 6000| WGS      | Paired  | adult             | SAMN25851855    |
| Russia          | SRR26549080          | 17,167,488   | 5.1G       | 2.3Gb| 2024-09-14  | Illumina HiSeq 2500 | WGS      | Paired  | adult             | SAMN37946768    |
| China           | SRR23103754          | 19,292,824   | 5.8G       | 1.7Gb| 2024-04-30  | Illumina NovaSeq 6000| WGS      | Paired  | adult             | SAMN32772670    |
| Spain           | SRR24223130          | 30,664,281   | 9G         | 2.8Gb| 2024-08-31  | Illumina NovaSeq 6000| WGS      | Paired  | adult             | SAMN34257693    |
| Central Africa  | SRR21854039          | 46,871,379   | 11.7G      | 4.4Gb| 2022-10-12  | Illumina HiSeq 4000 | WGS      | Paired  | adult             | SAMN30837313    |
| West Africa     | ERR9463903           | 35,724,955   | 10.3G      | 3.2Gb| 2024-07-29  | Illumina NovaSeq 6000| WGS      | Paired  | adult             | SAMEA13793122   |


## Results and Visualization

How to interpret the output.
Provide instructions for visualizing results in tools like IGV.


# Customize Pipeline

## Resources
The suer can modify the default cps and memory of docker for all process, by addind the specific requirements in each of them .
This could be done by mofiying each of the modules inside the models direcotry or directly modifying the nextlfow configuration profile 
by setting inside the docker profile the limits. For example, if the user desire is to limir cpus and memor for the RunFastQC process, 
the following lines must be added to the nextflow configurarion file inside the docker profile with the name of the process of interes: 


cpus = 2
memory = '4 GB'
        
Describe how users can modify parameters, add modules, or change configurations.
Common issues (e.g., "What should I do if the pipeline crashes?" or "How do I specify a custom genome?").

## Not downloading Fastq files 
when testing the 

# Comments

### Input Requirements

- **sra_lst_fast.tsv**: The requirement to avoid underscores (`_`) in region names is due to how the pipeline handles file naming and pairing. 
In the workflow, the `paired_fastq_channel` associates regions with their paired FASTQ files by splitting file names using the underscore character (`_`). 
To ensure proper pairing, the FASTQ files are renamed during the download process based on the region name and SRA accession number, 
using the format `region_SRAnum_1.fastq.gz` and `region_SRAnum_2.fastq.gz`. The pipeline assumes that no underscores are present in the region names to avoid unintended splitting of the file names. 
Additionally, the SRA accession numbers naturally do not contain underscores, which aligns with this assumption. 
Spaces in region names are also problematic because they can cause errors during the alignment process. For instance, a file named `region otherpartofregion_SRA12345_1.fastq.gz` would include a space, 
and during BWA alignment, this might be misinterpreted as an attempt to provide an additional option rather than being part of the file name. To reduce errors and ensure smooth execution, 
it is recommended to avoid using spaces or underscores in region names. Instead, use simple alphanumeric characters for consistency and to minimize pipeline issues.

Remove alignment publish Dir if not wnat to save this files as I know that this might not be useful and use space in memory

## Sobre example 

Acerca de publish dir y de downloadign fastq files ;( - ve cuanot tiempo te toma hacer esto 
Traté de hacer dinámica nada más no s epudo ? 

# References

Cite tools, databases, and publications used.