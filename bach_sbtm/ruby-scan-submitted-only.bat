@ECHO OFF
REM ### THIS USES THE NEW RUBY SCAN.RB SCRIPT ###

del reports\breakdowns*.txt
del reports\charters*.txt
del reports\data.txt
del reports\bugs.txt
del reports\issues.txt
del reports\test*.txt
del scan.log


tools-ruby\scan.rb submitted datafiles . reports scan.log
start notepad scan.log
