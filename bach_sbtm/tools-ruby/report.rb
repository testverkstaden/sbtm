#!/bin/ruby
#-------------------------------------------------------------------------------------------------------------#
# report.rb
# Command Line Options : 3 Required - 3 directory locations (see RUBY-SCAN-APPROVED-THEN-RUN-REPORT.BAT)
# Purpose: to generate html reports based upon the data files created by the SCAN.RB script
#
# Ported from the original PERL script (dated 07-Mar-2001) to RUBY by Paul Carvalho
# Last Updated: 15 July 2009
# Version: 2.1
#------------------------------------------------------------------------------------------------------------ #
@ScriptName = File.basename($0).upcase

if ARGV[0].nil? or ARGV[1].nil? or ARGV[2].nil?
	puts "\nUsage: #{@ScriptName} TEMPLATE_DIR DATA_DIR REPORT_DIR"
	puts "\nTEMPLATE_DIR is the path to the directory containing the HTML templates."
	puts "DATA_DIR is the path to the directory containing the data input files."
	puts "REPORT_DIR is the path to the directory where the reports will be placed.\n"
	exit
end

templatedir, datadir, @reportdir = ARGV

# Some Ruby system updates may hide a required method from the Time class
require 'Time' unless Time.methods.include? 'parse'

### METHODS ###

def die( parting_thought, line_num )
	puts  @ScriptName + ": " + parting_thought + ": line ##{line_num}"
	exit
end

def makecover( title, sortby )
	if ( sortby != 8)
		@fields.sort! { |a,b| b[ sortby ].to_f <=> a[ sortby ].to_f }     # (i.e. descending sort)
	else
		@fields.sort! { |a,b| a[ sortby ] <=> b[ sortby ] }     # (i.e. ascending sort)
	end
	
	@f_TCOVER.rewind
	@f_COVER = File.new(@reportdir + "/#{title}", "w") rescue die( "Can't open #{@reportdir}\\#{title}", __LINE__ )

	while ( line = @f_TCOVER.gets )
		if ( line =~ /^table data goes here\n/ )
			getcoverline()
		elsif ( line =~ /^Report current.*/ )
			@f_COVER.puts "Report current as of: #{@thedate}"
		else
			@f_COVER.puts line
		end
	end
	
	@f_COVER.close
end

def getcoverline()
	@fields.each_index do |row|
		@total = @fields[ row ][0]
		@chtr = @fields[ row ][1]
		@opp = @fields[ row ][2]
		@test =@fields[ row ][3]
		@bug = @fields[ row ][4]
		@setup = @fields[ row ][5]
		@bugs = @fields[ row ][6]
		@issues = @fields[ row ][7]
		@area = @fields[ row ][8]
		postcoverline( row.to_f )
	end
end

def postcoverline( row_num )
	( row_num/2 ) == ( row_num/2 ).to_i ? bkgd_clr = '' : bkgd_clr = 'bgcolor="#FFFFCC"'
	@f_COVER.puts "  <tr #{bkgd_clr}>"
	@f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@total}</font></td>"
	@f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@chtr}</font></td>"
	@f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@opp}</font></td>"
	@f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@test}</font></td>"
	@f_COVER.puts "    <td width=\"7%\"><font face=\"Courier New\" size=\"2\">#{@bug}</font></td>"
	@f_COVER.puts "    <td width=\"7%\"><font face=\"Courier New\" size=\"2\">#{@setup}</font></td>"
	@f_COVER.puts "    <td width=\"7%\"><font face=\"Courier New\" size=\"2\">#{@bugs}</font></td>"
	@f_COVER.puts "    <td width=\"7%\"><font face=\"Courier New\" size=\"2\">#{@issues}</font></td>"
	@f_COVER.puts "    <td width=\"48%\"><font face=\"Courier New\" size=\"2\">#{@area}</font></td>"
	@f_COVER.puts "  </tr>"
end

def makeses( title, sortby )
	if ( sortby == 0 )
		@fields.sort! { |a,b| a[ sortby ] <=> b[ sortby ] }     # (i.e. ascending sort)
	elsif ( sortby == 1 )
		@fields.sort! {|a,b| Time.parse( b[1]+' '+b[2] ) <=> Time.parse( a[1]+' '+a[2] ) }     # (i.e. descending date+time sort)
	elsif ( sortby == 2 )
		@fields.sort! {|a,b| Time.parse( b[ sortby ] ) <=> Time.parse( a[ sortby ] ) }     # (i.e. descending time sort)
	else  # ( sortby > 2 )
		@fields.sort! { |a,b| b[ sortby ].to_f <=> a[ sortby ].to_f }     # (i.e. descending numeric sort)
	end
	
	@f_TSES.rewind
	@f_SES = File.new(@reportdir + "/#{title}", "w") rescue die( "Can't open #{@reportdir}\\#{title}", __LINE__ )
	
        while ( line = @f_TSES.gets )
        	if ( line =~ /^table data goes here\n/)
        		getsesline()
        	elsif ( line =~ /^Report current.*/)
        		@f_SES.puts "Report current as of: #{@thedate}"
        	else
        		@f_SES.puts line
        	end
        end
	
        @f_SES.close
end

def getsesline()
	@fields.each_index do |row|
		@session = "<a href=\"sessions\\#{@fields[ row ][ 0]}\">#{@fields[ row ][ 0][0..-5]}</a>"
		@date = @fields[ row ][ 1]
		@time = @fields[ row ][ 2]
		@dur = @fields[ row ][ 3]
		@chtr = @fields[ row ][ 4]
		@opp = @fields[ row ][ 5]
		@test = @fields[ row ][ 6]
		@bug = @fields[ row ][ 7]
		@setup = @fields[ row ][ 8]
		@bugs = @fields[ row ][ 9]
		@issues = @fields[ row ][10]
		@tstrs = @fields[ row ][11]
		postsesline( row.to_f )
	end
end

def postsesline( row_num )
	( row_num/2 ) == ( row_num/2 ).to_i ? bkgd_clr = '' : bkgd_clr = 'bgcolor="#FFFFCC"'
	@f_SES.puts "  <tr #{bkgd_clr}>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@session}</font></td>"
	@f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@date}</font></td>"
	@f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@time}</font></td>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@dur}</font></td>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@chtr}</font></td>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@opp}</font></td>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@test}</font></td>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@bug}</font></td>"
	@f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@setup}</font></td>"
	@f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@bugs}</font></td>"
	@f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@issues}</font></td>"
	if @tstrs.to_i == 1
		@f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@tstrs}</font></td>"
	else
		@f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\"><font color=\"red\">#{@tstrs}</font></font></td>"
	end
	@f_SES.puts "  </tr>"
end

def format_num( tmp_arr )
	tmp_arr.collect! do |x|
		if ( ( x.to_f.to_s == x ) and ( x.to_f == x.to_i ) )     # (integer value - no decimals)
			x.to_i.to_s
		elsif ( x.to_f.to_s == x )     # (decimal value - format to 2 decimals)
			sprintf("%0.2f", x)
		else
			x
		end
	end
end

### START ###

f_TSTATUS = File.open(templatedir + "/status.tpl") rescue die( "Can't open #{templatedir}\\status.tpl", __LINE__ )
f_STATUS = File.new(@reportdir + "/status.htm", "w") rescue die( "Can't open #{@reportdir}\\status.htm", __LINE__ )
f_BREAKS = File.open(datadir + "/breakdowns.txt") rescue die( "Can't open #{datadir}\\breakdowns.txt", __LINE__ )

## Create the main "Rapid Testing Status" page ##

@thedate = Time.now.strftime("%m/%d %H:%M:%S")

f_BREAKS.gets     # (skip the first line)
sessioncount, totalsessions, totalbugs = 0, 0, 0

while ( line = f_BREAKS.gets )
	values = line.split(/\"/).delete_if {|x| x.strip.empty? }
	sessioncount += 1
	totalsessions += values[9].to_f     # ( = "N Total")
	totalbugs += values[15].to_i     # ( = "Bugs")
end

while ( line = f_TSTATUS.gets )
	if ( line =~ /^ Updated:.*/ )
		f_STATUS.puts " Updated: #{@thedate}"
	elsif ( line =~ /^Sessions:.*/ )
		totalsessions = sprintf( "%0.2f", totalsessions ) 
		f_STATUS.puts "Sessions: #{totalsessions} (#{sessioncount} reports)"
	elsif ( line =~ /^    Bugs:.*/ )
		f_STATUS.puts "    Bugs: #{totalbugs}"
	else
		f_STATUS.puts line
	end
end

f_STATUS.close
f_TSTATUS.close

## Create the "Test Coverage Totals" pages (with column heading resorting) ##

f_DATA = File.open(datadir + "/breakdowns-coverage-total.txt") rescue die( "Can't open #{datadir}\\breakdowns-coverage-total.txt", __LINE__ )

f_DATA.gets     # (skip the first line)
@fields = []
count = 0
while ( line = f_DATA.gets )
	rawfields = line.split(/\"/).delete_if {|x| x.strip.empty? }
	@fields[count] = format_num( rawfields )
	count += 1
end
f_DATA.close

@f_TCOVER = File.open(templatedir + "/coverage.tpl") rescue die( "Can't open #{templatedir}\\coverage.tpl", __LINE__ )

makecover("c_by_total.htm", 0)
makecover("c_by_chtr.htm", 1)
makecover("c_by_opp.htm", 2)
makecover("c_by_test.htm", 3)
makecover("c_by_bug.htm", 4)
makecover("c_by_setup.htm", 5)
makecover("c_by_bugs.htm", 6)
makecover("c_by_issues.htm", 7)
makecover("c_by_area.htm", 8)

@f_TCOVER.close

## Create the "Completed Session Reports" pages (with column heading resorting) ##

f_BREAKS.rewind
f_BREAKS.gets     # (skip the first line)
@fields = []
count = 0
while ( line = f_BREAKS.gets )
	rawfields = line.split(/\"/).delete_if {|x| x.strip.empty? }
	6.times { rawfields.delete_at(3) }     # (remove the columns we don't need)
	@fields[count] = format_num( rawfields )
	count += 1
end
f_BREAKS.close

@f_TSES = File.open(templatedir + "/sessions.tpl") rescue die( "Can't open #{templatedir}\\sessions.tpl", __LINE__ )

makeses("s_by_ses.htm", 0)
makeses("s_by_datetime.htm", 1)
makeses("s_by_time.htm", 2)
makeses("s_by_dur.htm", 3)
makeses("s_by_chtr.htm", 4)
makeses("s_by_opp.htm", 5)
makeses("s_by_test.htm", 6)
makeses("s_by_bug.htm", 7)
makeses("s_by_setup.htm", 8)
makeses("s_by_bugs.htm", 9)
makeses("s_by_issues.htm", 10)
makeses("s_by_tstrs.htm", 11)

@f_TSES.close

### END ###