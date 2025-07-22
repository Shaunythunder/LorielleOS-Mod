import os

print("-- Auto-generated download script for floppy /mnt/efe")
for root, dirs, files in os.walk('.'):
    for dir in dirs:
        path = os.path.join(root, dir).replace('\\', '/').replace('./', '')
        if path:
            print(f'os.execute("mkdir -p /mnt/efe/{path}")')
for root, dirs, files in os.walk('.'):
    for file in files:
        path = os.path.join(root, file).replace('\\', '/').replace('./', '')
        print(f'os.execute("wget http://localhost:8000/{path} /mnt/efe/{path}")')