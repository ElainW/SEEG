#!/bin/bash

AGENT_HOME=/home/yw222/AGeNT_2.0.5/agent
TMP_DIR=~/temp

CMD="java -Djava.io.tmpdir=${TMP_DIR} -Xmx64G -jar ${AGENT_HOME}/lib/locatit-2.0.5.jar $@"
echo ${CMD}
${CMD}
