import os, terminal, random, sequtils, parseutils

# capture keyboard on windows
when defined(windows):
  when defined(useConio):
    proc getch(): cint {.importc: "_getch", header: "<conio.h>".}
    proc kbhit(): cint {.importc: "_kbhit", header: "<conio.h>".}
  else:
    proc getch(): cint {.importc: "_getch", dynlib: "msvcrt.dll".}
    proc kbhit(): cint {.importc: "_kbhit", dynlib: "msvcrt.dll".}

proc detect*(): cint =
  if kbhit() != 0:
    return getch()
  else:
    return -1