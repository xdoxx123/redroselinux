#pragma once

#include "installer.h"
#include "drive_uuid.h"

int list_dev(void);
int list_devices(char *drives[64], int max);
char *get_partition(const char *drive, int partnum);
int wipe_drive(char *drive);
int makefs(char *drive);
int copy_root(char *drive);
int create_users(char *username, char *password, char *root_password);
int install_grub(char *drive);
int install_utils(char *_);
int propriertary_(char *_);
int localhost(char *name);
int init_car(char *_);
int regenerate_initramfs_fstab(char *_);
int patch(char *drive);
int chroot_(char *h);
int umount_detach(char *path);
int detect_efi(void);
int sanitize_input(char *input);
