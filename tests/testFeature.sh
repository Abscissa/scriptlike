#!/bin/sh
SCRIPT_DIR="$(dirname "$(dirname "$0")/$(readlink "$0")")"
if [ -z "$DMD" ]; then
	DMD=dmd
fi
rdmd --compiler=$DMD -debug -g -I$SCRIPT_DIR/../src/ -of$SCRIPT_DIR/.testFeature $SCRIPT_DIR/testFeature.d "$@"
