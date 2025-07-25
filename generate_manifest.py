# This script generates an install manifest for the LorielleOS Mod project.

import os
excluded_files = {'README.txt', 
           'generate_manifest.py', 
           'install_manifest.txt',
           'bootstrap.lua',
           'disk_imager.lua',
           'license.txt',
           '.gitignore',}

excluded_directories = {'.git',}

def checksum(path):
    with open(path, 'rb') as f:
        return sum(f.read()) % (2**32)

with open('install_manifest.txt', 'w') as out:
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in excluded_directories]
        # Exclude files in excluded_directories
        for file in files:
            if file not in excluded_files:
                path = os.path.relpath(os.path.join(root, file))
                if path.startswith('.' + os.sep):
                    path = path[2:]
                out.write(path + '\n')