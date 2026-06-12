#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/reboot.h>
#include "tui.h"
#include "backend.h"


void shutdown_computer() {
    sync(); reboot(RB_AUTOBOOT);
}

void error() {
    set_text_color(RED);
    printf("\nInstallation has failed. ");
    set_text_color(RESET);
    printf("Please report the error at our Github Issues: ");
    set_text_color(BLUE);
    printf("https://github.com/redroselinux/redroselinux/issues\n");
    set_text_color(RESET);
    printf("\n");
    enable_echo();


    char buf[8];
    printf("Do you want to restart the installer or shutdown? [R/s] ");
    if (fgets(buf, sizeof(buf), stdin)) {
        if (buf[0] == 'r' || buf[0] == 'R') {
            execv("/bin/install", NULL);
            perror("execv");
            _exit(1);
        } else if (buf[0] == 's' || buf[0] == 'S') {
            shutdown_computer();
        } else {
            execv("/bin/install", NULL);
            perror("execv");
            _exit(1);
        }
    }
}

int run_installation_step(int (*operation)(char*),
    char* arg,
    const char* step_name,
    int is_destructive) {
        set_text_color(is_destructive ? RED : GREEN);
        printf("* ");
        set_text_color(RESET);
        printf("\e[1m%s\e[0m\n", step_name);
        fflush(stdout);

        if (operation(arg) != 0) {
            install_failed();
            error();
            return -1;
        }

        fputs("\n", stdout);
        return 0;
}

int main() {
    // Run checks
    printf("Running checks...\n");
    list_dev();

    // Show main header
    clear();
    main_header();

    // Localization
    clear();
    char* keyboard = localization_header();
    char* lang = language();
    char* time = timezone();
    enter_continue();

    // Disk
    clear();
    char* drive = disk_header();
    if (!drive) {
        set_text_color(RED);
        printf("No drive selected. Exiting installer.\n");
        set_text_color(RESET);
        enter_continue();
        free(keyboard);
        free(lang);
        free(time);
        return 0;
    }

    // User creation
    clear();
    char* username = user_creation();
    char* userpassword = user_password();
    if (!userpassword) {
        userpassword = malloc(100);
        if (!userpassword) { perror("malloc"); exit(1); }
        strcpy(userpassword, "redrose\n");
    }
    if (userpassword[0] == '\n' || userpassword[0] == '\0') {
        set_text_color(RED);
        printf("REMEMBER THE DEFAULT PASSWORD ABOVE!\n");
        set_text_color(RESET);
    }

    char* rootpassword = root_password();
    if (!rootpassword) {
        rootpassword = malloc(100);
        if (!rootpassword) { perror("malloc"); exit(1); }
        strcpy(rootpassword, "redrose\n");
    }
    if (rootpassword[0] == '\n' || rootpassword[0] == '\0') {
        set_text_color(RED);
        printf("REMEMBER THE DEFAULT PASSWORD ABOVE!\n");
        set_text_color(RESET);
    }

    char* host_name = hostname();
    int propriertary = proprietary_enable();
    enter_continue();

    // Ask for confirmation
    clear();
    installing_header();
    printf("\n");
    separator();
    printf("\nInstalling to %s. Are you sure? (Y/n): ", drive);

    char confirm[4];
    fgets(confirm, sizeof(confirm), stdin);

    if (confirm[0] == 'y' || confirm[0] == '\n') {
        clear();
        disable_echo();

        int success = 1;
        if (FAIL_DEBUG == 1)
            if (run_installation_step(fail, "", "FAIL_DEBUG is on!", 1) < 0) success = 0;
        if (success && run_installation_step(wipe_drive,   drive, "Erasing the drive!", 1) < 0)    success = 0;
        if (success && run_installation_step(makefs,       drive, "Making filesystems!", 1) < 0)   success = 0;
        if (success && run_installation_step(copy_root,    drive, "Copying root!", 1) < 0)         success = 0;
        if (success && run_installation_step(install_utils, "",   "Installing utilities!", 0) < 0) success = 0;
        if (success) {
            set_text_color(GREEN); printf("* "); set_text_color(RESET);
            printf("\e[1mSetting up user accounts!\e[0m\n"); fflush(stdout);
            if (create_users(username, userpassword, rootpassword) != 0) {
                install_failed(); error();
                success = 0;
            } else {
                fputs("\n", stdout);
            }
        }
        if (success && run_installation_step(install_grub, drive, "Installing GRUB!", 1) < 0) success = 0;
        if (success && propriertary == 0)
            if (run_installation_step(propriertary_,                     "",        "Enabling propriertary software!", 0) < 0)   success = 0;
        if (success && run_installation_step(localhost,                  host_name, "Setting hostname!", 0) < 0)                 success = 0;
        if (success && run_installation_step(init_car,                   "",        "Initializing Car!", 0) < 0)                 success = 0;
        if (success && run_installation_step(regenerate_initramfs_fstab, "",        "Regenerating initramfs and fstab!", 1) < 0) success = 0;
        if (success && run_installation_step(uuid_drive,                 "/mnt",    "Assigning UUID to drive!", 1) < 0)          success = 0;
        if (success && run_installation_step(patch,                      drive,     "Running patches!", 1) < 0)                  success = 0;
        enable_echo();

        // Ask the user if they want to open a shell or chroot (backend.c:chroot_)
        if (success) {
            if (run_installation_step(chroot_, "", "Choose an option!", 0) < 0) success = 0;
        }

        // Unmount /mnt
        if (success) {
            disable_echo();
            if (run_installation_step(umount_detach, "/mnt", "Unmounting root!", 0) < 0) success = 0;
            enable_echo();
        }

        if (success) {
            installed_header();
            printf("Thank you for installing the Redrose Linux alpha! Reboot to your new system.\n");
            printf("Please report bugs on Github Issues: ");
            set_text_color(BLUE);
            printf("https://github.com/redroselinux/redroselinux/issues\n");
            set_text_color(RESET);
            printf("\n");
            set_text_color(YELLOW);
            printf(
                "If you are on a VM, after the VM restarts, pick \"Boot existing OS\"\n"
                "You can also remove the CD-ROM from the VM. If you see no such option,"
                " you can ignore this warning.\n\n"
            );
            set_text_color(RESET);
            separator();
            printf("\n");
            enter_continue();
            shutdown_computer();
        }
    } else {
        printf("Restart installer? [Y/n]: ");

        char buf[8];
        if (fgets(buf, sizeof(buf), stdin)) {
            if (buf[0] == 'n' || buf[0] == 'N') {
                printf("Reboot or shutdown? [R/s]: ");
                if (fgets(buf, sizeof(buf), stdin)) {
                    if (buf[0] == 's' || buf[0] == 'S') {
                        printf("Shutting down in 5 seconds...");
                        fflush(stdout);
                        sleep(5);
                        reboot(RB_POWER_OFF);
                    } else {
                        printf("Rebooting in 5 seconds...");
                        fflush(stdout);
                        sleep(5);
                        reboot(RB_AUTOBOOT);
                    }
                }
            } else {
                clear();
                execl("/bin/install", "install", NULL);
                perror("execl");
                _exit(1);
            }
        }
    }

cleanup_free:
    free(keyboard);
    free(lang);
    free(time);
    free(drive);
    free(username);
    free(userpassword);
    free(rootpassword);
    free(host_name);
    return 0;
}
