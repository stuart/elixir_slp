MKDIR_P = mkdir -p

ifeq (${MIX_ENV},prod)
	DEBUG_FLAG=0
else
	DEBUG_FLAG=1
endif

INC_DIR=inc/
SRC_DIR=src/
PRIV_DIR=priv/

CFLAGS= -g -O3 -pedantic -Wall -Wextra -I ${INC_DIR} -D DEBUG=${DEBUG_FLAG}
LFLAGS= -lslp

OBJECTS=${PRIV_DIR}slp_port

.PHONY: directories

all: directories ${OBJECTS}

directories: ${PRIV_DIR}

${PRIV_DIR}:
	${MKDIR_P} ${PRIV_DIR}

${PRIV_DIR}slp_port: ${SRC_DIR}*.c
	gcc ${CFLAGS} ${LFLAGS} ${SRC_DIR}*.c -o ${OBJECTS}

clean:
	rm ${OBJECTS}
