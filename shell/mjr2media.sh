#!/bin/bash

# converter.sh

# Declare the binary path of the converter
januspprec_binary=/usr/local/bin/janus-pp-rec

# Contains the prefix of the recording session of janus e.g
dir_path="$1"
audio_suffix="$2" # opus
video_suffix="$3" # webm
output_dir="$4"
output_ext="$5"
room_seq="$6"
work_dir="/mnt/anyput/janus/tmp"

files=`find $dir_path -type f -name *.mjr -printf "%f\n"`
if [ $? -ne 0 ]; then
    echo "Oops..."
    exit 1
fi

audiofiles=()

# Create temporary files that will store the individual tracks (audio and video)
for filenm in $files; do
    fullpath="${dir_path}/${filenm}"
echo $fullpath
    case "${filenm}" in
        *audio-*.mjr)
            tmp_file="$work_dir/${filenm%.mjr}.$audio_suffix"
            audiofiles=("${audiofiles[@]}" $tmp_file)
            ;;
        *video-*.mjr)
            tmp_file="$work_dir/${filenm%.mjr}.$video_suffix"
            ;;
        *)
            tmp_file=""
            ;;
    esac
    if [[ "$tmp_file" != "$" ]]; then
   #     echo $tmp_file
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
sqlfile="$output_dir/update.sql"
if [ -f "$sqlfile" ]; then  
   /usr/bin/rm $sqlfile 
fi

for audiofile in ${audiofiles[@]}; do
    basename="${audiofile##*/}"
    echo "b1 $basename"
    basename="${basename/-audio-0/-video-1}"
    basename="${basename/.$audio_suffix/.$video_suffix}"
    echo "b2 $basename"
    videofile="$work_dir/$basename"
    echo "videofile $videofile"

    outputfile="$output_dir/${basename%-video-1.$video_suffix}.$output_ext"
    uniqueid=`echo "$basename" | cut -d "-" -f4`
    timestamp=`echo "$basename" | cut -d "-" -f5`

#    echo "base $basename uniqueid $uniqueid timestamp $timestamp $sqlfile"
#    echo -e "update t_video_room_join set recording_timestamp=$timestamp where video_room_seq=$room_seq and _id='$uniqueid';" | tee -a $sqlfile >> /dev/null

    echo "start marge `date '+%y/%m/%d %H:%M:%S'` $outputfile"
    if [[ "$output_ext" == "webm" ]]; then
        ffmpeg -y -loglevel warning -i $audiofile -i $videofile -c:v copy -r 30 -c:a copy -strict experimental $outputfile
    fi
    if [[ "$output_ext" == "mp4" ]]; then
        ffmpeg -y -loglevel warning -i $audiofile -i $videofile -c:v libx264 -r 30 -c:a aac -strict experimental $outputfile
    fi
    echo "end   marge `date '+%y/%m/%d %H:%M:%S'`"

    /usr/bin/rm -f $audiofile
    /usr/bin/rm -f $videofile

done


#/usr/bin/psql -U teams -d teams_tabei -h teams-ilb-dev.omnialink.net -p 9998 -f $sqlfile

echo "Done !"
exit  
