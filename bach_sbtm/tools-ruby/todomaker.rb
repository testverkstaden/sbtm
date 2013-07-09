#!/bin/ruby
#-------------------------------------------------------------------------------------------------------------#
# todomaker.rb
# Command Line Options : 2 Required - (1) input file (XLS), (2) destination path (see RUBY-TODO-MAKER.BAT)
# Purpose: to create empty TODO session reports based on the content in TODO.XLS
#
# Ported from the original PERL script (dated 14-Feb-2001) to RUBY by Paul Carvalho
# Last Updated: 01 May 2007
#------------------------------------------------------------------------------------------------------------ #

if ARGV[0].nil? or ARGV[1].nil? or ! File.exist?( ARGV[0] )
	  puts "\nUsage: #{File.basename($0)} [C:\\Sessions\\todo.xls] [C:\\Sessions\\todos]"
	  puts "\nSpecify the FULL path name for the TODO.XLS input file."
	  exit
end

### START ###

file, dir = ARGV

require 'win32ole'

## Read in the Excel file and Create new 'Todo' Session sheets ##
excel = WIN32OLE::new('excel.Application')
excel['Visible'] = false
workbook = excel.Workbooks.Open( file )     # (must specify the FULL path name here)
worksheet = workbook.Worksheets(1)

line = '2'     # (Skip the Header Row)
while worksheet.Range("a#{line}")['Value']
	data = []
	# (Only interested in the first four columns: [0] Session title, [1] Areas, [2] Priority, [3] Charter)
	data << worksheet.Range("a#{line}:d#{line}")['Value'].flatten     # (2D array)
	data.flatten!     # (make it a 1D array)
  
	todofile =  File.new( dir + '\et-todo-' + data[2].to_i.to_s + '-' + data[0].to_s + '.ses',  'w' )
  
	todofile.puts <<EOF
CHARTER
-----------------------------------------------
#{data[3]}

#AREAS
#{data[1].gsub(';', "\n")}

START
-----------------------------------------------


TESTER
-----------------------------------------------


TASK BREAKDOWN
-----------------------------------------------

#DURATION


#TEST DESIGN AND EXECUTION


#BUG INVESTIGATION AND REPORTING


#SESSION SETUP


#CHARTER VS. OPPORTUNITY
100/0

DATA FILES
-----------------------------------------------
#N/A

TEST NOTES
-----------------------------------------------


BUGS
-----------------------------------------------
#N/A

ISSUES
-----------------------------------------------
#N/A

EOF

	todofile.close
	line.succ!
end

excel.quit()

### END ###