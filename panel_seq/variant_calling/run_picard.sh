#!/bin/bash

PICARD_DIR=picard-1.138/bin # picard v1.138
TMP_DIR=/home/yw222/temp/

CMD="java -XX:+UseSerialGC -Xmx64G -jar ${PICARD_DIR}/picard.jar $@"
echo ${CMD}
${CMD}
