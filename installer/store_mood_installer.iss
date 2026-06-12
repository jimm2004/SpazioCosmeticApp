#define MyAppName "Store Mood"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Store Mood"
#define MyAppExeName "store_mood_app.exe"

[Setup]
AppId={{A7F5D8D2-9C44-4E2A-9D88-8F2B63A12026}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=StoreMood_Installer_v{#MyAppVersion}
; SetupIconFile=app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}