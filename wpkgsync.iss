; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

; 06/01/17  dce  added uninstall sections to tidy up left behind data
;                if we ship a new version of wpkg with this, then we'll need to update [Run] & [UninstallRun] sections
; 05/01/18  dce  new cwRsync version 5.5.0
;                in [Run] section use skipifsilent so will be ignored if run silent (auto)
; 08/01/18  dce  fix takeown and icacls syntax in wpkgsync.bat
;                uninstall section should ask if we're to uninstall wpkg and remove all the data
; 11/01/18  dce  we need waituntilterminated on installs regardless of what the documentation implies
; 21/05/18  dce  new version of wpkgsync.bat
; 17/09/18  dce  new version of wpkgsync.bat adds /fast option
; 22/10/18  dce  .4 new version of wpkgsync.bat adds rsync --times
; 26/02/20  dce  .6 use any relevant packages\exclude file 
; 28/02/20  dce  .10 use /setup & separate option for full synch
; 07/05/20  dce  .11 use the new way of getting last user and boot time
; 15/05/20  dce  .12 use LastBootUpTime now, remove no longer required script dependancy
; 03/07/20  dce  .15 autogenerate exclude file, abort if not admin
; 09/11/20  dce  .16 get systeminfo and serial number
; 23/11/20  dce  .20 use "logfile" for systeminfo and serial number
; 23/11/20  dce  6.2.0.20 use 64 bit CWrsync 6.2.0
; 31/12/20  dce  .21 add wpkgcontrol
; 07/03/21  dce  .22 fold wpkgcontrol into wpkgsync
; 11/03/21  dce  .22 build version depending on Architecture
; 01/12/21  dce  remove wpkgcontrol
; 20/01/22  dce  6.2.4 build one combined version for x64 & x86, destination files will now always be in %PROGRAMFILES%
; 11/02/22  dce  add scheduled tasks
; 15/02/22  dce  and remove them on uninstall, install files are "here"

[Setup]
; ============================================================
; update these variables to match what you're building
#define RsyncVer_x64 "6.2.4"      
#define RsyncVer_x86 "5.5.0"    
#define ScriptVersion "25"
#define MyCompany "company"
; ============================================================
; #define MyAppVersion {#RsyncVer} + "." + {#ScriptVersion}
AppVersion={#RsyncVer_x64}.{#ScriptVersion}
OutputBaseFilename=wpkgsync_setup.{#RsyncVer_x64}.{#ScriptVersion}.{#MyCompany}
AppName=WpkgSync
#include AddBackslash(SourcePath) + "config." + AddBackslash(MyCompany) + "include.iss" 
UninstallDisplayName=WpkgSync
DefaultDirName={commonpf}\WpkgSync
DisableDirPage=yes
DefaultGroupName=WpkgSync
DisableProgramGroupPage=yes 
OutputDir=C:\progs\wpkgsync
InfoBeforeFile=config.{#MyCompany}\readme.txt
UninstallDisplayIcon={app}\wpkgsync.ico
SetupIconFile=wpkgsync.ico
Compression=lzma
SolidCompression=yes
; ExtraDiskSpaceRequired for the wpkg folder download (bytes) we need about 2 Gb = 2,147,483,648 bytes 
ExtraDiskSpaceRequired=2147483648
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.  On all other architectures it will install in "32-bit mode".
ArchitecturesInstallIn64BitMode=x64
; Note: We don't set ProcessorsAllowed because we want this installation to run on all architectures (including Itanium,
; since it's capable of running 32-bit code too).

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[InstallDelete]
; delete files before the installer runs, we want to remove the .x86 .dll files
Type: files; Name: "{app}\*.dll";

[Files]
Source: "wpkgsync.bat";                             DestDir: "{app}";                                                      Flags: ignoreversion
Source: "wpkgsync.ico";                             DestDir: "{app}";                                                      Flags: ignoreversion
Source: "config.{#MyCompany}\wpkgsync.ini";         DestDir: "{app}";                                                      Flags: ignoreversion
Source: "config.{#MyCompany}\.ssh\wpkgsyncuser.id"; DestDir: "{commonappdata}\wpkgsync\.ssh";                              Flags: ignoreversion
Source: "config.{#MyCompany}\.ssh\known_hosts";     DestDir: "{commonappdata}\wpkgsync\.ssh"; DestName: "known_hosts";     Flags: ignoreversion
Source: "cwRsync_{#RsyncVer_x64}_x64\bin\*";        DestDir: "{app}";                     Check: not Is64BitInstallMode;   Flags: ignoreversion recursesubdirs createallsubdirs
Source: "cwRsync_{#RsyncVer_x86}_x86\bin\*";        DestDir: "{app}";                     Check: Is64BitInstallMode;       Flags: ignoreversion recursesubdirs createallsubdirs
Source: "WPKG-service-schedule.xml";                DestDir: "{app}";                                                      Flags: ignoreversion 
Source: "WPKG-sync-task.xml";                       DestDir: "{app}";                                                      Flags: ignoreversion 
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

; push the wpkg client so we can run the install
Source: "client\WPKG Client 1.3.14-x32.msi";        DestDir: "{commonappdata}\wpkg\client"; Check: not Is64BitInstallMode; Flags: ignoreversion
Source: "client\WPKG Client 1.3.14-x64.msi";        DestDir: "{commonappdata}\wpkg\client"; Check: Is64BitInstallMode;     Flags: ignoreversion
Source: "client\wpkg_local_settings.xml";           DestDir: "{commonappdata}\wpkg\client";                                Flags: ignoreversion

; to silently install wpkg, you use this
; msiexec /qn /i WPKGSetup.msi SETTINGSFILE=f:\wpkg\images\setup\settings.xml
; to silently update the settings of an already installed WPKG Client, use:
; %PROGRAMFILES%\WPKG\wpkginst.exe --SETTINGSFILE=f:\wpkg\images\setup\settings.xml

[Run]
Filename: "{commonappdata}\wpkg\client\WPKG Client 1.3.14-x32.msi"; Parameters: "/qn SETTINGSFILE={commonappdata}\wpkg\client\wpkg_local_settings.xml"; StatusMsg: "Installing the x32 WPKG client..."; Description: "Install the WPKG client (if it's not installed)";    Check: not Is64BitInstallMode; Flags: postinstall skipifsilent shellexec runascurrentuser waituntilterminated
Filename: "{commonappdata}\wpkg\client\WPKG Client 1.3.14-x64.msi"; Parameters: "/qn SETTINGSFILE={commonappdata}\wpkg\client\wpkg_local_settings.xml"; StatusMsg: "Installing the x64 WPKG client..."; Description: "Install the WPKG client (if it's not installed)";    Check: Is64BitInstallMode;     Flags: postinstall skipifsilent shellexec runascurrentuser waituntilterminated
; to update the settings of an already installed WPKG Client, use:
Filename: "{commonpf32}\WPKG\wpkginst.exe"; Parameters: "--SETTINGSFILE={commonappdata}\wpkg\client\wpkg_local_settings.xml"; StatusMsg: "Updating the settings of the WPKG client..."; Description: "Update the settings of the WPKG client (if it's already installed)"; Check: not Is64BitInstallMode; Flags: postinstall runascurrentuser waituntilterminated
Filename: "{commonpf64}\WPKG\wpkginst.exe"; Parameters: "--SETTINGSFILE={commonappdata}\wpkg\client\wpkg_local_settings.xml"; StatusMsg: "Updating the settings of the WPKG client..."; Description: "Update the settings of the WPKG client (if it's already installed)"; Check: Is64BitInstallMode;     Flags: postinstall runascurrentuser waituntilterminated
; minimal synchronisation
Filename: "{app}\wpkgsync.bat"; StatusMsg: "Synchronising the data..."; Description: "Run the initial synchronisation"; Parameters: "/setup"; Flags: postinstall shellexec runascurrentuser waituntilterminated
; and then run the first synchronisation
Filename: "{app}\wpkgsync.bat"; StatusMsg: "Synchronising the data..."; Description: "Run the first full synchronisation (should run in the background for about 1 hour)"; Flags: unchecked postinstall skipifsilent shellexec runascurrentuser waituntilterminated runminimized hidewizard
; set the Service start type (default is Auto which doesn't actually work on Win 10) and schedule the Service and Sync task to run
Filename: "sc"; Parameters: "config WPKGService start= delayed-auto"; StatusMsg: "Set WPKG Service to Auto Start..."; Description: "Set WPKG Service to Auto Start"; Flags: runascurrentuser waituntilterminated
Filename: "schtasks"; Parameters: "/Create /F /RU ""SYSTEM"" /TN ""WPKG Service""   /XML ""{app}\WPKG-service-schedule.xml"" "; StatusMsg: "Schedule the WPKG client..."; Description: "Schedule the WPKG client to run every day"; Flags: runascurrentuser waituntilterminated
Filename: "schtasks"; Parameters: "/Create /F /RU ""SYSTEM"" /TN ""WPKG Sync task"" /XML ""{app}\WPKG-sync-task.xml"" ";        StatusMsg: "Schedule the WPKGsync client..."; Description: "Schedule the WPKGsync client to run every hour"; Flags: runascurrentuser waituntilterminated

[UninstallDelete]
; include here actions to run after the uninstaller runs, so we want to remove the \ProgramData\wpkgsync data folder
Type: filesandordirs; Name: "{commonappdata}\wpkgsync";

[UninstallRun]
Filename: "schtasks"; Parameters: "/Delete /TN ""WPKG Service""   /F"; Flags: runhidden; RunOnceId: "DelService"
Filename: "schtasks"; Parameters: "/Delete /TN ""WPKG Sync task"" /F"; Flags: runhidden; RunOnceId: "DelSync"


