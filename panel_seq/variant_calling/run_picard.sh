#!/bin/bash

PICARD_DIR=/home/yh174/tools/picard-1.138/bin
TMP_DIR=/home/yw222/temp/

CMD="java -XX:+UseSerialGC -Xmx64G -jar ${PICARD_DIR}/picard.jar $@"
echo ${CMD}
${CMD}
