# Needed for file name parsing
use File::Basename;

# Look for special switches
foreach (@ARGV)
{
	$nodatafiles++ if /\-nodata/;
}

# Directories for scanning
$scandir = shift @ARGV;
$filedir = shift @ARGV;
$coveragedir = shift @ARGV;
$reportdir = shift @ARGV;

open(CFG,"$coveragedir\\coverage.ini") || die "Can't open $coveragedir\\coverage.ini";

while (<CFG>)
{
	chomp;
	tr/a-z/A-Z/;	
	s/^\s+//;
	s/\s+$//;
	if (/^#AREAS/) {$bin = \@areas_list; next}
	if (/\w+/) {push(@$bin,$_)}
}

if ($outfile = shift @ARGV) { if ($outfile !~ /^\-/) {open (OUTFILE, ">$outfile")}else{$outfile=""}}

if ($filedir eq "" || $scandir eq "" || $coveragedir eq "" || $reportdir eq "")
{
	print STDERR "\nUsage: scan.pl SCAN_DIR FILE_DIR COVERAGE_DIR REPORT_DIR [LOGFILE]\n";
	print STDERR "\nSCAN_DIR is the path to the directory containing the session sheets.\n";
	print STDERR "FILE_DIR is the path to the directory containing the data files.\n";
	print STDERR "COVERAGE_DIR is the path to the directory containing coverage.ini.\n";
	print STDERR "REPORT_DIR is the path to the directory where the reports will be placed.\n";
	print STDERR "LOGFILE is a file that will capture the output that otherwise goes to the console.\n";
	exit;
}

# Get the file lists
@sheets = <$scandir\\*.*>;
@datafiles = <$filedir\\*.*>;

open (CHARTERS,">$reportdir\\charters.txt");
print CHARTERS "\"Session\"\t\"Field\"\t\"Value\"\n";

open (TESTERS,">$reportdir\\testers.txt");
print TESTERS "\"Session\"\t\"Tester\"\n";

open (BREAKDOWNS,">$reportdir\\breakdowns.txt");
print BREAKDOWNS "\"Session\"\t".
		 "\"Start\"\t".
		 "\"Time\"\t".
		 "\"Duration\"\t".
		 "\"On Charter\"\t".
		 "\"On Opportunity\"\t".
		 "\"Test\"\t".
		 "\"Bug\"\t".
		 "\"Setup\"\t".
		 "\"N Total\"\t".
		 "\"N On Charter\"\t".
		 "\"N Opportunity\"\t".
		 "\"N Test\"\t".
		 "\"N Bug\"\t".
		 "\"N Setup\"\t".
		 "\"Bugs\"\t".
		 "\"Issues\"\t".
		 "\"Testers\"\n";

open (DATA,">$reportdir\\data.txt");
print DATA "\"Session\"\t\"Files\"\n";

open (TESTNOTES,">$reportdir\\testnotes.txt");
print TESTNOTES "\"Session\"\t\"Notes\"\n";

open (BUGS,">$reportdir\\bugs.txt");
print BUGS "\"Session\"\t\"Bugs\"\t\"ID\"\n";

open (ISSUES,">$reportdir\\issues.txt");
print ISSUES "\"Session\"\t\"Issues\"\t\"ID\"\n";

for ($i=0;$i<scalar(@sheets);$i++)
{
	$sheets[$i] =~ tr/A-Z/a-z/;	
	if (basename($sheets[$i]) =~ /et\-todo\-\d\-.+/) 
	{
		push (@todo,$sheets[$i]);
		splice(@sheets,$i,1);
		redo if ($i != scalar(@sheets));
	}
}

foreach $file (@sheets)
{
	next if basename($file) !~ /\./;
	if (basename($file) !~ /^et\-\w\w\w\-\d\d\d\d\d\d\-\w\.ses/) {error("Unexpected session file name. If it's a session sheet, its name must be: \"ET\-\<tester initials\>\-\<yymmdd\>\-\<A, B, C, etc.\>.SES. If it's a TODO sheet, its name must be: \"ET\-TODO\-<priority number\>\-\<title\>.SES")}
	parsefile($file);
	$testers = parsetester(@tester);
	parsecharter(@charter);
	$startmode = "sessions"; parsestart(@start);
	parsebreakdown(@breakdown);
	parsedata(@data);
	parsetestnotes(@testnotes);
	parsebugs(@bugs);
	parseissues(@issues);
	print BREAKDOWNS "\"".basename($file).
			 "\"\t\"".$start_line.
			 "\"\t\"".$breakdown_line.
			 "\"\t\"".$no_of_bugs.
			 "\"\t\"".$no_of_issues.
			 "\"\t\"".$testers."\"\n";
}

close CHARTERS;
close STARTS;
close TESTERS;
close BREAKDOWNS;
close DATA;
close TESTNOTES;
close BUGS;
close ISSUES;

open (CHARTERS,">$reportdir\\charters-todo.txt");
print CHARTERS "\"Session\"\t\"Field\"\t\"Value\"\n";

foreach $file (@todo)
{
	parsefile($file);
	parsecharter(@charter);
	$startmode = "todo"; parsestart(@start);
}
close CHARTERS;

open (CHARTERS,"$reportdir\\charters-todo.txt");
$line = <CHARTERS>; #ignore banner line
@todo_raw = <CHARTERS>;
@todo = ();
while ($line = shift @todo_raw)
{
	while(@todo_raw[0] && ($line !~ /\"\n$/)) {$line = $line." ".@todo_raw[0]; shift @todo_raw}
	push @todo, $line;
}
close CHARTERS;

if (scalar(@todo) > 0)
{
	open (CHARTERS,">$reportdir\\charters-todo.txt");
	print CHARTERS "\"Title\"\t\"Area\"\t\"Priority\"\t\"Description\"\n";
	
	foreach(@todo)
	{
		($session,$a_type,$area) = (split /\"/)[1,3,5];
		$area =~ s/^\s+//;
		$area =~ s/\s+$//;
		push(@{$todoarea{"$session\{\{\{$a_type"}},$area) if ($a_type);
	}
	$session = ""; 
	$priority = "";
	$title = "";
	$area = "";
	$description = "";
						
	foreach(sort keys %todoarea)
	{
		($newsession, $a_type) = split /\{\{\{/;
		if (lc($newsession) ne $session && $title)
		{
			$area = substr($area,1,length($area)-1);

			print CHARTERS "\"".$title.
					"\"\t\"".$area.
					"\"\t\"".$priority.
					"\"\t\"".$description."\"\n";				
			$session = lc($newsession);
			$session =~ /et\-todo\-(\d)\-(.+)\.ses/;
			$priority = $1;
			$title = $2;
			$area = "";
			$description = "";
		}
		elsif (!$title)
		{
			$session = lc($newsession);
			$session =~ /et\-todo\-(\d)\-(.+)\.ses/;
			$priority = $1;
			$title = $2;
		}
		while (defined($aline = pop @{$todoarea{$_}}))
		{
			if ($a_type eq "AREA") {$area = $area.";".$aline}
			if ($a_type eq "DESCRIPTION") {$description = $aline}
		}
	}
	$area = substr($area,1,length($area)-1);
	
	print CHARTERS "\"".$title.
			"\"\t\"".$area.
			"\"\t\"".$priority.
			"\"\t\"".$description."\"\n";				
	
	close CHARTERS;
}
	
open(CHARTERS,"$reportdir\\charters.txt");
open(TESTERS,"$reportdir\\testers.txt");
$line = <CHARTERS>; #ignore banner line
$line = <TESTERS>; #ignore banner line
@charters = <CHARTERS>;
@testers = <TESTERS>;
close TESTERS;
close CHARTERS;

foreach(@testers)
{
	($session,$t_name) = (split /\"/)[1,3];
	$t_name =~ s/^\s+//;
	$t_name =~ s/\s+$//;
	push(@{$tester{$t_name}},$session) if ($t_name);
}

foreach(@charters)
{
	($session,$a_type,$area) = (split /\"/)[1,3,5];
	$area =~ s/^\s+//;
	$area =~ s/\s+$//;
	push(@{$testarea{"$area"}},$session) if ($a_type && lc($a_type) ne "description");
}
foreach (@areas_list){if (!exists($testarea{"$_"})){$testarea{"$_"}=""}}

open(BREAKDOWNS,"$reportdir\\breakdowns.txt");
open(DAYBREAKS,">$reportdir\\breakdowns-day.txt");

# Ignore the first line.
$line = <BREAKDOWNS>;
while(<BREAKDOWNS>)
{
	next if (!/\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\t\"(.+?)\"\n/);	

	$session = $1;
	$start = $2;
	$time =	$3;
	$duration = $4;
	$oncharter = $5;
	$onopportunity = $6;
	$test = $7;
	$bug = $8;
	$prep = $9;
	$n_total = $10;
	$n_charter = $11;
	$n_opportunity = $12;
	$n_test = $13;
	$n_bug = $14;
	$n_prep = $15;
	$bugs = $16;
	$issues	= $17;
	$testers = $18;

	push(@{$sessions{$session}}, $start);
	push(@{$sessions{$session}}, $time);
	push(@{$sessions{$session}}, $duration);
	push(@{$sessions{$session}}, $oncharter);
	push(@{$sessions{$session}}, $onopportunity);
	push(@{$sessions{$session}}, $test);
	push(@{$sessions{$session}}, $bug);
	push(@{$sessions{$session}}, $prep);
	push(@{$sessions{$session}}, $n_total);
	push(@{$sessions{$session}}, $n_charter);
	push(@{$sessions{$session}}, $n_opportunity);
	push(@{$sessions{$session}}, $n_test);
	push(@{$sessions{$session}}, $n_bug);
	push(@{$sessions{$session}}, $n_prep);
	push(@{$sessions{$session}}, $bugs);
	push(@{$sessions{$session}}, $issues);
	push(@{$sessions{$session}}, $testers);
	
	$n_total{$start}         += $n_total;
	$n_charter{$start}       += $n_charter;
	$n_opportunity{$start}   += $n_opportunity;
	$n_test{$start}          += $n_test;
	$n_bug{$start}           += $n_bug;
	$n_prep{$start}          += $n_prep;
	$bugs{$start}            += $bugs;
	$issues{$start}          += $issues;
}
print DAYBREAKS "\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\"\n";

foreach(sort bydate keys %n_total)
{
	print DAYBREAKS "\"".$_."\"\t\""
	                    .$n_total{$_}."\"\t\""
	                    .$n_charter{$_}."\"\t\""
	                    .$n_opportunity{$_}."\"\t\""
			    .$n_test{$_}."\"\t\""
			    .$n_bug{$_}."\"\t\""
			    .$n_prep{$_}."\"\t\""
			    .$bugs{$_}."\"\t\""
			    .$issues{$_}."\"\n";
}

close DAYBREAKS;
close BREAKDOWNS;

open(TDAYBREAKS,">$reportdir\\breakdowns-tester-day.txt");
print TDAYBREAKS "\"Tester\"\t\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\"\n";
open(TESTERTOTALS,">$reportdir\\breakdowns-testers-total.txt");
print TESTERTOTALS "\"Tester\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\"\n";
open(TESTERBREAKS,">$reportdir\\breakdowns-testers-sessions.txt");
print TESTERBREAKS "\"Session\"\t".
		 "\"Start\"\t".
		 "\"Time\"\t".
		 "\"Duration\"\t".
		 "\"On Charter\"\t".
		 "\"On Opportunity\"\t".
		 "\"Test\"\t".
		 "\"Bug\"\t".
		 "\"Setup\"\t".
		 "\"N Total\"\t".
		 "\"N On Charter\"\t".
		 "\"N Opportunity\"\t".
		 "\"N Test\"\t".
		 "\"N Bug\"\t".
		 "\"N Setup\"\t".
		 "\"Bugs\"\t".
		 "\"Issues\"\t".
		 "\"Testers\"\t".
		 "\"Tester\"\n";


foreach $tester (keys %tester)
{
	%n_total = ();
	%n_charter = ();
	%n_oportunity = ();
	%n_prep = ();
	%n_test = ();
	%n_bug = ();
	%n_tester = ();
	%bugs = ();
	%issues = ();
	%dn_total = ();
	%dn_charter = ();
	%dn_oportunity = ();
	%dn_prep = ();
	%dn_test = ();
	%dn_bug = ();
	%dn_tester = ();
	%dbugs = ();
	%dissues = ();
		
	foreach $session (@{$tester{$tester}})
	{
		$start         = @{$sessions{$session}}[0];
		$time          = @{$sessions{$session}}[1];
		$duration      = @{$sessions{$session}}[2];
		$oncharter     = @{$sessions{$session}}[3];
		$onopportunity = @{$sessions{$session}}[4];
		$test          = @{$sessions{$session}}[5];
		$bug           = @{$sessions{$session}}[6];
		$prep          = @{$sessions{$session}}[7];
		$n_total       = @{$sessions{$session}}[8];
		$n_charter     = @{$sessions{$session}}[9];
		$n_opportunity = @{$sessions{$session}}[10];
		$n_test        = @{$sessions{$session}}[11];
		$n_bug         = @{$sessions{$session}}[12];
		$n_prep        = @{$sessions{$session}}[13];
		$bugs          = @{$sessions{$session}}[14];
		$issues	       = @{$sessions{$session}}[15];
		$testers       = @{$sessions{$session}}[16];

		print TESTERBREAKS "\"".$session."\"\t\""
                        .$start."\"\t\""
                        .$time."\"\t\""
                        .$duration."\"\t\""
                        .$oncharter."\"\t\""
                        .$onopportunity."\"\t\""
                        .$test."\"\t\""
                        .$bug."\"\t\""
                        .$prep."\"\t\""
                        .$n_total/$testers."\"\t\""
                        .$n_charter/$testers."\"\t\""
                        .$n_opportunity/$testers."\"\t\""
                        .$n_test/$testers."\"\t\""
                        .$n_bug/$testers."\"\t\""
                        .$n_prep/$testers."\"\t\""
                        .$bugs/$testers."\"\t\""
                        .$issues/$testers."\"\t\""
                        .$testers."\"\t\""
                        .$tester."\"\n";

		$n_total{$tester}         += $n_total/$testers;
		$n_charter{$tester}       += $n_charter/$testers;
		$n_opportunity{$tester}   += $n_opportunity/$testers;
		$n_test{$tester}          += $n_test/$testers;
		$n_bug{$tester}           += $n_bug/$testers;
		$n_prep{$tester}          += $n_prep/$testers;
		$bugs{$tester}            += $bugs/$testers;
		$issues{$tester}          += $issues/$testers;

		$dn_total{$start."\t".$tester}         += $n_total/$testers;
		$dn_charter{$start."\t".$tester}       += $n_charter/$testers;
		$dn_opportunity{$start."\t".$tester}   += $n_opportunity/$testers;
		$dn_test{$start."\t".$tester}          += $n_test/$testers;
		$dn_bug{$start."\t".$tester}           += $n_bug/$testers;
		$dn_prep{$start."\t".$tester}          += $n_prep/$testers;
		$dbugs{$start."\t".$tester}            += $bugs/$testers;
		$dissues{$start."\t".$tester}          += $issues/$testers;


	}
	print TESTERTOTALS  "\"".$tester."\"\t\""
	                    .$n_total{$tester}."\"\t\""
	                    .$n_charter{$tester}."\"\t\""
	                    .$n_opportunity{$tester}."\"\t\""
			    .$n_test{$tester}."\"\t\""
			    .$n_bug{$tester}."\"\t\""
			    .$n_prep{$tester}."\"\t\""
			    .$bugs{$tester}."\"\t\""
			    .$issues{$tester}."\"\n";	
	foreach (sort keys dn_total)
	{
		$start = (split /\t/)[0];
		print TDAYBREAKS  "\"".$tester."\"\t\""
	                    .$start."\"\t\""
	                    .$dn_total{$_}."\"\t\""
	                    .$dn_charter{$_}."\"\t\""
	                    .$dn_opportunity{$_}."\"\t\""
			    .$dn_test{$_}."\"\t\""
			    .$dn_bug{$_}."\"\t\""
			    .$dn_prep{$_}."\"\t\""
			    .$dbugs{$_}."\"\t\""
			    .$dissues{$_}."\"\n";	
	}
}
close TESTERTOTALS;
close TESTERBREAKDOWNS;
close TDAYBREAKS;

open (COVERAGEBREAKS,">$reportdir\\breakdowns-coverage-sessions.txt");
print COVERAGEBREAKS "\"Session\"\t".
		 "\"Start\"\t".
		 "\"Time\"\t".
		 "\"Duration\"\t".
		 "\"On Charter\"\t".
		 "\"On Opportunity\"\t".
		 "\"Test\"\t".
		 "\"Bug\"\t".
		 "\"Setup\"\t".
		 "\"N Total\"\t".
		 "\"N On Charter\"\t".
		 "\"N Opportunity\"\t".
		 "\"N Test\"\t".
		 "\"N Bug\"\t".
		 "\"N Setup\"\t".
		 "\"Bugs\"\t".
		 "\"Issues\"\t".
		 "\"Testers\"\t".
		 "\"Area\"\n";
open (COVERAGETOTALS,">$reportdir\\breakdowns-coverage-total.txt");
print COVERAGETOTALS "\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\"\t\"Area\"\n";

foreach $area (sort keys %testarea)
{
	%n_total = ();
	%n_charter = ();
	%n_oportunity = ();
	%n_prep = ();
	%n_test = ();
	%n_bug = ();
	%n_tester = ();
	%bugs = ();
	%issues = ();
	
	if (!@{$testarea{$area}}) {push @{$testarea{$area}}, " "}
	foreach $session (@{$testarea{$area}})
	{
		$start         = @{$sessions{$session}}[0];
		$time          = @{$sessions{$session}}[1];
		$duration      = @{$sessions{$session}}[2];
		$oncharter     = @{$sessions{$session}}[3];
		$onopportunity = @{$sessions{$session}}[4];
		$test          = @{$sessions{$session}}[5];
		$bug           = @{$sessions{$session}}[6];
		$prep          = @{$sessions{$session}}[7];
		$n_total       = @{$sessions{$session}}[8];
		$n_charter     = @{$sessions{$session}}[9];
		$n_opportunity = @{$sessions{$session}}[10];
		$n_test        = @{$sessions{$session}}[11];
		$n_bug         = @{$sessions{$session}}[12];
		$n_prep        = @{$sessions{$session}}[13];
		$bugs          = @{$sessions{$session}}[14];
		$issues	       = @{$sessions{$session}}[15];
		$testers       = @{$sessions{$session}}[16];

		print COVERAGEBREAKS "\"".$session."\"\t\""
                        .$start."\"\t\""
                        .$time."\"\t\""
                        .$duration."\"\t\""
                        .$oncharter."\"\t\""
                        .$onopportunity."\"\t\""
                        .$test."\"\t\""
                        .$bug."\"\t\""
                        .$prep."\"\t\""
                        .$n_total."\"\t\""
                        .$n_charter."\"\t\""
                        .$n_opportunity."\"\t\""
                        .$n_test."\"\t\""
                        .$n_bug."\"\t\""
                        .$n_prep."\"\t\""
                        .$bugs."\"\t\""
                        .$issues."\"\t\""
                        .$testers."\"\t\""
                        .$area."\"\n";

		$n_total{$area}         += $n_total;
		$n_charter{$area}       += $n_charter;
		$n_opportunity{$area}   += $n_opportunity;
		$n_test{$area}          += $n_test;
		$n_bug{$area}           += $n_bug;
		$n_prep{$area}          += $n_prep;
		$bugs{$area}            += $bugs;
		$issues{$area}          += $issues;
	}
	print COVERAGETOTALS  "\"".$n_total{$area}."\"\t\""
	                    .$n_charter{$area}."\"\t\""
	                    .$n_opportunity{$area}."\"\t\""
			    .$n_test{$area}."\"\t\""
			    .$n_bug{$area}."\"\t\""
			    .$n_prep{$area}."\"\t\""
			    .$bugs{$area}."\"\t\""
			    .$issues{$area}."\"\t\""
			    .$area."\"\n";	
}

close COVERAGEBREAKS;
close COVERAGETOTALS;

#Sort Breakdowns file
open(BREAKDOWNS,"$reportdir\\breakdowns.txt");
@breakdowns = <BREAKDOWNS>;
close BREAKDOWNS;

open(BREAKDOWNS,">$reportdir\\breakdowns.txt");

$header = shift @breakdowns;
@sorted = sort bylinedate @breakdowns;
print BREAKDOWNS $header;
print BREAKDOWNS @sorted;
close BREAKDOWNS;

if (!$outfile) {print STDOUT "Your papers are in order!\n"}
else {print OUTFILE "Your papers are in order!\n"}
#-------------------------------------------------------
sub bydate
{
	my $a_month=0;
	my $b_month=0;
	my $a_day=0;
	my $b_day=0;
	my $a_year=0;
	my $b_year=0;
	my $ta=0;
	my $ta=0;
	
	($a_month,$a_day,$a_year) = split /\//, $a;
	($b_month,$b_day,$b_year) = split /\//, $b;

	$ta = $a_year*400+$a_month*32+$a_day;	
	$tb = $b_year*400+$b_month*32+$b_day;	
	
	$tb<=>$ta;
}

sub bylinedate
{
	my $a_month=0;
	my $b_month=0;
	my $a_day=0;
	my $b_day=0;
	my $a_year=0;
	my $b_year=0;
	my $ta=0;
	my $ta=0;
	my $adate="";
	my $bdate="";

	$adate = (split /\"/, $a)[3];
	$bdate = (split /\"/, $b)[3];
	($a_month,$a_day,$a_year) = split /\//, $adate;
	($b_month,$b_day,$b_year) = split /\//, $bdate;

	$ta = $a_year*400+$a_month*32+$a_day;	
	$tb = $b_year*400+$b_month*32+$b_day;	
	
	$tb<=>$ta;	
}

sub parsecharter
{
	my @section = @_;
	
	my $area = 0;
	my $text_val = "";
	my $area_val = "";
	my $in_area = "";
	my $in_charter = "";
	my $line = "";
	my $occurs = 0;
	my @charter = ();
	my $charter = 0;
		
	while (@section)
	{
		$line = shift @section;
		chomp $line;

		if ($line =~ /^#/ && !($in_charter || $charter)) {error("Missing charter description in Charter section")}
		
		if ($line =~ /^#AREAS/)
		{
			if ($in_area) { error("More than one #AREAS keyword found in Charter section")}
			$in_area++;
			next;
		}	
		elsif (!$charter)
		{
			$in_charter++;
			push(@charter, $line."\n");
			if ($section[0] =~ /^#/) 
			{
				$charter++;
				$temp = pop @charter; chomp $temp; push(@charter, $temp);
				print CHARTERS "\"".basename($file)."\"\t\"DESCRIPTION\"\t\"";
				print CHARTERS @charter;
				print CHARTERS "\"\n";
			}
		}
		elsif (($line ne "")) 
		{ 
			if (!$in_area) {error("Unexpected text \'$line\' found in Charter section. Except for the charter description text \(which must precede all other '#' commands\), all text in the Charter section must be preceded by a '#' command.")}
			chomp;
			$line =~ tr/a-z/A-Z/;
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			$occurs = 0; foreach (@areas_list) {$occurs++ if ($_ eq $line)}
			if ($occurs)
			{
				print CHARTERS "\"".basename($file)."\"\t\"AREA\"\t\"$line\"\n";
			}
			else
			{
				error("Unexpected #AREAS label \'$line\' in Charter section. Ensure that the the area label is one of the legal values in COVERAGE.INI.");
			}
			$area++;
			next;
		}
	}
	if (!$charter && !$in_charter) {error("No charter description was given in Charter section")}
	if (!$area) {error("Missing area values in Charter section. Ensure that you have specified #AREAS and listed legal area values underneath.")}
}

sub parsestart
{
	my @section = @_;
	my $time_happened = 0;
	my $year = "";
	my $l_year = "";
	my $month = "";
	my $l_month = "";
	my $year = "";
	my $l_year = "";

	basename($file) =~ /et\-\w\w\w\-(\d\d)(\d\d)(\d\d)\-\w\.ses/;
	$year= $1;
	$month = $2;
	$day= $3;
	
	foreach (@section)
	{
		if (/^\s*(\d+)\/(\d+)\/(\d+) (\d+):(\d+)(am|pm)\s*\n/)
		{	
			if ($time_happened)
			{
				error("Multiple time stamps detected in Start section");
			}
			else
			{
				$time_happened++;
				chomp;
				$l_month = $1;
				$l_day = $2;
				$l_year = $3;
				
				$start_line = "$1\/$2\/$3\"\t\"$4:$5 $6";
				$start_line =~ s/^0//;
				$start_line =~ s/(^\d+\/)0/\1/;				
			}
		}
		elsif ($_ ne "\n" && $_ ne "")
		{
			error("Unexpected text found in Start section. Ensure that the time stamp is in this format: mm\/dd\/yy hh:mm\{am\|pm\}");
		}
	}
	if (!$time_happened && $startmode eq "sessions") {error("Missing time stamp in Start section")}	
	if ($time_happened && $startmode eq "todo")     {error("Start section must be empty if the sheet is named as a TODO. Did you forget to rename the session sheet?")}	
	if ((($l_month != $month) || ($l_day != $day) || ($l_year != $year)) && $startmode eq "sessions") {error("File name does not match date in Start section")}
}

sub parsetester
{
	my @section = @_;
	my $tester_happened = 0;

	foreach (@section)
	{
		chomp;
		if (/\w+/)
		{
			print TESTERS "\"".basename($file)."\"\t\"$_\"\n";
			push @testername;
			$tester_happened++;
		}
	}	
	if (!$tester_happened)
	{
		error("Missing tester name in Tester section");
	}
	return $tester_happened;
}

sub parsebreakdown
{
	my @section = @_;
	my $d = 0;
	my $p = 0;
	my $tde = 0;
	my $bir = 0;
	my $cvo = 0;
	my $d_happened = 0;
	my $p_happened = 0;
	my $tde_happened = 0;
	my $bir_happened = 0;
	my $cvo_happened = 0;
	my $dur_val = 0;
	my $dur_line = "";
	my $dur_times = 0;
	my $prep_val = 0;
	my $test_val = 0;
	my $bug_val = 0;
	my $opp_val = 0;
	my $c_val = 0;
	my $o_val = 0;
	my $in_tester = 0;
	my $line = "";
	my $newtestername = "";
	my $secondvalue = "";
		
	while (@section)
	{
		$line = shift @section;
		chomp $line;
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		# The following keyword is for a feature that isn't quite implemented, yet.
		# It would allow there to be different breakdowns for each tester.
		if ($line =~ /^#TESTER/)
		{
			$newtestername = substr($line,length("#TESTER"),length($line)-"#TESTER");
			$newtestername =~ s/^\s+//;
			$newtestername =~ s/\s+$//;			
			if ($in_tester)
			{
				if (!$p) {error("Missing #SESSION SETUP field in Task Breakdown section")}
				if (!$tde) {error("Missing #TEST DESIGN AND EXECUTION field in Task Breakdown section")}
				if (!$bir) {error("Missing #BUG INVESTIGATION AND REPORTING field in Task Breakdown section")}
				if (!$cvo) {error("Missing #CHARTER VS. OPPORTUNITY field in Task Breakdown section")}
				
			}
			$testername = $newtestername;
			
			$dur_line = lc(shift @section); chomp $dur_line;
			($dur_val,$dur_times) = split /\*/, $dur_line;
			$dur_val =~ s/^\s+//;
			$dur_val =~ s/\s+$//;
			$dur_times =~ s/^\s+//;
			$dur_times =~ s/\s+$//;
		}

		if ($line =~ /^#DURATION/)
		{
			if (!$d)
			{
				$d++;
				$dur_line = lc(shift @section); chomp $dur_line;
				($dur_val,$dur_times) = split /\*/, $dur_line;
				$dur_val =~ s/^\s+//;
				$dur_val =~ s/\s+$//;
				$dur_times =~ s/^\s+//;
				$dur_times =~ s/\s+$//;
				if ($dur_times =~ /\D+/) {error("Unexpected #DURATION multiplier \'$dur_times\' in Task Breakdown section.")}
				if ($dur_times eq "") {$dur_times = 1}
				
				if ($dur_val eq "short" || $dur_val eq "normal" || $dur_val eq "long")
				{
					while(scalar(@section)> 0 && $section[0] !~ /^#/)
					{
						$secondvalue = shift @section;
						if (!$d_happened) {$d_happened++}
						elsif ($secondvalue =~ /\S+/) {error("More than one value encountered under #DURATION in the Task Breakdown section")}
					}
				}
				else
				{
					error("Unexpected #DURATION value in Task Breakdown section. Legal values are: short, normal, or long");
				}
			}
			else
			{ 
				error("More than one #DURATION field found in Task Breakdown section");
			}
			next;
		}
		if ($line =~ /^#SESSION SETUP/)
		{
			if (!$p)
			{
				$p++;
				$prep_val = shift @section; chomp $prep_val;
				if ($prep_val >= 0 && $prep_val < 101 && $prep_val =~ /\d+/)
				{
					while(scalar(@section)> 0 && $section[0] !~ /^#/)
					{
						$secondvalue = shift @section;
						if ($secondvalue =~ /\S+/) {error("More than one value encountered under #SESSION SETUP in the Task Breakdown section")}
					}
				}
				else
				{
					error("Unexpected #SESSION SETUP value in Task Breakdown section. Ensure that the value is an integer from 0-100.");
				}
			}
			else
			{ 
				error("More than one #SESSION SETUP field found in Task Breakdown section");
			}
			next;
		}
		if ($line =~ /^#TEST DESIGN AND EXECUTION/)
		{
			if (!$tde)
			{
				$tde++;
				$test_val = shift @section; chomp $test_val;
				if ($test_val >= 0 && $test_val < 101 && $test_val =~ /\d+/)
				{
					while(scalar(@section)> 0 && $section[0] !~ /^#/)
					{
						$secondvalue = shift @section;
						if ($secondvalue =~ /\S+/) {error("More than one value encountered under #TEST DESIGN AND EXECUTION in the Task Breakdown section")}
					}
				}
				else
				{
					error("Unexpected #TEST DESIGN AND EXECUTION value in Task Breakdown section. Ensure that the value is an integer from 0-100.");
				}
			}
			else
			{ 
				error("More than one #TEST DESIGN AND EXECUTION field found in Task Breakdown section");
			}
			next;
		}
		if ($line =~ /^#BUG INVESTIGATION AND REPORTING/)
		{
			if (!$bir)
			{
				$bir++;
				$bug_val = shift @section; chomp $bug_val;
				if ($bug_val >= 0 && $bug_val < 101 && $bug_val =~ /\d+/)
				{
					while(scalar(@section)> 0 && $section[0] !~ /^#/)
					{
						$secondvalue = shift @section;
						if ($secondvalue =~ /\S+/) {error("More than one value encountered under #BUG INVESTIGATION AND REPORTING in the Task Breakdown section")}
					}
				}
				else
				{
					error("Unexpected #BUG INVESTIGATION AND REPORTING value in Task Breakdown section. Ensure that the value is an integer from 0-100.");
				}
			}
			else
			{ 
				error("More than one #BUG INVESTIGATION AND REPORTING field found in Task Breakdown section");
			}
			next;
		}
		if ($line =~ /^#CHARTER VS. OPPORTUNITY/)
		{
			if (!$cvo)
			{
				$cvo++;
				$opp_val = shift @section; chomp $opp_val;
				($c_val,$o_val) = split /\//, $opp_val;
				if (($c_val+$o_val) == 100)
				{
					while(scalar(@section)> 0 && $section[0] !~ /^#/)
					{
						$secondvalue = shift @section;
						if ($secondvalue =~ /\S+/) {error("More than one value encountered under #CHARTER VS. OPPORTUNITY in the Task Breakdown section")}
					}
				}
				else
				{
					error("#CHARTER VS. OPPORTUNITY value does not add up to 100 in Task Breakdown section");
				}
			}
			else
			{ 
				error("More than one #CHARTER VS. OPPORTUNITY field found in Task Breakdown section");
			}
			next;
		}
	}
	if (!$d) {error("Missing #DURATION field in Task Breakdown section")}
	if (!$p) {error("Missing #SESSION SETUP field in Task Breakdown section")}
	if (!$tde) {error("Missing #TEST DESIGN AND EXECUTION field in Task Breakdown section")}
	if (!$bir) {error("Missing #BUG INVESTIGATION AND REPORTING field in Task Breakdown section")}
	if (!$cvo) {error("Missing #CHARTER VS. OPPORTUNITY field in Task Breakdown section")}

	if (($prep_val+$test_val+$bug_val) != 100 && ($prep_val+$test_val+$bug_val) != 99)
	{
		error("Unexpected sum of Task breakdown values. Values of #SESSION SETUP, #TEST DESIGN AND EXECUTION, and #BUG INVESTIGATION AND REPORTING must add up to 100 or 99");
	}
	if ($dur_val eq "long") {$dur_val = 1.33333*$dur_times}
	elsif ($dur_val eq "normal") {$dur_val = $dur_times}
	else {$dur_val = .66667*$dur_times}
	
	$breakdown_line =  $dur_val."\"\t".
			   "\"".$c_val."\"\t".
	                   "\"".$o_val."\"\t".
			   "\"".$test_val."\"\t".
			   "\"".$bug_val."\"\t".
			   "\"".$prep_val."\"\t".
			   "\"".($dur_val * $testers)."\"\t".
			   "\"".($dur_val * $testers * $c_val / 100)."\"\t".
			   "\"".($dur_val * $testers * $o_val / 100)."\"\t".
			   "\"".($dur_val * $testers * $test_val / 100 * $c_val / 100)."\"\t".
			   "\"".($dur_val * $testers * $bug_val / 100 * $c_val / 100)."\"\t".
			   "\"".($dur_val * $testers * $prep_val / 100 * $c_val / 100);
}

sub parsedata
{
	my @section = @_;	
	my $content = 0;
	my $na = 0;
	
	foreach (@section)
	{
		chomp;
		if (/^#N\/A\s*/) {$na++}
		elsif (/\w+/) {$content++}
	}
	if ($na && !$content)
	{
		$content++;
		@section = ();
	}
	elsif ($na && $content)
	{
		error("Unexpected text found with #N\/A tag in Data Files section. If you specify #N\/A, no other text is permitted in this section.");
	}
	if (!$content) {error("Data Files section is empty. If you used no data files in this test session, specify #N\/A.")}
	$content = 0;
	
	foreach (@section) 
	{
		chomp;
		if ($_ ne "" && !-s $filedir."\\".$_) 
		{
			error("Missing data file $_ in the data file directory. Ensure the file exists in the directory specified as the second argument on the SCAN.PL command line. (e.g. SCAN.PL SHEETS SHEETS\\DATAFILE)") if (!$nodatafiles);
		}
		if (/\w+/)
		{
			print DATA "\"".basename($file)."\"\t\"$_\"\n";
			$content++;
		}
	}
	if (!$content)
	{
			print DATA "\"".basename($file)."\"\t\"<empty>\"\n";		
	}
}

sub parsetestnotes
{
	my @section = @_;
	my $na = 0;
	my $content = 0;
	
	foreach (@section)
	{
		if (/^#N\/A\s*\n/) {$na++}
		elsif (/\w+/) {$content++}
	}
	if ($na && !$content)
	{
		$content++;
		@section = ();
	}
	elsif ($na && $content)
	{
		error("Unexpected text found with #N\/A tag in Test Notes section. If you specify #N\/A, no other text is permitted in this section.");
	}
	if (!$content) {error("Test Notes section is empty. If you have no notes, specify #N\/A.")}
	$content = 0;

	foreach(@section)
	{	
		if (/\w+/) {$content++}
	}
	if ($content)
	{
		$temp = pop @section; chomp $temp; push(@section, $temp);
		print TESTNOTES "\"".basename($file)."\"\t\"";
		print TESTNOTES @section;
		print TESTNOTES "\"\n";
	}
	else
	{	
		print TESTNOTES "\"".basename($file)."\"\t\"<empty>\"\n";		
	}
}

sub parsebugs
{
	my @section = @_;
	my $bug_content = 0;
	my $section_content = 0;
	my $dims = "";
	my @bug = ();
	my $na = 0;
	my $in_bug = 0;
	
	foreach (@section)
	{
		chomp;
		if (/^#N\/A\s*/) {$na++}
		elsif (/\S+/) {$bug_content++}
	}
	if ($na && !$bug_content)
	{
		$bug_content++;
		@section = ();
	}
	elsif ($na && $bug_content)
	{
		error("Unexpected text found with #N\/A tag in Bugs section. If you specify #N\/A, no other text is permitted in this section.");
	}
	if (!$bug_content) {error("Bugs section is empty. If you have no bugs to report in this session, specify #N\/A.")}
	$bug_content = 0;	

	foreach(@section)
	{
		if (/^BUG / || /^# BUG/)
		{
			error("Possible typo in Bugs section. Don't put \"BUG\" at the start of a line and don't put \"# BUG\" (space between # and BUG).");
		}
		if (/^#BUG/)
		{
			if ($in_bug)
			{
				if (!$bug_content) {error("Empty bug field in Bugs section. Ensure that you provided bug description text after each #BUG.")}
				$temp = pop @bug; chomp $temp; push(@bug, $temp);
				print BUGS "\"".basename($file)."\"\t\"";
				print BUGS @bug;
				print BUGS "\"\t\"$dims\"\n";
				$bug_content = 0;
				$section_content++;
			}
			if (/^#BUG\s+(.+)/) {$dims = $1} else {$dims = ""}
			@bug = ();
			$in_bug = 1;
		}
		elsif ($in_bug)
		{
			push(@bug,$_."\n");
			if (/\S+/) {$bug_content++}
		}
		elsif (/\S+/)
		{
			error("Unexpected text in Bugs section. Ensure that you provided bug description text after each #BUG.");
		}
	}
	if ($in_bug)
	{
		if (!$bug_content) {error("Empty bug field in Bugs section. Ensure that you specify #BUG before each report in this section.")}
		$temp = pop @bug; chomp $temp; push(@bug, $temp);
		print BUGS "\"".basename($file)."\"\t\"";
		print BUGS @bug;
		print BUGS "\"\t\"$dims\"\n";
		$section_content++;
	}
	if (!$section_content)
	{
		print BUGS "\"".basename($file)."\"\t\"<empty>\"\n";
	}
	$no_of_bugs = $section_content;
}

sub parseissues
{
	my @section = @_;
	my $issue_content = 0;
	my $section_content = 0;
	my @issue = ();
	my $in_issue = 0;
	my $na = 0;
	my $dims = "";
		
	foreach (@section)
	{
		chomp;
		if (/^#N\/A\s*/) {$na++}
		elsif (/\w+/) {$issue_content++}
	}
	if ($na && !$issue_content)
	{
		$issue_content++;
		@section = ();
	}
	elsif ($na && $issue_content)
	{
		error("Unexpected text found with #N\/A tag in the Issues section. If you specify #N\/A, no other text is permitted in this section.");
	}
	if (!$issue_content) {error("Issues section is empty. If you have no issues to report in this session, specify #N\/A.")}
	$issue_content = 0;

	foreach(@section)
	{
		if (/^ISSUE / || /^# ISSUE/)
		{
			error("Possible typo in Issues section. Don't put \"ISSUE\" at the start of a line and don't put \"# ISSUE\" (space between # and ISSUE).");
		}
		if (/^#ISSUE/)
		{
			if ($in_issue)
			{
				if (!$issue_content) {error("Empty issue field in Issues section. Ensure you included an issue description after each #ISSUE.")}
				$temp = pop @issue; chomp $temp; push(@issue, $temp);
				print ISSUES "\"".basename($file)."\"\t\"";
				print ISSUES @issue;
				print ISSUES "\"\t\"$dims\"\n";
				$issue_content = 0;
				$section_content++;
			}
			if (/^#ISSUE\s+(.+)/) {$dims = $1} else {$dims = ""}
			@issue = ();
			$in_issue = 1;
		}
		elsif ($in_issue)
		{
			push(@issue,$_."\n");
			if (/\w+/) {$issue_content++}
		}
		elsif (/\w+/)
		{
			error("Unexpected text in Issues section. Ensure you specify #ISSUE before each issue in this section.");
		}
	}
	if ($in_issue)
	{
			if (!$issue_content) {error("Empty issue field in Issues section. Ensure you included an issue description after each #ISSUE.")}
			$temp = pop @issue; chomp $temp; push(@issue, $temp);
			print ISSUES "\"".basename($file)."\"\t\"";
			print ISSUES @issue;
			print ISSUES "\"\t\"$dims\"\n";
			$section_content++;
	}
	if (!$section_content)
	{
		print ISSUES "\"".basename($file)."\"\t\"<empty>\"\n";
	}
	$no_of_issues = $section_content;
}

sub parsefile
{
	my $file = @_[0];
	
	$charter=0; @charter = ();
	$start=0; @start = ();
	$tester=0; @tester = ();
	$breakdown=0; @breakdown = ();
	$data=0; @data = ();
	$testnotes=0; @testnotes = ();
	$bugs=0; @bugs = ();
	$issues=0; @issues = ();

	open(SESSION,$file) || die "Can't open $file\n";
	while ($line = <SESSION>)
	{
		if ($line =~ /^\U\w*/)
		{
			if ($line =~ /^CHARTER/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($charter == 1) {error("More than one Charter section")}
				$charter++;
				$bin = \@charter;
				next;
			}
			elsif ($line =~ /^START/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($start== 1) {error("More than one Start section")}
				$start++;
				$bin = \@start;
				next;
			}
			elsif ($line =~ /^TESTER/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($tester == 1) {error("More than one Tester section")}
				$tester++;
				$bin = \@tester;
				next;
			}
			elsif ($line =~ /^TASK BREAKDOWN/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($breakdown == 1) {error("More than one Task Breakdown section")}
				$breakdown++;
				$bin = \@breakdown;
				next;
			}
			elsif ($line =~ /^DATA FILES/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($data == 1) {error("More than one Data Files section")}
				$data++;
				$bin = \@data;
				next;
			}
			elsif ($line =~ /^TEST NOTES/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($testnotes == 1) {error("More than one Test Notes section")}
				$testnotes++;
				$bin = \@testnotes;
				next;
			}
			elsif ($line =~ /^BUGS/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($bugs == 1) {error("More than one Bugs section")}
				$bugs++;
				$bin = \@bugs;
				next;
			}
			elsif ($line =~ /^ISSUES/)
			{
				$line = <SESSION>; next if $line !~ /--------+/;
				if ($issues == 1) {error("More than one Issues section")}
				$issues++;
				$bin = \@issues;
				next;
			}
		}
		$line =~ s/\"/\'/g;
		push (@$bin,$line);
	}
	if (!$charter) {error("Missing a Charter section")}
	if (!$start) {error("Missing a Start section")}
	if (!$tester) {error("Missing a Tester section")}
	if (!$breakdown) {error("Missing a Breakdowns section")}
	if (!$data) {error("Missing a Data Files section")}
	if (!$testnotes) {error("Missing a Test Notes section")}
	if (!$bugs) {error("Missing a Bugs section")}
	if (!$issues) {error("Missing an Issues section")}
}

sub error
{
	if (!$outfile) {die "### Error \"@_[0]\" in file $file\n"}
	else {
		print OUTFILE "### Error \"@_[0]\" in file $file\n";
		close OUTFILE; 
		die "";
	     }	
}
