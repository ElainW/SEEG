#!/bin/env Rscript

library(yyxMosaicHunter)
library(pryr)
library(stats)

args<-commandArgs(TRUE)
verbose=TRUE
read_file=args[1]
write_file=args[2]

input=read.delim(file=read_file,header=FALSE,stringsAsFactors=FALSE,colClasses=c("character","numeric","numeric","character","character","character","character","character","character"),quote="")
output=numeric(0)

for(i in 1:nrow(input))
{
	chr=input[i,1]
	pos=input[i,3]
	ref_nt=input[i,4]
	alt1_nt=input[i,5]
	alt2_nt=input[i,6]
	ref_base=input[i,7]
	alt1_base=input[i,8]
	alt2_base=input[i,9]
	
	ref_base=gsub("~","",ref_base)
	alt1_base=gsub("~","",alt1_base)
	alt2_base=gsub("~","",alt2_base)

	ref_depth=nchar(ref_base)
	alt1_depth=nchar(alt1_base)
	alt2_depth=nchar(alt2_base)
	
	mle_calculate_only=alt1_depth/(ref_depth+alt1_depth)
	mle_interval=1.5/sqrt((ref_depth+alt1_depth))
	mle_lw=mle_calculate_only-mle_interval
	mle_up=mle_calculate_only+mle_interval
	if(mle_lw<0|is.na(mle_lw)|is.null(mle_lw))
	{
		mle_lw=0
	}
	if(mle_up>1|is.na(mle_up)|is.null(mle_up))
	{
		mle_up=1
	}
	
	mh_result=yyx_wrapped_mosaic_hunter_for_one_site(ref_base,alt1_base,output_log10=TRUE)
	cred_int=yyx_get_credible_interval(mh_result$likelihood_fun,c(mle_lw,mle_up),0.95)
	
	output=rbind(output,c(chr,pos,ref_nt,alt1_nt,alt2_nt,ref_depth,alt1_depth,alt2_depth,signif(mh_result$ref_het_alt_mosaic_posterior,7),signif(cred_int$MLE,7),signif(cred_int$CI,7)))
}

write.table(output,file=write_file,sep="\t",row.names=FALSE,quote=FALSE,col.names=FALSE)
