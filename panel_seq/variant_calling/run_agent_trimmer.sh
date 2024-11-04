#!/bin/bash

AGENT_HOME=... # downloaded from agilent website: AGeNT_2.0.5
TMP_DIR=~/temp

CMD="java -Djava.io.tmpdir=${TMP_DIR} -Xmx64G -jar ${AGENT_HOME}/lib/trimmer-2.0.3.jar $@"
echo ${CMD}
${CMD}
