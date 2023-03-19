# rnaseq_compare
A pipeline for: Download, align, count, and analyze for rna-seq data in a lightweight fashion


download -> quality check -> trim -> quality check -> align -> repeat for next sample

SRAtoolkit -> FASTQC -> trimgalore -> FASTQC -> STAR -> repeat for next sample

## Instructions
1. download accession values from rna-seq of interest from [SRA](this)
    - download: send to -> file -> summary
2. move file into same directory as 
