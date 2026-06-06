#pragma once

#define BLUE    94
#define RED     91
#define YELLOW  93
#define GREEN   92
#define RESET   0
#define WHITE   97

#define DEBUG 0
#define FAIL_DEBUG 0

#include <stdio.h>

static inline int fail(char* arg) {
    (void)arg;
    printf("FAIL_DEBUG is set to 1; Returning 1\n");
    return 1;
}
