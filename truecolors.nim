import math

proc setForegroundColor*(r,g,b: int) =
    stdout.write("\x1b[38;2;" & $min(max(r,0),255) & ";" & $min(max(g,0),255) & ";" & $min(max(b,0),255) & "m")
proc setBackgroundColor*(r,g,b: int) =
    stdout.write("\x1b[48;2;" & $min(max(r,0),255) & ";" & $min(max(g,0),255) & ";" & $min(max(b,0),255) & "m")