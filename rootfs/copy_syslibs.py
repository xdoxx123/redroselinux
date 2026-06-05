import os
import sys

# was ai used in this script? no

os.system("cp /usr/sbin/grub-install rootfs/filesystem/bin/")

if not os.path.exists("libcp"):
    print("=> Downloading libcp...")
    os.system(
        "curl -# -L -o libcp"
        "https://github.com/redroselinux/libcp/releases/download/v0.1/libcp"
    )
    os.system("chmod +x libcp")
else:
    pass

def execc(command):
    if os.system(command) != 0:
        print("failed to run command")
        sys.exit(1)

execc("./libcp rootfs/filesystem/bin/grub-install rootfs/filesystem")
execc("cp /usr/lib/grub rootfs/filesystem/lib/ -r")
execc("mkdir -p rootfs/filesystem/usr/lib/")
execc("cp /usr/lib/grub rootfs/filesystem/usr/lib/ -r")
