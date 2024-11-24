#Requires AutoHotkey v2.0
#Warn All, Off

TITLE := "OLHelper"
win := "Zoom Workplace"

if !WinExist(win) {
    MsgBox("Zoom 화상통화를 먼저 실행해야합니다. 녹화를 중단하려면 프롬프트 창에서 Ctrl+C를 입력하세요")
    ExitApp
}    

desc := "녹화 길이(초) 입력"
ib := InputBox(desc, TITLE, "", 1)
if ib.Result = "Cancel"  
    ExitApp
duration := ib.value

displayId := IniRead("config.ini", "Essential", "displayId")
RunWait '*RunAs PowerShell.exe Enable-Display ' displayId
Sleep IniRead("config.ini", "General", "displayDelay")

WinMaximize(win)
offsetX := IniRead("config.ini", "Essential", "offsetX")
offsetY := IniRead("config.ini", "Essential", "offsetY")
WinMove(OffsetX, OffsetY, , ,win)

fname := A_WorkingDir '\record-' FormatTime(A_Now, "yyyy-MM-dd-hh-mm-ss") '.mp4'
ffmpeg := 'ffmpeg -init_hw_device d3d11va -filter_complex ddagrab=' displayId-1 ' -c:v h264_nvenc -cq:v 20 -t ' duration ' ' fname
A_Clipboard := ffmpeg
; if RunWait(A_ComSpec ' /c powershell.exe "' ffmpeg)
;     MsgBox("정상적으로 녹화되지 않았습니다")

RunWait '*RunAs PowerShell.exe Disable-Display ' displayId

;;TODO - 강의 녹화 테스트(아직 실시간 통화 환경에서 안해봄)
;;소리 녹음 확인
;;TODO - 로그 파일 redirect
;;TODO - output 폴더 지정 to NAS
;;TODO - UI; 녹화 시작/중지 버튼