use DirHandle;

printdirectory(shift @ARGV);

sub printdirectory
{
	my $dir = $_[0];
	my $dh = DirHandle->new($dir) or die "can't opendir $dir: $!";;
	my @dirs = $dh->read();

	foreach (sort @dirs) 
	{
		if ((-d "$dir\\$_") && ($_ ne ".") && ($_ ne "..")) {printdirectory("$dir\\$_")}
		elsif ($_ eq ".") {print "$dir\\\n"}
		elsif ($_ ne "..") 
		{
			if (/(.+)\.(.*)/)
			{
				print "$dir\\\t$1\t$2\n";
			}
			else
			{
				print "$dir\\$_\n";
			}
		}
	}
}

