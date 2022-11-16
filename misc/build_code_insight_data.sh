#!/bin/bash
set -e

source setenv.sh

if [ $# -ne 1 ]; then
    echo "Illegal number of arguments"
    exit 1
fi

SYSTEM_DIR=${SYSTEM_DIR:-/opt/python_analysis_tool}
mkdir -p "$SYSTEM_DIR"

JAVA_OPTS="-Didea.system.path=\"$SYSTEM_DIR\" $JIGSAW_JAVA_OPTS"

eval "java -jar $JAVA_OPTS PythonAnalysisServer_deploy.jar python_skeleton_generator $1"
eval "java -jar $JAVA_OPTS PythonAnalysisServer_deploy.jar indexer $1"