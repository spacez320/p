#!/bin/bash

# `p` is a program that gets a password out of
# my gpg encrypted passwords file and places it
# within the X clipboard

PASSWD_FILE_PATH="/home/matthew/mnt/logos"
PASSWD_MASTER_FILE="pass.gpg"

p_main() {

    local toecho=false

    SEARCH="$1"

    while getopts "o:d:" opt; do 
        case "$opt" in
            o)
                toecho=true    
                SEARCH="$OPTARG"
                ;;
            d)
               PASSWD_FILE_PATH="$OPTARG" 
               ;;
        esac
    done

    local passtmp=$(gpg --no-verbose --quiet \
        --homedir "$PASSWD_FILE_PATH/.gnupg" \
       -d "$PASSWD_FILE_PATH/$PASSWD_MASTER_FILE" | grep "$SEARCH")
    local passval=$(awk -F' ' '{ print $2 }' <<< $passtmp)

    if $toecho; then
        echo $passval
    else
        echo $passval | xclip -selection clipboard
    fi
}

p_main $@
