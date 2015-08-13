#include "ksyrtmp.h"
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int rtmp_init(LibRTMPContext **ctx)
{
    *ctx = (LibRTMPContext*)malloc(sizeof(LibRTMPContext));
    memset(*ctx,0,sizeof(LibRTMPContext));
    (*ctx)->client_buffer_time = strdup("3000");
    return 0;
}

int rtmp_unit(LibRTMPContext **ctxp)
{
    LibRTMPContext * ctx = *ctxp;
    if(ctx==NULL)
        return 0;
    if(ctx->app)                                                        free(ctx->app);
    if(ctx->conn)                                                     free(ctx->conn);
    if(ctx->subscribe)                                        free(ctx->subscribe);
    if(ctx->playpath)                                           free(ctx->playpath);
    if(ctx->tcurl)                                                   free(ctx->tcurl);
    if(ctx->flashver)                                           free(ctx->flashver);
    if(ctx->swfurl)                                                free(ctx->swfurl);
    if(ctx->swfverify)                                        free(ctx->swfverify);
    if(ctx->pageurl)                                             free(ctx->pageurl);
    if(ctx->client_buffer_time)                free(ctx->client_buffer_time);
    if(ctx->filename)                                          free(ctx->filename);
    if(ctx->temp_filename)                             free(ctx->temp_filename);
    free(ctx);
    *ctxp = NULL;
    return 0;
}

static void rtmp_log(int level, const char *fmt, va_list args)
{
    return ;
}

int rtmp_seturl(LibRTMPContext *ctx,  char* url)
{
    RTMP *r = &ctx->rtmp;
    RTMP_Close(r);
    ctx->filename = strdup(url);
    return 0;
}

int rtmp_close(LibRTMPContext *ctx)
{
    RTMP *r = &ctx->rtmp;
    RTMP_Close(r);
    free(ctx->temp_filename);
    return 0;
}

int rtmp_open(LibRTMPContext *ctx , int flags)
{
    RTMP *r = &ctx->rtmp;
    int rc = 0;
    char *filename = NULL;
    if(ctx->filename==NULL)
        return -1;
    int len = strlen(ctx->filename) + 1;

    RTMP_LogSetLevel(RTMP_LOGERROR);
    RTMP_LogSetCallback(rtmp_log);

    if (ctx->app)      len += strlen(ctx->app)      + sizeof(" app=");
    if (ctx->tcurl)    len += strlen(ctx->tcurl)    + sizeof(" tcUrl=");
    if (ctx->pageurl)  len += strlen(ctx->pageurl)  + sizeof(" pageUrl=");
    if (ctx->flashver) len += strlen(ctx->flashver) + sizeof(" flashver=");

    if (ctx->conn) {
        char *sep, *p = ctx->conn;
        int options = 0;

        while (p) {
            options++;
            p += strspn(p, " ");
            if (!*p)
                break;
            sep = strchr(p, ' ');
            if (sep)
                p = sep + 1;
            else
                break;
        }
        len += options * sizeof(" conn=");
        len += strlen(ctx->conn);
    }

    if (ctx->playpath)
        len += strlen(ctx->playpath) + sizeof(" playpath=");
    if (ctx->live)
        len += sizeof(" live=1");
    if (ctx->subscribe)
        len += strlen(ctx->subscribe) + sizeof(" subscribe=");

    if (ctx->client_buffer_time)
        len += strlen(ctx->client_buffer_time) + sizeof(" buffer=");

    if (ctx->swfurl || ctx->swfverify) {
        len += sizeof(" swfUrl=");

        if (ctx->swfverify)
            len += strlen(ctx->swfverify) + sizeof(" swfVfy=1");
        else
            len += strlen(ctx->swfurl);
    }

    if (!(ctx->temp_filename = filename = malloc(len)))
        return ERROR_MEM;

    strlcpy(filename, ctx->filename, len);
    if (ctx->app) {
        strlcat(filename, " app=", len);
        strlcat(filename, ctx->app, len);
    }
    if (ctx->tcurl) {
        strlcat(filename, " tcUrl=", len);
        strlcat(filename, ctx->tcurl, len);
    }
    if (ctx->pageurl) {
        strlcat(filename, " pageUrl=", len);
        strlcat(filename, ctx->pageurl, len);
    }
    if (ctx->swfurl) {
        strlcat(filename, " swfUrl=", len);
        strlcat(filename, ctx->swfurl, len);
    }
    if (ctx->flashver) {
        strlcat(filename, " flashVer=", len);
        strlcat(filename, ctx->flashver, len);
    }
    if (ctx->conn) {
        char *sep, *p = ctx->conn;
        while (p) {
            strlcat(filename, " conn=", len);
            p += strspn(p, " ");
            if (!*p)
                break;
            sep = strchr(p, ' ');
            if (sep)
                *sep = '\0';
            strlcat(filename, p, len);

            if (sep)
                p = sep + 1;
        }
    }
    if (ctx->playpath) {
        strlcat(filename, " playpath=", len);
        strlcat(filename, ctx->playpath, len);
    }
    if (ctx->live)
        strlcat(filename, " live=1", len);
    if (ctx->subscribe) {
        strlcat(filename, " subscribe=", len);
        strlcat(filename, ctx->subscribe, len);
    }
    if (ctx->client_buffer_time) {
        strlcat(filename, " buffer=", len);
        strlcat(filename, ctx->client_buffer_time, len);
    }
    if (ctx->swfurl || ctx->swfverify) {
        strlcat(filename, " swfUrl=", len);

        if (ctx->swfverify) {
            strlcat(filename, ctx->swfverify, len);
            strlcat(filename, " swfVfy=1", len);
        } else {
            strlcat(filename, ctx->swfurl, len);
        }
    }

    RTMP_Init(r);
    if (!RTMP_SetupURL(r, filename)) {
        rc = ERROR_SETUP;
        goto fail;
    }

   // if (flags & WRITE_FLAGS)
        RTMP_EnableWrite(r);

    if (!RTMP_Connect(r, NULL) || !RTMP_ConnectStream(r, 0)) {
        rc = ERROR_CONNECT;
        goto fail;
    }
/*
    if (ctx->buffer_size >= 0 && (flags & WRITE_FLAGS)) {
        int tmp = ctx->buffer_size;
        setsockopt(r->m_sb.sb_socket, SOL_SOCKET, SO_SNDBUF, &tmp, sizeof(tmp));
    }
*/
    return 0;
fail:
    //free(ctx->temp_filename);
    if (rc)
        RTMP_Close(r);

    return rc;
}

int rtmp_write(LibRTMPContext *ctx , const char *buf, int size)
{
    RTMP *r = &ctx->rtmp;
    return RTMP_Write(r, buf, size);
}

int rtmp_read(LibRTMPContext *ctx , char *buf, int size)
{
    RTMP *r = &ctx->rtmp;
    return RTMP_Read(r, buf, size);
}

int rtmp_read_pause(LibRTMPContext *ctx, int pause)
{
    RTMP *r = &ctx->rtmp;

    if (!RTMP_Pause(r, pause))
        return ERROR_UNKNOWN;
    return 0;
}

int64_t rtmp_read_seek(LibRTMPContext *ctx, int64_t timestamp)
{
    RTMP *r = &ctx->rtmp;

    if (!RTMP_SendSeek(r, timestamp))
        return ERROR_UNKNOWN;
    return timestamp;
}
