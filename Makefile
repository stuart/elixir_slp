CFLAGS= -g -O3 -pedantic -Wall -Wextra
LFLAGS= -lslp
SRC_DIR=src/
PRIV_DIR=priv/
OBJECTS=${PRIV_DIR}slp_port

all: ${OBJECTS}

${PRIV_DIR}slp_port: ${SRC_DIR}*.c
	gcc ${CFLAGS} ${LFLAGS} ${SRC_DIR}*.c -o ${OBJECTS}

clean:
	rm ${OBJECTS}
