import strutils

# this can be used to return labels or comments
# probably better to split into 2 different pieces
proc makeComment*(wr: string, sug: seq[string]): string = 
  var answer:string = ""
  var la:int = 0
  if wr != "":
    answer = "C[" & wr & "]"
  for s in sug:
    if s.len > 0:
      la = la + 1
      var label:string = "LB["
      label = label & s[0].toLowerAscii()
      var itp:int = parseInt(s[1..^1])
      if(itp>8):
        itp = itp + 97
      else:
        itp = itp + 96
      label = label & char(itp) & ":" & $la &  "]"
      answer = answer & label
  return answer

# take instruction like play black c4 and translate
proc makeMove*(a:string): string = 
  var answer:string = "W["
  let mm = a.split({' '})
  if mm[1] == "black":
    answer = "B["
  answer = answer & mm[2][0].toLowerAscii()
  var itp:int = parseInt(mm[2][1..^1])
  if(itp>8):
    itp = itp + 97
  else:
    itp = itp + 96
  answer = answer & char(itp) & "]"
  return answer

proc makeSGFFile*(fName:string , sgf:seq[string]): int=
  let f = open(fName, fmWrite)
  defer: f.close()
  f.writeLine("(")
  for s in sgf:
    f.writeLine(";" & s )
  f.writeLine(")")
  return 1
    