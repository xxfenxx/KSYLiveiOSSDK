#ifndef _KSY_RTMP_H_
#define _KSY_RTMP_H_

#include "rtmp.h"//<librtmp/rtmp.h>
#include "log.h"//<librtmp/log.h>
#include <pthread.h>

#define READ_FLAGS 1
#define WRITE_FLAGS 2

#define ERROR_UNKNOWN (-1)
#define ERROR_CONNECT (-2)
#define ERROR_SETUP   (-3)
#define ERROR_MEM     (-4)

#define KSY_RTMP_LOG_TAG "RTMP"

typedef struct LibRTMPContext {
    RTMP rtmp;
    char *app;
    char *conn;
    char *subscribe;
    char *playpath;
    char *tcurl;
    char *flashver;
    char *swfurl;
    char *swfverify;
    char *pageurl;
    char *client_buffer_time;
    int live;
    char *filename;
    char* temp_filename;
    int buffer_size;
    int fd;
} LibRTMPContext;

int rtmp_init(LibRTMPContext **ctx);
int rtmp_unit(LibRTMPContext **ctx);
int rtmp_seturl(LibRTMPContext *ctx,  char* url);
int rtmp_open(LibRTMPContext *ctx,  int flags);
int rtmp_write(LibRTMPContext *ctx, const char *buf, int size);
int rtmp_read(LibRTMPContext *ctx, char *buf, int size);
int rtmp_close(LibRTMPContext *ctx);
int rtmp_read_pause(LibRTMPContext *ctx, int pause);
int64_t rtmp_read_seek(LibRTMPContext *ctx, int64_t timestamp);

#endif // _KSY_RTMP_H_
