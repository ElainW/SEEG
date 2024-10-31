#!/bin/bash

INFQ=$1
OUTFQ=$2

# there is an extra field in the @SEQ_ID line, remove it before bwa mem
zcat $INFQ | cut -d" " -f1 | gzip > $OUTFQ
