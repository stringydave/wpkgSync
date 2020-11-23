# wpkgSync

[WPKG](https://wpkg.org/) is an automated software deployment, upgrade and removal program for Windows. It expects to connect to a SMB fileshare on a server on your local network.  This obviously doesn't work for laptops which are out of the office.

We created wpkgSync to allow us to sync a copy of the remote wpkg structure to the local machine
 

- we have created a repository on a public facing server with all our WPKG setup in it.
- client computers will connect to this server using (only) a ssh key which we distribute with the installer
- the server is of course locked down so this user can only read the files, but can write the logfile
- in our environment we call this script _after_ wpkg has run, it then uses (cw)rsync to update the local copy of the repository at `c:\programdata\wpkg\`
- the next time wpkg runs, the cycle is repeated
- we include a script (awk) which causes cwRsync to download _only_ the packages folders we need

wpkgsync.bat file needs to run as Admin equivalent, so that rsync logging to logfile, and fixing up the permissions of the local package store will work, this is not a problem if we include it as a WPKG "post action".

# usage
to use this, on the end user computers make folders like:

```
c:\Program Files (x86)\WpkgSync
```

```
C:\PROGRAMDATA\WPKG
└───client

c:\ProgramData\wpkgsync\.ssh\
├───known_hosts
└───wpkgsyncuser.id
```

- obtain cwRsync from https://www.itefix.net/content/cwRsync-free-edition (there's now a x64 update)
- copy the contents to "c:\Program Files (x86)\WpkgSync\"
- on the server create a user for this process to use.
- grant the user read access on the wpkg folder
- grant the user read/write access on the wpkgreports folder
- create user id file using ssh-keygen, either the one on your server, or the one from the cwRsync package
- put public part on server in the user .ssh folder, and private part at c:\ProgramData\wpkgsync\.ssh\wpkgsyncuser.id

TODO: describe how to create known_hosts file

# build (optional):
to build with [Inno Setup](https://jrsoftware.org/isinfo.php):

make a folder structure like:
```
<WPKGsyncBuildfolder>
├───client
├───config.company
│   └───.ssh
└───cwRsync
```
- obtain cwRsync from https://www.itefix.net/content/cwRsync-free-edition
- copy the contents to <WPKGsyncBuildfolder>\cwRsync\
- obtain wpkg, set up linux (?) server as above
- copy the contents of <wpkg-folder>\client to <WPKGsyncBuildfolder>\client\
- copy wpkg_local_settings.xml to <WPKGsyncBuildfolder>\client\
- copy the other files in _this_ repository to <WPKGsyncBuildfolder>\
- run Inno Setup on the file: wpkgsync.iss
- adjust the build number as required and compile (Ctrl+F9) the executable.
- deploy the executable to run on the target computers somehow (using wpkg obviously)

# returned codes:
``` 
  101: missing ini file
  102: could not read from ini file
  103: FIX_ACLS failed
  104: not running as Admin
other: setup rsync failed
``` 

# call:
``` 
/fast - don't speed limit (default 2,000Kbps)
/setup  just do the minimum - top level
```
# server structure
```
/opt
├───updates
│   └───packages... etc
└───wpkgreports
```
