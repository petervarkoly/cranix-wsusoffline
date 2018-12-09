# Copright (c) Peter Varkoly 
import salt
import os

#Unlocks the client
def do():
  if __grains__['os_family'] == 'Windows':
    os.system("net use W: \\\\install\\itool\\wsusoffline /persistent:no /user:ossreader ossreader")
    os.system("W:\client\cmd\DoUpdate.cmd /all /showlog")
    os.system("net use W: /delete /yes")
  else:
    return True
  return True

