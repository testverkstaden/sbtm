What's New in SBTM Tools-Ruby v1.2
===================================
The following SBTM "tools" directory scripts were converted from Perl to Ruby:

 * ERRORS.RB
 * RECENT.RB
 * REPORT.RB
 * SCAN.RB
 * SEARCH.RB
 * TODOMAKER.RB

These scripts perform the same functions and produce the same outputs as their 
Perl originals.  Slight improvements have been made in some cases, and some 
minor bug fixes have been made where appropriate or unavoidable.

For this initial release, I tried to stick as closely to the original Perl 
code structure as possible.  My primary goal here was to *port* the files, 
not to completely rewrite them.

The purpose for converting the scripts to Ruby was so that I could customise 
them for the specific needs of our Testing Team.  Since we use Ruby and not 
Perl, I found it very difficult to customise the originals.  With the help of 
some friends, O'Reilly references, and the comp.lang newsgroups, I learned just 
enough Perl to help me understand how to recreate them in Ruby.

These files are freely available for download and use by anyone who uses the 
command-line scripts to manage their SBTM session sheets.  Drop me a line if you 
have any improvement suggestions or bug reports related to these Ruby scripts.

Thanks.  Paul C.


INSTALLATION:
-------------
0. Install the original Satisfice 'sessions.exe' archive obtained elsewhere.
   (No, this is not a self-contained zip file.  This is an add-on.)

1. Install Ruby if you don't already have it installed.
   (download free at: http://www.ruby-lang.org/en/downloads/)
   (Use revision Ruby 1.8.7-p358, not the latest version)

2. Unzip 'sbtm_ruby-tools_v#.#.zip' into your main SESSIONS folder. (e.g. C:\Sessions)
   => The Ruby scripts are in a new subfolder called "tools-ruby" so that they can 
      be placed alongside the original "tools" Perl scripts.

3. Run the new ruby*.bat files like you would the original *.bat files.
   (see the file C:\Sessions\install_readme.txt)


Last Updated: 15 July 2009

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Differences between Ruby scripts and original Perl scripts:
===========================================================

FILE: COVERAGE.INI

ENHANCEMENT NOTE:
-----------------
- The 'tools-ruby' folder does NOT contain a copy of this file like the 
  Perl 'tools' folder does.
  => The calling BAT files were changed so that you only need to update COVERAGE.INI 
     in *one* place - the C:\Sessions folder.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: ERRORS.RB v1.0 (01-May-07)

ENHANCEMENTS:
-------------
- Added a command-line argument check.  (Wasn't really required, but it's consistent now.)

- Changed the regex check slightly to allow for spaces.  (My initial SCAN.RB 
file had spaces that resulted in this script turning up *no* matches.  I changed 
the SCAN.RB script message format back so that the original Perl script output 
can be compared to the Ruby script output.)

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: RECENT.RB v1.1 (21-Dec-07)

BUG FIXES:
----------
- 21-Dec-07: Fixed typo in method name (from the ruby port 1.0 release).

v1.0 release (01-May-07):

- Removed the "Per Tester" references that caused the data to display incorrectly.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: REPORT.RB v2.1 (15-Jul-09)

BUG FIXES:
----------
- 15-Jul-09: Added a method check to work with certain updated versions of Ruby.

v1.0 release (01-May-07):

- The 's_by_datetime.htm' file now correctly sorts descending by Date+Time, 
  rather than just by Date.

- The 's_by_time.htm' file now correctly sorts descending by Time. 
  (It didn't work in the original Perl script.)

ENHANCEMENTS:
-------------
- 15-Jul-09: Decided to provide my 2.0 version of this report.rb file.
             => Punched up the table rows with some colour for easier reading.
             => Table heading rows are stored in a template file that you will
                have to update manually since they are not included here.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: SCAN.RB v1.2 (15-Jul-09)

BUG FIXES:
----------
- 15-Jul-09: Added a method check to work with certain updated versions of Ruby.

- 15-Jul-09: Fixed an error message typo - typo ported from the original.

- 21-Dec-07: TBS #DURATION value error handling improved (from ruby 1.0 release).

- 21-Dec-07: Improved Date sort algorithm for creating 2 'breakdown' reports files.
  (This was only noticeable when session sheets from one year to the next were 
   getting scanned together.  e.g. 'Approved' folder contains session sheets 
   for 2006 and 2007.)

v1.0 release (01-May-07):

- Fixed bug where BUGS and ISSUES were being incorrectly skipped in the metrics.
  For example, when the first bug in the BUGS section was identified in all caps 
  "#BUG" but each subsequent bug was in different case (e.g. "#Bug") then only 
  the first bug was counted and the rest were considered a part of the first bug.
  => The "#BUG" and "#ISSUE" identifier check is now case independent.

- Ruby appears to produce more accurate numeric calculations than Perl.
  For example, Perl generated numbers like:
          "0.1999995", "1.466663", "1.1333305"
  and Ruby generates these instead: 
          "0.2", "1.46666666666666", "1.13333333333333"
  (I had noticed occasional rounding errors with the original Perl scripts which 
   are gone now.)

- Error messages: a few have been changed slightly to correct typos and improve 
  readability.

- Removed duplicate error checking and added missing error checks in a few 
  subroutines/methods.

- VARIABLES:
  (a) CONSTANT variable names used to represent file names were changed to not 
      be constants anymore.  The CONSTANTS produced warnings and errors so I 
      changed them to local/instance variables as required.
      => FYI - "f_" was prefixed to the original uppercase constant names to 
         indicate that they represent "files".
  (b) Corrected a typo in a variable name that produced errors.
  (c) Some of the Ruby script variable names were changed to improve readability.


ENHANCEMENTS:
-------------
- 15-Jul-09: Timestamp may now be in 24-hour format (i.e. HH:MM).

- 15-Jul-09: Updated an error message to add clarity.

- 15-Jul-09: Changed error message format so it displays the ET Session sheet
             filename first and then the message.

- 15-Jul-09: Changed certain error messages to display the unexpected text found
             in the scanned session sheet.
             => Changed certain error messages as a result.  No longer identical
                to the original ported scripts.

- 15-Jul-09: Removed the TBS addition check that allowed a sum of 99 or 100.
             => Sum must equal 100 now. (Why would it allow 99?)


- 21-Dec-07: TBS #DURATION multiplier now allows decimal values! (e.g. 'short * 2.5')
             => Added check to ensure positive multiplier value.

v1.0 release (01-May-07):

- "breakdowns.txt" is only written once now - at the end of the script.
  => This file is now sorted in reverse (Date+Time) order rather than just 
     reverse Date order.

- ET Session sheet filename check now allows either 2 *or* 3 Tester initials as 
  valid.  (Used to *require* 3 initials.)

- Script no longer stops when the first parsing error is encountered.
  (It still stops if a required INPUT file is missing, but not for parsing errors.)

- If the script cannot find a required input file, it now includes the script 
  Line number in the output message.

- Session sheet Text blocks (e.g. the Charter description, Test Notes, Bug and 
  Issue descriptions) now automatically strip out the trailing blank lines.

- Date and Time values (in the Session Sheet 'START' section) are now more flexible.
  => For example, now accept years in either YY or YYYY format, extra embedded 
     spaces are ignored, and AM/PM can be either lowercase or uppercase.

- Date and Time values in output files include leading zeros.
  For example, "4/7/07" now appears as "04/07/07", and "1:07" as "01:07"
  (This is the Ruby default for Date/Time format, so I didn't bother to manually 
   change it.)

- 'CHARTER VS. OPPORTUNITY' section values may now include embedded spaces.
  (Before, there had to be *no* spaces for it to parse correctly - e.g. "100/0".
   Now "100 / 0" will also be accepted as valid.)

- Removed incomplete code for unimplemented #TESTER feature in the 
  'parsebreakdown' subroutine/method.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: SEARCH.RB v1.0 (01-May-07)

BUG FIXES:
----------
- The Session sheet sorting is now: Ascending by (filedate)+(tester initials)
  (Before, it used to just be by (filedate) and *randomly* by (tester initials) 
   which bugged me.)

- Script now exits if *no* search criteria is specified, rather than matching 
  *all* the sheets.

- "sheets.bat" file now includes "@ECHO OFF" for silent execution in a Command 
  Prompt window

- "sheets.bat" file now "start's" each matching file in NotePad so that *all* 
  the matched files open at once instead of one at a time.


ENHANCEMENTS:
-------------
- Added the specified search directory to the Input prompt.
  (I use different batch files for different directories, so this is a handy 
   reminder to let me know which directory I am searching.)

- Final note to user only displays if matches are found.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: TODOMAKER.RB v1.0 (21-Dec-07)

ENHANCEMENTS:
-------------
- Added a command-line argument check.  (Wasn't really required, but it's consistent now.)

- Now directly reads from C:\Sessions\todo.xls rather than having the user 
  convert the spreadsheet contents to "todos.txt" first.
  (i.e. in the original C:\Sessions\install_readme.txt file, this changes 
   step 2 and skips steps 3 & 5.)
  
  => ASIDE: this particular script only works in the MS Windows environment.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FILE: TODOMAKER-ORIG.RB v1.0 (21-Dec-07)

- Port of original Perl script.  Reads the Tab-delimited 'todos.txt' file as input.

--> You may modify 'ruby-todo-maker.bat' batch file to use desired ruby script tool 
    i.e. either the one that reads from the TXT file or from the XLS file (default).

ENHANCEMENTS:
-------------
- Added a command-line argument check.  (Wasn't really required, but it's consistent now.)

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
