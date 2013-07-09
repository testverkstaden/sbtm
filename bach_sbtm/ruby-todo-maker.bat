@ECHO OFF
REM ### THIS USES THE NEW RUBY TODOMAKER.RB SCRIPT ###
REM Input file is todo.xls in the C:\Sessions folder. (Run this batch script in the same directory.)
REM NOTE: Unlike some of the other ruby scripts, the XLS file location *must* include the FULL PATH name.

tools-ruby\todomaker.rb C:\Sessions\todo.xls C:\Sessions\todos
