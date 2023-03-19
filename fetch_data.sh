#!/bin/bash

#store accession values in array
accession_values=( $(cut -d ' ' -f1 hit_list.txt) )
count=0

#for each accession, run the program
for accession in ${accession_values[@]}; do

    echo ------------------------------------------------------
    echo "current experiment: " $accession " num completed: " $count
    echo ------------------------------------------------------

    #download a single rna-seq experiment (may be 2 files if paired-end)
    srun --mem=30G fasterq-dump $accession -O ./data/RAW_FASTQ

    #find all downloaded files
    fastqs=(`ls ./data/RAW_FASTQ`)
    echo "retrieved " ${#fastqs[@]} " files"

    if [ ${#fastqs[@]} -eq 2 ]; then

        echo "running paired-end mode"

        #run fastqc on raw
        srun --mem=30G fastqc -o ./data/RAW_QC ./data/RAW_FASTQ/${fastqs[0]} ./data/RAW_FASTQ/${fastqs[1]}

        #trim raw with trimgalore
        srun --mem=30G -c 7 trim_galore --cores 7 -o ./data/TRIMMED_FASTQ --paired ./data/RAW_FASTQ/${fastqs[0]} ./data/RAW_FASTQ/${fastqs[1]}

        #run fastqc again
        trimmed=(`ls ./data/TRIMMED_FASTQ/*.fq`)
        srun --mem=30G fastqc -o ./data/TRIMMED_QC ${trimmed[0]} ${trimmed[1]}

        #align and get genecounts
        srun --mem=50G -c 10 STAR --runThreadN 10 --sjdbGTFfeatureExon exon --sjdbGTFtagExonParentTranscript Parent --sjdbGTFtagExonParentGene gene --readFilesIn ${trimmed[0]} ${trimmed[1]} --quantMode GeneCounts --sjdbGTFfile ./data/GCF_003473485.1_MtrunA17r5.0-ANR_genomic.gff

        #move and label folder, delete big fastq files
        mkdir ./data/ALIGNMENT_RESULTS/$accession
        mv Log.final.out ReadsPerGene.out.tab SJ.out.tab ./data/ALIGNMENT_RESULTS/$accession
        rm ./data/RAW_FASTQ/*
        rm ./data/TRIMMED_FASTQ/*

    else

        echo "running single-ended mode"

        #run fastqc on raw
        srun --mem=30G fastqc -o ./data/RAW_QC ./data/RAW_FASTQ/${fastqs[0]}

        #trim raw with trimgalore
        srun --mem=30G -c 7 trim_galore --cores 7 -o ./data/TRIMMED_FASTQ ./data/RAW_FASTQ/${fastqs[0]}

        #run fastqc again
        trimmed=(`ls ./data/TRIMMED_FASTQ/*.fq`)
        srun --mem=30G fastqc -o ./data/TRIMMED_QC ${trimmed[0]}

        #align and get genecounts
        srun --mem=50G -c 50 STAR --runThreadN 50 --sjdbGTFfeatureExon exon --sjdbGTFtagExonParentTranscript Parent --sjdbGTFtagExonParentGene gene --readFilesIn ${trimmed[0]} --quantMode GeneCounts --sjdbGTFfile ./data/GCF_003473485.1_MtrunA17r5.0-ANR_genomic.gff

        #move and label folder, delete big fastq files
        mkdir ./data/ALIGNMENT_RESULTS/$accession
        mv Log.final.out ReadsPerGene.out.tab SJ.out.tab ./data/ALIGNMENT_RESULTS/$accession
        rm ./data/RAW_FASTQ/*
        rm ./data/TRIMMED_FASTQ/*
    fi

    count=$((count+1))
done
