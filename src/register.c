#include "slp_port.h"

void RegReport(SLPHandle hslp __attribute__ ((unused)), SLPError errcode, void* cookie){
    *(SLPError*)cookie = errcode;
}

SLPBoolean reg(SLPHandle hslp, char* buffer){
  SLPError err;
  SLPError callbackerr;
  char* service_url;
  char* attributes;
  unsigned short* lifetime;

  service_url = buffer + strlen(buffer) + 1;
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
    sprintf(buffer, "error: %d", callbackerr);
    return(callbackerr);
  }

  sprintf(buffer, "ok");
  return SLP_TRUE;
}

SLPBoolean deregister(SLPHandle hslp, char* buffer){
  SLPError err;
  SLPError callbackerr;
  char* service_url;

  service_url = buffer + strlen(buffer) + 1;

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
