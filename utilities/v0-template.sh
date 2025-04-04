#!/bin/bash

# Path to REAPER executable on macOS
REAPER="/Applications/REAPER.app/Contents/MacOS/REAPER"

# Path to your Lua script
LUA_SCRIPT="'/Users/danielramirez/Library/Application Support/REAPER/Scripts/v0_template.lua'"

# Run REAPER with the Lua script
"$REAPER" -run "$LUA_SCRIPT"
