#!/bin/sh
# Load demo. Launcher written for toolenv, adjust to your needs.

SN_VERSION=11.10.11
export SPECMAN_PATH=".." 
toolenv cadence-ius--$SN_VERSION specview -p "load examples/test_memoize; test"


# clean
rm -f *.elog *.log *.*~

# end
