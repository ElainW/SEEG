#!/bin/bash

GATK_HOME=/home/yh174/tools/gatk-3.6/gatk
TMP_DIR=/home/yw222/temp/

CMD="java -XX:+UseSerialGC -Xmx64G -Djava.io.tmpdir=${TMP_DIR} -jar ${GATK_HOME}/GenomeAnalysisTK.jar $@"
echo ${CMD}
${CMD}
