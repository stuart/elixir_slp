#include "slp_port.h"

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

SLPBoolean attrCallback(SLPHandle hslp __attribute__ ((unused)),
                        const char* attrlist,
                        SLPError err,
                        void* attributes){
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

SLPBoolean find_services(SLPHandle hslp, char* buffer){
  SLPError err;
  char* service_type;
  char* scope_list;
  char* filter;
  char* urls;

  if((urls = (char *)calloc(BUFFER_SIZE, 1)) == NULL){
    fprintf(stderr, "%s %d Out of memory error.\n", __FILE__, __LINE__);
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
