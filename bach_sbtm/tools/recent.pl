$number = shift;
if (!$number) {$number = 1}

open (DAYBREAKS,"/reports/breakdowns-day.txt") || die "Can't find 'breakdowns-day.txt' file.";

$_ = <DAYBREAKS>; #Discard the banner

($sec, $min, $hr, $day, $month, $year) = (localtime)[0..5];

$month++;
$year += 1900;
if ($hr > 12) {$hr = $hr - 12; $pm = "pm";} else {$am = "am"};
if ($min < 10) {$min .= "0";}

print "\nThese are the last $number days of test session progress\nas of $month\/$day\/$year at $hr:$min$pm$am:\n\n";

for ($count=0;$count<$number;$count++)
{
	$_ = <DAYBREAKS>; 
	($date,$total,$oncharter,$opportunity,$test,$bug,$prep,$pertester,$bugs,$issues) = (split /\"/)[1,3,5,7,9,11,13,15,17,19];

	print "       Date: $date\n".	
	      "      Total: $total\n".	
	      " On Charter: $oncharter\n".	
	      "Opportunity: $opportunity\n".	
	      "       Test: $test\n".	
	      "        Bug: $bug\n".	
	      "      Setup: $prep\n".	
	      " Per Tester: $pertester\n".	
	      "       Bugs: $bugs\n".	
	      "     Issues: $issues\n\n";
}