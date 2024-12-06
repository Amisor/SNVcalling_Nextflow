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

The workflow includes the following steps:
* Downloads the reference genome.
* Indexes the reference genome with BWA.
* Downloads short-read paired sequence data with fastq-dump and compressed the files.
* Obtains quality control metrics with FastQC for all paired FASTQ files.
* Aligns paired sequence data to the reference genome with BWA.
* Converts alignments to compressed format and removes PCR duplicates (`.bam`) with samtools.
* Generates index files with samtools of alignment data without PCR duplicates for IGV visualization. 
* Identifies SNVs and indels with BCFtools from the processed alignment data without PCR duplicates. 
* Creates index files with BCFtools of SNVs and indels files for IGV visualization. 

![Workflow Diagram](images/DiagramNextflow.png "Workflow diagram V")

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
Open your terminal and placed yourself in the directory where you want to save this github repository.
Now clone the this github repository:

```bash
git clone https://github.com/Amisor/SNVcalling_Nextflow.git
```
Change your working directory to the GitHub repository with the following command:

```bash
cd SNVcalling_Nextflow
```

# Data
This section specifies the required input files and the expected output files for running the Nextflow pipeline.

## Input

All input files must be saved in the [data](data) directory.

- `reference_url.txt`: a text file containing the URL to download the reference genome.
- `sra_list_fastq.tsv`: A TSV file containing two columns:
  - **region**: The name of the regions, formatted without underscores or spaces.
  - **sra_num**: The SRA accession numbers for downloading the FASTQ files.

If the user does not wish to download the FASTQ files, only the `reference_url.txt` is required. 
However, the alignment process relies on the assumption that the FASTQ file names are renamed during 
the downloading process (`DownloadFastq`) based on the TSV file. This renaming step associates each region with 
its corresponding paired FASTQ files based on the file names. Refer to [Customize Pipeline](#customize-pipeline) 
for details about running the pipeline without downloading the FASTQ files.

## Output 
The output files include:

- **Reference genome and its index files** (`.fna, ): Stored in the [Reference_Genome](data/Reference_Genome) directory.
- **Downloaded FASTQ Files**: Stored in the [FASTQ](data/FASTQ) directory.
- **FastQC Analysis**: Quality control reports for FASTQ files are available in [FastQC](data/FastQC).
- **Alignment Files**: Alignment `.sam` files stored in [Alignment](data/Alignment).
- **BAM Files**: Processed alignment files to remove PCR duplicates and generate the final BAM files.
Aligned FASTQ files to the reference genome, with PCR duplicates removed (`.bam`), are stored in the [BAM](data/BAM) directory.
- **SNVs and Indels**: Final variant call files (`.vcf.gz`) are stored in the [SNV](data/SNV) directory.
_ ****
## Example Datasets 

For this project, Drosophila melanogaster (fruit fly) data was used for testing. 
The primary goal is to identify the genetic diversity within Drosophila melanogaster populations from different regions, 
including North America, South America, Africa, Asia, Oceania, and Europe.

The datasets were carefully selected from the NCBI Genome Database to ensure comparability. 
All samples consist of short-read paired-end sequences from Drosophila melanogaster in the adult stage. Sequencing was performed using the Illumina platform, with data generated on different platforms. 
If detailed information about the data is available, such as the specific country, it is stored in the region variable. However, if the data lacks such granularity, only the continent is stored.

Unfortunately, no short-read sequencing genomes generated on the Illumina platform were found for South America. 
The majority of datasets from this region were produced using long-read sequencing technologies, 
such as Peru (SRR7816670). One dataset from Chile (SRR21942766) was generated using the Illumina HiSeq 2500, 
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

The reader will notice that the size of each original FASTQ file is quite large. 
To test the pipeline efficiently, I downloaded each FASTQ file and created smaller test files by extracting only the first 40,000 lines 
from each paired FASTQ file for every region. This results in 10,000 sequences per file 
(since a FASTQ file consists of 4 lines per sequence: sequence ID, nucleotide sequence, separator, and Phred quality scores).

The smaller test files were compressed and used as input for the pipeline. The code to generate these smaller FASTQ files is not part of the pipeline; 
it was executed separately to prepare the desired test files for pipeline functionality.

An example of this process for the Australia dataset is provided below:

```bash
region="Australia"
sra_num="SRR17978916"

# Download the FASTQ files using fastq-dump
fastq-dump --split-files ${sra_num}

# Obtain the first 10,000 sequences (40,000 lines) from the first FASTQ file
head -n 40000 ${sra_num}_1.fastq > ${region}_${sra_num}_1.fastq
gzip ${region}_${sra_num}_1.fastq

# Obtain the first 10,000 sequences (40,000 lines) from the second FASTQ file
head -n 40000 ${sra_num}_2.fastq > ${region}_${sra_num}_2.fastq
gzip ${region}_${sra_num}_2.fastq
```
This will produce the desired compressed files: `${region}_${sra_num}_1.fastq.gz` and `${region}_${sra_num}_2.fastq.gz`.

The reader may have the following questions:
**Can I use the pipeline with downloading or without downloading the FASTQ files?**
Yes. The pipeline originally is designed to download the FASTQ files. However,
you can download the fastq files and placed them inside the [FASTQ](data/FASTQ) directory .
They automallycally will be used as an input for subsequent processes, but you have to keep in mind to modify acquertly 
the workflow of the pipeline. See  [Customize Pipeline](#customize-pipeline) 

**How can I test the DownloadFastq process of the pipeline?**

Because orignal fastq files are large, I added a `sra_list_fastq_example.tsv` inside [data](data) 
file for downloading fastq files from two example regions with their respective sra accesion number whose sizes
are muhc more smaller. The example download w paired-fastq files files from Bordatella hinzi fastq files. 
The reader will noticed that the example employs DownloadFastqExample instead of DownloadFastq process. 
The reason is because DownloadFastq save the files inside [FASTQ](data/FASTQ) directory, which then will be sued
for the upcoming processes, while DownloadFastqExample has the same script as DownloadFastq  but do not publish the results 
in the FASTQ directory. I decided to to this because if I used the same process (DownloadFastq), the Bordetella hinzi files
would be aslso used for theAlignReads process and all the upcomong processes, which is is not only bioligcal nonsense 
(reference from drosophilia and fastq files from bordetella), but also memorry consuming. 

If the user wnat so use the original DownloadFastq with the publish dear, please be aware that it's memory requirement edepends on
the desired fifiles to download and if the process exceds the limits set in the nextflow.config, 
the user has to modify the configuration file. Additionally, has to ensure that its equipment ahs enough memory
to donwload and compress the desire files.

# Running the pipeline

When you clone the github repository, you´ll have the following directories: 

```plaintext
SNVcalling_Nextflow/
├── data/
|   ├── [some directories and files]
├── modules/
|   ├── [some directories and files]
├── main.nf
├── nextflow.config
```

Let's zoom in into the data directory. 

```plaintext
data/
├── Alignment/
|   ├── [empty]
├── BAM/
|   ├── [empty]
├── FASTQ/
│   ├── Australia_SRR17978916_1.fastq.gz
│   ├── Australia_SRR17978916_2.fastq.gz
│   ├── CentralAfrica_SRR21854039_1.fastq.gz
│   ├── CentralAfrica_SRR21854039_2.fastq.gz
│   ├── China_SRR23103754_1.fastq.gz
│   ├── China_SRR23103754_2.fastq.gz
│   ├── Russia_SRR26549080_1.fastq.gz
│   ├── Russia_SRR26549080_2.fastq.gz
│   ├── Spain_SRR24223130_1.fastq.gz
│   ├── Spain_SRR24223130_2.fastq.gz
│   ├── USA_SRR30674540_1.fastq.gz
│   ├── USA_SRR30674540_2.fastq.gz
│   ├── WestAfrica_ERR9463903_1.fastq.gz
│   └── WestAfrica_ERR9463903_2.fastq.gz
├── FastQC/
│   ├── Australia_SRR17978916_2_fastqc.html
│   ├── Australia_SRR17978916_2_fastqc.zip
│   ├── CentralAfrica_SRR21854039_1_fastqc.html
│   ├── CentralAfrica_SRR21854039_1_fastqc.zip
│   ├── CentralAfrica_SRR21854039_2_fastqc.html
│   ├── CentralAfrica_SRR21854039_2_fastqc.zip
│   ├── China_SRR23103754_1_fastqc.html
│   ├── China_SRR23103754_1_fastqc.zip
│   ├── China_SRR23103754_2_fastqc.html
│   ├── China_SRR23103754_2_fastqc.zip
│   ├── Russia_SRR26549080_1_fastqc.html
│   ├── Russia_SRR26549080_1_fastqc.zip
│   ├── Russia_SRR26549080_2_fastqc.html
│   ├── Russia_SRR26549080_2_fastqc.zip
│   ├── Spain_SRR24223130_1_fastqc.html
│   ├── Spain_SRR24223130_1_fastqc.zip
│   ├── Spain_SRR24223130_2_fastqc.html
│   ├── Spain_SRR24223130_2_fastqc.zip
│   ├── USA_SRR30674540_1_fastqc.html
│   ├── USA_SRR30674540_1_fastqc.zip
│   ├── USA_SRR30674540_2_fastqc.html
│   ├── USA_SRR30674540_2_fastqc.zip
│   ├── WestAfrica_ERR9463903_1_fastqc.html
│   ├── WestAfrica_ERR9463903_1_fastqc.zip
│   ├── WestAfrica_ERR9463903_2_fastqc.html
│   ├── WestAfrica_ERR9463903_2_fastqc.zip
├── IndexBAM/
|   ├── [empty]
├── IndexVCF/
|   ├── [empty]
├── ReferenceGenome/
|   ├── [empty]
├── SNV/
|   ├── [empty]
├── reference_url.txt
├── sra_list_fastq_example.tsv
├── sra_list_fastq.tsv
```


After running main.nf you'll have the following data directory, where the new created files are highligthed in **bold**: 

```plaintext
data/
├── Alignment/
│   ├── **aligned_Australia.sam**
│   ├── **aligned_CentralAfrica.sam**
│   ├── **aligned_China.sam**
│   ├── **aligned_Russia.sam**
│   ├── **aligned_Spain.sam**
│   ├── **aligned_USA.sam**
│   ├── **aligned_WestAfrica.sam**
│   └── README.md
├── BAM/
│   ├── **aligned_Australia_final.bam**
│   ├── **aligned_CentralAfrica_final.bam**
│   ├── **aligned_China_final.bam**
│   ├── **aligned_Russia_final.bam**
│   ├── **aligned_Spain_final.bam**
│   ├── **aligned_USA_final.bam**
│   ├── **aligned_WestAfrica_final.bam**
│   └── README.md
├── FASTQ/
│   ├── Australia_SRR17978916_1.fastq.gz
│   ├── Australia_SRR17978916_2.fastq.gz
│   ├── CentralAfrica_SRR21854039_1.fastq.gz
│   ├── CentralAfrica_SRR21854039_2.fastq.gz
│   ├── China_SRR23103754_1.fastq.gz
│   ├── China_SRR23103754_2.fastq.gz
│   ├── Russia_SRR26549080_1.fastq.gz
│   ├── Russia_SRR26549080_2.fastq.gz
│   ├── Spain_SRR24223130_1.fastq.gz
│   ├── Spain_SRR24223130_2.fastq.gz
│   ├── USA_SRR30674540_1.fastq.gz
│   ├── USA_SRR30674540_2.fastq.gz
│   ├── WestAfrica_ERR9463903_1.fastq.gz
│   ├── WestAfrica_ERR9463903_2.fastq.gz
│   └── README.md
├── FastQC/
│   ├── **Australia_SRR17978916_1_fastqc.html**
│   ├── **Australia_SRR17978916_1_fastqc.zip**
│   ├── Australia_SRR17978916_2_fastqc.html
│   ├── Australia_SRR17978916_2_fastqc.zip
│   ├── CentralAfrica_SRR21854039_1_fastqc.html
│   ├── CentralAfrica_SRR21854039_1_fastqc.zip
│   ├── CentralAfrica_SRR21854039_2_fastqc.html
│   ├── CentralAfrica_SRR21854039_2_fastqc.zip
│   ├── China_SRR23103754_1_fastqc.html
│   ├── China_SRR23103754_1_fastqc.zip
│   ├── China_SRR23103754_2_fastqc.html
│   ├── China_SRR23103754_2_fastqc.zip
│   ├── Russia_SRR26549080_1_fastqc.html
│   ├── Russia_SRR26549080_1_fastqc.zip
│   ├── Russia_SRR26549080_2_fastqc.html
│   ├── Russia_SRR26549080_2_fastqc.zip
│   ├── Spain_SRR24223130_1_fastqc.html
│   ├── Spain_SRR24223130_1_fastqc.zip
│   ├── Spain_SRR24223130_2_fastqc.html
│   ├── Spain_SRR24223130_2_fastqc.zip
│   ├── USA_SRR30674540_1_fastqc.html
│   ├── USA_SRR30674540_1_fastqc.zip
│   ├── USA_SRR30674540_2_fastqc.html
│   ├── USA_SRR30674540_2_fastqc.zip
│   ├── WestAfrica_ERR9463903_1_fastqc.html
│   ├── WestAfrica_ERR9463903_1_fastqc.zip
│   ├── WestAfrica_ERR9463903_2_fastqc.html
│   ├── WestAfrica_ERR9463903_2_fastqc.zip
│   └── README.md
├── FASTQFastQCExample
│   ├── Australia_SRR17978916_1.fastq.gz
│   └── README.md
├── IndexBAM/
│   ├── **aligned_Australia_final.bam.bai**
│   ├── **aligned_CentralAfrica_final.bam.bai**
│   ├── **aligned_China_final.bam.bai**
│   ├── **aligned_Russia_final.bam.bai**
│   ├── **aligned_Spain_final.bam.bai**
│   ├── **aligned_USA_final.bam.bai**
│   ├── **aligned_WestAfrica_final.bam.bai**
│   └── README.md
├── IndexVCF/
│   ├── **Australia.vcf.gz.tbi**
│   ├── **CentralAfrica.vcf.gz.tbi**
│   ├── **China.vcf.gz.tbi**
│   ├── **Russia.vcf.gz.tbi**
│   ├── **Spain.vcf.gz.tbi**
│   ├── **USA.vcf.gz.tbi**
│   ├── **WestAfrica.vcf.gz.tbi**
│   └── README.md
├── ReferenceGenome/
│   ├── **reference_genome.fna**
│   ├── **reference_genome.fna.amb**
│   ├── **reference_genome.fna.ann**
│   ├── **reference_genome.fna.bwt**
│   ├── **reference_genome.fna.pac**
│   ├── **reference_genome.fna.sa**
│   └── README.md
├── SNV/
│   ├── **Australia.vcf.gz**
│   ├── **CentralAfrica.vcf.gz**
│   ├── **China.vcf.gz**
│   ├── **Russia.vcf.gz**
│   ├── **Spain.vcf.gz**
│   ├── **USA.vcf.gz**
│   ├── **WestAfrica.vcf.gz**
│   └── README.md
├── reference_url.txt
├── sra_list_fastq_example.tsv
├── sra_list_fastq.tsv
```
This is <span style="color: red;">red text</span>

# Results and Visualization
Download your unzipped reference genome (.fna), .bam, .bam.bai, 
.vcf.gz, and .vc.gz.tbi 
files onto your local machine and open them in the IGV viewer. 

The user has 
How to interpret the output.
Provide instructions for visualizing results in tools like IGV.


# Customize Pipeline

## Resources
The user can modify the default cps and memory of docker for all process, by adding the specific requirements in each of them .
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