This is the Installation and How-to notes for the Session-Based Test Management Scan Tool

(c) 2000 Satisfice, Inc. 

If you have questions, call 540-631-0600 and ask for Jon.

-------------------------

1. Install Perl (free on the web at http://www.activestate.com). - !!!!!!!!This is not needed anymore.!!!!!!!!!!!!!

2. Run "sessions.exe" on drive C of your PC.  This is a self-extracting zip file that will install a directory titled SESSIONS with the files needed to process exploratory testing session reports. (Note: since this tool uses batch files, you will need to edit each batch file if your root drive letter is different than C.)

The following directory structure results:

Sessions dir:
	coverage.ini
	debrief_checklist.htm
	et.xls
	install_readme.txt
	SBTM.pdf	
	scan.log	
	scan-approved-then-run-report.bat
	scan-submitted-only.bat
	search.bat
	session-template.ses
	sheets.bat
	todo.xls
	todos.txt
	todo-maker.bat

	
	Approved dir
		(9 sample session reports)
	
	Datafiles dir
		(25 sample datafiles)
	
	Reports dir
		Sessions dir
			(no files)
		Templates dir
			coverage.tpl
			hopper.tpl 
			sessions.tpl
			status.tpl
			
	Submitted dir
		(no files)

	Todos dir
		(no files)
	
	Tools dir
		coverage.ini
		db.pl
		dirs.pl
		errors.bat
		errors.pl
		recent.pl
		report.pl
		scan.pl
		search.pl
		sheets.bat
		sheets.txt
		test.pl
		todomaker.pl


(If you demoing this with testers, you must share out the SESSIONS directory.  This enables your testers to submit their session reports and datafiles so that they can be scanned.)  

At this point, you can run a sample scan if you want to see how a report would look.  Skip to the "Running a scan" section below and return to step 4 when finished.

4. The "coverage.ini" file is important.  It is the engine that drives SBTM accuracy.  It's the list of features and functions of the product to be tested.  The one we included allows you to run the sample session files we included for a product called DecideRight.  
Before using the scan tool for *your* project, you'll need to customize this file to contain function areas for which you want to track coverage and base coverage reports.  Testers will need to understand what's in it, too, because it contains the areas they need to list in the #AREAS section of each report they file.  

Once the ini file is built, it needs to be copied two places:
	
		SESSIONS dir
		SESSIONS\TOOLS dir


About the sample files 
------------------------------
Included in the installation are 9 sample session reports and 25 datafiles.

The .ses files in the APPROVED directory are the session reports.  Filed by testers, they contains information about the chartered session of exploratory testing, including the tester's notes, bugs, and issues.

Datafiles go with sessions.  A datafile is any file that the tester referenced, used, or created during the session to aid their testing. There may be many files used by the tester during a particular session, and the DATAFILES dir must be used to store them.  During a scan, the tool will check to see whether the files the tester listed in the DATAFILES section of the session report are indeed stored in the DATAFILES dir.


Running a scan
--------------
You can run a scan right now since you have sample files.  The sample files represent sample output for a tester who's completed several sessions for a product called DecideRight.  

To see what a report would look like for the exploratory testing that was done so far on DecideRight, run "scan-approved-then-run-report.bat" located in the SESSIONS dir.

A notepad window titled "scan.log" will appear that says "Your papers are in order!"  This means that all 9 session reports have been scanned, are syntactically correct, and have corresponding datafiles in the DATAFILES dir.  The scan tool checks for about 100 different errors in the session reports to maintain data integrity.   If there are syntax errors in the session report, scan.log will tell you what each one is in turn, so that it can be corrected and the scan can be run again.  

An HTML summary report appears:  

The "View Completed Session Reports" link takes you to a page that lists what sessions have been done.  Once there is more than one session in the list, it can be sorted by clicking on the desired column heading.

The "View Test Coverage" link shows you how many 90-minute sessions of testing each area in the coverage.ini has gotten to-date.

NOTE: When running a scan, 36 small supporting files will be created in the REPORTS dir.  Each of these files contains data needed to view metrics reports.  They will be re-created with new data every time a scan is run.

A copy of each session is copied to SESSIONS\REPORTS\SESSIONS for backup.

What the tester needs to do
---------------------------
1. Testers can get their charters (mission statements for sessions) from the test manager or write them on their own -- whatever the manager and tester agree.  

2. Once a charter is given, the tester declares a start to the session, noting the approximate time, and they start testing, filling out the session report as they test.  

(There's a file titled sbtm.pdf in the "sessions" directory or out on http://www.satisfice.com/articles/ that explains more about how to write the report.)

3. It's important to note that this reporting method is tester-centric.  In other words, the tester is the captain of the session.  They can stop it for many reasons:
	
	* they've decided that they've satisfied the charter
	* they discover there's much more work to be done than they can do in this session
	* the functions they are too unstable to get any real testing done
	* they're losing focus because of fatigue
	* they have a meeting to go to
	* it's the end of the day
	* any other reason (explained to the test manager)

Whatever the reason, at the end of the session, the tester notes the end time and chooses a session duration to type into the DURATION section of the session report:
	
	SHORT = 60 minutes (+ or - 15 minutes)
	NORMAL = 90 minutes (+ or - 15 minutes)
	LONG = 120 minutes (+ or - 15 minutes)

NOTE: An exact time to the minute or second is *not* necessary.  We want testers to be testing, not looking at the clock, that's why an estimation of the length is good enough.

4. They save their report using the following naming convention: ET-xxx-000000-A.ses

	ET: 	stands for Exploratory Testing
	xxx: 	the tester's 3 initials
	000000:	date in YYMMDD format
	A, B, C, D, etc: current session of the day.  A is the first, B the second, etc.

So the sample title "ET-jsb-000530-A.ses" means this session is from me (Jonathan S. Bach), I did the session on May 30, 2000, and it was my first session of the day.

5. The tester saves the session report to a directory they create on their PC. They also copy any datafiles they used during the session to the DATAFILES directory on their PC.  Then they run a scan to verify the syntax is correct.  If the scan.log file says "Your papers are in order!", they can move the session report to the SUBMITTED directory (on a network share) and their datafiles to the networked DATAFILES directory. When they're ready, they can find the test lead and let them know a session is done and is ready to be debriefed.

6. Every session is debriefed by the test manager (or an appointed lead).  To aid that process, we've included the file "debrief_checklist.htm" to help both of them get ready.  The checklist is designed to remind the tester and manager about questions that could reveal more information about the session.  

After the debrief, they (or the test manager) can move it into the APPROVED directory so it can be scanned with other approved/debriefed sheets.

OPTIONAL: Generating "To-Do" Sessions
-----------------------------------------------------------
If you have ideas for charters and want to generate sessions for your testers to perform, you can list those ideas in a text file or an Excel spreadsheet and the tool will create session templates automatically.

If you run "todo-maker.bat" now, you'll see that it creates 3 sample session templates in the TODOS dir.  

Here's how it works:

1) "Todo-maker.bat" calls "todomaker.pl" (located in the TOOLS dir)...

2) "Todomaker.pl" reads "todos.txt" to populate session to-do templates...

3) "Todos.txt" is a tab delimited text file of all cells and rows copied from "todo.xls"...

4) "Todo.xls" is the master file.  It contains your to-do ideas in four categories: Session title, Area (function area in coverage.ini), Priority (1-3: 1 being the highest), and Charter (explanation of the testing to be done).   Enter your test ideas into this spreadsheet.  If a charter idea has more than one function area, separate the areas in the Areas column with semicolons.

5) Here's the important step:  after saving the spreadsheet, copy its entire contents (column titles and all) into the "todos.txt" file, replacing its contents each time you need to create a batch of to-dos. Keep the xls file up-to-date, deleting to-dos that have already been done.  Once the data is copied into todos.txt, you can run the todo-maker batch file to create the to-do sessions. 

6) Your testers can now go to the TODOS dir to get assignments.  As soon as they take ownership of a to-do charter, they change the session title to the normal session syntax.


----------------------
REVIEW: 

Session Setup/Installation Checklist:

* Install Perl
* Copy "sessions.exe" to the root drive and run it
* Edit the batch files (i.e. "scan-approved-then-run-report.bat") to contain the correct drive letter (if it is different than "C")
* For network use with other testers, share the SESSIONS dir (and subdirs) created during install
* Install Perl and "sessions.exe" on each tester's machine from which they'll be typing session reports
* Create a new, customized "coverage.ini" that maps to your product's functions and copy it to the following locations:

		SESSIONS dir
		SESSIONS\TOOLS dir
* Delete the sample files in APPROVED and DATAFILES directories


---------------------------
END OF FILE