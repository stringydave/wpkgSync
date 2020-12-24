@echo off
rem run WPKG service once a day, run wpkgSync otherwise
rem schedule to start when the computer starts and repeat every hour after that

set wpkgsync_process=rsync
set wpkgsync_file=%~dp0wpkgsync.bat
set wpkg_service=WPKG Service

set ini_file=%ProgramData%\wpkgsync\%~n0.ini
set wpkglogfile=%SystemDrive%\wpkg-%computername%.log


set syncabortlimit=20
set wpkgabortlimit=5

set syncabortcount=0
set wpkgabortcount=0

set dd=
set mm=
set yy=

rem get the date in wpkg-log format
for /f "Tokens=1-3 Delims=/." %%i in ("%date%") do set dd=%%i& set mm=%%j& set yy=%%k

rem read the configuration file
if exist "%ini_file%" (
    FOR /F "usebackq tokens=1,2 delims==" %%i in ("%ini_file%") do (
        if "%%i"=="last_sync"       set last_sync=%%j
        if "%%i"=="syncabortcount"  set syncabortcount=%%j
        if "%%i"=="wpkgabortcount" 	set wpkgabortcount=%%j
    )
)

rem is wpkgsync_process already running?
tasklist  | find /i "%wpkgsync_process%" >nul 2>&1 && goto SYNC_ALREADY_RUNNING

rem is wpkg_service already running?
net start | find /i "%wpkg_service%"     >nul 2>&1 && goto WPKG_ALREADY_RUNNING
tasklist  | find /i "%wpkg_service%"     >nul 2>&1 && goto WPKG_ALREADY_RUNNING

rem if it doesn't look like wpkg has run today then start it
find "XML files" %wpkglogfile% | find "%yy%-%mm%-%dd%" >nul 2>&1 || goto START_WPKG
rem else
goto START_SYNC

:START_WPKG
rem do the process here
echo start the WPKG Service...
net start "%wpkg_service%"
if errorlevel 1 (set /a wpkgabortcount=wpkgabortcount+1) else (set wpkgabortcount=0)
goto WRITE_INI

:START_SYNC
echo time to do a sync...
call "%wpkgsync_file%"
if errorlevel 1 (
	echo "%wpkgsync_file%" terminated with: %errorlevel%
	set /a syncabortcount=syncabortcount+1
	) else (
	set syncabortcount=0
	set last_sync=%date% %time%
	)
goto WRITE_INI

:WPKG_ALREADY_RUNNING
echo %wpkg_service% is already running
set /a wpkgabortcount=wpkgabortcount+1
goto WRITE_INI

:SYNC_ALREADY_RUNNING
echo %wpkgsync_process% is already running
set /a syncabortcount=syncabortcount+1
goto WRITE_INI

:WRITE_INI
rem write ini file
echo #ini file for %~dpnx0 at %date% %time% > "%ini_file%"
echo last_sync=%last_sync% >> "%ini_file%"
echo syncabortcount=%syncabortcount% >> "%ini_file%"
echo wpkgabortcount=%wpkgabortcount% >> "%ini_file%"
echo ------------------------------------------------
type "%ini_file%"
echo ------------------------------------------------

if %syncabortcount% GEQ %syncabortlimit% goto ERROR
if %wpkgabortcount% GEQ %wpkgabortlimit% goto ERROR
goto END

:ERROR
echo ################## WPKG ################## > "%temp%\%~n0.txt"
rem if we've failed to sync, tell the user
if %syncabortcount% GEQ %syncabortlimit% echo WPKG is having difficulty synchronising update files from the server >> "%temp%\%~n0.txt"
if %syncabortcount% GEQ %syncabortlimit% echo this has happened %syncabortcount% times since %last_sync% >> "%temp%\%~n0.txt"

rem if we've failed to run WPKG for a long time, but sync is OK, then we can see that in the log file, still, a restart is probably a good idea.
if %wpkgabortcount% GEQ %wpkgabortlimit% echo WPKG is having difficulty updating programs on your computer >> "%temp%\%~n0.txt"
if %wpkgabortcount% GEQ %wpkgabortlimit% echo this has happened %wpkgabortcount% times >> "%temp%\%~n0.txt"
if %wpkgabortcount% GEQ %wpkgabortlimit% echo please restart your computer, if you still see this message >> "%temp%\%~n0.txt"
echo please tell Group IT Support. >> "%temp%\%~n0.txt"
msg * < "%temp%\%~n0.txt"

:END
