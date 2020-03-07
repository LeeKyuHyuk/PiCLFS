#!/bin/bash
#
# PiCLFS packages download script
# Optional parameteres below:
export WORKSPACE_DIR=$PWD
export SOURCES_DIR=$WORKSPACE_DIR/sources
# End of optional parameters

function success() {
    echo -e "\e[1m\e[32m$1\e[0m"
}

function timer {
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local stime=$1
        etime=$(date '+%s')
        if [[ -z "$stime" ]]; then stime=$etime; fi
        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%02d:%02d:%02d' $dh $dm $ds
    fi
}

total_download_time=$(timer)

wget -c -i $WORKSPACE_DIR/wget-list -P $SOURCES_DIR

success "\nTotal download time: $(timer $total_download_time)\n"
