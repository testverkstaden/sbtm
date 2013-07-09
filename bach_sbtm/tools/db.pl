use Win32::ODBC;
$Data = new Win32::ODBC("testmanager");
if (!$Data) {die "can't open database"}
@tables = $Data->TableList;

foreach (@tables)
{
	print "$_\n";
}

foreach (@tables)
{
	print "$_\n";
	$stmt = "SELECT * FROM ".uc($_);
        $rc = $Data->Sql($stmt);
        while (defined($Data->FetchRow()))
        {
        	@values = $Data->Data;
        	foreach (@values)
        	{
        		print "$_\t";
        	}
        	print "\n";
        }
	print "\n";
}
$Data->Close();
