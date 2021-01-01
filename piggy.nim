import os
import osproc
import strutils
import streams
import piglet

var oFile: string
var iFile: string
var pOuts: string = "--playouts="
#let lookUp: string = "abcdefghjklmnopqrst" #97=a i=95
var sgf:seq[string] = @[]
var agf:seq[string] = @[]
var instructions:seq[string] = @[]
var robot:seq[string] = @[]
var gtp:string = ""
var itp:int = 0
let bedtime: int = 250
var blackTurn: bool = true
var secondComment: string = ""

# There are just a few params to handle
for i in 0 .. paramCount():
  if paramStr(i) == "-o":
    oFile = paramStr(i+1)
  if paramStr(i) == "-i":
    iFile = paramStr(i+1)
  if paramStr(i) == "-p":
    pOuts = pOuts & paramStr(i+1)
if pOuts == "--playouts=":
  pOuts = pOuts & "100" 

# Read in the input file and then split it into a seq
let entireFile = readFile(iFile)
sgf = entireFile.split({';'})
#echo sgf
#there seems to be some hideous rotation going on
agf.add(sgf[1])

for sg in sgf:
  var isMove:int = 0
  if sg.startsWith("B"):
    isMove = 1
  if sg.startsWith("W"):
    isMove = 1
  if isMove == 1:
    try:
      if sg.startsWith("B"):
        gtp = "play black "
      else:
        gtp = "play white "
      gtp = gtp & sg[2]
      itp = int(sg[3])
      if(itp>105):
        itp = itp - 97
      else:
        itp = itp - 96
      gtp = gtp & $itp
      instructions.add(gtp)
      instructions.add("vn_winrate")
      if sg.contains("?"):    
        if sg.startsWith("B"):
          instructions.add("genmove B")
        if sg.startsWith("W"):
          instructions.add("genmove W")
    except:
      discard
#echo instructions
echo "instruction count:" , $instructions.len()

var pig = startProcess(command = "Leela0110GTP.exe", args = ["--gtp","--noponder","--lagbuffer=250",pOuts], options ={poStdErrToStdOut})
var iStream = inputStream(pig)
var oStream = outputStream(pig)
#var eStream = errorStream(pig)

for inst in instructions:
  echo inst
  var tHaltCondition = 1
  if(inst.startsWith("vn_")):
    tHaltCondition = 2
  if(inst.startsWith("genmove")):
    tHaltCondition = 3
  if inst.startsWith("play b"): #because we have to keep winrate from the perspective of 1 player
    blackTurn = true
    agf.add(makeMove(inst))
  if inst.startsWith("play w"):
    blackTurn = false
    agf.add(makeMove(inst))
  try:
    iStream.writeLine(inst)
    sleep(50)
    iStream.flush()
  except:
    let e = getCurrentException()
    let msg = getCurrentExceptionMsg()
    echo "Got input exception ", repr(e), " with message ", msg
  sleep(bedtime)
  var tWaiter:int = 0
  var tSuggestions:seq[string] = @[]

# Wait until we have finished reading in the robot's answers
  while tWaiter < 1000:
    try:
      gtp = oStream.readLine()
      if gtp != "":
        robot = gtp.split({' '})
        echo robot
        if tHaltCondition == 1:
          if robot[0] == "=":
            tWaiter = 1000
            sleep(bedtime)
        if tHaltCondition == 2:
          if robot[0] == "=":
            var tWinrate:float = parseFloat(robot[1])
            if blackTurn == false:
              tWinrate = 1 - tWinrate
            if tWinrate > 0:
              tWaiter = 1000
              sleep(bedtime)
              #echo makeComment($tWinrate , tSuggestions)
              agf[agf.len-1] = agf[agf.len-1] & makeComment($tWinrate , tSuggestions)
        if tHaltCondition == 3:
        # [2] == -> then it is a move suggestion and we need at least 1 of those in theory
          if robot.len > 2:
            if robot[2] == "->":
              tSuggestions.add(robot[1])
            if robot[0] == "MC":
              secondComment = " " & robot[3]
          if robot[0] == "=":
            tWaiter = 1000
            sleep(bedtime)
            #echo makeComment("" , tSuggestions)
            agf[agf.len-1] = agf[agf.len-1] & makeComment(secondComment , tSuggestions)
    except:
      let e = getCurrentException()
      let msg = getCurrentExceptionMsg()
      echo "Got output exception ", repr(e), " with message ", msg
      tWaiter = tWaiter + 1
      sleep(bedtime)
    sleep(bedtime)
    tWaiter = tWaiter + 1
# play colour coord should receive the response
# =
# vn_winrate 
# = float
# genmove colour
#  coord ->          This is a suggestion
# = coord

echo "Finished the instructions now"
echo makeSgfFile(oFile,agf)
#put the winrate in plotly and the sgf