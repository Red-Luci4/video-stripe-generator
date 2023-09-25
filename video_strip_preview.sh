#!/bin/bash

Help_Func(){
printf "\t%s\n\n" "This is script to generate Video Stripe Preview generator"
printf "\tUsage : \v video-stripe-preview [Flag Input]...\n\n\n"
printf "%15s%5c%10s%5c%15s\n\n" "Flag" "|" "Input" "|" "Discription"
printf "%17s%16s\t%s\n\n" "-h/--help" 			"N/A" 					"This flag will print this Help Information"
printf "%17s%16s\t%s\n\n" "-el/--error_log"		"N/A" 					"This flag will make ffmpeg log everything to stderr"
printf "%17s%16s\t%s\n\n" "-ew/--error_write"	"N/A" 					"This flag will write FFmpegs stderr to \"ffmpeg_error.log\" in Current Working Directory"
printf "%17s%16s\t%s\n\n" "-vf/--video_file" 	"Input File" 			"This flag will take <String>Input of the Video File location"
printf "%17s%16s\t%s\n\n" "-l/--length" 		"Preview Width" 		"This flag will take <Intiger>Input of the approximate width in pixels of the final preview image"
printf "%17s%16s\t%s\n\n" "-b/--border" 		"Border size" 			"This flag will take <Intiger>Input of border size in pixels of the final tiled preview"
printf "%17s%16s\t%s\n\n" "-p/--padding" 		"Padding Size" 			"This flag will take <Intiger>Input of padding size in pixels of the final tiled preview"
printf "%17s%16s\t%s\n\n" "-c/--column" 		"No of Columns" 		"This flag will take <Intiger>Input of number of columns of tiles in the final preview Minimum Value = 1"
printf "%17s%16s\t%s\n\n" "-r/--row" 			"No of Rows" 			"This flag will take <Intiger>Input of number of rows of tiles in the final preview Minimum Value = 1"
}

Cache_Error(){
Error_List="$Error_List$(echo -e $1)"
}

Error_List=""

ARGV=("$@")
ARGC=$#

LENGTH=720
SIZE=360
BORDER=10
PADDING=10
COLUMN=3
ROW=2
#SIZE=372
INPUT=""


ffmpeg_log_flag=""
ffmpeg_log_output=""


while [[ $# -gt 0 ]]; do
    case "$1" in
        -vf|--video_file)
            if [[ -f "$2" && -z $INPUT ]];then
				INPUT="$2"
				if [[ -s "$2" ]];then
					VID_CHK=$(ffprobe -v error -select_streams \
							v:0 -count_packets -show_entries \
							stream=nb_read_packets "$2"|\
							grep -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nnb_read_packets=\K[\d]+\n'|\
							tr -d '\0')

					if [[ $VID_CHK -gt 1 ]];then
						printf "The Input file is a valid video file\n"
					elif [[ $VID_CHK -eq 1 ]];then
						Cache_Error "\n\t Input file = $2\n\tError  :  The Input file is a image file with single frame\n"
					else
						Cache_Error "\n\t Input file = $2\n\tError  :  Input file is of unknown Data/Format\n"
					fi
				else
					Cache_Error "\n\t Input file = $2\n\tError  :  The Input File is empty file\n"
				fi
			elif [[ ! -z $INPUT ]];then
				Cache_Error "\n\t Input file = $2\n\tError  :  The Input File already provided \n"
			else
				Cache_Error "\n\t Input file = $2\n\tError  :  The Input File is not a regular file\n"
				INPUT="--Irregular File-- $2"
			fi
			shift 2
            ;;
		-h|--help)
			Help_Func
			exit 0
			;;
		-el|--error_log)
			ffmpeg_log_flag="-loglevel error -v 99"
			printf "\n\tFFmpeg will show all stderr\n\n"
			shift 1
			;;
		-ew|--error_write)
			ffmpeg_log_output="ffmpeg_error.log"
			printf "\n\tWritting FFmpeg Error log to : $ffmpeg_log_output\n\n"
			shift 1
			;;
		-l|--length)
			LENGTH=$2
			if [[ $LENGTH -lt 0 ]];then
				Cache_Error "\n\t Length = $2\n\tError  :  Length cannot be a Negative Number Minimum Length is 540 \n"
			elif [[ $LENGTH -lt 540 ]];then
				Cache_Error "\n\t Length = $2\n\tError  :  Minimum Length is 540 \n"
			fi
			shift 2
			;;
		-b|--border)
			BORDER=$2
			if [[ $BORDER -lt 0 ]];then
				Cache_Error "\n\t Border = $2\n\tError  :  Border cannot be a Negative Number Minimum Length is 0 \n"
			fi
			shift 2
			;;
		-p|--padding)
			PADDING=$2
			if [[ $PADDING -lt 0 ]];then
				Cache_Error "\n\t Padding = $2\n\tError  :  Padding cannot be a Negative Number Minimum Length is 0 \n"
			fi
			shift 2
			;;
		-r|--row)
			ROW=$2
			if [[ $ROW -lt 1 ]];then
				Cache_Error "\n\t Row = $2\n\tError  :  Minimum Row is 1 \n"
			fi
			shift 2
			;;
		-c|--column)
			COLUMN=$2
			if [[ $COLUMN -lt 1 ]];then
				Cache_Error "\n\t Column = $2\n\tError  :  Minimum Column is 1 \n"
			fi
			shift 2
			;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$INPUT" ]];then
Cache_Error "\n\t Input file = [NULL]\n\tError  :  The Input File is not provided\n"
fi

if [[ ! -z $Error_List ]];then
printf "\n\tThe following errors have been detected :\n\n"
echo "$Error_List"
exit 1
fi

OUTPUT="Preview_$(echo   "$(basename "$INPUT")"|\
							sed -E "s~(.*\.)[^\.]*$~\1jpg~g")"
echo "output = $OUTPUT"

TITLE="$(basename "$INPUT")"
echo "title = $TITLE"

TITLE_SAN=$(echo $TITLE|\
			sed -E 's~[^a-z^A-Z^0-9^\.^ ^\-^_]~~g')

SIZE=$(($(($((LENGTH-BORDER*2)) - $(($((COLUMN - 1)) * PADDING)))) / COLUMN))
echo "Reverse Calculated Size = $SIZE"

TOTAL_PREV=$((COLUMN * ROW))
echo "Preview image count = $TOTAL_PREV"

Tot_Frames="$(ffmpeg -i "$INPUT" -map 0:v:0 -c:v copy -f null /dev/null 2>&1 |\
				grep -oP 'frame=[\s]*\K\d+' |\
				tail -n1)"
echo "total no. of frames = $Tot_Frames"


Encoding="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_long_name "$INPUT"|\
			grep -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\ncodec_long_name=\K[^\n]+\n'|\
			tr -d '\0')"
echo "Input File Encoding = $Encoding"

Duration="$(ffprobe -v error -select_streams v:0 -show_entries stream=duration "$INPUT"|\
			grep -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nduration=\K[\d \.]+\n'|\
			tr -d '\0')"


Duration=${Duration%.*}
echo "Video Duration = $Duration"

Duration_F="$(($((${Duration%.*} / 3600)) % 24))\:$(($((${Duration%.*} / 60)) % 60))\:$((${Duration%.*} % 60))"
echo "Formatted Video Duration = $Duration_F"

#FRMS_TIME=$(ffprobe -v error -select_streams v:0 -show_entries program_stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 "$INPUT")


FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate "$INPUT"|\
		grep  -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\navg_frame_rate=\K[\d \. \/]+\n'|\
		tr -d '\0')
FPS=$(($FPS))

echo "Video FPS = $FPS"

SKIP=$((Tot_Frames / TOTAL_PREV))
if [[ $SKIP -eq 0 ]];then
SKIP=1
fi
echo "Frame Gap = $SKIP"

W_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=width "$INPUT"|\
			grep  -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nwidth=\K[\d]+\n'|\
			tr -d '\0')"
echo "width of video = $W_Frame"

H_Frame="$(ffprobe -v error -select_streams v:0 -show_entries stream=height "$INPUT"|\
			grep  -ozP '(?<![\[]PROGRAM[\]]\n)[\[]STREAM[\]]\nheight=\K[\d]+\n'|\
			tr -d '\0')"
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


#TITLE_SPACE=$(($(($(( W_Frame > H_Frame ? W_Frame : H_Frame )) / $(( W_Frame < H_Frame ? W_Frame : H_Frame )) * $FINAL_WIDTH)) / 5))
TITLE_SPACE=$(($(($(( FINAL_WIDTH > FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT )) / $(( FINAL_WIDTH < FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT )) * $FINAL_WIDTH)) / 5))
#exit 0
for (( i=0 ; i <= $ARGC ; i++ ))
do
echo "Final Echo"
done
#exit 0

if [[ -z $ffmpeg_log_output ]];then
ffmpeg $ffmpeg_log_flag -i "$INPUT" -y -vframes 1 -q:v 2 -vf \
	"select=not(mod(n\\,$SKIP)),\
	drawtext=fontfile=$FONT:text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
	scale=$SIZE:-1,\
	tile=${COLUMN}x${ROW}:padding=$PADDING:margin=$BORDER:color=Black,\
	pad=width=2+iw:height=2+ih+$TITLE_SPACE:x=1:y=1+$TITLE_SPACE:color=black,\
	drawtext=fontfile=$FONT:text='Title - ${TITLE_SAN}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20,\
	drawtext=fontfile=$FONT:text='Dimentions - ${H_Frame} x ${W_Frame} | FPS - ${FPS}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*1.5,\
	drawtext=fontfile=$FONT:text='Encoding - ${Encoding}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*3,\
	drawtext=fontfile=$FONT:text='Duration - ${Duration_F}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*4.5"\
	"$OUTPUT" 2>&1
else 
	ffmpeg $ffmpeg_log_flag -i "$INPUT" -y -vframes 1 -q:v 2 -vf \
	"select=not(mod(n\\,$SKIP)),\
	drawtext=fontfile=$FONT:text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
	scale=$SIZE:-1,\
	tile=${COLUMN}x${ROW}:padding=$PADDING:margin=$BORDER:color=Black,\
	pad=width=2+iw:height=2+ih+$TITLE_SPACE:x=1:y=1+$TITLE_SPACE:color=black,\
	drawtext=fontfile=$FONT:text='Title - ${TITLE_SAN}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20,\
	drawtext=fontfile=$FONT:text='Dimentions - ${H_Frame} x ${W_Frame} | FPS - ${FPS}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*1.5,\
	drawtext=fontfile=$FONT:text='Encoding - ${Encoding}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*3,\
	drawtext=fontfile=$FONT:text='Duration - ${Duration_F}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*4.5"\
	"$OUTPUT" 2>$ffmpeg_log_output
fi