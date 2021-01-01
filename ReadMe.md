piggy is a little utility to help review your games
input is an sgf file which can contain a little markup
output are two plots : vn_winrate and mc_score
for the above we can use plotly 
if the file contains C[?] beside a certain move we output a small list of suggestions

piggy.exe -f sgfFile -o outputFile -p Playouts

by default playouts is set to the very small value of 250

We rely on the following great things
* https://github.com/gcp/Leela
* https://github.com/brentp/nim-plotly
* https://www.red-bean.com/sgf
