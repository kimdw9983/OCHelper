#Requires AutoHotkey v2.0

init_ini() {
  IniWrite("Zoom Workplace", "config.ini", "General", "window_title")
  IniWrite("Linux FHD", "config.ini", "General", "device_name")
  
  IniWrite("30", "config.ini", "Video", "framerate")
  IniWrite("1920", "config.ini", "Video", "width")
  IniWrite("1080", "config.ini", "Video", "height")
  IniWrite("", "config.ini", "Video", "save_dir")
}

install_ffmpeg() {
  bin_dir := A_ScriptDir "\bin"
  DirCreate(bin_dir)

  url := "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
  zip := bin_dir "\tmp.zip"
  Download(url, zip)
  if RunWait("PowerShell.exe -Command Expand-Archive -Path " zip " -DestinationPath " bin_dir " -Force") {
    throw Error("ffmpeg를 다운로드하는데 오류가 발생했습니다 code 1")
  }
  
  Loop Files bin_dir "\*", "D" {
    if InStr(A_LoopFileName, "ffmpeg-") {
      FileMove(A_LoopFilePath "/bin/ffmpeg.exe", bin_dir, 1)
  
      FileDelete(zip)
      DirDelete(A_LoopFileFullPath, 1)
      break
    }
  } else {
    throw Error("ffmpeg를 설치하는데 오류가 발생했습니다 code 2")
  } 
}

install_audio_capturer() {
  bin_dir := A_ScriptDir "\bin"
  DirCreate(bin_dir)

  url := "https://sourceforge.net/projects/screencapturer/files/Setup%20Screen%20Capturer%20Recorder%20v0.12.11.exe/download"
  exe := bin_dir "\capturer_setup.exe"
  Download(url, exe)
  if RunWait(exe) {
    throw Error("오디오 캡처러를 설치하는데 오류가 발생했습니다 code 1")
  }
}

init_ini()
install_ffmpeg()
install_audio_capturer()