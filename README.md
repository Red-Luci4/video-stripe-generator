Video Stripe Preview Generator
===

This is a Script that uses ffmpeg to generate a stripe preview of a given video.
<br></br>


Usage
---
```bash
video_strip_preview.sh -Flag "Input"

```

- First Argument is the path to the shell script file
- Second argument is the Flag
- Third Argument is the Input for the Flag (ATTENTION - If the name contains spaces, wrap in double quots and don't use '\' to escape space)

<br></br>

Flag, Input, and Description Table
---
### This table will show possible flags and Inputs

Flag | Input | Description
---|---|---
-h<br> --help| N/A | This Flag will print out the useful info about this script
-vf<br>--video_file| Input File | This flag will take \<String\> Input of the Video File location<br><b>NOTE: If Name has [Space], then wrap it in Double Quotes -> "Name"</b>
-l<br>--lenght| Final Preview Width | This flag will take \<Integer\> Input of the approximate width in pixels of the final preview image
-b<br>--border| Border Size | This flag will take \<Integer\> Input of border size in pixels of the final tiled preview
-p<br>--padding| Padding Size | This flag will take \<Integer\> Input of padding size in pixels of the final tiled preview
-c<br>--column | No of Columns| This flag will take \<Integer\> Input of number of columns of tiles in the final preview Minimum Value = 1
-r<br>--row| No of Rows| This flag will take \<Integer\> Input of number of rows of tiles in the final preview Minimum Value = 1

Requiremets
---
### I don’t know what packages you'll need to use the following tools, i.e I'll just list the tools, and you make sure to get it before running the script.
- bash
- printf
- echo
- test
- expr
- ffmpeg
- ffprobe
- exit
- shift
- basename
- grep
- sed
- tail
- tr
