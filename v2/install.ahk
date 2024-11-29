#Requires AutoHotkey v2.0

Unzip(src, dest) {
  RunWait "PowerShell.exe -Command Expand-Archive -Path " src " -DestinationPath " dest " -Force"
}

; Initialize the config file
IniWrite("Zoom Workplace", "config.ini", "General", "window_title")
IniWrite("Linux FHD", "config.ini", "General", "device_name")

IniWrite("30", "config.ini", "Video", "framerate")
IniWrite("1920", "config.ini", "Video", "width")
IniWrite("1080", "config.ini", "Video", "height")
IniWrite("", "config.ini", "Video", "save_dir")

lib_dir := A_ScriptDir "\lib"
DirCreate(lib_dir)

; Download ffmpeg
url := "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
dest := lib_dir "\tmp.zip"
Download(url, dest)
Unzip(dest, lib_dir)
FileDelete(dest)