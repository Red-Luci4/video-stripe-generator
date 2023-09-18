#!/bin/bash

ARGV=("$@")
ARGC=$#

INPUT="$1"
OUTPUT="$(echo "$(basename "$1")"|sed -E "s~(.*\.)[^\.]*$~\1jpg~g")"
echo "output = $OUTPUT"
TITLE="$(basename "$1")"
echo "title = $TITLE"
SIZE=360
BORDER=10
PADDING=10
COLUMN=4
ROW=3
TOTAL_PREV=$((COLUMN * ROW))
echo "Preview image count = $TOTAL_PREV"
Tot_Frames="$(ffmpeg -i "$1" -map 0:v:0 -c:v copy -f null /dev/null 2>&1 | grep -oP 'frame=[\s]*\K\d+' | tail -n1)"
echo "total no. of frames = $Tot_Frames"
SKIP=$((Tot_Frames / TOTAL_PREV))
echo "Frame Gap = $SKIP"
W_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nokey=1:noprint_wrappers=1 "$1")"
echo "width of video = $W_Frame"
H_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nokey=1:noprint_wrappers=1 "$1")"
echo "height of video = $H_Frame"

FONT="/usr/share/fonts/TTF/OpenSans-Regular.ttf"
TIME="%{eif\:t/3600\:d\:2}\:%{eif\:mod(t/60\,60)\:d\:2}\:%{eif\:mod(t\,60)\:d\:2}\.%{eif\:100*mod(t\,1)\:d\:2}"

#TIME_FONT_SIZE=$((W_Frame/1280 * 48))
TIME_FONT_SIZE=$(($(( W_Frame > H_Frame ? W_Frame : H_Frame ))/640 * 48))
echo "Frame time font size = $TIME_FONT_SIZE"
FONT_PROP=":fontcolor=white:fontsize=$TIME_FONT_SIZE"
echo "Font properties = $FONT_PROP"
BOX_PROP=":box=1:boxcolor=black@0.5:boxborderw=5"

FINAL_WIDTH=$(($COLUMN * $SIZE + $(($COLUMN - 1)) * $PADDING + $BORDER * 2 ))
FINAL_HEIGHT=$(($COLUMN * $SIZE + $(($COLUMN - 1)) * $PADDING + $BORDER * 2 ))
echo "Final Sample image width = $FINAL_WIDTH"
TIT_FONT_SIZE=$(($(( W_Frame > H_Frame ? W_Frame : H_Frame ))/720 * 30))
echo "Title Sample Font size = $TIT_FONT_SIZE"

TIT_FONT_PROP=":fontcolor=white:fontsize=$TIT_FONT_SIZE"
TIT_BOX_PROP=":box=1:boxcolor=black@0.5:boxborderw=5"


TITLE_SPACE=200
#exit 0
for (( i=0 ; i <= $ARGC ; i++ ))
do
echo "Final Echo"
done
#exit 0
ffmpeg -i "$INPUT" -y -vframes 1 -q:v 2 -vf "select=not(mod(n\\,$SKIP)),\
                                                    drawtext=fontfile="$FONT":text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
                                                    scale=$SIZE:-1,\
                                                    tile=${COLUMN}x${ROW}:padding=$PADDING:margin=$BORDER:color=Black,\
                                                    pad=width=2+iw:height=2+ih+$TITLE_SPACE:x=1:y=1+$TITLE_SPACE:color=black,\
                                                    drawtext=fontfile="$FONT":text='$TITLE'$TIT_FONT_PROP$TIT_BOX_PROP:x=50:y=50" \
                                                    "$OUTPUT"

