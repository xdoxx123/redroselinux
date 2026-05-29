FS_DIR = filesystem
INITRAMFS_DIR = initramfs
OUTPUT_DIR = .

INITRAMFS_CPIO = $(OUTPUT_DIR)/initramfs.cpio
INITRAMFS_GZ = $(OUTPUT_DIR)/initramfs.cpio.gz
ISO = $(OUTPUT_DIR)/redrose_linux.iso

all: dep clean installer install-packages strip-bins squash-root initramfs iso vm
no-vm: dep clean installer squash-root initramfs iso

help:
	@echo "=> Run 'make' to compile"
	@echo "=> On Fedora, run 'make -f Makefile-fedora'"

dep:
	@echo "=> Checking dependencies..."
	@mkdir -p rootfs/filesystem/lib64
	@mkdir -p rootfs/filesystem/lib
	@mkdir -p rootfs/filesystem/usr/
	@mkdir -p rootfs/filesystem/usr/lib
	@mkdir -p rootfs/filesystem/usr/lib/grub
	@cp -p /lib64/ld-linux-x86-64.so.2 rootfs/filesystem/lib64/
	@for cmd in grub-mkrescue curl bash gzip gcc qemu-img qemu-system-x86_64 python3 cpio fakeroot xorriso; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo  "  => Found $$cmd  "; \
		else \
			echo "  => Missing $$cmd  "; \
			exit 1; \
		fi; \
	done;
	@echo ""
	@echo "  => Running rootfs/copy_syslibs.py"
	@python3 rootfs/copy_syslibs.py

initramfs: dep squash-root
	@echo "==> Building initramfs..."
	@bash -c 'mkdir -p initramfs/{proc,sys,mnt}'
	@test -f $(INITRAMFS_DIR)/bin/sgdisk || ( \
		echo "  -> $(INITRAMFS_DIR)/bin/sgdisk" && \
		curl -s -L -o $(INITRAMFS_DIR)/bin/sgdisk https://github.com/redroselinux/car-coreutils-repo/raw/refs/heads/main/sgdisk-static-bin && \
		chmod +x $(INITRAMFS_DIR)/bin/sgdisk \
	)
	@test -f initramfs/bin/mkfs.vfat || ( \
		echo "  -> initramfs/bin/mkfs.vfat" && \
		curl -s -L -o initramfs/bin/mkfs.vfat https://github.com/redroselinux/car-coreutils-repo/raw/refs/heads/main/mkfs.fat && \
		chmod +x initramfs/bin/mkfs.vfat \
	)
	@chmod +x $(INITRAMFS_DIR)/bin/init
	@ln -sf bin/init $(INITRAMFS_DIR)/init
	@chmod +x $(INITRAMFS_DIR)/bin/*
	@chmod +x rootfs/filesystem/bin/*
	@chmod +x rootfs/filesystem/bin/sh
	@chmod +x $(INITRAMFS_DIR)/init
	@cd $(INITRAMFS_DIR) && find . -print0 | cpio --null -o -H newc > ../$(INITRAMFS_CPIO)
	@gzip -f $(INITRAMFS_CPIO)
	@echo "  -> $(INITRAMFS_GZ)"

strip-bins: dep install-packages
	@echo "==> Stripping binaries..."
	@find rootfs/filesystem/bin rootfs/filesystem/*/bin rootfs/filesystem/*/lib* -type f -exec file {} \; | \
	grep -E 'ELF .* (executable|shared object)' | \
	cut -d: -f1 | \
	while read -r f; do \
		echo "  => $$f"; \
		strip --strip-unneeded "$$f" || true; \
	done

install-packages: dep
	@echo "==> Installing packages..."
	@rm -f rootfs/filesystem/etc/redrose-strap
	@while IFS= read -r line; do \
	    echo "$$line" | python3 rootfs/strap.py; \
	done < rootfs/rootfs_strap_packages
	@echo "  -> rootfs/filesystem/etc/repro.car"

squash-root: dep
	@echo "=> Merging /usr paths"
	@mkdir -p rootfs/filesystem/usr/bin rootfs/filesystem/usr/sbin rootfs/filesystem/usr/lib rootfs/filesystem/usr/lib64
	@echo "  ==> Copying /bin"
	@[ -d rootfs/filesystem/bin ]   && cp -a rootfs/filesystem/bin/* rootfs/filesystem/usr/bin/ >/dev/null 2>&1 || true
	@echo "  ==> Copying /sbin"
	@[ -d rootfs/filesystem/sbin ]  && cp -a rootfs/filesystem/sbin/* rootfs/filesystem/usr/sbin/ >/dev/null 2>&1 || true
	@echo "  ==> Copying /lib"
	@[ -d rootfs/filesystem/lib ]   && cp -a rootfs/filesystem/lib/* rootfs/filesystem/usr/lib/ >/dev/null 2>&1 || true
	@echo "  ==> Copying /lib64"
	@[ -d rootfs/filesystem/lib64 ] && cp -a rootfs/filesystem/lib64/* rootfs/filesystem/usr/lib64/ >/dev/null 2>&1 || true
	@echo "  ==> Removing original / paths"
	@rm -rf rootfs/filesystem/bin rootfs/filesystem/sbin rootfs/filesystem/lib rootfs/filesystem/lib64
	@echo "  ==> Symlinking new /usr paths"
	@ln -s usr/bin   rootfs/filesystem/bin
	@ln -s usr/sbin  rootfs/filesystem/sbin
	@ln -s usr/lib   rootfs/filesystem/lib
	@ln -s usr/lib64 rootfs/filesystem/lib64
	@echo "=> Symlinking /proc/mounts to /etc/mtab"
	@ln -sf /proc/mounts rootfs/filesystem/etc/mtab
	@echo "=> Installing car"
	@test -f rootfs/filesystem/bin/car || ( \
		echo "  -> rootfs/filesystem/bin/car" && \
		curl -s -L -o rootfs/filesystem/bin/car https://github.com/redroselinux/car/releases/latest/download/car && \
		chmod +x rootfs/filesystem/bin/car \
	)
	@chmod +x rootfs/filesystem/sbin/reload-hostname-daemon
	@mkdir -p rootfs/filesystem/lib64
	@mkdir -p rootfs/filesystem/lib
	@mkdir -p rootfs/filesystem/usr/
	@mkdir -p rootfs/filesystem/usr/lib
	@mkdir -p rootfs/filesystem/usr/lib/grub
	@echo "=> Copying kernel image"
	@cp linux-7.0.3 rootfs/filesystem/boot/vmlinuz-7.0.3
	@ln -sf vmlinuz-7.0.3 rootfs/filesystem/boot/vmlinuz
	@cp linux-7.0.3 filesystem/boot/vmlinuz-7.0.3
	@ln -sf vmlinuz-7.0.3 filesystem/boot/vmlinuz
	@echo "=> Creating rootfs tgz..."
	@echo "  ==> Creating uncompressed rootfs.tar"
	@fakeroot tar -cpf initramfs/rootfs.tar -C rootfs filesystem
	@echo "  ==> Compressing rootfs.tar"
	@gzip -f initramfs/rootfs.tar
	@rm -f initramfs/rootfs.tar
	@echo "  -> initramfs/rootfs.tar.gz"

iso: squash-root initramfs
	@echo "=> Building ISO..."
	@echo "  ==> Copying initramfs"
	@cp $(INITRAMFS_GZ) $(FS_DIR)/boot/
	@echo "  ==> Creating ISO with grub-mkrescue"
	@grub-mkrescue -o $(ISO) $(FS_DIR) --xorriso /usr/bin/xorriso >/dev/null
	@echo "  -> $(ISO)"

installer: dep
	@$(CC) src/installer/main.c -o initramfs/bin/install -static 2>&1
	@echo "  -> initramfs/bin/install"

run-installer:
	@echo "=> Running installer..."
	initramfs/bin/install

clean:
	@echo "=> Cleaning..."
	@rm -f rootfs/filesystem/etc/repro.car
	@rm -f $(INITRAMFS_CPIO) $(INITRAMFS_GZ) $(ISO)
	@rm -f initramfs/bin/install filesystem/boot/initramfs.cpio.gz filesystem/boot/vmlinuz-7.0.3 redrose_linux.qcow2
	@rm -f rootfs/filesystem/boot/initramfs_rootfs.cpio.gz rootfs/filesystem/boot/vmlinuz-7.0.3
	@rm -f initramfs_rootfs.cpio.gz initramfs_rootfs.cpio initramfs/rootfs.sqsh.
	@echo "  => Done"

clean-downloads:
	@echo "=> Cleaning downloads..."
	@rm -f $(INITRAMFS_DIR)/bin/sgdisk

clean-all: clean clean-downloads
bare-build: installer squash-root initramfs iso
no-clean: installer squash-root initramfs iso vm
short-build: installer squash-root initramfs iso vm

installed-vm: ./redrose_linux.qcow2
	@echo "=> Starting VM from disk..."
	@qemu-system-x86_64 -drive file=redrose_linux.qcow2,format=qcow2 -m 2048 -boot c -enable-kvm -smp $$(nproc) -display gtk

vm: ./redrose_linux.iso
	@echo "  -> redrose_linux.qcow2"
	@qemu-img create -f qcow2 redrose_linux.qcow2 1G
	@echo "  => Starting VM from ISO..."
	@qemu-system-x86_64 -cdrom $(ISO) -drive file=redrose_linux.qcow2,format=qcow2 -m 2048 -boot d -enable-kvm -smp $$(nproc) -display gtk

.PHONY: all initramfs iso clean vms installer run-installer clean-downloads clean-all bare-build no-clean vm help installed-vm squash-root dep
