use File::Basename;

$scandir = shift @ARGV;
if (!$scandir) {die "#### You must specify a directory to scan.\n"}
print "What do you want to search for? ";
$search = uc(<STDIN>);
chomp $search;

@sheets = <$scandir\\*.ses>;
open (CONCAT, ">sheets.txt");
open (BATCH,">sheets.bat");

foreach $file (sort bydate @sheets)
{ 
	open(SHEET, $file);
	while ( $line = uc(<SHEET>))
	{
		if ($line =~ /$search/o) 
		{
			$hits++;
			print "$file\n";
			print BATCH "notepad $file\n";
			concat($file);
			last;
		}
	}
	close SHEET;
}

print "\n$hits file(s) were found that matched your search.\n";

print "\nType SHEETS to view each file in notepad.\n";
print "Type NOTEPAD SHEETS.TXT to view a concatenation of all the files that were found.\n";


sub concat()
{
	print CONCAT <<EOF;


###########################################################
Session: $file
!##########################################################

EOF
	seek(SHEET, 0, 0);
	while (<SHEET>)
	{
		print CONCAT $_;
	}
}

sub bydate
{
	substr(basename($a),7,8) <=> substr(basename($b),7,8);
}