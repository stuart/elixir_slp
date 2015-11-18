#ifndef SLP_PORT_H

#define BUFFER_SIZE 4096
#define COMMAND_REGISTER 1
#define COMMAND_DEREGISTER 2
#define COMMAND_FIND_SERVICES 3
#define COMMAND_FIND_ATTRIBUTES 4

#if defined(DEBUG) && DEBUG > 0
 #define DEBUG_PRINT(fmt, ...) fprintf(stderr, "%s:%d:%s(): " fmt, \
    __FILE__, __LINE__, __func__, __VA_ARGS__)
#else
 #define DEBUG_PRINT(fmt, ...)
#endif

#include <slp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SLP_PORT_H
#endif
