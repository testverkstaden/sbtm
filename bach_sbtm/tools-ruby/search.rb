#!/bin/ruby
#-------------------------------------------------------------------------------------------------------------#
# search.rb
# Command Line Options : 1 Required - directory with *.SES files to scan (run RUBY-SEARCH.BAT)
# Purpose: Search all the *.SES files in the folder specified for the search string input
#
# Ported from the original PERL script (dated 14-Jun-2000) to RUBY by Paul Carvalho
# Last Updated: 01 May 2007
#------------------------------------------------------------------------------------------------------------ #

if ARGV[0].nil?
	puts "\nUsage: #{File.basename($0)} [directory to scan]"
	exit
end

### METHODS ###

def concat( file_name )
	@f_CONCAT.puts <<EOF


###########################################################
Session: #{file_name}
!##########################################################

EOF
	@f_SHEET.rewind
	@f_SHEET.each_line {|line| @f_CONCAT.puts line }
end

### START ###

scandir = ARGV[0]

print "\nEnter the text to search for in '#{scandir}' : "
search_string = $stdin.gets.chomp

exit if search_string.empty?

@sheets = Dir[ scandir + "/*.ses" ]
@f_CONCAT = File.new("sheets.txt", "w")
f_BATCH = File.new("sheets.bat", "w")
f_BATCH.puts "@ECHO OFF"

@sheets.sort! do |a,b|
	a_start = a =~ /\d{6}-/
	a_prefix = a.scan(/et-(\w{2,3})-/).to_s
	b_start = b =~ /\d{6}-/
	b_prefix = b.scan(/et-(\w{2,3})-/).to_s
	( a[ a_start, 8] + a_prefix ) <=> ( b[ b_start, 8] + b_prefix )
end

hits = 0
@sheets.each do | file |
	@f_SHEET = File.open( file )
	match_found = false
	while ( line = @f_SHEET.gets ) and ( ! match_found )
		if ( line =~ /#{search_string}/io)
			puts file
			f_BATCH.puts "start notepad #{file}"
			concat( file )
			hits += 1
			match_found = true
		end
	end
	@f_SHEET.close
end

puts "\n#{hits} file(s) were found that matched your search."

unless hits.zero?
	puts "\nType SHEETS to view each file in notepad."
	puts "Type NOTEPAD SHEETS.TXT to view a concatenation of all the files found."
end

### END ###