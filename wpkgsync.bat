@echo off
rem obtain cwrsync from https://www.itefix.net/content/cwrsync-free-edition
rem create user id file using ssh-keygen
rem put public part on server, and private part at %wpkgidfile%
rem schedule this file to run
rem file needs to run as Admin equivalent, or wpkguserdetails and rsync logging to logfile won't work

rem returned codes:
rem   101 missing ini file
rem   102 could not read from ini file
rem   103 FIX_ACLS failed
rem   104 not running as Admin
rem   200+rsync get failed
rem   300+rsync send failed
rem other setup rsync failed

rem call:
rem /fast - don't speed limit (default 2,000Kbps)
rem /setup  just do the minimum - top level

rem changelog
rem 20/10/16  dce  tidy up
rem 13/07/17  dce  id file in .ssh
rem 04/01/18  dce  new version of cwrsync, log sending of wpkg log file
rem                fix received file permissions
rem                add -o UserKnownHostsFile=%wpkg_hosts%
rem 08/01/18  dce  fix takeown and icacls syntax
rem 21/05/18  dce  append username to log file, derive rsync wpkglogfile from DOS version
rem 17/09/18  dce  add /fast option
rem 21/10/18  dce  add required --times option to rsync
rem 26/02/20  dce  use any relevant packages\exclude file, delete-excluded
rem 11/03/20  dce  site specific variables in .ini file
rem 29/04/20  dce  add /setup
rem 07/05/20  dce  use the new way of getting last user and boot time
rem 12/05/20  dce  grant users RX on the folder too
rem 15/05/20  dce  use wmic for boot time as it's locale independent
rem                LastLoggedOnUser gives just as good results as the script we were using
rem 02/07/20  dce  autogenerate exclude file
rem 03/07/20  dce  abort if not running as Admin, tidy up variables
rem 09/11/20  dce  get systeminfo and serial number
rem 23/11/20  dce  we'll get wpkg to run "logfile" now, so we just need to deal with the output

rem abort if not running as Admin
net file >nul 2>&1
if errorlevel 1 (
	echo this script must run as Admin
	exit /b 104
)

rem Make environment variable changes local to this batch file
SETLOCAL

rem Specify where to find rsync and related files, and add to PATH
set CWRSYNCHOME=%~dp0
set PATH=%CWRSYNCHOME%;%PATH%
rem save these because %~0 will be destroyed by shift
set scriptname=%~n0
set scriptpath=%~dpn0

rem load variables from the .ini file in the same folder as this file, use usebackq otherwise quoted path is interpreted as a string
if exist "%scriptpath%.ini" (
    FOR /F "usebackq tokens=1,2 delims==" %%i in ("%scriptpath%.ini") do (
        if "%%i"=="wpkgremote" set wpkgremote=%%j
    )
) else (
	echo missing file "%scriptpath%.ini"
	exit /b 101
)

rem check we got the value we need
if "%wpkgremote%"=="" (
	echo failed to initialise variables from "%scriptpath%.ini"
	exit /b 102
)

rem we're required to set HOME, but it seems to be ignored
set HOME=%ProgramData%\wpkgsync
set wpkgFolder=%ProgramData%\wpkg
set wpkglogfile=%systemdrive%\wpkg-%computername%.log

rem now parse any parameters
set bwlimit=--bwlimit=2000
set setup=
:PARSE
if /i '%1'=='/fast'   set bwlimit=
if /i '%1'=='/setup'  set setup=True
shift
rem loop until we've consumed all the parameters passed
if not '%1'=='' goto PARSE

rem rsync variables in linux format, colon defines a remote host, so:
rem replace c: with /cygdrive/c and \ with /  Example: C:\WORK\* --> /cygdrive/c/work/*
set wpkgidfile=/cygdrive/c/ProgramData/wpkgsync/.ssh/wpkgsyncuser.id
set wpkg_hosts=/cygdrive/c/ProgramData/wpkgsync/.ssh/known_hosts
set wpkglocal=/cygdrive/c/ProgramData/wpkg

rem rsync/ssh options
rem  -r                     recurse into folders
rem  -n                     dry run
rem  -v                     verbose
rem  -h                     human readable numbers
rem  -e                     use this shell
rem  -i                     use this identity file
rem -o UserKnownHostsFile=  use this KnownHosts file
rem --delete                files here which don't exist at the source end
rem --delete-excluded       also delete excluded files from dest dirs, this would delete the client files, but we don't need them any more
rem --timeout=seconds 
rem --exclude=PATTERN       exclude files matching PATTERN
rem --exclude-from=file     read exclude patterns from FILE
rem --partial               keep partially transferred files
rem --times                 transmit file modification time, so subsequent checks can use this instead of file compare.
rem --bwlimit=KBPS          limit I/O bandwidth; KBytes per second

rem  0     Success
rem  1     Syntax or usage error
rem  2     Protocol incompatibility
rem  3     Errors selecting input/output files, dirs
rem  4     Requested action not supported (by the client and not by the server)
rem  5     Error starting client-server protocol
rem  6     Daemon unable to append to log-file
rem 10     Error in socket I/O
rem 11     Error in file I/O
rem 12     Error in rsync protocol data stream
rem 13     Errors with program diagnostics
rem 14     Error in IPC code
rem 20     Received SIGUSR1 or SIGINT
rem 21     Some error returned by waitpid()
rem 22     Error allocating core memory buffers
rem 23     Partial transfer due to error
rem 24     Partial transfer due to vanished source files
rem 25     The --max-delete limit stopped deletions
rem 30     Timeout in data send/receive
rem 35     Timeout waiting for daemon connection

rem can't talk to the remote server will result in code 12
rem can't find the file/folder you're after will result in code 23

:SETUP
if '%setup%'=='' goto MAKE-EXCLUDE-FILE
rem just the top level, no packages as yet, no logging, because we'll be running this whilst wpkg is active
rem if it failed then abort, so that automated install will abort
set exclude=--exclude='profiles.sites' --exclude='packages/'
rsync -r -e "ssh -i %wpkgidfile% -o UserKnownHostsFile=%wpkg_hosts%" --partial --times --timeout=120 %bwlimit% %exclude% %wpkgremote%:/opt/updates/ %wpkglocal%/ >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
rem and the package.xml files, so we can process excludes later
rsync -e "ssh -i %wpkgidfile% -o UserKnownHostsFile=%wpkg_hosts%" --partial --times --timeout=120 %bwlimit% %wpkgremote%:/opt/updates/packages/*.xml %wpkglocal%/packages/ >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
rem and skip all the next bits
goto FIX_ACLS

:MAKE-EXCLUDE-FILE
if exist "%temp%\%scriptname%.excl.txt" del "%temp%\%scriptname%.excl.txt"
if not exist %wpkgFolder%\Tools\awk.exe               goto RSYNC-GET
if not exist %wpkgFolder%\scripts\wpkgsyncexclude.awk goto RSYNC-GET
%wpkgFolder%\Tools\awk.exe -f %wpkgFolder%\scripts\wpkgsyncexclude.awk %wpkgFolder%\packages\*.xml %wpkglogfile% > "%temp%\%scriptname%.excl.txt"

:RSYNC-GET
rem if previous step has made an exclude file then use it, exclude-from works with DOS syntax too
set exclude=--exclude='profiles.sites' --exclude='client/'
if exist "%temp%\%scriptname%.excl.txt"                             set exclude=--exclude-from=%temp%\%scriptname%.excl.txt
rem sync the remote structure to here, append the log to the wpkg log (wpkg creates a new one each time):
rsync -rvh -e "ssh -i %wpkgidfile% -o UserKnownHostsFile=%wpkg_hosts%" --progress --delete --delete-excluded --partial --times --timeout=120 %bwlimit% %exclude% --log-file=%wpkglogfile% %wpkgremote%:/opt/updates/ %wpkglocal%/ 2>nul
if errorlevel 1 set /a sync_get=200+%errorlevel%

:APPEND-LOG
rem if our logfile script has made an extra file, append that to the log
if exist "%temp%\wpkgExtras.tmp" type "%temp%\wpkgExtras.tmp" >> "%wpkglogfile%"
if exist "%windir%\temp\wpkgExtras.tmp" type "%windir%\temp\wpkgExtras.tmp" >> "%wpkglogfile%"

:RSYNC-SEND
rem set wpkglogfile for rsync, add /cygdrive/ and remove colons
set wpkglogfile=/cygdrive/%wpkglogfile::=%
rem replace \ with /
set wpkglogfile=%wpkglogfile:\=/%
rem should end up with e.g. wpkglogfile=/cygdrive/c/wpkg-%computername%.log
rem and send the wpkglogfile
rsync -vh  -e "ssh -i %wpkgidfile% -o UserKnownHostsFile=%wpkg_hosts%" --timeout=120 %bwlimit% --log-file=%wpkglogfile% %wpkglogfile% %wpkgremote%:/opt/wpkgreports/ 2>nul
if errorlevel 1 set /a sync_send=300+%errorlevel%

:FIX_ACLS
echo setting file ownership...
echo setting file ownership... >> "%temp%\%scriptname%_acl.log"
rem takeown /File to /Administrators group /Recurse /D prompt Y, send error out and cmd out to the log file
takeown /F %ProgramData%\wpkg /A /R /D Y > "%temp%\%scriptname%_acl.log" 2>&1
set takeown=%errorlevel%

echo setting file permissions...
echo setting file permissions... >> "%temp%\%scriptname%_acl.log"
rem /T change Tree (recurse) /Grant, output to log file, apart from error text to CON which we can't capture
icacls %ProgramData%\wpkg /T /grant:r "Administrators":F "SYSTEM":F "USERS":RX >> "%temp%\%scriptname%_acl.log" 2>&1
set icacls=%errorlevel%

rem if there was an error
if not     '%sync_get%'==''    exit /b %sync_get%
if not    '%sync_send%'==''    exit /b %sync_send%
if '%takeown%.%icacls%'=='0.0' goto END
rem append acl log to the end of the logfile (might not work in setup mode)
type "%temp%\%scriptname%.acl.log" >> %wpkglogfile%
rem and quit
exit /b 103

:END
if exist "%temp%\%scriptname%.acl.log" del "%temp%\%scriptname%.acl.log"
