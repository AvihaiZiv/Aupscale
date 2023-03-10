@echo off
type Dev.md
SET script_path=%~dp0
SET waifu2x_path_exe=%script_path%waifu2x\waifu2x-ncnn-vulkan.exe
SET ffmpeg_path_exe=%script_path%ffmpeg\ffmpeg.exe
SET ffprobe_path_exe=%script_path%ffmpeg\ffprobe.exe
SET frames_path=%script_path%Frames\
SET upscaled_path=%script_path%Upscaled\
set Export_path=%script_path%Export\
if exist Frames\ ( 
echo Frames folder exists 
) else ( 
mkdir Frames
)
if exist Upscaled\ (
echo Upscaled folder exists
) else ( 
mkdir Upscaled 
)
if exist Export\ (
echo Export folder exist
) else ( 
mkdir Export
)
SET /p "file_path=Enter anime video file path (remove quotation marks!): "
SET /p "scale=Enter upscale ratio (x2\x4\x8\x16\x32) number only: "
SET /p "noise=Emter de-noise level (-1/0/1/2/3): "
for %%F in ("%file_path%") do echo %%~nxF > file_pathtmp
set /p file_name= <file_pathtmp
del file_pathtmp
echo Getting the frame rate of the video
%ffprobe_path_exe% -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "%file_path%" > fpout
set /p frame_rate= <fpout
del fpout
echo Encodiing audio from original video to Opus
mkdir "%file_name%-audio"
%ffmpeg_path_exe% -i "%file_path%" -c:a libopus -vbr on -b:a 192k "%file_name%-audio\audio.opus"
echo Extracting frames from video
%ffmpeg_path_exe% -i "%file_path%" -r %frame_rate% %frames_path%frame%%09d.png
echo Upscaling frames
%waifu2x_path_exe% -i %frames_path% -o %upscaled_path% -s %scale% -n %noise% -v
echo Rendering upscaled video
%ffmpeg_path_exe% -framerate %frame_rate% -pattern_type sequence -start_number 000000001 -i %upscaled_path%frame%%09d.png -i "%file_name%-audio\audio.opus" -c:a copy -shortest -c:v libx265 -crf 19 -preset slow -x265-params "limit-sao=1:bframes=8:psy-rd=1:aq-mode=3" "%Export_path%%file_name%.upscaled.mkv"
rmdir /s /q "%file_name%"-audio
del /s /q %frames_path%*
del /s /q %upscaled_path%*
type Dev.md
echo Finished!
pause

