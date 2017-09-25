import os, stat

for root, folders, files in os.walk('.'):
    for file in files:
        if file == "desktop.ini":
            fullpath = os.path.join(root, file)
            isfile = os.path.isfile(fullpath)
            if not isfile:
                continue
            os.chmod( fullpath, stat.S_IWRITE )
            print(isfile, fullpath)
            os.remove(fullpath)
        
