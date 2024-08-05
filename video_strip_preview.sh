#!/bin/bash

####INIT - Constants, Variables, Empty initialization

## Init Constants for get_value function

#Height Key Constant
readonly C_HEIGHT_KEY="streams.stream.0.height"
#Width Key Constant
readonly C_WIDTH_KEY="streams.stream.0.width"
#Frame Key Constant
readonly C_FRAMES_KEY="streams.stream.0.nb_read_packets"
#FPS Key Constant
readonly C_FPS_KEY="streams.stream.0.avg_frame_rate"
#Video Duration Key Constant
readonly C_DURATION_KEY="format.duration"
#Video Data Codec Key Constant
readonly C_ENCODING_KEY="streams.stream.0.codec_long_name"

#readonly C_ARGV=("$@")
#readonly C_ARGC=$#

## Init Default Variables

#Preview Font Value
V_FONT="/usr/share/fonts/TTF/OpenSans-Regular.ttf"
#Preview Output Format
V_FORMAT='apng'
#FFmpeg Error stream Redirect
V_REDIR='2>&1'
#Preview Length
V_LENGTH=720
#V_SIZE=360

#Preview Border Length
V_BORDER=10
#Preview Padding Length
V_PADDING=10
#Preview Column Number
V_COLUMN=3
#Preview Row Number
V_ROW=2
#Input File Name
V_INPUT=""
#Flag to increase FFmpeg Verbosity
V_ffmpeg_log_flag=""
#Log File Name
V_ffmpeg_log_output="ffmpeg_error.log"

## Init Empty Variables

#Error List
L_Error_List=""
#Report List
L_Report_List=""
#Dry Run Bool
B_dry_run=""
#Safe Run Bool
B_safe_run=""
#Quiet Run Bool
B_quiet=""

####!INIT

####INIT - Function initialization

# Used by Help_Func to discribe to print Flags and Discription
Flag_Disc(){
printf "%17s%16s\t%s\n\n" "$1" "$2" "$3"
}
# Prints out Help documentation
Help_Func(){
printf "\t%s\n\n" "This script can generate Video-Stripe-Preview image of a Video/Image-Sequences"
printf "\tUsage : \v video-stripe-preview [Flag Input]...\n\n\n"
printf "%15s%5c%10s%5c%15s\n\n" "Flag" "|" "Input" "|" "Discription"

Flag_Disc "-h/--help"          "N/A"           "This flag will print this Help Information"
Flag_Disc "-sr/--safe_run"     "N/A"           "This flag will Quit the Script right before FFmpeg command (-dr -el -ew wont work with this)"
Flag_Disc "-dr/--dry_run"      "N/A"           "This flag will Run the FFmpeg but outputs no data \"-f null /dev/null\""
Flag_Disc "-el/--error_log"    "N/A"           "This flag will make ffmpeg log everything to stderr"
Flag_Disc "-ew/--error_write"  "N/A"           "This flag will write FFmpegs stderr to \"ffmpeg_error.log\" in Current Working Directory"
Flag_Disc "-q/--quiet"         "N/A"           "This flag will Disable printing Report to stdout "
Flag_Disc "-vf/--video_file"   "Input File"    "This flag will take <String>Input of the Video File location"
Flag_Disc "-l/--length"        "Preview Width" "This flag will take <Intiger>Input of the approximate width in pixels of the final preview image"
Flag_Disc "-b/--border"        "Border size"   "This flag will take <Intiger>Input of border size in pixels of the final tiled preview"
Flag_Disc "-p/--padding"       "Padding Size"  "This flag will take <Intiger>Input of padding size in pixels of the final tiled preview"
Flag_Disc "-c/--column"        "No of Columns" "This flag will take <Intiger>Input of number of columns of tiles in the final preview Minimum Value = 1"
Flag_Disc "-r/--row"           "No of Rows"    "This flag will take <Intiger>Input of number of rows of tiles in the final preview Minimum Value = 1"

}
# Emergency Exit incase sanity check fails for input name variable.
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
# Build a Error-List by appending one error after another to the variable L_Error_List.
Cache_Error(){
L_Error_List="$L_Error_List$(printf '%s' "$1")\n\n"
}
# Build a Report-List by appending one report after another to the Variable L_Report_List.
Cache_Report(){
	if [[ $2 != "-fs" ]];then
		L_Report_List="$L_Report_List$(printf '\n\t-------\n%s' "$1")"
	else
		L_Report_List="$(printf '%s' "$1")\n\n$L_Report_List"
	fi
}
# Backup existing log files if any exists to 0000ffmpeg_error.log , 0001ffmpeg_error.log , ...
Backup_Exist_Log(){
	if [[ -e $V_ffmpeg_log_output || -L $V_ffmpeg_log_output ]];then
		i=0
		while [[ -e "$(printf "%04d" $i)-$V_ffmpeg_log_output" || -L "$(printf "%04d" $i)-$V_ffmpeg_log_output"  ]];do
			i=$(( i + 1 ))
		done
		mv $V_ffmpeg_log_output "$(printf "%04d" $i)-$V_ffmpeg_log_output"
	fi
}
# Returns Value for a Key from data_prop variable
get_value() {
    local key=${1} # get the Input Key for Key=Value pairs
	local value=""
    key=${key//./'\.'} # Format dots to escape-dots for "sed" command in next line
    value=$(sed -n "/^$key=/{s///;p}" <<<"$data_prop")
    value=${value#\"}; value=${value%\"} # Clean up Value if it has Quotes
    [[ -z "$value" ]] && {
        printf "%s\n" "No ffprobe value for '$key'" >&2
        return 1
    }
    printf '%s' "$value"
}
# Uses ffprobe to get all video properties about the Input and stores in variable data_prop as Key=Value pairs
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
				if [[ $V_INPUT =~ ^[-0-9A-Za-z:\ \_\.\/\(\)\']+$ ]];then
				Cache_Report "$(printf '\tSanitization check complete for the Input File')"
				else
				Emg_Exit
				fi
				if [[ -s "$2" ]];then # Check if Input File is not a Empty File
					probe "$2" # First "probe" to get and store data about file
					VID_CHK=$(get_value $C_FRAMES_KEY) # Get Frames value from the stored data
					if [[ $VID_CHK -gt 1 ]];then # Proceed if Input File and Input Vaiable is OK
						Cache_Report "$(printf '\tInput file = "%s"\n\tThe Input file is a valid video file\n' "$(basename "$2")")"
						Cache_Report "$(printf '\tFile Location = "%s"\n' "$(readlink -f "$2")")"
					elif [[ $VID_CHK -eq 1 ]];then # Cache Error if Input File is a Image File
						Cache_Error "$(printf '\n\t Input file = %s\n\tError  :  The Input file is a image file with single frame\n\n' "$2")"
					else # Ceche Error if Input File is of Unknown Data
						Cache_Error "$(printf '\n\t Input file = %s\n\tError  :  Input file is of unknown Data/Format\n\n' "$2")"
					fi
				else # Cache Error if Input File is a Empty File
					Cache_Error "$(printf '\n\t Input file = %s\n\tError  :  The Input File is empty file\n\n' "$2")"
				fi
			elif [[ -n $V_INPUT ]];then # Cache Error if trying to Provide multiple Input File
				Cache_Error "$(printf '\n\t Input file = %s\n\tError  :  The Input File already provided \n\n' "$2")"
			else  # Cache Error if Input File in not a Regular File
				Cache_Error "$(printf '\n\t Input file = %s\n\tError  :  The Input File is not a regular file\n\n' "$2")"
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
			Cache_Report "$(printf '\n\tFFmpeg will show all stderr\n\n')"
			shift 1
			;;

		-ew|--error_write) # Write FFmpeg output to file
			V_REDIR="2>>$V_ffmpeg_log_output"
			Cache_Report "$(printf '\n\tWritting FFmpeg Error log to : %s\n\n' "$V_ffmpeg_log_output")"
			Backup_Exist_Log
			shift 1
			;;

		-dr|--dry_run) # Run FFmpeg wihout output
			B_dry_run="true"
			Cache_Report "$(printf '\n\tThis is Dry-Run\n\n')" "-fs"
			shift 1
			;;

		-sr|--safe_run) # Quit before running the final FFmpeg
			B_safe_run="true"
			Cache_Report "$(printf '\n\tThis is Safe-Run\n\n')" "-fs"
			shift 1
			;;
		-q|--quiet)
			B_quiet="true" # Wont print the report
			Cache_Report "$(printf '\n\tThis is a Quiet-Report\n\n')"
			shift 1
			;;

		-l|--length)
			if [[ "$2" =~ [-]{0,1}[^0-9^-]+ ]];then
				Cache_Error "$(printf '\tLength = %s is not a Number\n' "$2")"
			elif [[ $2 -lt 540 ]];then # Cache Error if Length Less that 540 pixels
				Cache_Error "$(printf '\n\t Length = %s\n\tError  :  Minimum Length is 540 \n' "$2")"
			else
				V_LENGTH=$2
			fi
			shift 2
			;;

		-b|--border)
			if [[ "$2" =~ [-]{0,1}[^0-9^-]+ ]];then
				Cache_Error "$(printf '\tBorder = %s\n\tError  :  not a Number\n' "$2")"
			elif [[ $2 -lt 0 ]];then # Cache Error if Border is Negative
				Cache_Error "$(printf '\n\t Border = %s\n\tError  :  Border Minimum Length is 0 \n' "$2")"
			else
				V_BORDER=$2
			fi
			shift 2
			;;

		-p|--padding)
			if [[ "$2" =~ [-]{0,1}[^0-9^-]+ ]];then
				Cache_Error "$(printf '\tPadding = %s\n\tError  :  not a Number\n' "$2")"
			elif [[ $2 -lt 0 ]];then # Cache Error if Padding is Negative
				Cache_Error "$(printf '\n\t Padding = %s\n\tError  :  Padding Minimum Length is 0 \n' "$2")"
			else
				V_PADDING=$2
			fi
			shift 2
			;;

		-r|--row)
			if [[ "$2" =~ [-]{0,1}[^0-9^-]+ ]];then
				Cache_Error "$(printf '\tRow = %s\n\tError  :  not a Number\n' "$2")"
			elif [[ $2 -lt 1 ]];then # Cache Error if Row Less that 1
				Cache_Error "$(printf '\n\t Row = %s\n\tError  :  Minimum Row is 1 \n' "$2")"
			else
				V_ROW=$2
			fi
			shift 2
			;;

		-c|--column)
			if [[ "$2" =~ [-]{0,1}[^0-9^-]+ ]];then
				Cache_Error "$(printf '\tColumn = %s\n\tError  :  not a Number\n' "$2")"
			elif [[ $2 -lt 1 ]];then # Cache Error if Column Less that 1
				Cache_Error "$(printf '\n\t Column = %s\n\tError  :  Minimum Column is 1 \n' "$2")"
			else
				V_COLUMN=$2
			fi
			shift 2
			;;

        *) # Cache Error if Unknown flag is used
            Cache_Error "$(printf '\n\tUnknown option: %s use the -h / --help Flag to print help Info\n\n' "$1")"
            shift 1
            ;;

    esac
done

if [[ -z "$V_INPUT" ]];then # Cache Error if no Input File is provided
Cache_Error "$(printf '\n\tInput file = [NULL]\n\tError  :  The Input File is not provided\n\n')"
fi

if [[ -n $L_Error_List ]];then # If error exists then printf Error and Exit 1
printf '\n\tThe following errors have been detected :\n\n%s\n' "$L_Error_List" 1>&2
exit 1
fi
####!JOB


####JOB - Generate, Calculate, Assign, Report, Format -> Values, Names, Constants
# Generate Preview output name
OUTPUT="Preview_$(basename "$V_INPUT"|\
					sed -E "s~(.*\.)[^\.]*$~\1png~g")"
Cache_Report "$(printf '\tOutput Name = %s' "$OUTPUT")"
Cache_Report "$(printf '\tOutput Location = "%s"' "$(pwd)/$(basename "$OUTPUT")")"

# Generate Title for input
TITLE="$(basename "$V_INPUT")"
Cache_Report "$(printf '\tTitle = %s' "$TITLE")"

# Sanatize title before using in ffmpeg
TITLE_SAN=$(printf '%s' "$TITLE"|\
			sed -E 's~[^a-z^A-Z^0-9^\.^ ^\-^_]~~g'|fold -s -w 55)
TITLE_NL_CNT=$(( $(echo "$TITLE_SAN"|wc -l)-1 ))
echo "This is Number of lines in title : $TITLE_NL_CNT"

# Reverse Calculate the size of each small tile using the final preview Length, Border Size, Padding Size -Default Values or once provided by user
V_SIZE=$((
		(
		(V_LENGTH-V_BORDER*2)-
		(
		(V_COLUMN - 1) * V_PADDING
		)
		) / V_COLUMN
		))
Cache_Report "$(printf '\tReverse Calculated Size = %s' "$V_SIZE")"

# Caclulate the total number of previews
TOTAL_PREV=$((V_COLUMN * V_ROW))
Cache_Report "$(printf '\tPreview image count = %s' "$TOTAL_PREV")"

# Get the total Number of frames
Tot_Frames="$(get_value $C_FRAMES_KEY)"
Cache_Report "$(printf '\tTotal no. of frames = %s' "$Tot_Frames")"

# Get the encoding of the Video
Encoding="$(get_value $C_ENCODING_KEY)"
Cache_Report "$(printf '\tInput File Encoding = %s' "$Encoding")"

# Get the Duration of the Video
Duration="$(get_value $C_DURATION_KEY)"
Duration=${Duration%.*}
Cache_Report "$(printf '\tVideo Duration = %s s' "$Duration")"

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
Cache_Report "$(printf '\tFormatted Video Duration = %s\n' "$Time_F")"

# Get FPS from the video
FPS="$(get_value $C_FPS_KEY)"
FPS=$(($FPS))

Cache_Report "$(printf '\tVideo FPS = %s' "$FPS")"

# Calculate the the Frames to SKIP by deviding the no. of frames by no. of tiles
SKIP=$((Tot_Frames / TOTAL_PREV))
if [[ $SKIP -eq 0 ]];then # Check if SKIP is 0 if total Frames is less than total Preview if true force it to 1
SKIP=1
fi
Cache_Report "$(printf '\tFrame Gap = %s' "$SKIP")"

# Get the Frame width of video
W_Frame="$(get_value $C_WIDTH_KEY)"
Cache_Report "$(printf '\twidth of video = %s' "$W_Frame")"

# Get the Frame Height of video
H_Frame="$(get_value $C_HEIGHT_KEY)"
Cache_Report "$(printf '\theight of video = %s' "$H_Frame")"

# Setup Time format to timestamp each preview image before ffmpeg tiling
TIME="%{eif\:t/3600\:d\:2}\:%{eif\:mod(t/60\,60)\:d\:2}\:%{eif\:mod(t\,60)\:d\:2}\.%{eif\:100*mod(t\,1)\:d\:2}"

# Dinamically calculate timestamp font size for portraight and landscape videos
TIME_FONT_SIZE=$((
				(( W_Frame > H_Frame ? W_Frame : H_Frame )/640) * 48
				))
Cache_Report "$(printf '\tFrame time font size = %s' "$TIME_FONT_SIZE")"

# Set the timestamp font properties for the timestamp in each tile
FONT_PROP=":fontcolor=white:fontsize=$TIME_FONT_SIZE"
Cache_Report "$(printf '\tFont properties = %s' "$FONT_PROP")"

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
Cache_Report "$(printf '\tFinal Sample image width = %s' "$FINAL_WIDTH")"

# Dinamically Calculate the title font size for portraight and landscape final Preview image
TIT_FONT_SIZE=$((
				(
				(( FINAL_WIDTH > FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT )/
				( FINAL_WIDTH < FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT ))
				*$FINAL_WIDTH
				)
				/35
				))
Cache_Report "$(printf '\tTitle Sample Font size = %s' "$TIT_FONT_SIZE")"

# Setup Title font properties
TIT_FONT_PROP=":fontcolor=white:fontsize=$TIT_FONT_SIZE"

# Setup Title background box properties
TIT_BOX_PROP=":box=1:boxcolor=black@0.5:boxborderw=5"

# Calculate the amount of space to be padded of video metadata like title dimention fps encoding duration 
TITLE_SPACE=$((
				(
				(( FINAL_WIDTH > FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT )/
				( FINAL_WIDTH < FINAL_HEIGHT ? FINAL_WIDTH : FINAL_HEIGHT ))
				*$FINAL_WIDTH
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
printf '\nThe Process Report :\n\n%s\n\n' "$L_Report_List"
fi

if [[ $V_REDIR != '2>&1' ]];then
printf '\nThe Process Report :\n\n%s\n' "$L_Report_List">$V_ffmpeg_log_output
fi

# Exit with 0 if  Safe Run is enables
if [[ $B_safe_run == "true" ]];then
exit 0
fi

DIM_POS=$(echo "20+$TIT_FONT_SIZE*((1+$TITLE_NL_CNT)*1.5)"|bc )
ENC_POS=$(echo "20+$TIT_FONT_SIZE*((2+$TITLE_NL_CNT)*1.5)"|bc )
DUR_POS=$(echo "20+$TIT_FONT_SIZE*((3+$TITLE_NL_CNT)*1.5)"|bc )

####ANCHOR - Final FFmpeg step
eval "ffmpeg -v quiet -hide_banner $V_ffmpeg_log_flag -i \"$V_INPUT\" -y -vframes 1 -q:v 2 -vf \
	\"select=not(mod(n\\,$SKIP)),\
	drawtext=fontfile=$V_FONT:text='$TIME'$FONT_PROP$BOX_PROP:x=($W_Frame-text_w)-10:y=($H_Frame-text_h)-10,\
	scale=$V_SIZE:-1,\
	tile=${V_COLUMN}x${V_ROW}:padding=$V_PADDING:margin=$V_BORDER:color=Black,\
	pad=width=2+iw:height=2+ih+50+$DUR_POS:x=1:y=1+50+$DUR_POS:color=black,\
	drawtext=fontfile=$V_FONT:text='Title - ${TITLE_SAN}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=20,\
	drawtext=fontfile=$V_FONT:text='Dimentions - ${H_Frame} x ${W_Frame} | FPS - ${FPS}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=$DIM_POS,\
	drawtext=fontfile=$V_FONT:text='Encoding - ${Encoding}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=$ENC_POS,\
	drawtext=fontfile=$V_FONT:text='Duration - ${Duration_F}'$TIT_FONT_PROP$TIT_BOX_PROP:x=20:y=$DUR_POS\"\
	-f $V_FORMAT \"$OUTPUT\" $V_REDIR"
