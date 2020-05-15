# wpkgSync
 sync a remote copy of the wpkg structure to the local machine

the idea of this file is that we have created a repository on a public facing server with all ouyr our WPKG setup in it.
client computers will connect to this using a ssh key which we distribute with the installer
the server is of course locked down so this user can only read the files, but can write the logfile

in our environment we call this script ~after~ wpkg has run, it then uses (cw)rsync to update the local copy of the repository at c:\programdata\wpkg\
the next time wpkg runs, the cycle is repeated

to use this:
on the end user computers make folders like:

c:\Program Files (x86)\WpkgSync

C:\PROGRAMDATA\WPKG
└───client

c:\ProgramData\wpkgsync\.ssh\
├───known_hosts
└───wpkgsyncuser.id

obtain cwrsync from https://www.itefix.net/content/cwrsync-free-edition
copy the contents to "c:\Program Files (x86)\WpkgSync\"

on the server create a user for this process to use.
grant the user read access on the wpkg folder
grant the user read/write access on the wpkgreports folder
create user id file using ssh-keygen, either the one on your server, or the one from the cwrsync package
put public part on server in the user .ssh folder, and private part at c:\ProgramData\wpkgsync\.ssh\wpkgsyncuser.id

TODO ##################################################
** describe how to create known_hosts file

wpkgsync.bat file needs to run as Admin equivalent, or rsync logging to logfile won't work

Build (optional) ######################################
to build with Inno Setup:
#######################################################

make a folder structure like:
C:\<WPKGsyncBuildfolder>
├───client
├───config.company
│   └───.ssh
└───cwRsync

obtain cwrsync from https://www.itefix.net/content/cwrsync-free-edition
copy the contents to C:\WPKGSYNC\cwRsync\
obtain wpkg, set up linux (?) server as above
copy the contents of <wpkg-folder>\client to C:\<WPKGsyncBuildfolder>\client\
copy wpkg_local_settings.xml to C:\<WPKGsyncBuildfolder>\client\

copy the other files in this repository to c:\<WPKGsyncBuildfolder>\

Run Inno Setup on the file: wpkgsync.iss
adjust the build number as required and compile (Ctrl+F9) the executable.
deploy the executable to run on the target computers somehow.

TODO ##################################################
abort if not running as Admin
#######################################################

returned codes:
  101 missing ini file
  102 could not read from ini file
  103 FIX_ACLS failed
other setup rsync failed

call:
/fast - don't speed limit (default 2,000Kbps)
/setup  just do the minimum - top level

changelog
20/10/16  dce  tidy up
13/07/17  dce  id file in .ssh
04/01/18  dce  new version of cwrsync, log sending of wpkg log file
               fix received file permissions
               add -o UserKnownHostsFile=%wpkg_hosts%
08/01/18  dce  fix takeown and icacls syntax
21/05/18  dce  append username to log file, derive rsync wpkglogfile from DOS version
17/09/18  dce  add /fast option
21/10/18  dce  add required --times option to rsync
26/02/20  dce  use any relevant packages\exclude file, delete-excluded
11/03/20  dce  site specific variables in .ini file
29/04/20  dce  add /setup
07/05/20  dce  use the new way of getting last user and boot time
12/05/20  dce  grant users RX on the folder too
15/05/20  dce  use wmic for boot time as it's locale independent
               LastLoggedOnUser gives just as good results as the script we were using