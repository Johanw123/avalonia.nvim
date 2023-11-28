#!/bin/bash
transmit_png() {
    data=$(base64 "$1")
    data="${data//[[:space:]]}"
    builtin local pos=0
    builtin local chunk_size=4096
    while [ $pos -lt ${#data} ]; do
        builtin printf "\e_G"
        [ $pos = "0" ] && printf "a=T,f=100,"
        builtin local chunk="${data:$pos:$chunk_size}"
        pos=$(($pos+$chunk_size))
        [ $pos -lt ${#data} ] && builtin printf "m=1"
        [ ${#chunk} -gt 0 ] && builtin printf ";%s" "${chunk}"
        builtin printf "\e\\"
    done
}

transmit_png "$1"
