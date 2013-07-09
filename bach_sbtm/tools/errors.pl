open (ERRORS,">errors.txt");

while (<>)
{
	push @errors, "$1\n" if /.+?error\(\"(.+?)\"\)/;
}

print ERRORS sort @errors;

close ERRORS;