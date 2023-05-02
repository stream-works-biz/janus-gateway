#!/bin/bash

# converter.sh

# Declare the binary path of the converter
januspprec_binary=/usr/local/bin/janus-pp-rec

# Contains the prefix of the recording session of janus e.g
input_dir="$1"
input_prefix="$2"
audio_sufix="$3" # wav
output_dir="$4"
output_ext="$5"
work_dir="/mnt/anyput/janus/tmp"

files=`find $input_dir -type f -name $input_prefix*.mjr -printf "%f\n"`
if [ $? -ne 0 ]; then
    echo "Oops..."
    exit 1
fi

audiofiles=()

# Create temporary files that will store the individual tracks (audio and video)
for filenm in $files; do
    fullpath="${input_dir}/${filenm}"
    case "${filenm}" in
        *audio.mjr)
            tmp_file="$work_dir/${filenm%.mjr}.$audio_sufix"
            audiofiles=("${audiofiles[@]}" $tmp_file)
            ;;
        *)
            tmp_file=""
            ;;
    esac
    if [[ "$tmp_file" != "$" ]]; then
        echo $tmp_file
        $januspprec_binary --debug-level=3 $fullpath $tmp_file
    else
        echo "undfined $fullpath"
    fi
done

if [ $? -ne 0 ]; then
    echo "Oops..."
    exit 1
fi


mkdir -m 775 -p $output_dir

uniqueids=();

for audiofile in ${audiofiles[@]}; do
    basename="${audiofile##*/}"
    #echo "base $basename"
    uniqueid="`echo "$basename" | cut -b 1-19`"
    #echo "id $uniqueid"

    exists=false

    for i in "${uniqueids[@]}"; do
        if [[ $uniqueid == "$i" ]]; then
            exists=true
        fi
    done

    if ! $exists ; then
        uniqueids=(${uniqueids[@]} "$uniqueid") 
        echo "add $uniqueid"
    fi
done

for audiofile in ${uniqueids[@]}; do

    user="$work_dir/$audiofile-user-audio.wav"
    peer="$work_dir/$audiofile-peer-audio.wav"

    outputfile="$output_dir/$audiofile.$output_ext"

    echo "start marge `date '+%y/%m/%d %H:%M:%S'` $outputfile"
    echo $user
    echo $peer
    ffmpeg -y -i $user -i $peer -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" $outputfile
    echo "end   marge `date '+%y/%m/%d %H:%M:%S'`"

    /usr/bin/rm -f $audiofile
    /usr/bin/rm -f $videofile

done

echo "Done !"
exit 0
