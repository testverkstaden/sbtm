$file = $ARGV[0];
$dir = $ARGV[1];

open(FILE,$file) || die ("Can't open $file\n");

#Throw away the first line
$line = <FILE>;

while (<FILE>)
{
	chomp;
	($title,$area,$priority,$description) = split /\t/;
	open(TODOFILE,">$dir\\et\-todo\-$priority\-$title.ses");
	@area = split /;/, $area;

print TODOFILE <<'EOF';
CHARTER
-----------------------------------------------
EOF

print TODOFILE "$description\n\n";
print TODOFILE "\n#AREAS\n";
foreach (@area) {print TODOFILE "$_\n"}

print TODOFILE <<'EOF';

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


DATA FILES
-----------------------------------------------


TEST NOTES
-----------------------------------------------


BUGS
-----------------------------------------------


ISSUES
-----------------------------------------------
EOF


}