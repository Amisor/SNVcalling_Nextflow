# SNVcalling_Nextflow

This Nextflow pipeline identifies single nucleotide variants (SNVs) and indels from paired-end FASTQ files of an organism of interest.

## Table of Contents
- [Workflow Overview](#workflow-overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Data](#data)
  - [Input](##input)
  - [Output](##output)
  - [Command-line Options](#command-line-options)
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

The pipeline includes a "docker" profile that uses public repository Docker images, most of which are from **BioContainers**. A list of the Docker images used can be found in the [Nextflow configuration file](config/nextflow.config).

By default, no specific resource limits are assigned to Docker containers. This means they can use all available memory on the host system unless specific limits are set.

If you want to adjust the resource allocations for this pipeline, refer to the [Customize Pipeline](#customize-pipeline) section.


# Installation

Step-by-step instructions to set up the pipeline.Instructions for 
- cloning the repository and setting up the environment.

# Data

## Input

All input files must be saved in the [data](data) directory.

- A text file named `reference_url.txt` containing the URL to download the reference genome.
- A TSV file named `sra_list_fastq.tsv` containing two columns:
  - **region**: The name of the regions, formatted without underscores or spaces.
  - **sra_num**: The SRA accession numbers for downloading the FASTQ files.

If the user does not wish to download the FASTQ files (this option is explained in [Customize Pipeline](#customize-pipeline)), 
both files are still required. The alignment process relies on the TSV file to associate each region with its corresponding paired FASTQ files.

## Output 
Describe the expected outputs (e.g., BAM, VCF, QC reports).

## Command-line Options.
List parameters for running the pipeline (e.g., --genome, --reads).

## Example Datasets 
Droshophilia 

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

## Downloading Fastq files 
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

# References

Cite tools, databases, and publications used.