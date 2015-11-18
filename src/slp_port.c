/*
  slp_port

  A small program to make SLP calls communicating with an Elixir/Erlang process.

*/
#include "slp_port.h"

int read_command(char *buf);
int write_command(char *buf, int length);
SLPBoolean reg(SLPHandle hslp, char* buffer);
SLPBoolean deregister(SLPHandle hslp, char* buffer);
SLPBoolean find_services(SLPHandle hslp, char* buffer);
SLPBoolean find_attributes(SLPHandle hslp, char* buffer);

int main()
{
    SLPError err;
    SLPHandle hslp;
    char *buffer;

    if((buffer = (char *)malloc(BUFFER_SIZE)) == NULL){
      fprintf(stderr, "Out of memory error.\n");
      exit(1);
    }

    err = SLPOpen(NULL,SLP_FALSE,&hslp);

    if(err != SLP_OK)
    {
      fprintf(stderr, "Cannot open SLP connection. %d\n", err);
      exit(err);
    }

    while (read_command(buffer) > 0) {
      switch(buffer[0]){
        case COMMAND_REGISTER :
          reg(hslp, buffer);
          break;
        case COMMAND_DEREGISTER :
          deregister(hslp, buffer);
          break;
        case COMMAND_FIND_SERVICES :
          find_services(hslp, buffer);
          break;
        case COMMAND_FIND_ATTRIBUTES :
          find_attributes(hslp, buffer);
          break;
        default :
          DEBUG_PRINT("Unknown command: %i\n", buffer[0]);
      }
      write_command(buffer, strlen(buffer));
    }

    SLPClose(hslp);
}
