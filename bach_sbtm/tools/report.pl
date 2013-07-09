$templatedir = shift @ARGV;
$datadir = shift @ARGV;
$reportdir = shift @ARGV;

if ($datadir eq "" || $reportdir eq "" || $templatedir eq "")
{
	print STDERR "\nUsage: report.pl TEMPLATE_DIR DATA_DIR REPORT_DIR\n";
	print STDERR "\nTEMPLATE_DIR is the path to the directory containing the HTML templates.\n";
	print STDERR "\nDATA_DIR is the path to the directory containing coverage.ini.\n";
	print STDERR "REPORT_DIR is the path to the directory where the reports will be placed.\n";
	exit;
}


open(TSTATUS, "$templatedir\\status.tpl") || die "Can't open $templatedir\\status.tpl";
open(STATUS, ">$reportdir\\status.htm") || die "Can't open $reportdir\\status.htm";

($sec,$min,$hour,$mday,$mon,$year) = localtime(time);

(($pm = $mon+1)<10) && ($pm = "0".$pm);
(($pd = $mday)<10) && ($pd = "0".$pd);
(($ph = $hour)<10) && ($ph = "0".$ph);
(($pmn = $min)<10) && ($pmn = "0".$pmn);
(($ps = $sec)<10) && ($ps = "0".$ps);

$thedate = "$pm\/$pd $ph:$pmn:$ps";

open (BREAKS,"$datadir\\breakdowns.txt") || die "Can't open $datadir\\breakdowns.txt";

$labels = <BREAKS>; #throw away first line

while (defined($line = <BREAKS>))
{
	next if ($line !~ /^\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"([^"]*)"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"[^"]*"\t\"([^"]*)"\t/);
	$sessioncount++;
	$totalsessions += $1;
	$totalbugs += $2;
}

while (defined($line = <TSTATUS>))
{
	if ($line =~ /^ Updated:.*/)
	{
		print STATUS " Updated: $thedate\n";
	}
	elsif ($line =~ /^Sessions:.*/)
	{
		$totalsessions = int($totalsessions*100)/100;
		print STATUS "Sessions: $totalsessions ($sessioncount reports)\n";
	}
	elsif ($line =~ /^    Bugs:.*/)
	{
		print STATUS "    Bugs: $totalbugs\n";
	}
	else
	{
		print STATUS $line;
	}
}

close STATUS;
close TSTATUS;
close BREAKS;

open(DATA, "$datadir\\breakdowns-coverage-total.txt") || die "can't open $datadir\\breakdowns-coverage-total.txt";
$line = <DATA>; #throw away the first line
@fields = ();
$count = 0;
while (defined($line = <DATA>))
{
	@rawfields = ();
	push @rawfields, (split /\"/, $line)[1,3,5,7,9,11,13,15,17];
	foreach (@rawfields) {if ($_ > 0){$_ = int($_*100)/100}}
	push @{$fields[$count]}, @rawfields;
	$count++;
}
close DATA;

makecover("c_by_total.htm", 0);
makecover("c_by_chtr.htm",  1);
makecover("c_by_opp.htm",   2);
makecover("c_by_test.htm",  3);
makecover("c_by_bug.htm",   4);
makecover("c_by_setup.htm", 5);
makecover("c_by_bugs.htm",  6);
makecover("c_by_issues.htm",7);
makecover("c_by_area.htm",  8);

open(DATA, "$datadir\\breakdowns.txt") || die "can't open $datadir\\breakdowns.txt";
$line = <DATA>; #throw away the first line
@fields = ();
$count = 0;
while (defined($line = <DATA>))
{
	@rawfields = ();
	push @rawfields, (split /\"/, $line)[1,3,5,19,21,23,25,27,29,31,33,35];
	foreach (@rawfields[3..10]) {if ($_ > 0){$_ = int($_*100)/100}}
	push @{$fields[$count]}, @rawfields;
	$count++;
}
close DATA;

makeses("s_by_ses.htm",       0);
makeses("s_by_datetime.htm",  1);
makeses("s_by_time.htm",      2);
makeses("s_by_dur.htm",       3);
makeses("s_by_chtr.htm",      4);
makeses("s_by_opp.htm",       5);
makeses("s_by_test.htm",      6);
makeses("s_by_bug.htm",       7);
makeses("s_by_setup.htm",     8);
makeses("s_by_bugs.htm",      9);
makeses("s_by_issues.htm",   10);
makeses("s_by_tstrs.htm",    11);

sub getsesline()
{
	if ($row == scalar(@fields)) {return 0}
	$session = "<a href=\"sessions\\".${$fields[$row]}[ 0]."\">".substr(${$fields[$row]}[ 0],0,length(${$fields[$row]}[ 0])-4)."</a>";
	$date =    ${$fields[$row]}[ 1];
	$time =    ${$fields[$row]}[ 2];
	$dur =     ${$fields[$row]}[ 3];
	$chtr =    ${$fields[$row]}[ 4];
	$opp =     ${$fields[$row]}[ 5];
	$test =    ${$fields[$row]}[ 6];
	$bug =     ${$fields[$row]}[ 7];
	$setup =   ${$fields[$row]}[ 8];
	$bugs =    ${$fields[$row]}[ 9];
	$issues =  ${$fields[$row]}[10];
	$tstrs =   ${$fields[$row]}[11];
	$row++; 
	return 1; 
}

sub postsesline()
{
	print SES "<tr>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$session</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$date</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$time</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$dur</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$chtr</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$opp</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$test</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$bug</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$setup</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$bugs</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$issues</font></td>\n";
   	print SES "<td><font face=\"Courier New\" size=\"2\">$tstrs</font></td>\n";
	print SES "</tr>\n";
}

sub getcoverline()
{
	if ($row == scalar(@fields)) {return 0}
	$total =  ${$fields[$row]}[0];
	$chtr =   ${$fields[$row]}[1];
	$opp =    ${$fields[$row]}[2];
	$test =   ${$fields[$row]}[3];
	$bug =    ${$fields[$row]}[4];
	$setup =  ${$fields[$row]}[5];
	$bugs =   ${$fields[$row]}[6];
	$issues = ${$fields[$row]}[7];
	$area =   ${$fields[$row]}[8];
	$row++; 
	return 1; 
}

sub postcoverline()
{
	print COVER "<tr>\n";
   	print COVER "<td width=\"6%\"><font face=\"Courier New\" size=\"2\">$total</font></td>\n";
   	print COVER "<td width=\"6%\"><font face=\"Courier New\" size=\"2\">$chtr</font></td>\n";
   	print COVER "<td width=\"6%\"><font face=\"Courier New\" size=\"2\">$opp</font></td>\n";
   	print COVER "<td width=\"6%\"><font face=\"Courier New\" size=\"2\">$test</font></td>\n";
   	print COVER "<td width=\"7%\"><font face=\"Courier New\" size=\"2\">$bug</font></td>\n";
   	print COVER "<td width=\"7%\"><font face=\"Courier New\" size=\"2\">$setup</font></td>\n";
   	print COVER "<td width=\"7%\"><font face=\"Courier New\" size=\"2\">$bugs</font></td>\n";
   	print COVER "<td width=\"7%\"><font face=\"Courier New\" size=\"2\">$issues</font></td>\n";
   	print COVER "<td width=\"48%\"><font face=\"Courier New\" size=\"2\">$area</font></td>\n";
	print COVER "</tr>\n";
}

sub makecover()
{
	my $title = $_[0];
	my $sortby = $_[1];
	if ($sortby != 8) {@fields = sort {${$b}[$sortby] <=> ${$a}[$sortby]} @fields;}
	else {@fields = sort {${$a}[$sortby] cmp ${$b}[$sortby]} @fields;}
	
	open(COVER, ">$reportdir\\$title") || die "Can't open $reportdir\\$title";
	open(TCOVER, "$templatedir\\coverage.tpl") || die "Can't open $templatedir\\coverage.tpl";

	$row = 0;
	while (defined($line = <TCOVER>))
	{
		if ($line =~ /^table data goes here\n/)
		{
			while (getcoverline()) {postcoverline()}
		}
		elsif ($line =~ /^Report current.*/)
		{
			print COVER "Report current as of: $thedate"
		}
		else
		{
			print COVER $line;
		}
	}

	close TCOVER;
	close COVER;
}

sub bydate()
{

	${$a}[1] =~ /(\d+)\/(\d+)\/(\d+)/;
	$a_date = $3*400+$1*40+$2;
	${$b}[1] =~ /(\d+)\/(\d+)\/(\d+)/;
	$b_date = $3*400+$1*40+$2;
	return $b_date <=> $a_date;
}

sub bytime()
{
        ${$a}[2] =~ /(\d\d):(\d\d) (..)/;
	$a_time = $1*60+$2; if (($3 eq "pm") && ($1 != 12)) {$a_time += 12*60}
        ${$b}[2] =~ /(\d\d):(\d\d) (..)/;
	$b_time = $1*60+$2; if (($3 eq "pm") && ($1 != 12)) {$b_time += 12*60}
	return $b_time <=> $a_time;
}

sub makeses()
{
	my $title = $_[0];
	my $sortby = $_[1];
	if ($sortby > 2) {@fields = sort {${$b}[$sortby] <=> ${$a}[$sortby]} @fields;}
	elsif ($sortby == 0) {@fields = sort {${$a}[$sortby] cmp ${$b}[$sortby]} @fields;}
	elsif ($sortby == 1) {@fields = sort bydate @fields;}
	elsif ($sortby == 2) {@fields = sort bytime @fields;}

        open(TSES, "$templatedir\\sessions.tpl") || die "Can't open $templatedir\\sessions.tpl";
        open(SES, ">$reportdir\\$title") || die "Can't open $reportdir\\$title";

	$row = 0;
        while (defined($line = <TSES>))
        {
        	if ($line =~ /^table data goes here\n/)
        	{
        		while (getsesline()) {postsesline()}
        	}
        	elsif ($line =~ /^Report current.*/)
        	{
        		print SES "Report current as of: $thedate"
        	}
        	else
        	{
        		print SES $line;
        	}
        }

        close TSES;
        close SES;
}