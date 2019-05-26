#!/bin/sh

cd ~/build/Refactorio/RedMew/locale/ || exit
echo "Changing working directory to: "
pwd

ldiff() {

    while read file; do

        cat en/$file | sed 's/=.*//' | sed '/^#/ d' >diff_file.tmp
        count=$(cat "$1/$file" | sed 's/=.*//' | sed '/^#/ d' | git --no-pager diff --no-index -- diff_file.tmp - | tail -n +6 | grep -o '\-.*' | sed '/^-$/d' | wc -l)
        if [ "$count" -ne 0 ]; then
            echo
            echo "locale/$1/$file: ($count differences)"
            echo "------------------------------"

            cat "$1/$file" | sed 's/=.*//' | sed '/^#/ d' | git --no-pager diff --no-index -- diff_file.tmp - | tail -n +6 | grep -o '\-.*' | sed '/^-$/d' | sed 's/^-//'

            echo "------------------------------"
            rm diff_file.tmp
        fi
    done
}

echo "##############################"
echo "Checking locale for misplaced/missing keys."
for dir in *; do
    if [ "$dir" != "en" ]; then
        ls en | ldiff $dir
    fi
done

echo
echo "Done checking locale"
echo "##############################"

cd ../../../
echo "Changing working directory back to: "
pwd
