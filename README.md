# wpkgSync
 sync a remote copy of the wpkg structure to the local machine

- we have created a repository on a public facing server with all our WPKG setup in it.
- client computers will connect to this server using (only) a ssh key which we distribute with the installer
- the server is of course locked down so this user can only read the files, but can write the logfile
- in our environment we call this script ~after~ wpkg has run, it then uses (cw)rsync to update the local copy of the repository at `c:\programdata\wpkg\`
- the next time wpkg runs, the cycle is repeated

wpkgsync.bat file needs to run as Admin equivalent, or rsync logging to logfile, and fixing up the permissions of the local package store won't work

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

- obtain cwrsync from https://www.itefix.net/content/cwrsync-free-edition
- copy the contents to "c:\Program Files (x86)\WpkgSync\"
- on the server create a user for this process to use.
- grant the user read access on the wpkg folder
- grant the user read/write access on the wpkgreports folder
- create user id file using ssh-keygen, either the one on your server, or the one from the cwrsync package
- put public part on server in the user .ssh folder, and private part at c:\ProgramData\wpkgsync\.ssh\wpkgsyncuser.id

TODO: describe how to create known_hosts file

# build (optional):
to build with Inno Setup:

make a folder structure like:
```
C:\<WPKGsyncBuildfolder>
├───client
├───config.company
│   └───.ssh
└───cwRsync
```
- obtain cwrsync from https://www.itefix.net/content/cwrsync-free-edition
- copy the contents to C:\WPKGSYNC\cwRsync\
- obtain wpkg, set up linux (?) server as above
- copy the contents of <wpkg-folder>\client to C:\<WPKGsyncBuildfolder>\client\
- copy wpkg_local_settings.xml to C:\<WPKGsyncBuildfolder>\client\
- copy the other files in this repository to c:\<WPKGsyncBuildfolder>\
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
