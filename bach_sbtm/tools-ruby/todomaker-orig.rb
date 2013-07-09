#!/bin/ruby
#-------------------------------------------------------------------------------------------------------------#
# todomaker-orig.rb
# Command Line Options : 2 Required - (1) input file ({TAB}-delimited TXT file), (2) destination path (see RUBY-TODO-MAKER.BAT)
# Purpose: to create empty TODO session reports based on the content of the "todos.txt" file
#
# Ported from the original PERL script (dated 14-Feb-2001) to RUBY by Paul Carvalho
# Last Updated: 21 December 2007
#------------------------------------------------------------------------------------------------------------ #

if ARGV[0].nil? or ARGV[1].nil? or ! File.exist?( ARGV[0] )
	  puts "\nUsage: #{File.basename($0)} [C:\\Sessions\\todos.txt] [C:\\Sessions\\todos]"
	  puts "\nSpecify the FULL path name for the TODOS.TXT input file."
	  exit
end

### START ###

file, dir = ARGV

f_TODOS = File.open( file )
f_TODOS.gets     # (skip first/header line)

while (line = f_TODOS.gets)
	(title, area, priority, description) = line.split(/\t/)

	todofile =  File.new( dir + '\et-todo-' + priority + '-' + title + '.ses',  'w' )
  
	todofile.puts <<EOF
CHARTER
-----------------------------------------------
#{description.chomp}

#AREAS
#{area.gsub(';', "\n")}

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
end

f_TODOS.close

### END ###