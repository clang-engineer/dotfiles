#!/bin/bash
# Usage: aerospace-move-node.sh <workspace>
# Captures focused app name, moves it, then notifies Hammerspoon

WS="$1"
APP=$(aerospace list-windows --focused --format '%{app-name}')
aerospace move-node-to-workspace "$WS"
open -g "hammerspoon://aerospace-node-moved?ws=${WS}&app=${APP// /%20}"
