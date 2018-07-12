#!/bin/bash

#SBATCH --time=0-1  # days-hours
#SBATCH --job-name=APSO-particle  # Job name
#SBATCH --nodes=1
#SBATCH --ntasks=8  # Number of cores
#SBATCH --mem=16G  # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production  # Partition to submit to
#SBATCH --output=apso_%A_%a.out  # File to which STDOUT will be written
#SBATCH --error=apso_%A_%a.err  # File to which STDERR will be written
##SBATCH --mail-type=END  # Type of email notification- BEGIN,END,FAIL,ALL
##SBATCH --mail-user=jnfass@ucdavis.edu  # Email to which notifications will be sent

## READ in read file, self overlaps PAF, parameters vector, ... expected assembled piece sizes
READS=${0}
OVLPS=${1}
OPT_m=${2}
OPT_i=${3}
OPT_s=${4}
OPT_c=${5}
OPT_o=${6}
OPT_h=${7}
OPT_I=${8}
OPT_g=${9}
OPT_d=${10}
OPT_n=${11}
OPT_F=${12}
# forget chr sizes for now?

## create uniquely named temp directory
NS=`date -Ins | cut -f2 -d, | cut -f1 -d-`
TMP="tmp.APSO.${SLURM_JOB_ID}.${NS}"
rmdir $TMP
mkdir $TMP

## OVERLAP reads via minimap2
# should be done only once, before this script

## ASSEMBLE via miniasm
# run actual assembly
module load miniasm
miniasm -m $OPT_m -i $OPT_i -s $OPT_s -c $OPT_c \
    -o $OPT_o -h $OPT_h -I $OPT_I -g $OPT_g -d $OPT_d \
    -n $OPT_n -F $OPT_F -f $READS $OVLPS > $TMP/asm.gfa
# strip out unitigs
cat $TMP/asm.gfa | grep ^S | while read line; do
    name=`echo $line | cut -f2 -d\ `
    seq=`echo $line | cut -f3 -d\ `
    echo ">$name" > $TMP/"$name".fa
    echo "$seq" >> $TMP/"$name".fa
done
countL=`ls temp_contigs/*l.fa | wc -l`
countC=`ls temp_contigs/*c.fa | wc -l`
lengthL=`ls -ltra temp_contigs/*l.fa | perl -ane 'print $F[4].";"'`
lengthC=`ls -ltra temp_contigs/*c.fa | perl -ane 'print $F[4].";"'`
# echo -ne "$params\t$countL\t$lengthL\t$countC\t$lengthC\n" >> paramScan.tsv

## POLISH via racon
# skip for now??

## MAP reads back to assembly via minimap2
module load minimap2
module load samtools
minimap2 -a -x ava-pb $TMP/asm.fa $READS | samtools view -uhS | \
    samtools sort -m 16G -o $TMP/reads2asm.bam -
samtools index $TMP/reads2asm.bam

## RETURN score, destroy temp directory(?)
# score depends on clipping, %id(?), sizes conforming to expected (fuzzily)








