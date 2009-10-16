#!/bin/sh

RHELPFILE="/tmp/.R-help-$USER"
cat > $RHELPFILE
XTT=`head -n 1 $RHELPFILE | awk '{print $1}'`

if [ "x$DISPLAY" = "x" ] 
then
  less $RHELPFILE
else
  xterm -T "$XTT - R Help" -e less $RHELPFILE &
  #gnome-terminal -t "$XTT - R Help" -x less $RHELPFILE &
  #konsole --new-tab -p tabtitle="R Help - $XTT" -e less $RHELPFILE &
fi
