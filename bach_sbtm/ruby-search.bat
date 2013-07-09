@echo off
REM ### THIS USES THE NEW RUBY SEARCH.RB SCRIPT ###

del sheets.txt
tools-ruby\search.rb Approved
START notepad sheets.txt