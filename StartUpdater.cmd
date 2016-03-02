@echo off
REM ***** Konfiguration ******
set Freigabe=\\install\itool\wsusoffline
set NetDrive=W:


:Update
if not exist %NetDrive% (
net use %NetDrive% %Freigabe%  /persistent:no
)

:WinUpdate
echo Starte Windows-Update
%NetDrive%
cd \
echo %DATE% %TIME% %COMPUTERNAME% Win-Update>> log\UpdateLog.txt
cd client\cmd
call DoUpdate.cmd /all /showlog
rem /updatecpp /updatercerts /updatedx /instwmf /instmsse /showlog

REM /autoreboot funktioniert nur, wenn der anonyme Zugriff auf das Netzwerklaufwerken möglich ist

echo Update durchgefuehrt

:unmount
if exist %NetDrive% (
%Systemdrive%
net use %NetDrive% /delete /yes
exit /B
)




