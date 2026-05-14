#pragma once

// ANSI color codes
#define BLUE    94
#define RED     91
#define YELLOW  93
#define GREEN   92
#define RESET   0
#define WHITE   97

// If you are developing, enable this by running:
// python3 enable_debug.py
// This lets you view some extra logs and also run commands on the Press ENTER prompts.
// Make sure not to push this with 1 as the value.
#define DEBUG 0
// same as above - this breaks the installer on purpose
#define FAIL_DEBUG 0
#include <stdio.h>
int fail(char*) {
    printf("FAIL_DEBUG is set to 1; Returning 1\n");
    return 1;
}

int set_text_color(unsigned color);
int clear(void);
void enter_continue(void);
void separator(void);
void main_header(void);
void installing_header(void);
void installed_header(void);
void install_failed(void);
char *localization_header(void);
char *language(void);
char *timezone(void);
char *disk_header(void);
char *user_creation(void);
char *user_password(void);
char *root_password(void);
char *hostname(void);
char *proprietary_enabled(void);
int list_dev(void);
int list_devices(char *drives[64], int max);
char *get_partition(const char *drive, int partnum);
int wipe_drive(char *drive);
int makefs(char *drive);
int install_grub(char *drive);
void enable_echo(void);
void disable_echo(void);
int install_utils_ui();
