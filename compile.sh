#!/bin/bash

if [ $DEBUG ]; then
    set -x
fi

#
# Compile examples
#    Args: examples to compile
#

function info () {
    echo "INFO: $@"
}

function error () {
    echo "ERROR: $@"
    exit 1
}

function compile () {
    local ex output compiled
    compiled=''
    ex=$1
    if  [ -d $ex ]; then
        output=$ex/output
        rm -Rf $output
        mkdir -p $output

        for templ in `find $ex -maxdepth 1 -type f -name '*.pan'`; do
            grep -E "^[[:space:]]*object[[:space:]]+template[[:space:]]+" $templ >& /dev/null
            if [ $? -ne 0 ];then
                continue
            fi

            # To add dep output format, need to search/repalce the abosute paths of this repo and teplate_library_core
            comp_out=`panc --include-path $ex:$template_library --output-dir $output --formats json,xml,pan $templ 2>&1`
            if [ $? -eq 0 ]; then
                compiled="$compiled $templ"
            else
                error "Compilation $templ failed: $comp_out"
            fi
        done
        
        if [ -z "$compiled" ]; then
            error "Nothing compiled in example directory $ex"
        else
            # compiled starts with ' '
            info "Compiled templates in example directory $ex:$compiled"
        fi
    else
        error "Failed to locate example directory $ex"
    fi
}


function find_template_library_core () {
    template_library=$TEMPLATE_LIBRARY_CORE
    default_name=template-library-core

    if [ -z "$template_library" ]; then
        for base in .. ../../quattor; do
            dest=`readlink -f "$base/$default_name"`
            if [ -d $dest ]; then
                template_library=$dest
                break
            fi
        done
    fi

    if [ -z "$template_library" ]; then
        error "Cannot find template-library-core. Set it via TEMPLATE_LIBRARY_CORE variable."
    fi
}

find_template_library_core

for ex in "$@"; do
    compile $ex
done
