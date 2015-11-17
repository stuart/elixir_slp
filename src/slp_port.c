/*
  slp_port

  A small program to make SLP calls communicating with an Elixir/Erlang process.

*/
#include <slp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 4096
#define COMMAND_REGISTER 1
#define COMMAND_DEREGISTER 2
#define COMMAND_FIND_SERVICES 3
#define COMMAND_FIND_ATTRIBUTES 4

#define DEBUG 1

#if defined(DEBUG) && DEBUG > 0
 #define DEBUG_PRINT(fmt, ...) fprintf(stderr, "%s:%d:%s(): " fmt, \
    __FILE__, __LINE__, __func__, __VA_ARGS__)
#else
 #define DEBUG_PRINT(fmt, ...)
#endif

int read_command(char *buf);
int write_command(char *buf, int length);

void RegReport(SLPHandle hslp __attribute__ ((unused)), SLPError errcode, void* cookie){
    *(SLPError*)cookie = errcode;
}

SLPBoolean URLCallback(SLPHandle hslp __attribute__ ((unused)),
                      const char* service_url,
                      unsigned short lifetime __attribute__ ((unused)),
                      SLPError err, void* urls){
  if(err == SLP_OK || err == SLP_LAST_CALL){
    DEBUG_PRINT("Service URL     = %s\n",service_url);
    DEBUG_PRINT("Service Timeout = %i\n",lifetime);

    if(service_url != NULL && strlen(urls) + strlen(service_url) + 6 < BUFFER_SIZE){
      strncat(urls, service_url, strlen(service_url));
      strncat(urls, "\n", 1);
    }
  }
  else
  {
    *(SLPError*)urls = err;
  }

  return SLP_TRUE;
}

SLPBoolean attrCallback(SLPHandle hslp, const char* attrlist, SLPError err, void* attributes){
  DEBUG_PRINT("err = %d\n", err);
  if(err == SLP_OK || err == SLP_LAST_CALL){
    DEBUG_PRINT("Attributes = %s\n", attrlist);
    if(attrlist != NULL && strlen(attributes) + strlen(attrlist) + 6 < BUFFER_SIZE){
      strncat(attributes, attrlist, strlen(attrlist));
      strncat(attributes, "\n", 1);
    }
  }
  else{
    *(SLPError*)attributes = err;
  }

  return SLP_TRUE;
}

SLPBoolean reg(SLPHandle hslp, char* buffer){
  SLPError err;
  SLPError callbackerr;
  char* service_url;
  char* attributes;
  unsigned short* lifetime;

  service_url = buffer + strlen((char *)buffer) + 1;
  attributes = service_url + strlen(service_url) + 1;
  lifetime = (unsigned short*)(attributes + strlen(attributes) + 1);

  err = SLPReg(
    hslp,
    service_url,
    ntohs(*lifetime),
    0,
    attributes,
    SLP_TRUE,
    RegReport,
    &callbackerr);

  if(err != SLP_OK){
    sprintf(buffer, "error: %d", err);
    return(err);
  }

  if(callbackerr != SLP_OK){
    return(callbackerr);
  }

  sprintf(buffer, "ok");
  return SLP_TRUE;
}

SLPBoolean deregister(SLPHandle hslp, char* buffer){
  SLPError err;
  SLPError callbackerr;
  char* service_url;

  service_url = buffer + strlen((char *)buffer) + 1;

  err = SLPDereg(
    hslp,
    service_url,
    RegReport,
    &callbackerr);

  if(err != SLP_OK){
    sprintf(buffer, "error: %d", err);
    return(err);
  }

  if(callbackerr != SLP_OK){
    sprintf(buffer, "error: %d", callbackerr);
    return(callbackerr);
  }

  sprintf(buffer, "ok");
  return SLP_TRUE;
}

SLPBoolean find_services(SLPHandle hslp, char* buffer){
  SLPError err;
  char* service_type;
  char* scope_list;
  char* filter;
  char* urls;

  if((urls = (char *)calloc(BUFFER_SIZE, 1)) == NULL){
    fprintf(stderr, "Out of memory error.\n");
    exit(1);
  }
  service_type = buffer + strlen((char *)buffer) + 1;
  scope_list = service_type + strlen(service_type) + 1;
  filter = scope_list + strlen(scope_list) + 1;

  err = SLPFindSrvs(
    hslp,
    service_type,
    scope_list,
    filter,
    URLCallback,
    urls);

  sprintf(buffer, "ok: ");
  strncat(buffer, urls, strlen(urls));
  free(urls);
  return err;
}

SLPBoolean find_attributes(SLPHandle hslp, char* buffer){
  SLPError err;
  char* service_url;
  char* scope_list;
  char* attrids;
  char* attributes;

  if((attributes = (char *)calloc(BUFFER_SIZE, 1)) == NULL){
    fprintf(stderr, "Out of memory error.\n");
    exit(1);
  }

  service_url = buffer + strlen((char *)buffer) + 1;
  attrids = service_url + strlen(service_url) + 1;
  scope_list = attrids + strlen(attrids) + 1;

  err = SLPFindAttrs(
    hslp,
    service_url,
    scope_list,
    attrids,
    attrCallback,
    attributes );

  DEBUG_PRINT("Find Attributes %s\n", attrids);

  sprintf(buffer, "ok: ");
  strncat(buffer, attributes, strlen(attributes));
  free(attributes);
  return err;
}

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
