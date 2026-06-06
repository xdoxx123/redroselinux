#pragma once

#include "installer.h"

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
int proprietary_enable(void);
void enable_echo(void);
void disable_echo(void);
int install_utils_ui(void);
