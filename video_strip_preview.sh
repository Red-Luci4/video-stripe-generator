#!/bin/bash

ARGV=("$@")
ARGC=$#

INPUT="$1"
<<<<<<< HEAD
<<<<<<< HEAD
OUTPUT="Preview_$(echo   "$(basename "$1")"|\
							sed -E "s~(.*\.)[^\.]*$~\1jpg~g")"
=======
OUTPUT="$(echo "$(basename "$1")"|sed -E "s~(.*\.)[^\.]*$~\1jpg~g")"
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
=======
OUTPUT="$(echo "$(basename "$1")"|sed -E "s~(.*\.)[^\.]*$~\1jpg~g")"
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
echo "output = $OUTPUT"

TITLE="$(basename "$1")"
echo "title = $TITLE"
<<<<<<< HEAD
<<<<<<< HEAD

TITLE_SAN=$(echo $TITLE|\
			sed -E 's~[^a-z^A-Z^0-9^\.^ ^\-^_]~~g')
LENGTH=1920
=======
=======
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
SIZE=360
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
BORDER=10
PADDING=10
COLUMN=5
ROW=3
SIZE=372
#SIZE=$(($(($((LENGTH-BORDER*2)) - $(($((COLUMN - 1)) * PADDING)))) / COLUMN))
echo "Reverse Calculated Size = $SIZE"

TOTAL_PREV=$((COLUMN * ROW))
echo "Preview image count = $TOTAL_PREV"
Tot_Frames="$(ffmpeg -i "$1" -map 0:v:0 -c:v copy -f null /dev/null 2>&1 |\
				grep -oP 'frame=[\s]*\K\d+' |\
				tail -n1)"
echo "total no. of frames = $Tot_Frames"
<<<<<<< HEAD
<<<<<<< HEAD

Encoding="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_long_name "$INPUT"|\
			grep -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\ncodec_long_name=\K[^\n]+\n'|\
			tr -d '\0')"
echo "Input File Encoding = $Encoding"

Duration="$(ffprobe -v error -select_streams v:0 -show_entries stream=duration "$INPUT"|\
			grep -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nduration=\K[\d \.]+\n'|\
			tr -d '\0')"
=======
Encoding="$(ffprobe -v error -select_streams v:0 -show_entries stream=duration "$INPUT"|grep -zP "(?:<\!\[PROGRAM\]\n)(?<=\[STREAM\]\nduration=)[\. 0-9]+\n")"
echo "Input File Encoding = $Encoding"
Duration="$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nokey=1:noprint_wrappers=1 "$INPUT")"
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
=======
Encoding="$(ffprobe -v error -select_streams v:0 -show_entries stream=duration "$INPUT"|grep -zP "(?:<\!\[PROGRAM\]\n)(?<=\[STREAM\]\nduration=)[\. 0-9]+\n")"
echo "Input File Encoding = $Encoding"
Duration="$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nokey=1:noprint_wrappers=1 "$INPUT")"
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
Duration=${Duration%.*}
echo "Video Duration = $Duration"

Duration_F="$(($((${Duration%.*} / 3600)) % 24))\:$(($((${Duration%.*} / 60)) % 60))\:$((${Duration%.*} % 60))"
echo "Formatted Video Duration = $Duration_F"

#FRMS_TIME=$(ffprobe -v error -select_streams v:0 -show_entries program_stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 "$INPUT")
<<<<<<< HEAD
<<<<<<< HEAD

FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate "$INPUT"|\
		grep  -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\navg_frame_rate=\K[\d \. \/]+\n'|\
		tr -d '\0')
FPS=$(($FPS))
=======
FPS=$(($(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 "$INPUT")))
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
=======
FPS=$(($(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 "$INPUT")))
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
echo "Video FPS = $FPS"

SKIP=$((Tot_Frames / TOTAL_PREV))
echo "Frame Gap = $SKIP"
<<<<<<< HEAD
<<<<<<< HEAD

W_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=width "$INPUT"|\
			grep  -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nwidth=\K[\d]+\n'|\
			tr -d '\0')"
echo "width of video = $W_Frame"

H_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=height "$INPUT"|\
			grep  -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nheight=\K[\d]+\n'|\
			tr -d '\0')"
=======
W_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nokey=1:noprint_wrappers=1 "$1")"
echo "width of video = $W_Frame"
H_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nokey=1:noprint_wrappers=1 "$1")"
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
=======
W_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nokey=1:noprint_wrappers=1 "$1")"
echo "width of video = $W_Frame"
H_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nokey=1:noprint_wrappers=1 "$1")"
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
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

#TIT_FONT_SIZE=$(($(($(( FINAL_WIDTH > FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT ))/FINAL_WIDTH)) * 30))
TIT_FONT_SIZE=$(($(($(( W_Frame > H_Frame ? W_Frame : H_Frame )) / $(( W_Frame < H_Frame ? W_Frame : H_Frame )) * $FINAL_WIDTH)) / 30))
echo "Title Sample Font size = $TIT_FONT_SIZE"

TIT_FONT_PROP=":fontcolor=white:fontsize=$TIT_FONT_SIZE"
TIT_BOX_PROP=":box=1:boxcolor=black@0.5:boxborderw=5"


TITLE_SPACE=$(($(($(( W_Frame > H_Frame ? W_Frame : H_Frame )) / $(( W_Frame < H_Frame ? W_Frame : H_Frame )) * $FINAL_WIDTH)) / 5))
#exit 0
for (( i=0 ; i <= $ARGC ; i++ ))
do
echo "Final Echo"
done
#exit 0
<<<<<<< HEAD
ffmpeg -i "$INPUT" -y -vframes 1 -q:v 2 -vf \
	"select=not(mod(n\\,$SKIP)),\
	drawtext=fontfile="$FONT":text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
	scale=$SIZE:-1,\
	tile=${COLUMN}x${ROW}:padding=$PADDING:margin=$BORDER:color=Black,\
	pad=width=2+iw:height=2+ih+$TITLE_SPACE:x=1:y=1+$TITLE_SPACE:color=black,\
	drawtext=fontfile="$FONT":text='Title - ${TITLE_SAN}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20,\
	drawtext=fontfile="$FONT":text='Dimentions - ${H_Frame} x ${W_Frame} | FPS - ${FPS}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*1.5,\
	drawtext=fontfile="$FONT":text='Encoding - ${Encoding}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*3,\
	drawtext=fontfile="$FONT":text='Duration - ${Duration_F}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*4.5"\
	"$OUTPUT" 2>&1
=======
ffmpeg -i "$INPUT" -y -vframes 1 -q:v 2 -vf "select=not(mod(n\\,$SKIP)),\
                                                    drawtext=fontfile="$FONT":text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
                                                    scale=$SIZE:-1,\
                                                    tile=${COLUMN}x${ROW}:padding=$PADDING:margin=$BORDER:color=Black,\
                                                    pad=width=2+iw:height=2+ih+$TITLE_SPACE:x=1:y=1+$TITLE_SPACE:color=black,\
                                                    drawtext=fontfile="$FONT":text='Title - $TITLE'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20,\
                                                    drawtext=fontfile="$FONT":text='Dimentions - ${H_Frame} x ${W_Frame} | FPS - ${FPS}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*1.5,\
                                                    drawtext=fontfile="$FONT":text='Encoding - ${Encoding}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*3,\
                                                    drawtext=fontfile="$FONT":text='Duration - ${Duration_F}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*4.5"\
                                                    "$OUTPUT"
<<<<<<< HEAD
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)
=======
>>>>>>> parent of 2c011a1 (Fix name-stb time-font-size property-aggregator)

