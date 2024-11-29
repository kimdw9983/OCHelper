#Requires AutoHotkey v2.0

RUN_MODE := A_Args[1] ; 0: enable, 1: position, 2: get position

TARGET_DEVICE_NAME := EnvGet("DEVICE_NAME")
WIDTH := EnvGet("WIDTH")
HEIGHT := EnvGet("HEIGHT")

QDC_FLAG := RUN_MODE > 1 ? 0x00000001 : 0x00000011
SDC_FLAG := RUN_MODE > 1 ? 0x000002A0 : 0x000082A0
DEVICE_INFO_TARGET_TYPE := 0x00000002

SIZEOF_DISPLAYCONFIG_PATH_INFO := 72
SIZEOF_DISPLAYCONFIG_MODE_INFO := 64

SIZEOF_DEVICE_INFO_HEADER := 20
SIZEOF_TARGET_DEVICE_NAME := 420

try {
  path_count := Buffer(4)
  mode_count := Buffer(4)

  result := DllCall("User32.dll\GetDisplayConfigBufferSizes", "UInt", QDC_FLAG, "ptr", path_count.ptr, "ptr", mode_count.ptr)
  if (result != 0) 
    throw Error("Failed to get buffer sizes. Error code: " . result)

  path_buffer_size := NumGet(path_count, "UInt") * SIZEOF_DISPLAYCONFIG_PATH_INFO
  mode_buffer_size := NumGet(mode_count, "UInt") * SIZEOF_DISPLAYCONFIG_MODE_INFO

  path_buffer := Buffer(path_buffer_size)
  mode_buffer := Buffer(mode_buffer_size)

  result := DllCall("User32.dll\QueryDisplayConfig", "UInt", QDC_FLAG, "ptr", path_count.ptr, "ptr", path_buffer.ptr, "ptr", mode_count.ptr, "ptr", mode_buffer.ptr, "ptr", 0)
  if (result != 0) 
    throw Error("Failed to query display config. Error code: " . result)

  found := false
  Loop NumGet(path_count, "UInt") {
    idx := A_index
    offset := (idx - 1) * SIZEOF_DISPLAYCONFIG_PATH_INFO

    source_mode_index := NumGet(path_buffer, offset + 12, "UInt")

    target_adapter_id := NumGet(path_buffer, offset + 20, "Int64")
    target_id := NumGet(path_buffer, offset + 28, "UInt")
    target_available := NumGet(path_buffer, offset + 60, "UInt")

    path_info_flags := NumGet(path_buffer, offset + 68, "UInt") 
    if (target_available == 0) 
      continue

    device_info_buffer := Buffer(SIZEOF_TARGET_DEVICE_NAME, 0)

    NumPut("UInt", DEVICE_INFO_TARGET_TYPE, device_info_buffer, 0)
    NumPut("UInt", SIZEOF_TARGET_DEVICE_NAME, device_info_buffer, 4)
    NumPut("Int64", target_adapter_id, device_info_buffer, 8)
    NumPut("UInt", target_id, device_info_buffer, 16)

    result := DllCall("User32.dll\DisplayConfigGetDeviceInfo", "Ptr", device_info_buffer)
    if (result != 0) 
      throw Error("Failed to get device info. Error code: " . result)

    if (StrGet(device_info_buffer.Ptr + SIZEOF_DEVICE_INFO_HEADER + 16, Encoding := "UTF-16") != TARGET_DEVICE_NAME) ;; TODO: v3 내가 설치했다는 표시가 없음. 구현방법 모색
      continue
    
    found := true
    switch RUN_MODE {
      case 0, 1:
        NumPut("UInt", 0xffff0000, path_buffer, offset + 12)
        NumPut("Uint", 0xffffffff, path_buffer, offset + 32)
        NumPut("UInt", RUN_MODE, path_buffer, offset + 68)
      case 2:
        offset := source_mode_index * SIZEOF_DISPLAYCONFIG_MODE_INFO
      
        ; TODO: v3 calculate most isolated position using convex hull
        positionX := -9999
        positionY := -9999  
        
        NumPut("UInt", WIDTH, mode_buffer, offset + 16)
        NumPut("UInt", HEIGHT, mode_buffer, offset + 20)
        NumPut("Int", positionX, mode_buffer, offset + 28)
        NumPut("Int", positionY, mode_buffer, offset + 32)
      case 3:
        offset := source_mode_index * SIZEOF_DISPLAYCONFIG_MODE_INFO

        width := NumGet(mode_buffer, offset + 16, "UInt")
        height := NumGet(mode_buffer, offset + 20, "UInt")
        pX := NumGet(mode_buffer, offset + 28, "int")
        pY := NumGet(mode_buffer, offset + 32, "int")
        if FileExist(".tmp")
          FileDelete(".tmp")

        FileAppend(width "," height "," pX "," pY, ".tmp")

        ExitApp
    }

    result := DllCall("User32.dll\SetDisplayConfig", "UInt", NumGet(path_count, "UInt"), "ptr", path_buffer.ptr, "UInt", NumGet(mode_count, "UInt"), "ptr", mode_buffer.ptr, "UInt", SDC_FLAG)
    if (result != 0) 
      throw Error("Failed to set display config. Error code: " . result)
  }

  if !found 
    throw Error("Failed to find target device")
} catch as e {
  if (IsObject(e)){
    MsgBox(e.Stack . "`n`n" . e.Message)
  } else
    MsgBox("Error: " . e)
  ExitApp 1
}