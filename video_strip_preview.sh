#!/bin/bash

####INIT - Constants, Variables, Empty initialization

readonly C_HEIGHT_KEY="streams.stream.0.height"
readonly C_WIDTH_KEY="streams.stream.0.width"
readonly C_FRAMES_KEY="streams.stream.0.nb_read_packets"
readonly C_FPS_KEY="streams.stream.0.avg_frame_rate"
readonly C_DURATION_KEY="format.duration"
readonly C_ENCODING_KEY="streams.stream.0.codec_long_name"

readonly C_ARGV=("$@")
readonly C_ARGC=$#

L_Error_List=""
L_Report_List=""

V_FONT="/usr/share/fonts/TTF/OpenSans-Regular.ttf"
V_FORMAT='mjpeg'
V_REDIR='2>&1'
V_LENGTH=720
#V_SIZE=360
V_BORDER=10
V_PADDING=10
V_COLUMN=3
V_ROW=2
V_INPUT=""
V_ffmpeg_log_flag=""
V_ffmpeg_log_output="ffmpeg_error.log"

B_dry_run=""
B_safe_run=""
B_quiet=""

####!INIT

####INIT - Function initialization

Flag_Disc(){
printf "%17s%16s\t%s\n\n" "$1" "$2" "$3"
}

Help_Func(){
printf "\t%s\n\n" "This script can generate Video-Stripe-Preview image of a Video/Image-Sequences"
printf "\tUsage : \v video-stripe-preview [Flag Input]...\n\n\n"
printf "%15s%5c%10s%5c%15s\n\n" "Flag" "|" "Input" "|" "Discription"

Flag_Disc "-h/--help"          "N/A"           "This flag will print this Help Information"
Flag_Disc "-sr/--safe_run"     "N/A"           "This flag will Quit the Script right before FFmpeg command (-dr -el -ew wont work with this)"
Flag_Disc "-dr/--dry_run"      "N/A"           "This flag will Run the FFmpeg but outputs no data \"-f null /dev/null\""
Flag_Disc "-el/--error_log"    "N/A"           "This flag will make ffmpeg log everything to stderr"
Flag_Disc "-ew/--error_write"  "N/A"           "This flag will write FFmpegs stderr to \"ffmpeg_error.log\" in Current Working Directory"
Flag_Disc "-vf/--video_file"   "Input File"    "This flag will take <String>Input of the Video File location"
Flag_Disc "-l/--length"        "Preview Width" "This flag will take <Intiger>Input of the approximate width in pixels of the final preview image"
Flag_Disc "-b/--border"        "Border size"   "This flag will take <Intiger>Input of border size in pixels of the final tiled preview"
Flag_Disc "-p/--padding"       "Padding Size"  "This flag will take <Intiger>Input of padding size in pixels of the final tiled preview"
Flag_Disc "-c/--column"        "No of Columns" "This flag will take <Intiger>Input of number of columns of tiles in the final preview Minimum Value = 1"
Flag_Disc "-r/--row"           "No of Rows"    "This flag will take <Intiger>Input of number of rows of tiles in the final preview Minimum Value = 1"

}

Emg_Exit(){
	printf "\n\n\tSanity Check Failed !!!\n\
			\n\tPlease make sure that the File name only contains these charectors:\n\
			\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n\t%15s\n"\
			\
			"A - Z"\
			"a - z"\
			"0 - 9"\
			"-"\
			":"\
			"_"\
			"."\
			"/"\
			"("\
			")"\
			"[SPACE]"
	exit 2
}

Cache_Error(){
L_Error_List="$L_Error_List$(printf "$1")\n"
}

Cache_Report(){
	if [[ $2 != "-fs" ]];then
		L_Report_List="$L_Report_List\t-------\n$(printf "$1")\n"
	else
		L_Report_List="$(printf "$1")\n\n$L_Report_List"
	fi
}

Backup_Exist_Log(){
	if [[ -e $V_ffmpeg_log_output || -L $V_ffmpeg_log_output ]];then
		i=0
		while [[ -e "$(printf "%04d" $i)-$V_ffmpeg_log_output" || -L "$(printf "%04d" $i)-$V_ffmpeg_log_output"  ]];do
			let i++
		done
		mv $V_ffmpeg_log_output "$(printf "%04d" $i)-$V_ffmpeg_log_output"
	fi
}

get_value() {
    local key=${1} # get the Input Key=Value pairs
	local value=""
    key=${key//./'\.'} # Format dots to escape-dots for "sed" command in next line
    value=$(sed -n "/^$key=/{s///;p}" <<<"$data_prop")
    value=${value#\"}; value=${value%\"} # Clean up Value if it has Quotes
    [[ -z "$value" ]] && {
        printf "%s\n" "No ffprobe value for '$key'" >&2
        return 1
    }
    printf "$value"
}

probe() {
    local input=$1
    local ffprobe_opts=(
					-loglevel error
					-print_format flat
					-count_packets
					-select_streams v
					-show_streams
					-show_format
    			)
    data_prop=$(ffprobe "${ffprobe_opts[@]}" "$input") #Store all Key=Value pair in "data_prop" variable
}

####!INIT

####ANCHOR - Code Start
####JOB - Get -> Process -> Cache - User-Inputs and Errors

if [[ $# -eq 0 ]];then # Provide Help Document if no Input is Provided
Help_Func
exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -vf|--video_file)
            if [[ -f "$2" && -z $V_INPUT ]];then # Check if Input Variable is Empty and Input File is Regular File 
				V_INPUT=$2
				if [[ $V_INPUT =~ ^[-0-9A-Za-z:\ \_\.\/\(\)]+$ ]];then
				Cache_Report "\tSanitization check complete for the Input File"
				else
				Emg_Exit
				fi
				if [[ -s "$2" ]];then # Check if Input File is not a Empty File
					probe "$2" # First "probe" to get and store data about file
					VID_CHK=$(get_value $C_FRAMES_KEY) # Get Frames value from the stored data
					if [[ $VID_CHK -gt 1 ]];then # Proceed if Input File and Input Vaiable is OK
						Cache_Report "\tInput file = '$(basename "$2")'\n\tThe Input file is a valid video file\n"
						Cache_Report "\tFile Location = \"$(readlink -f "$2")\"\n"
					elif [[ $VID_CHK -eq 1 ]];then # Cache Error if Input File is a Image File
						Cache_Error "\n\t Input file = $2\n\tError  :  The Input file is a image file with single frame\n"
					else # Ceche Error if Input File is of Unknown Data
						Cache_Error "\n\t Input file = $2\n\tError  :  Input file is of unknown Data/Format\n"
					fi
				else # Cache Error if Input File is a Empty File
					Cache_Error "\n\t Input file = $2\n\tError  :  The Input File is empty file\n"
				fi
			elif [[ ! -z $V_INPUT ]];then # Cache Error if trying to Provide multiple Input File
				Cache_Error "\n\t Input file = $2\n\tError  :  The Input File already provided \n"
			else  # Cache Error if Input File in not a Regular File
				Cache_Error "\n\t Input file = $2\n\tError  :  The Input File is not a regular file\n"
				V_INPUT="--Irregular File-- $2"
			fi
			shift 2
            ;;

		-h|--help)
			Help_Func
			exit 0
			;;

		-el|--error_log) # Make FFmpeg to be more verbos
			V_ffmpeg_log_flag="-loglevel error -v 99"
			Cache_Report "\n\tFFmpeg will show all stderr\n\n"
			shift 1
			;;

		-ew|--error_write) # Write FFmpeg output to file
			V_REDIR="2>>$V_ffmpeg_log_output"
			Cache_Report "\n\tWritting FFmpeg Error log to : $V_ffmpeg_log_output\n\n"
			Backup_Exist_Log # Backup existing log files if any exists to 0000ffmpeg_error.log , 0001ffmpeg_error.log , ...
			shift 1
			;;

		-dr|--dry_run) # Run FFmpeg wihout output
			B_dry_run="true"
			Cache_Report "\n\tThis is Dry-Run\n\n" "-fs"
			shift 1
			;;

		-sr|--safe_run) # Quit before running the final FFmpeg
			B_safe_run="true"
			Cache_Report "\n\tThis is Safe-Run\n\n" "-fs"
			shift 1
			;;
		-q|--quiet)
			B_quiet="true" # Wont print the report
			Cache_Report "\n\tThis is a Quiet-Report\n\n"
			shift 1
			;;

		-l|--length)
			if [[ "$2" =~ [^0-9]+ ]];then
				Cache_Error "\tLength = $2 is not a Number\n"
			elif [[ $2 -lt 0 ]];then # Cache Error if Length is Negative
				Cache_Error "\n\t Length = $2\n\tError  :  Length cannot be a Negative Number Minimum Length is 540 \n"
			elif [[ $2 -lt 540 ]];then # Cache Error if Length Less that 540 pixels
				Cache_Error "\n\t Length = $2\n\tError  :  Minimum Length is 540 \n"
			else
				V_LENGTH=$2
			fi
			shift 2
			;;

		-b|--border)
			if [[ "$2" =~ [^0-9]+ ]];then
				Cache_Error "\tBorder = $2 is not a Number\n"
			elif [[ $2 -lt 0 ]];then # Cache Error if Border is Negative
				Cache_Error "\n\t Border = $2\n\tError  :  Border cannot be a Negative Number Minimum Length is 0 \n"
			else
				V_BORDER=$2
			fi
			shift 2
			;;

		-p|--padding)
			if [[ "$2" =~ [^0-9]+ ]];then
				Cache_Error "\tPadding = $2 is not a Number\n"
			elif [[ $2 -lt 0 ]];then # Cache Error if Padding is Negative
				Cache_Error "\n\t Padding = $2\n\tError  :  Padding cannot be a Negative Number Minimum Length is 0 \n"
			else
				V_PADDING=$2
			fi
			shift 2
			;;

		-r|--row)
			if [[ "$2" =~ [^0-9]+ ]];then
				Cache_Error "\tRow = $2 is not a Number\n"
			elif [[ $V_ROW -lt 1 ]];then # Cache Error if Row Less that 1
				Cache_Error "\n\t Row = $2\n\tError  :  Minimum Row is 1 \n"
			else
				V_ROW=$2
			fi
			shift 2
			;;

		-c|--column)
			if [[ "$2" =~ [^0-9]+ ]];then
				Cache_Error "\tColumn = $2 is not a Number\n"
			elif [[ $V_COLUMN -lt 1 ]];then # Cache Error if Column Less that 1
				Cache_Error "\n\t Column = $2\n\tError  :  Minimum Column is 1 \n"
			else
				V_COLUMN=$2
			fi
			shift 2
			;;

        *) # Cache Error if Unknown flag is used
            Cache_Error "\n\tUnknown option: $1 use the -h / --help Flag to print help Info\n\n"
            shift 1
            ;;

    esac
done

if [[ -z "$V_INPUT" ]];then # Cache Error if no Input File is provided
Cache_Error "\n\t Input file = [NULL]\n\tError  :  The Input File is not provided\n\n"
fi

if [[ ! -z $L_Error_List ]];then # If error exists then printf Error and Exit 1
printf "\n\tThe following errors have been detected :\n\n$L_Error_List\n"
exit 1
fi
####!JOB


####JOB - Generate, Calculate, Assign, Report, Format -> Values, Names, Constants
# Generate Preview output name
OUTPUT="Preview_$(echo   "$(basename "$V_INPUT")"|\
							sed -E "s~(.*\.)[^\.]*$~\1jpg~g")"
Cache_Report "\tOutput Name = '$OUTPUT'"
Cache_Report "\tOutput Location = \"$(pwd)/$(basename "$OUTPUT")\""

# Generate Title for input
TITLE="$(basename "$V_INPUT")"
Cache_Report "\tTitle = $TITLE"

# Sanatize title before using in ffmpeg
TITLE_SAN=$(echo $TITLE|\
			sed -E 's~[^a-z^A-Z^0-9^\.^ ^\-^_]~~g')

# Reverse Calculate the size of each small tile using the final preview Length, Border Size, Padding Size -Default Values or once provided by user
V_SIZE=$((
		(
		(V_LENGTH-V_BORDER*2)-
		(
		(V_COLUMN - 1) * V_PADDING
		)
		) / V_COLUMN
	))
Cache_Report "\tReverse Calculated Size = $V_SIZE"

# Caclulate the total number of previews
TOTAL_PREV=$((V_COLUMN * V_ROW))
Cache_Report "\tPreview image count = $TOTAL_PREV"

# Get the total Number of frames
Tot_Frames="$(get_value $C_FRAMES_KEY)"
Cache_Report "\tTotal no. of frames = $Tot_Frames"

# Get the encoding of the Video
Encoding="$(get_value $C_ENCODING_KEY)"
Cache_Report "\tInput File Encoding = $Encoding"

# Get the Duration of the Video
Duration="$(get_value $C_DURATION_KEY)"
Duration=${Duration%.*}
Cache_Report "\tVideo Duration = $Duration s"

# Calculate Formatted Time using Duration
HRS=$(( ($Duration / 3600) % 24))
MNS=$(( ($Duration / 60) % 60))
SEC=$(($Duration % 60))

# Format Duration to use with ffmpeg
Duration_F=$(printf "%02d\:%02d\:%02d"\
					"$HRS" "$MNS" "$SEC")

# Format Duration to Report Cache
Time_F=$(printf "%02d:%02d:%02d"\
			"$HRS" "$MNS" "$SEC")
Cache_Report "\tFormatted Video Duration = $Time_F\n"

# Get FPS from the video
FPS="$(get_value $C_FPS_KEY)"
FPS=$(($FPS))

Cache_Report "\tVideo FPS = $FPS"

# Calculate the the Frames to SKIP by deviding the no. of frames by no. of tiles
SKIP=$((Tot_Frames / TOTAL_PREV))
if [[ $SKIP -eq 0 ]];then # Check if SKIP is 0 if total Frames is less than total Preview if true force it to 1
SKIP=1
fi
Cache_Report "\tFrame Gap = $SKIP"

# Get the Frame width of video
W_Frame="$(get_value $C_WIDTH_KEY)"
Cache_Report "\twidth of video = $W_Frame"

# Get the Frame Height of video
H_Frame="$(get_value $C_HEIGHT_KEY)"
Cache_Report "\theight of video = $H_Frame"

# Setup Time format to timestamp each preview image before ffmpeg tiling
TIME="%{eif\:t/3600\:d\:2}\:%{eif\:mod(t/60\,60)\:d\:2}\:%{eif\:mod(t\,60)\:d\:2}\.%{eif\:100*mod(t\,1)\:d\:2}"

# Dinamically calculate timestamp font size for portraight and landscape videos
TIME_FONT_SIZE=$((
				( W_Frame > H_Frame ? W_Frame : H_Frame )/640 * 48
				))
Cache_Report "\tFrame time font size = $TIME_FONT_SIZE"

# Set the timestamp font properties for the timestamp in each tile
FONT_PROP=":fontcolor=white:fontsize=$TIME_FONT_SIZE"
Cache_Report "\tFont properties = $FONT_PROP"

# Set the timestamp Background box properties
BOX_PROP=":box=1:boxcolor=black@0.5:boxborderw=5"

# Calculate the Finale Preview Width
FINAL_WIDTH=$((
			$V_COLUMN * $V_SIZE + 
			($V_COLUMN - 1) * $V_PADDING +
			$V_BORDER * 2
			))

# Calculate the Final Preview Height
FINAL_HEIGHT=$((
			$V_COLUMN * $V_SIZE +
			($V_COLUMN - 1) * $V_PADDING +
			$V_BORDER * 2
			))
Cache_Report "\tFinal Sample image width = $FINAL_WIDTH"

# Dinamically Calculate the title font size for portraight and landscape final Preview image
TIT_FONT_SIZE=$((
				(
				( W_Frame > H_Frame ? W_Frame : H_Frame )/
				( W_Frame < H_Frame ? W_Frame : H_Frame )
				*$FINAL_WIDTH
				)
				/30
				))
Cache_Report "\tTitle Sample Font size = $TIT_FONT_SIZE"

# Setup Title font properties
TIT_FONT_PROP=":fontcolor=white:fontsize=$TIT_FONT_SIZE"

# Setup Title background box properties
TIT_BOX_PROP=":box=1:boxcolor=black@0.5:boxborderw=5"

# Calculate the amount of space to be padded of video metadata like title dimention fps encoding duration 
TITLE_SPACE=$((
				(
				( FINAL_WIDTH > FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT )/
				( FINAL_WIDTH < FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT )*
				$FINAL_WIDTH
				)/ 5
			))
####!JOB

# Change output format and location if Dry Run is enables
if [[ $B_dry_run == "true" ]];then
V_FORMAT='null'
OUTPUT="/dev/null"
fi

# Disable Printing Report if Quiet is enabled
if [[ $B_quiet != "true" ]];then
printf "\nThe Process Report :\n\n$L_Report_List\n"
fi

printf "\nThe Process Report :\n\n$L_Report_List\n">$V_ffmpeg_log_output

# Exit with 0 if  Safe Run is enables
if [[ $B_safe_run == "true" ]];then
exit 0
fi
####ANCHOR - Final FFmpeg step
eval "ffmpeg -hide_banner $V_ffmpeg_log_flag -i \"$V_INPUT\" -y -vframes 1 -q:v 2 -vf \
	\"select=not(mod(n\\,$SKIP)),\
	drawtext=fontfile=$V_FONT:text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
	scale=$V_SIZE:-1,\
	tile=${V_COLUMN}x${V_ROW}:padding=$V_PADDING:margin=$V_BORDER:color=Black,\
	pad=width=2+iw:height=2+ih+$TITLE_SPACE:x=1:y=1+$TITLE_SPACE:color=black,\
	drawtext=fontfile=$V_FONT:text='Title - ${TITLE_SAN}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20,\
	drawtext=fontfile=$V_FONT:text='Dimentions - ${H_Frame} x ${W_Frame} | FPS - ${FPS}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*1.5,\
	drawtext=fontfile=$V_FONT:text='Encoding - ${Encoding}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*3,\
	drawtext=fontfile=$V_FONT:text='Duration - ${Duration_F}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20+$TIT_FONT_SIZE*4.5\"\
	-f $V_FORMAT \"$OUTPUT\" $V_REDIR"