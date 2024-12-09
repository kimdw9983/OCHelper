#Requires AutoHotkey v2.0

ccw(o, a, b) {
  return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
}

Sorted(arr) {
  Loop arr.length{
    i := A_index
    Loop arr.length {
      j := A_index
      if (arr[i][1] > arr[j][1] || (arr[i][1] = arr[j][1] && arr[i][2] > arr[j][2])) {
        temp := arr[i]
        arr[i] := arr[j]
        arr[j] := temp
      }
    }
  }
  return arr
}

andrews(P) {
  P := Sorted(P)

  lo := []
  for p in P {
    while lo.Length >= 2 && ccw(lo[lo.Length - 1], lo[lo.Length], p) <= 0 {
      lo.Pop()
    }
    lo.Push(p)
  }
  lo.Pop()

  reversedP := []
  loop P.Length {
    reversedP.Push(P[P.Length - A_Index + 1])
  }

  up := []
  for p in reversedP {
    while up.Length >= 2 && ccw(up[up.Length - 1], up[up.Length], p) <= 0 {
      up.Pop()
    }
    up.Push(p)
  }
  up.Pop()

  for p in up {
    lo.Push(p)
  }

  return lo
}