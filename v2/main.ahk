#Requires AutoHotkey v2.0

APP_NAME := "OLHelper"

WINDOW_TITLE := IniRead("config.ini", "General", "window_title")
DEVICE_NAME := IniRead("config.ini", "General", "device_name")
DEV_MODE := IniRead("config.ini", "General", "dev_mode", 0)

VIDEO_FRAMERATE := IniRead("config.ini", "Video", "framerate")
VIDEO_WIDTH := IniRead("config.ini", "Video", "width")
VIDEO_HEIGHT := IniRead("config.ini", "Video", "height")
SAVE_DIR := IniRead("config.ini", "Video", "save_dir")

INSTALL_DIR := RegRead("HKLM\SOFTWARE\AutoHotkey", "InstallDir", "")
AHK_PATH := INSTALL_DIR ? INSTALL_DIR "\v2\AutoHotkey.exe" : ""

EnvSet("DEVICE_NAME", DEVICE_NAME)
EnvSet("WIDTH", VIDEO_WIDTH)
EnvSet("HEIGHT", VIDEO_HEIGHT)

get_command(dir, args*) {
  params := ""
  For v in args {
    params := Format("{1} {2}", params, v)
  }
  return Format("{1} {2} {3}", AHK_PATH, dir, params)
}

if !WinExist(WINDOW_TITLE) && DEV_MODE == 0 {
	MsgBox("녹화할 대상 프로그램(" WINDOW_TITLE ")을 먼저 실행해야합니다")
	ExitApp
}    

desc := "녹화 길이(초) 입력. `n녹화를 중단하려면 프롬프트 창에서 Ctrl+C를 입력하세요"
ib := InputBox(desc, APP_NAME, "", 1)
if ib.Result = "Cancel"  
	ExitApp
duration := ib.value

try {
  if RunWait(get_command("scripts/configurate_monitor.ahk", 4))
    throw Error("가상 모니터 정보를 가져오는증에 오류가 발생했습니다")

  coord := StrSplit(FileRead("scripts/.tmp"), ",")
  if (coord.Length != 2)
    throw Error("가상 모니터 정보를 불러오는증에 오류가 발생했습니다")
  
  EnvSet("POSITION_X", coord[1])
  EnvSet("POSITION_Y", coord[2])
  
  if RunWait(get_command("scripts/configurate_monitor.ahk", 1))
    throw Error("가상 모니터를 켜는증에 오류가 발생했습니다")

  if RunWait(get_command("scripts/configurate_monitor.ahk", 2))
    throw Error("가상 모니터를 설정하는증에 오류가 발생했습니다")

  if RunWait(get_command("scripts/configurate_monitor.ahk", 3))
    throw Error("가상 모니터 정보를 가져오는증에 오류가 발생했습니다")

  if !FileExist("scripts/.tmp")
    throw Error("가상 모니터 정보를 불러오는증에 오류가 발생했습니다")

  monitor_settings := StrSplit(FileRead("scripts/.tmp"), ",")
  if (monitor_settings.Length != 4)
    throw Error("가상 모니터 정보를 불러오는증에 오류가 발생했습니다")

  width := monitor_settings[1]
  height := monitor_settings[2]
  offset_x := monitor_settings[3]
  offset_y := monitor_settings[4]

  ; TODO find a reliable way to wait for the monitor to be ready
  Sleep(3000) 
  WinMaximize(WINDOW_TITLE)
  WinMove(offset_x, offset_y, , ,WINDOW_TITLE)
  Sleep(500)
  
  if RunWait(get_command("scripts/configurate_monitor.ahk", 0))
    throw Error("가상 모니터를 종료하는중에 오류가 발생했습니다")
  
  if RunWait(get_command("scripts/configurate_monitor.ahk", 1))
    throw Error("가상 모니터를 종료하는중에 오류가 발생했습니다")

  if RunWait(get_command("scripts/configurate_monitor.ahk", 2))
    throw Error("가상 모니터 정보를 가져오는증에 오류가 발생했습니다")

  Sleep(3000) ; Zoom meeting issue - Wierd behavior that the first record cannot render screen correctly on virtual monitor
  WinMaximize(WINDOW_TITLE)
  WinMove(offset_x, offset_y, , ,WINDOW_TITLE)
  Sleep(500)

  dir := (SAVE_DIR ? SAVE_DIR : A_WorkingDir) "\"
  fname := 'record-' FormatTime(A_Now, "yyyy-MM-dd-hh-mm-ss") '.mp4'
  ffmpeg := 'bin\ffmpeg -f dshow -i audio="virtual-audio-capturer" -f gdigrab -framerate ' VIDEO_FRAMERATE ' -offset_x ' offset_x ' -offset_y ' offset_y ' -video_size ' width 'x' height ' -i desktop -c:v libx264 -crf 23 -pix_fmt yuv420p -c:a libmp3lame -b:a 192k -t ' duration " " dir fname
  if DEV_MODE 
    A_Clipboard := ffmpeg
  if RunWait(A_ComSpec ' /c powershell.exe "' ffmpeg)
  	throw Error("정상적으로 녹화되지 않았1습니다")

  if RunWait(get_command("scripts/configurate_monitor.ahk", 0))
    throw Error("가상 모니터를 종료하는중에 오류가 발생했습니다")
} catch as e { 
  if (IsObject(e)){
    MsgBox(e.Stack . "`n`n" . e.Message)
	} else
    MsgBox("Error: " . e)
} finally {
  if FileExist("scripts/.tmp")
    FileDelete("scripts/.tmp")
}

;;TODO - 강의 녹화 테스트(아직 실시간 통화 환경에서 안해봄)
;;TODO - 로그 파일 redirect
;;TODO - output 폴더 지정 UI(to NAS)
;;TODO - 녹화 시작/중지 UI