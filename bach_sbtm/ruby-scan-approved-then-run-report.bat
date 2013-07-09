@ECHO OFF
REM ### THIS USES THE NEW RUBY SCAN.RB AND REPORT.RB SCRIPTS ###

del reports\breakdowns*.txt
del reports\charters*.txt
del reports\data.txt
del reports\bugs.txt
del reports\issues.txt
del reports\test*.txt
del reports\*.htm
del reports\sessions\*.ses


tools-ruby\scan.rb approved datafiles . reports scan.log
start notepad scan.log

tools-ruby\report.rb reports\templates reports reports

copy approved\*.ses reports\sessions
start reports\status.htm
