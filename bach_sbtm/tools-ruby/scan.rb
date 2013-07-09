#!/bin/ruby
#-------------------------------------------------------------------------------------------------------------#
# scan.rb
# Command Line Options : 4 Required, 1 Optional (e.g. run RUBY-SCAN-SUBMITTED-ONLY.BAT)
#     Here are some examples ([] added for readability; assumes run from C:\Sessions folder):
#     > tools-ruby\scan.rb [submitted] [datafiles] [.] [reports] [scan.log]
#     > tools-ruby\scan.rb [c:\sessions\submitted] [c:\sessions\datafiles] [c:\sessions] [c:\sessions\reports] [c:\sessions\scan.log]
# Purpose: to parse the *.SES files in the specified directory to check for structure and
#     missing elements, and then generate data files that capture certain metrics
#
# Ported from the original PERL script (dated 21-Mar-2001) to RUBY by Paul Carvalho
# Last Updated: 15 July 2009
# Version: 1.2
#------------------------------------------------------------------------------------------------------------ #
@ScriptName = File.basename($0).upcase

if ARGV[0].nil? or ARGV[1].nil? or ARGV[2].nil? or ARGV[3].nil? or ! File.exist?( ARGV[2] + "/coverage.ini" )
	puts "\nUsage: #{@ScriptName} SCAN_DIR FILE_DIR COVERAGE_DIR REPORT_DIR [LOGFILE]"
	puts "\nSCAN_DIR is the path to the directory containing the session sheets."
	puts "FILE_DIR is the path to the directory containing the data files."
	puts "COVERAGE_DIR is the path to the directory containing coverage.ini."
	puts "REPORT_DIR is the path to the directory where the reports will be placed."
	puts "LOGFILE is a file to capture the output that otherwise goes to the console."
	puts
	exit
end

# Look for special switches     (** still uncertain what this check is looking for or why **)
@nodatafiles = false
ARGV.each {|arg| @nodatafiles = true if ( arg =~ /-nodata/ ) }

scandir, @filedir, coveragedir, reportdir = ARGV

( ( ARGV[4].nil? ) or ( ARGV[4] =~ /^-/ ) ) ? @outfile = NIL : @outfile = File.new( ARGV[4], "w" )

# Some Ruby system updates may hide a required method from the Time class
require 'Time' unless Time.methods.include? 'parse'

### METHODS ###

def die( parting_thought, line_num )
	msg = @ScriptName + ": " + parting_thought + ": line ##{line_num}"
	puts  msg
	@outfile.puts msg unless @outfile.nil?
	exit
end

def error( message )
	@errors_found = true
	if @outfile.nil?
		puts "### Error : " + @file.sub("/", "\\") + " : " + message
	else
		@outfile.puts "### Error : " + @file.sub("/", "\\") + " : " + message
	end
#	exit     # (Comment this line out if you want to see *all* of the errors instead of stopping the script after the first error encountered.)
end

def clear_final_blanks( working_array )
	unless working_array.empty?
		last_line = false
		while ( ! last_line )
			temp_line = working_array.pop.chomp
			last_line = true unless temp_line.strip.empty?
		end
		working_array.push temp_line unless temp_line.strip.empty?
		return working_array
	end
end

def parsefile
	charter_found = false ; 	@charter_contents = []
	start_found = false ; 		@start_contents = []
	tester_found = false ; 		@tester_contents = []
	breakdown_found = false ; 	@breakdown_contents = []
	data_found = false ; 		@data_contents = []
	testnotes_found = false ; 	@testnotes_contents = []
	bugs_found = false ; 		@bugs_contents = []
	issues_found = false ; 		@issues_contents = []

	@f_SESSION = File.open( @file ) rescue die( "Can't open #{@file}", __LINE__ )
	
	while ( line = @f_SESSION.gets )
		if ( line =~ /^CHARTER/)
			error("More than one Charter section")  if ( charter_found )
			line = @f_SESSION.gets     # automatically skip the next line (should be dashed line)
			charter_found = true
			reference_array = @charter_contents
			next
		elsif ( line =~ /^START/)
			error("More than one Start section")  if ( start_found )
			line = @f_SESSION.gets
			start_found = true
			reference_array = @start_contents
			next
		elsif ( line =~ /^TESTER/)
			error("More than one Tester section")  if ( tester_found )
			line = @f_SESSION.gets
			tester_found = true
			reference_array = @tester_contents
			next
		elsif ( line =~ /^TASK BREAKDOWN/)
			error("More than one Task Breakdown section")  if ( breakdown_found )
			line = @f_SESSION.gets
			breakdown_found = true
			reference_array = @breakdown_contents
			next
		elsif ( line =~ /^DATA FILES/)
			error("More than one Data Files section")  if ( data_found )
			line = @f_SESSION.gets
			data_found = true
			reference_array = @data_contents
			next
		elsif ( line =~ /^TEST NOTES/)
			error("More than one Test Notes section")  if ( testnotes_found )
			line = @f_SESSION.gets
			testnotes_found = true
			reference_array = @testnotes_contents
			next
		elsif ( line =~ /^BUGS/)
			error("More than one Bugs section")  if ( bugs_found )
			line = @f_SESSION.gets
			bugs_found = true
			reference_array = @bugs_contents
			next
		elsif ( line =~ /^ISSUES/)
			error("More than one Issues section")  if ( issues_found )
			line = @f_SESSION.gets
			issues_found = true
			reference_array = @issues_contents
			next
		end
		line.gsub!('"', "'") if line.include? '"'
		reference_array << line rescue true   # (Rescue in case there are blank lines at the start of the file and the reference_array variable isn't set yet)
	end
	
	error("Missing a Charter section") unless charter_found
	error("Missing a Start section") unless start_found
	error("Missing a Tester section") unless tester_found
	error("Missing a Breakdowns section") unless breakdown_found
	error("Missing a Data Files section") unless data_found
	error("Missing a Test Notes section") unless testnotes_found
	error("Missing a Bugs section") unless bugs_found
	error("Missing an Issues section") unless issues_found
end

def parsetester
	testers_found = 0
	
	@tester_contents.delete_if {|x| x.strip.empty? }     # (Clear out the blank lines)
	
	@tester_contents.each do |name|
		name.strip!
		if ( name =~ /\w+/ )
			@f_TESTERS.puts "\"" + File.basename(@file) + "\"\t\"#{name}\""
			testers_found += 1
		end
	end
	error("Missing tester name in Tester section") if testers_found.zero?
	return testers_found
end

def parsecharter
	area_found = false
	charter_complete = false
	occurs = false
	charter_desc = []
	
	@charter_contents.delete_if {|x| x.strip.empty? }

	@charter_contents.each do |line|
		
		if ( line =~ /^#AREAS/ )
			error("More than one #AREAS keyword found in Charter section") if ( area_found )
			area_found = true
		end
		if ( ! charter_complete )
			charter_desc << line unless ( line =~ /^#/ ) or ( area_found )
			
			if ( line =~ /^#/ )
				charter_complete = true
				if ( ! charter_desc.empty? )
					clear_final_blanks( charter_desc )
					@f_CHARTERS.print "\"" + File.basename(@file) + "\"\t\"DESCRIPTION\"\t\""
					charter_desc.each {|x| @f_CHARTERS.print x }
					@f_CHARTERS.print "\"\n"
				else
					error("No charter description was given in Charter section")
				end
			end
			
		elsif ( ! area_found ) and ( line !~ /^#/ )
			error("Unexpected text \"#{line.chomp}\" found in Charter section. Except for the charter description text (which must precede all other '#' commands), all text in the Charter section must be preceded by a '#' command.")
			
		end
		if ( area_found ) and ( line !~ /^#/ )
			line.strip!.upcase!
			@areas_list.include?( line ) ? occurs = true : occurs = false
			if ( occurs )
				@f_CHARTERS.puts "\"" + File.basename(@file) + "\"\t\"AREA\"\t\"#{line}\""
			else
				error("Unexpected #AREAS label \"#{line}\" in Charter section. Ensure that the area label is one of the legal values in COVERAGE.INI.")
			end
		end
	end
	error("Missing charter description in Charter section") unless ( charter_complete )
	error("Missing area values in Charter section. Ensure that you have specified #AREAS and listed legal area values underneath.") unless ( area_found )
end

def parsestart( startmode = "sessions" )
	time_found = false
	fn_day = ''
	fn_month = ''
	fn_year = ''
	start_date = ''
	start_time = ''

	File.basename( @file ) =~ /et-\w{2,3}-(\d\d)(\d\d)(\d\d)-\w\.ses/
	fn_year = $1
	fn_month = $2.to_i
	fn_day = $3.to_i
	
	@start_contents.delete_if {|x| x.strip.empty? }
	@start_contents.each do |line|
		line.strip!
		if (line =~ /^(\d+)\/(\d+)\/(\d{2,4})\s+(\d+):(\d+)\s*(am|pm)?$/i)
			time_line = Time.parse( line )
			if ( time_found )
				error("Multiple time stamps detected in Start section")
			else
				time_found = true
				
				if ((( time_line.mon != fn_month ) or ( time_line.day != fn_day) or ( time_line.strftime("%y") != fn_year )) and startmode == "sessions" )
					error("File name does not match date in Start section") 
				end
				start_date = time_line.strftime("%m/%d/%y")
				start_time = time_line.strftime("%I:%M %p").downcase
				# (Aside: no longer stripping the leading 0's from the date and time)
			end
		elsif ( ! line.empty? )
			error("Unexpected text found \"#{line}\" in Start section. Ensure that the time stamp is in this format: mm/dd/yy hh:mm{am|pm}. 12-hr or 24-hr time format is acceptable.")
		end
	end
	error("Missing time stamp in Start section") if (! time_found && startmode == "sessions" )
	error("Start section must be empty if the sheet is named as a TODO. Did you forget to rename the session sheet?") if ( time_found && startmode == "todo" )
	
	return start_date, start_time
end

def parsebreakdown( num_testers )
	dur_found = false ;  	dur_happened = false
	tde_found = false ;  	tde_happened = false
	bir_found = false ;  	bir_happened = false
	set_found = false ;  	set_happened = false
	cvo_found = false ;  	cvo_happened = false
	
	in_section = ''
	dur_val = ''
	dur_times = ''
	test_val = '0'
	bug_val = '0'
	prep_val = '0'
	cha_val = '0'
	opp_val = '0'
		
	@breakdown_contents.delete_if {|x| x.strip.empty? }
	@breakdown_contents.each do |line|
		line.strip!
		
		case line
			when /^#DURATION/
				error("More than one #DURATION field found in Task Breakdown section") if ( dur_found )
				dur_found = true
				in_section = 'DUR'
				next
			when /^#TEST DESIGN AND EXECUTION/
				error("More than one #TEST DESIGN AND EXECUTION field found in Task Breakdown section") if ( tde_found )
				tde_found = true
				in_section = 'TDE'
				next
			when /^#BUG INVESTIGATION AND REPORTING/
				error("More than one #BUG INVESTIGATION AND REPORTING field found in Task Breakdown section") if ( bir_found )
				bir_found = true
				in_section = 'BIR'
				next
			when /^#SESSION SETUP/
				error("More than one #SESSION SETUP field found in Task Breakdown section") if ( set_found )
				set_found = true
				in_section = 'SET'
				next
			when /^#CHARTER VS. OPPORTUNITY/
				error("More than one #CHARTER VS. OPPORTUNITY field found in Task Breakdown section") if ( cvo_found )
				cvo_found = true
				in_section = 'CVO'
				next
		end
			
		if ( in_section == 'DUR' )
			if ( ! dur_happened )
				dur_happened = true
				
				(dur_val, dur_times) = line.split('*')
				dur_val.strip! ; dur_val.downcase!
				
				if ( dur_times.nil? ) or ( dur_times.strip.empty? )
					dur_times = '1'
				else
					dur_times.strip!
				end
				
				unless ( dur_val.eql?('short') or dur_val.eql?('normal') or dur_val.eql?('long') )
					error("Unexpected #DURATION value \"#{dur_val}\" in Task Breakdown section. Legal values are: short, normal, or long")
				end
				unless ( dur_times == dur_times.to_i.to_s and dur_times.to_i > 0 ) or ( dur_times == dur_times.to_f.to_s and dur_times.to_f > 0.0 )
					error("Unexpected #DURATION multiplier \"#{dur_times}\" in Task Breakdown section. Must be a positive integer or decimal value.")
				end
			else
				error("Unexpected value encountered under #DURATION in the Task Breakdown section: \"#{line}\"")
			end
			
		elsif ( in_section == 'TDE' )
			if ( ! tde_happened )
				tde_happened = true
				
				test_val = line
				if ( test_val.to_i < 0 or test_val.to_i > 100 ) or ( line =~ /\D+/ )
					error("Unexpected #TEST DESIGN AND EXECUTION value in Task Breakdown section. Ensure that the value is an integer from 0-100.")
				end
			else
				error("Unexpected value encountered under #TEST DESIGN AND EXECUTION in the Task Breakdown section: \"#{line}\"" )
			end
			
		elsif ( in_section == 'BIR' )
			if ( ! bir_happened )
				bir_happened = true
				
				bug_val = line
				if ( bug_val.to_i < 0 or bug_val.to_i > 100) or ( line =~ /\D+/ )
					error("Unexpected #BUG INVESTIGATION AND REPORTING value in Task Breakdown section. Ensure that the value is an integer from 0-100.")
				end
			else
				error("Unexpected value encountered under #BUG INVESTIGATION AND REPORTING in the Task Breakdown section: \"#{line}\"")
			end
			
		elsif ( in_section == 'SET' )
			if ( ! set_happened )
				set_happened = true
				
				prep_val = line
				if ( prep_val.to_i < 0 or prep_val.to_i > 100) or ( line =~ /\D+/ )
					error("Unexpected #SESSION SETUP value in Task Breakdown section. Ensure that the value is an integer from 0-100.")
				end
			else
				error("Unexpected value encountered under #SESSION SETUP in the Task Breakdown section: \"#{line}\"")
			end
			
		elsif ( in_section == 'CVO' )
			if ( ! cvo_happened )
				cvo_happened = true
				
				if ( line !~ /^\d+\s*\/\s*\d+/ )
					error("Unexpected #CHARTER VS. OPPORTUNITY value \"#{line}\" in Task Breakdown section. Ensure that the values are integers from 0-100 separated by '/'.")
				end
				
				(cha_val, opp_val) = line.split('/')
				
				if cha_val.nil?
					cha_val = '0'
				else
					cha_val.strip!
					cha_val = '0' if ( cha_val.empty? )
				end
				if opp_val.nil?
					opp_val = '0'
				else
					opp_val.strip!
					opp_val = '0' if ( opp_val.empty? )
				end
				
				unless ( ( cha_val.to_i + opp_val.to_i ) == 100 )
					error("#CHARTER VS. OPPORTUNITY value does not add up to 100 in Task Breakdown section")
				end
			else
				error("Unexpected value encountered under #CHARTER VS. OPPORTUNITY in the Task Breakdown section: \"#{line}\"")
			end
		end
	end
	
	error("Missing #DURATION field in Task Breakdown section") if ( ! dur_found ) or ( dur_found and ! dur_happened)
	error("Missing #TEST DESIGN AND EXECUTION field in Task Breakdown section") if ( ! tde_found ) or ( tde_found and ! tde_happened)
	error("Missing #BUG INVESTIGATION AND REPORTING field in Task Breakdown section") if ( ! bir_found ) or ( bir_found and ! bir_happened)
	error("Missing #SESSION SETUP field in Task Breakdown section") if ( ! set_found ) or ( set_found and ! set_happened)
	error("Missing #CHARTER VS. OPPORTUNITY field in Task Breakdown section") if ( ! cvo_found ) or ( cvo_found and ! cvo_happened)
	
	unless ( ( prep_val.to_i + test_val.to_i + bug_val.to_i ) == 100 )
		error("Unexpected sum of Task breakdown values. Values of #SESSION SETUP, #TEST DESIGN AND EXECUTION, and #BUG INVESTIGATION AND REPORTING must add up to 100")
	end
	
	if ( dur_val == "long" ) 
		dur_val = ( (4.0/3) * dur_times.to_f ).to_s
	elsif ( dur_val == "normal" ) 
		dur_val = dur_times
	else 
		dur_val = ( (2.0/3) * dur_times.to_f ).to_s
	end
	
	return dur_val, cha_val, opp_val, test_val, bug_val, prep_val, 
		(dur_val.to_f * num_testers), 
		(dur_val.to_f * num_testers * cha_val.to_i / 100), 
		(dur_val.to_f * num_testers * opp_val.to_i / 100), 
		(dur_val.to_f * num_testers * test_val.to_i / 100 * cha_val.to_i / 100), 
		(dur_val.to_f * num_testers * bug_val.to_i / 100 * cha_val.to_i / 100), 
		(dur_val.to_f * num_testers * prep_val.to_i / 100 * cha_val.to_i / 100)
	
end

def parsedata
	na = false
	content = false
	
	@data_contents.delete_if {|x| x.strip.empty? }
	
	@data_contents.each do |line|
		line.strip!
		if ( line =~ /^#N\/A/ )
			na = true
		elsif ( line =~ /\w+/ )
			content = true
		end
	end
	
	if ( ! na and ! content )
		error("Data Files section is empty. If you used no data files in this test session, specify #N/A.")
		
	elsif ( na and content )
		error("Unexpected text found with #N/A tag in Data Files section. If you specify #N/A, no other text is permitted in this section.")
		
	elsif ( na and ! content )
		@f_DATA.puts "\"" + File.basename(@file) + "\"\t\"<empty>\""
		
	elsif ( ! na and content )
		@data_contents.each do |line|
			file_exists = File.exist?( @filedir + "/" + line ) if ( line =~ /\w+/ )
			if ( file_exists )
				@f_DATA.puts "\"" + File.basename(@file) + "\"\t\"#{line}\""
			else
				error("Missing data file \"#{line}\" in the data file directory. Ensure the file exists in the \"#{@filedir}\" directory specified as the second argument on the #{@ScriptName} command line.") unless ( @nodatafiles )
			end
		end
	end
end

def parsetestnotes
	na = false
	content = false
	
	@testnotes_contents.each do |line|
		if ( line =~ /^#N\/A/ )
			na = true
		elsif ( line =~ /\w+/ )
			content = true
		end
	end
	
	if ( ! na and ! content)
		error("Test Notes section is empty. If you have no notes, specify #N/A.")
		
	elsif ( na and content )
		error("Unexpected text found with #N/A tag in Test Notes section. If you specify #N/A, no other text is permitted in this section.")
		
	elsif ( na and ! content )
		@f_TESTNOTES.puts "\"" + File.basename(@file) + "\"\t\"<empty>\""
		
	elsif ( ! na and content )
		clear_final_blanks( @testnotes_contents )
		@f_TESTNOTES.print "\"" + File.basename(@file) + "\"\t\""
		@testnotes_contents.each {|x| @f_TESTNOTES.print x }
		@f_TESTNOTES.print "\"\n"
	end
end

def parsebugs
	na = false
	bug_content = false
	in_bug = false
	bug_id = ''
	single_bug = []
	bug_found = false
	bug_count = 0
	
	@bugs_contents.delete_if {|x| x.strip.empty? }
	
	@bugs_contents.each do |line|
		if ( line =~ /^#N\/A/ )
			na = true
		elsif ( line =~ /\S+/ )
			bug_content = true
		end
		if ( line =~ /^BUG/i or line =~ /^# BUG/i )
			error("Possible typo in Bugs section. Don't put \"BUG\" at the start of a line and don't put \"# BUG\" (space between # and BUG).")
		end
	end
	
	if ( ! na and ! bug_content )
		error("Bugs section is empty. If you have no bugs to report in this session, specify #N/A.")
		
	elsif ( na and bug_content )
		error("Unexpected text found with #N/A tag in Bugs section. If you specify #N/A, no other text is permitted in this section.")
		
	elsif ( na and ! bug_content )
		@f_BUGS.puts "\"" + File.basename(@file) + "\"\t\"<empty>\""
		
	elsif ( ! na and bug_content )
		
		@bugs_contents.each do |line|
			if ( line =~ /^#BUG/i )
				if ( in_bug )
					clear_final_blanks( single_bug )
					
					if ( single_bug.empty? )
						error("Empty bug field in Bugs section. Ensure that you provided bug description text after each #BUG.")
					else
						@f_BUGS.print "\"" + File.basename(@file) + "\"\t\""
						single_bug.each {|x| @f_BUGS.print x }
						@f_BUGS.print "\"\t\"#{bug_id}\"\n"
						bug_count += 1
					end
				end
				
				line =~ /^#BUG\s+(.+)/i ? bug_id = $1 : bug_id = ''
				
				single_bug = []
				in_bug = true
				
			elsif ( in_bug )
				single_bug << line
				bug_found = true if ( line =~ /\S+/ )
				
			elsif ( line =~ /\S+/ )
				error("Unexpected text in Bugs section: \"#{line}\". Ensure you specify #BUG before each bug description in this section.")
			end
		end
		
		if ( in_bug )
			clear_final_blanks( single_bug )
			
			if ( single_bug.empty? )
				error("Empty bug field in Bugs section. Ensure that you provided bug description text after each #BUG.")
			else
				@f_BUGS.print "\"" + File.basename(@file) + "\"\t\""
				single_bug.each {|x| @f_BUGS.print x }
				@f_BUGS.print "\"\t\"#{bug_id}\"\n"
				bug_count += 1
			end
		end
	end
	
	return bug_count
end

def parseissues
	na = false
	issue_content = false
	in_issue = false
	issue_id = ''
	single_issue = []
	issue_found = false
	issue_count = 0
	
	@issues_contents.delete_if {|x| x.strip.empty? }
	
	@issues_contents.each do |line|
		if ( line =~ /^#N\/A/ )
			na = true
		elsif ( line =~ /\S+/ )
			issue_content = true
		end
		if ( line =~ /^ISSUE/i or line =~ /^# ISSUE/i )
			error("Possible typo in Issues section. Don't put \"ISSUE\" at the start of a line and don't put \"# ISSUE\" (space between # and ISSUE).")
		end
	end
	
	if ( ! na and ! issue_content )
		error("Issues section is empty. If you have no issues to report in this session, specify #N/A.")
		
	elsif ( na and issue_content )
		error("Unexpected text found with #N/A tag in the Issues section. If you specify #N/A, no other text is permitted in this section.")
		
	elsif ( na and ! issue_content )
		@f_ISSUES.puts "\"" + File.basename(@file) + "\"\t\"<empty>\""
		
	elsif ( ! na and issue_content )
		
		@issues_contents.each do |line|
			if ( line =~ /^#ISSUE/i )
				if ( in_issue )
					clear_final_blanks( single_issue )
					
					if ( single_issue.empty? )
						error("Empty issue field in Issues section. Ensure you included an issue description after each #ISSUE.")
					else
						@f_ISSUES.print "\"" + File.basename(@file) + "\"\t\""
						single_issue.each {|x| @f_ISSUES.print x }
						@f_ISSUES.print "\"\t\"#{issue_id}\"\n"
						issue_count += 1
					end
				end
				
				line =~ /^#ISSUE\s+(.+)/i ? issue_id = $1 : issue_id = ''
				
				single_issue = []
				in_issue = true
				
			elsif ( in_issue )
				single_issue << line
				issue_found = true if ( line =~ /\S+/ )
				
			elsif ( line =~ /\S+/ )
				error("Unexpected text in Issues section: \"#{line}\". Ensure you specify #ISSUE before each issue in this section.")
			end
		end
		
		if ( in_issue )
			clear_final_blanks( single_issue )
			
			if ( single_issue.empty? )
				error("Empty issue field in Issues section. Ensure you included an issue description after each #ISSUE.")
			else
				@f_ISSUES.print "\"" + File.basename(@file) + "\"\t\""
				single_issue.each {|x| @f_ISSUES.print x }
				@f_ISSUES.print "\"\t\"#{issue_id}\"\n"
				issue_count += 1
			end
		end
	end
	
	return issue_count
end

### START ###

@errors_found = false

f_CFG = File.open( coveragedir + "/coverage.ini" ) rescue die( "Can't open #{coveragedir}\\coverage.ini", __LINE__ )
@areas_list = []
while (line = f_CFG.gets)
	  @areas_list << line.strip.upcase unless ( line.strip.empty? or line =~ /^#/ )
end
f_CFG.close

# Get the file lists :

@sheets = Dir[ scandir + "/*.ses" ]
@datafiles = Dir[ @filedir + "/*" ]

@sheets.map! {|x| x.downcase }

todo = []
@sheets.each {|x| todo << x  if ( x =~ /et-todo/ ) }

@sheets.delete_if {|x| x =~ /et-todo/ }     # (exclude the "et-TODO-*.ses" files)

# Parse the Session Reports :

@f_CHARTERS = File.new( reportdir + "/charters.txt", "w" )
@f_CHARTERS.puts "\"Session\"\t\"Field\"\t\"Value\""

@f_TESTERS = File.new( reportdir + "/testers.txt", "w" )
@f_TESTERS.puts "\"Session\"\t\"Tester\""

breakdowns_heading = "\"Session\"\t" +
		"\"Start\"\t" +
		"\"Time\"\t" +
		"\"Duration\"\t" +
		"\"On Charter\"\t" +
		"\"On Opportunity\"\t" +
		"\"Test\"\t" +
		"\"Bug\"\t" +
		"\"Setup\"\t" +
		"\"N Total\"\t" +
		"\"N On Charter\"\t" +
		"\"N Opportunity\"\t" +
		"\"N Test\"\t" +
		"\"N Bug\"\t" +
		"\"N Setup\"\t" +
		"\"Bugs\"\t" +
		"\"Issues\"\t" +
		"\"Testers\""

@f_DATA = File.new( reportdir + "/data.txt", "w" )
@f_DATA.puts "\"Session\"\t\"Files\""

@f_TESTNOTES = File.new( reportdir + "/testnotes.txt", "w" )
@f_TESTNOTES.puts "\"Session\"\t\"Notes\""

@f_BUGS = File.new( reportdir + "/bugs.txt", "w" )
@f_BUGS.puts "\"Session\"\t\"Bugs\"\t\"ID\""

@f_ISSUES = File.new( reportdir + "/issues.txt", "w" )
@f_ISSUES.puts "\"Session\"\t\"Issues\"\t\"ID\""

@sessions = Hash.new { |h,k| h[k] = [] }     # (This is a hash which auto-creates non-existing members as an empty array)

@sheets.sort.each do |@file|
	file_name = File.basename( @file )
	if ( file_name !~ /^et-\w{2,3}-\d{6}-\w\.ses/ )
		error("Unexpected session file name. If it's a session sheet, its name must be: \"ET-<tester initials>-<yymmdd>-<A, B, C, etc.>.SES\". If it's a TODO sheet, its name must be: \"ET-TODO-<priority number>-<title>.SES\"")
	end
	
	parsefile()
	tester_count = parsetester()
	parsecharter()
	@sessions[ file_name ] << parsestart( "sessions" )
	@sessions[ file_name ] << parsebreakdown( tester_count )
	parsedata()
	parsetestnotes()
	@sessions[ file_name ] << parsebugs()
	@sessions[ file_name ] << parseissues()
	@sessions[ file_name ] << tester_count
	@sessions[ file_name ].flatten!
end

@f_CHARTERS.close
@f_TESTERS.close
@f_DATA.close
@f_TESTNOTES.close
@f_BUGS.close
@f_ISSUES.close

# Parse the ToDo files :

@f_CHARTERS = File.new( reportdir + "/charters-todo.txt", "w+")
@f_CHARTERS.puts "\"Session\"\t\"Field\"\t\"Value\""

todo.each do |@file|
	parsefile()
	parsecharter()
	parsestart( "todo" )
end

## Rewrite the charters-todo.txt file into a different layout (if there is any ToDo data) :

@f_CHARTERS.rewind
@f_CHARTERS.gets    # (ignore heading line)

todo_raw = []
@f_CHARTERS.each_line {|line| todo_raw.push line}
@f_CHARTERS.close

todo = []

# (compress multi-line Descriptions into single lines)
while ( line = todo_raw.shift )
	while ( todo_raw[0] and ( line !~ /\"\n$/ ) ) 
		line = line + " " + todo_raw[0]
		todo_raw.shift
	end
	todo << line
end

unless ( todo.empty? )
	# (compress multi-line Areas into single lines, and bring Descriptions and Areas into an array value for each session)
	session = ''
	field = ''
	content = ''
	todolist = Hash.new { |h,k| h[k] = [] }
	while ( line = todo.shift )
		session = line.split('"')[1].downcase
		field = line.split('"')[3]
		areas = []
		
		if ( field == "DESCRIPTION" )
			content = line.split('"')[5]     # (should we strip the \n characters out of this description?)
		else
			areas << line.split('"')[5]
			while ( todo[0] and todo[0].split('"')[3] == "AREA" ) 
				line = todo.shift
				
				if ( line.split('"')[3] != "AREA" )
					todo.unshift(line)
				else
					areas << line.split('"')[5]
				end
			end
			content = areas.join(';')
		end
		todolist[session] << content
	end
	
	f_CHARTERS = File.new( reportdir + "/charters-todo.txt", "w")
	f_CHARTERS.puts "\"Title\"\t\"Area\"\t\"Priority\"\t\"Description\""
	
	title = ''
	priority = ''
	todolist.sort.each do |session, value|
		session =~ /et-todo-(\d)-(.+)\.ses/
		priority = $1
		title = $2
		
		f_CHARTERS.puts "\"" + title + "\"\t\"" + value.last + 
			"\"\t\"" + priority + "\"\t\"" + value.first + "\""
	end
	f_CHARTERS.close
end

## Calculate Session Metrics and Totals, Print them to the Output files :

testarea = Hash.new { |h,k| h[k] = [] }
testers = Hash.new { |h,k| h[k] = [] }

f_CHARTERS = File.open( reportdir + "/charters.txt" )
f_CHARTERS.gets     # (ignore heading line)
f_CHARTERS.each_line { |line| testarea[ line.split('"')[5] ] << line.split('"')[1]  if ( line.split('"')[3] == "AREA" ) }     # ( testarea[ area ] << [session] )
f_CHARTERS.close

f_TESTERS = File.open( reportdir + "/testers.txt" )
f_TESTERS.gets     # (ignore heading line)
f_TESTERS.each_line { |line| testers[ line.split('"')[3] ] << line.split('"')[1] }     # ( testers[ tester_name ] << [session] )
f_TESTERS.close

f_DAYBREAKS = File.new( reportdir + "/breakdowns-day.txt", "w" )
f_DAYBREAKS.puts "\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

n_total = {}
n_charter = {}
n_opportunity = {}
n_test = {}
n_bug = {}
n_prep = {}
bugs = {}
issues = {}

@sessions.each do |key, value|
	date = value[0]
	n_total.has_key?( date ) ?  		n_total[ date ] += value[8] : 		n_total[ date ] = value[8]
	n_charter.has_key?( date ) ? 	n_charter[ date ] += value[9] : 		n_charter[ date ] = value[9]
	n_opportunity.has_key?( date ) ? 	n_opportunity[ date ] += value[10] : 	n_opportunity[ date ] = value[10]
	n_test.has_key?( date ) ? 	 	n_test[ date ] += value[11] : 		n_test[ date ] = value[11]
	n_bug.has_key?( date ) ? 		n_bug[ date ] += value[12] : 		n_bug[ date ] = value[12]
	n_prep.has_key?( date ) ? 		n_prep[ date ] += value[13] : 		n_prep[ date ] = value[13]
	bugs.has_key?( date ) ?  		bugs[ date ] += value[14] :  		bugs[ date ] = value[14]
	issues.has_key?( date ) ? 		issues[ date ] += value[15] : 		issues[ date ] = value[15]
end

n_total.sort { |a,b| Time.parse( b[0] ) <=> Time.parse( a[0] ) }.each do | date, value |     # (descending Date sort)
	f_DAYBREAKS.puts "\"" + date + "\"\t\"" + 
		n_total[ date ].to_s + "\"\t\"" + 
		n_charter[ date ].to_s + "\"\t\"" + 
		n_opportunity[ date ].to_s + "\"\t\"" + 
		n_test[ date ].to_s + "\"\t\"" + 
		n_bug[ date ].to_s + "\"\t\"" + 
		n_prep[ date ].to_s + "\"\t\"" + 
		bugs[ date ].to_s + "\"\t\"" + 
		issues[ date ].to_s + "\""
end

f_DAYBREAKS.close

f_TDAYBREAKS = File.new( reportdir + "/breakdowns-tester-day.txt", "w" )
f_TDAYBREAKS.puts "\"Tester\"\t\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

f_TESTERTOTALS = File.new( reportdir + "/breakdowns-testers-total.txt", "w" )
f_TESTERTOTALS.puts "\"Tester\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

f_TESTERBREAKS = File.new( reportdir + "/breakdowns-testers-sessions.txt", "w" )
f_TESTERBREAKS.puts "\"Session\"\t" + 
	"\"Start\"\t" + 
	"\"Time\"\t" + 
	"\"Duration\"\t" + 
	"\"On Charter\"\t" + 
	"\"On Opportunity\"\t" + 
	"\"Test\"\t" + 
	"\"Bug\"\t" + 
	"\"Setup\"\t" + 
	"\"N Total\"\t" + 
	"\"N On Charter\"\t" + 
	"\"N Opportunity\"\t" + 
	"\"N Test\"\t" + 
	"\"N Bug\"\t" + 
	"\"N Setup\"\t" + 
	"\"Bugs\"\t" + 
	"\"Issues\"\t" + 
	"\"Testers\"\t" + 
	"\"Tester\""


testers.each do | tester_name, sess_arr |
	tn_total = {} ; 		dn_total = {}
	tn_charter = {} ; 	dn_charter = {}
	tn_opportunity = {} ; 	dn_opportunity = {}
	tn_prep = {} ; 		dn_prep = {}
	tn_test = {} ; 		dn_test = {}
	tn_bug = {} ; 		dn_bug = {}
	tn_tester = {} ; 		dn_tester = {}
	tbugs = {} ; 		dbugs = {}
	tissues = {} ;  		dissues = {}
	
	sess_arr.each do | sess_name |
		start  	= @sessions[ sess_name ][0]
		time  	= @sessions[ sess_name ][1]
		duration  	= @sessions[ sess_name ][2]
		oncharter 	= @sessions[ sess_name ][3]
		onopportunity = @sessions[ sess_name ][4]
		test  		= @sessions[ sess_name ][5]
		bug  		= @sessions[ sess_name ][6]
		prep  	= @sessions[ sess_name ][7]
		n_total  	= @sessions[ sess_name ][8]
		n_charter 	= @sessions[ sess_name ][9]
		n_opportunity = @sessions[ sess_name ][10]
		n_test  	= @sessions[ sess_name ][11]
		n_bug  	= @sessions[ sess_name ][12]
		n_prep  	= @sessions[ sess_name ][13]
		bugs  	= @sessions[ sess_name ][14].to_f     # (to help more accurately split counts between multiple testers)
		issues  	= @sessions[ sess_name ][15].to_f
		testers  	= @sessions[ sess_name ][16]
		
		f_TESTERBREAKS.puts "\"" + sess_name + "\"\t\"" + 
			start + "\"\t\"" + 
			time + "\"\t\"" + 
			duration + "\"\t\"" + 
			oncharter + "\"\t\"" + 
			onopportunity + "\"\t\"" + 
			test + "\"\t\"" + 
			bug + "\"\t\"" + 
			prep + "\"\t\"" + 
			( n_total/testers ).to_s + "\"\t\"" + 
			( n_charter/testers ).to_s + "\"\t\"" + 
			( n_opportunity/testers ).to_s + "\"\t\"" + 
			( n_test/testers ).to_s + "\"\t\"" + 
			( n_bug/testers ).to_s + "\"\t\"" + 
			( n_prep/testers ).to_s + "\"\t\"" + 
			( bugs/testers ).to_s + "\"\t\"" + 
			( issues/testers ).to_s + "\"\t\"" + 
			testers.to_s + "\"\t\"" + 
			tester_name + "\""
		
		tn_total.has_key?( tester_name ) ? 	tn_total[ tester_name ] += ( n_total/testers ) : 		tn_total[ tester_name ] = ( n_total/testers )
		tn_charter.has_key?( tester_name ) ? 	tn_charter[ tester_name ] += ( n_charter/testers ) :   	tn_charter[ tester_name ] = ( n_charter/testers )
		tn_opportunity.has_key?( tester_name ) ? tn_opportunity[ tester_name ] += ( n_opportunity/testers ) : tn_opportunity[ tester_name ] = ( n_opportunity/testers )
		tn_test.has_key?( tester_name ) ?  	tn_test[ tester_name ] += ( n_test/testers ) : 		tn_test[ tester_name ] = ( n_test/testers )
		tn_bug.has_key?( tester_name ) ?   	tn_bug[ tester_name ] += ( n_bug/testers ) :  		tn_bug[ tester_name ] = ( n_bug/testers )
		tn_prep.has_key?( tester_name ) ?   	tn_prep[ tester_name ] += ( n_prep/testers ) : 		tn_prep[ tester_name ] = ( n_prep/testers )
		tbugs.has_key?( tester_name ) ? 	  	tbugs[ tester_name ] += ( bugs/testers ) : 	 		tbugs[ tester_name ] = ( bugs/testers )
		tissues.has_key?( tester_name ) ?   	tissues[ tester_name ] += ( issues/testers ) :   		tissues[ tester_name ] = ( issues/testers )
		
		# (change the date format so it correctly sorts in 'yy/mm/dd' format -- we'll switch it back later when writing to file)
		dnew_key = start[-2,2] + '/' + start[0,5] + "\t" + tester_name
		dn_total.has_key?( dnew_key ) ?   	dn_total[ dnew_key ] += ( n_total/testers ) : 		dn_total[ dnew_key ] = ( n_total/testers )
		dn_charter.has_key?( dnew_key ) ? 	dn_charter[ dnew_key ] += ( n_charter/testers ) :   	dn_charter[ dnew_key ] = ( n_charter/testers )
		dn_opportunity.has_key?( dnew_key ) ? 	dn_opportunity[ dnew_key ] += ( n_opportunity/testers ) : dn_opportunity[ dnew_key ] = ( n_opportunity/testers )
		dn_test.has_key?( dnew_key ) ?    	dn_test[ dnew_key ] += ( n_test/testers ) :   		dn_test[ dnew_key ] = ( n_test/testers )
		dn_bug.has_key?( dnew_key ) ?     	dn_bug[ dnew_key ] += ( n_bug/testers ) :    		dn_bug[ dnew_key ] = ( n_bug/testers )
		dn_prep.has_key?( dnew_key ) ?    	dn_prep[ dnew_key ] += ( n_prep/testers ) :  		dn_prep[ dnew_key ] = ( n_prep/testers )
		dbugs.has_key?( dnew_key ) ? 	  	dbugs[ dnew_key ] += ( bugs/testers ) : 	 		dbugs[ dnew_key ] = ( bugs/testers )
		dissues.has_key?( dnew_key ) ?     	dissues[ dnew_key ] += ( issues/testers ) :    		dissues[ dnew_key ] = ( issues/testers )
		
	end
	
	f_TESTERTOTALS.puts "\"" + tester_name + "\"\t\"" + 
		tn_total[ tester_name ].to_s + "\"\t\"" + 
		tn_charter[ tester_name ].to_s + "\"\t\"" + 
		tn_opportunity[ tester_name ].to_s + "\"\t\"" + 
		tn_test[ tester_name ].to_s + "\"\t\"" + 
		tn_bug[ tester_name ].to_s + "\"\t\"" + 
		tn_prep[ tester_name ].to_s + "\"\t\"" + 
		tbugs[ tester_name ].to_s + "\"\t\"" + 
		tissues[ tester_name ].to_s + "\""
	
	dn_total.sort.each do | date_name, value |
		start = date_name.split(/\t/)[0]
		f_TDAYBREAKS.puts "\"" + tester_name + "\"\t\"" + 
			start[-5,5] + '/' + start[0,2] + "\"\t\"" + 
			dn_total[ date_name ].to_s + "\"\t\"" + 
			dn_charter[ date_name ].to_s + "\"\t\"" + 
			dn_opportunity[ date_name ].to_s + "\"\t\"" + 
			dn_test[ date_name ].to_s + "\"\t\"" + 
			dn_bug[ date_name ].to_s + "\"\t\"" + 
			dn_prep[ date_name ].to_s + "\"\t\"" + 
			dbugs[ date_name ].to_s + "\"\t\"" + 
			dissues[ date_name ].to_s + "\""
	end
end

f_TDAYBREAKS.close
f_TESTERTOTALS.close
f_TESTERBREAKS.close

f_COVERAGEBREAKS = File.new( reportdir + "/breakdowns-coverage-sessions.txt", "w" )
f_COVERAGEBREAKS.puts "\"Session\"\t" + 
	"\"Start\"\t" + 
	"\"Time\"\t" + 
	"\"Duration\"\t" + 
	"\"On Charter\"\t" + 
	"\"On Opportunity\"\t" + 
	"\"Test\"\t" + 
	"\"Bug\"\t" + 
	"\"Setup\"\t" + 
	"\"N Total\"\t" + 
	"\"N On Charter\"\t" + 
	"\"N Opportunity\"\t" + 
	"\"N Test\"\t" + 
	"\"N Bug\"\t" + 
	"\"N Setup\"\t" + 
	"\"Bugs\"\t" + 
	"\"Issues\"\t" + 
	"\"Testers\"\t" + 
	"\"Area\""

f_COVERAGETOTALS = File.new( reportdir + "/breakdowns-coverage-total.txt", "w" )
f_COVERAGETOTALS.puts "\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\"\t\"Area\""


@areas_list.sort.each do |area|
	tn_total = {}
	tn_charter = {}
	tn_opportunity = {}
	tn_prep = {}
	tn_test = {}
	tn_bug = {}
	tn_tester = {}
	tbugs = {}
	tissues = {}
	
	if testarea.has_key?( area )
		sess_arr = testarea[ area ]
	else
		# (fill in blanks for the Coverage.ini Areas not yet covered)
		f_COVERAGEBREAKS.puts "\"\"\t" * 18 + "\"" + area + "\""
		sess_arr = []
	end
	
	sess_arr.each do | sess_name |
		start  	= @sessions[ sess_name ][0]
		time  	= @sessions[ sess_name ][1]
		duration  	= @sessions[ sess_name ][2]
		oncharter  	= @sessions[ sess_name ][3]
		onopportunity = @sessions[ sess_name ][4]
		test  		= @sessions[ sess_name ][5]
		bug  		= @sessions[ sess_name ][6]
		prep  	= @sessions[ sess_name ][7]
		n_total  	= @sessions[ sess_name ][8]
		n_charter  	= @sessions[ sess_name ][9]
		n_opportunity = @sessions[ sess_name ][10]
		n_test  	= @sessions[ sess_name ][11]
		n_bug  	= @sessions[ sess_name ][12]
		n_prep  	= @sessions[ sess_name ][13]
		bugs  	= @sessions[ sess_name ][14]
		issues  	= @sessions[ sess_name ][15]
		testers  	= @sessions[ sess_name ][16]
		
		f_COVERAGEBREAKS.puts "\"" + sess_name + "\"\t\"" + 
			start + "\"\t\"" + 
			time + "\"\t\"" + 
			duration + "\"\t\"" + 
			oncharter + "\"\t\"" + 
			onopportunity + "\"\t\"" + 
			test + "\"\t\"" + 
			bug + "\"\t\"" + 
			prep + "\"\t\"" + 
			n_total.to_s + "\"\t\"" + 
			n_charter.to_s + "\"\t\"" + 
			n_opportunity.to_s + "\"\t\"" + 
			n_test.to_s + "\"\t\"" + 
			n_bug.to_s + "\"\t\"" + 
			n_prep.to_s + "\"\t\"" + 
			bugs.to_s + "\"\t\"" + 
			issues.to_s + "\"\t\"" + 
			testers.to_s + "\"\t\"" + 
			area + "\""
		
		tn_total.has_key?( area ) ?    	tn_total[ area ] += n_total : 		tn_total[ area ] = n_total
		tn_charter.has_key?( area ) ? 	tn_charter[ area ] += n_charter :   	tn_charter[ area ] = n_charter
		tn_opportunity.has_key?( area ) ? 	tn_opportunity[ area ] += n_opportunity : tn_opportunity[ area ] = n_opportunity
		tn_test.has_key?( area ) ?     	tn_test[ area ] += n_test : 			tn_test[ area ] = n_test
		tn_bug.has_key?( area ) ?      	tn_bug[ area ] += n_bug :  			tn_bug[ area ] = n_bug
		tn_prep.has_key?( area ) ?     	tn_prep[ area ] += n_prep : 			tn_prep[ area ] = n_prep
		tbugs.has_key?( area ) ? 	  	tbugs[ area ] += bugs : 	 		tbugs[ area ] = bugs
		tissues.has_key?( area ) ?      	tissues[ area ] += issues :   			tissues[ area ] = issues
		
	end
	
	if testarea.has_key?( area )
		f_COVERAGETOTALS.puts "\"" + tn_total[ area ].to_s + "\"\t\"" + 
			tn_charter[ area ].to_s + "\"\t\"" + 
			tn_opportunity[ area ].to_s + "\"\t\"" + 
			tn_test[ area ].to_s + "\"\t\"" + 
			tn_bug[ area ].to_s + "\"\t\"" + 
			tn_prep[ area ].to_s + "\"\t\"" + 
			tbugs[ area ].to_s + "\"\t\"" + 
			tissues[ area ].to_s + "\"\t\"" + 
			area + "\""
	else
		f_COVERAGETOTALS.puts "\"0\"\t" * 8 + "\"" + area + "\""
	end
end

f_COVERAGEBREAKS.close
f_COVERAGETOTALS.close

## Re-Sort the Sessions (descending by Date+Time) and output to the Breakdowns file :
resorted_array = []
@sessions.each { |file_name, data| resorted_array << data.unshift( file_name ) }
resorted_array.sort! { |a,b| Time.parse( b[1]+' '+b[2] ) <=> Time.parse( a[1]+' '+a[2] ) }

f_BREAKDOWNS = File.new( reportdir + "/breakdowns.txt", "w" )
	f_BREAKDOWNS.puts breakdowns_heading
	resorted_array.each { |data| f_BREAKDOWNS.puts "\"" + data.join("\"\t\"") + "\"" }
f_BREAKDOWNS.close

## Final Note :
if @errors_found
	msg = "\nErrors Found!  Please correct the session sheet(s) listed above and re-run the scan utility."
else
	msg = "Your papers are in order!"
end

if @outfile.nil?
	puts msg
else
	@outfile.puts msg
end

### END ###