#!/bin/bash

# Take tab-separated input in 2+ colums (like a typos file), extract the first
# column, send it through a spell checker, and convert the result to xml.
# Finally open the xml in the default browser.

# For debugging, uncomment this command:
# set -x

# Language being tested, ISO 639-1 code if available:
GTLANG2=sto

# Directory variables:
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
top_srcdir="$SCRIPT_DIR/.."
builddir="."
spellerdir=tools/spellcheckers/fstbased/desktop/hfst

# File variables:
engine=vk
typos_file="$top_srcdir/test/data/typos.txt"
file_spesifier="$(basename ${typos_file} .txt)"
speller_test_data=speller_test_data.txt
speller_input=speller_input.${engine}.txt
speller_output=speller_output.${engine}.txt
speller_timeusage=speller_timeusage.${engine}.txt
speller_results="$SCRIPT_DIR/speller_result_${file_spesifier}.${engine}.xml"

# Other variables:
DATE=$(date +%Y%m%d)
TESTTIME=$(date +%H%M)

giella_core=$GTHOME/giella-core

function print_usage() {
    echo "Usage: $0 [OPTIONS...]"
    echo "Test the voikko command line speller voikkospell using typos data"
    echo
    echo "  -h, --help          Print this usage info"
    echo "  -b, --builddir DIR  Specify top build directory relative to"
    echo "                      the directory containing configure.ac"
    echo
}

# Wrong usage - short instruction:
if test $# -ge 3 ; then
    print_usage
    exit 1
fi

# manual getopt loop... Mac OS X does not have good getopt
while test $# -ge 1 ; do
    if test x$1 = x--help -o x$1 = x-h ; then
        print_usage
        exit 0
    elif test x$1 = x--builddir -o x$1 = x-b ; then
        if test -z "$2" ; then
            print_usage
            exit 1
        else
            builddir="$2"
            shift
        fi
    fi
    shift
done

# Set the top build dir after parameter parsing:
top_builddir="$top_srcdir/$builddir"

# Add easter egg version info trigger:
echo "nuvviDspeller	Divvun" > $SCRIPT_DIR/$speller_test_data
# Extract the typos, skipping input strings with space(s) in them:
grep -v '^[!#]' "$typos_file" | grep -v '^$' \
	| egrep -v '^[[:graph:]]+ [[:graph:]]' \
	>> $SCRIPT_DIR/$speller_test_data

# Extract the actual test data:
cut -f1 $SCRIPT_DIR/$speller_test_data > $SCRIPT_DIR/$speller_input

# Run the speller;
$giella_core/scripts/run_voikko_speller.sh $SCRIPT_DIR/$speller_input \
                                      $SCRIPT_DIR/$speller_output \
                                      $SCRIPT_DIR/$speller_timeusage \
                                      $GTLANG2 \
                                      "$top_builddir/$spellerdir"

rm -f "$speller_results"

# Convert speller output to common xml:
$giella_core/scripts/speller-testres.pl \
		--engine=${engine} \
		--lang=$GTLANG2 \
		--input="$SCRIPT_DIR/$speller_test_data" \
		--output="$SCRIPT_DIR/$speller_output" \
		--document=$(basename "$typos_file") \
		--date=$DATE-$TESTTIME \
		--version="n/a" \
		--toolversion="n/a" \
		--corpusversion="n/a" \
		--memoryuse="n/a" \
		--timeuse="$SCRIPT_DIR/$speller_timeusage" \
		--xml="$speller_results" \
		--corrsugg

# Open the xml file in the default browser
open "$speller_results"
