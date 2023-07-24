#ifndef _COMMON_H__
#define _COMMON_H__

#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <stdarg.h>
#include <assert.h>
#include <stdint.h>
#include <climits>

//especially for linux
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <syslog.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <libgen.h>
#include <pthread.h>
#include <sched.h>
#include <iconv.h> 
#include <signal.h>

//ptpd related
#include "datatypes.h"
#include "ptpd_dep.h"
#include "ptp_memmap.h"
#include "msg.h"
#include "net.h"
#include "servo.h"
#include "startup.h"
#include "sys.h"
#include "transport.h"
#include "ptp_timer.h"
#include "arith.h"
#include "bmc.h"
#include "display.h"
#include "management.h"
#include "protocol.h"
#include "ptpd.h"
#include "controller.h"

/* NOTE: this macro can be refactored into a function */ 
#define XMALLOC(ptr,size) \
    if(!((ptr)= (Octet*)malloc(size))) { \
        PERROR("failed to allocate memory"); \
        this->m_pApp->m_ptr_startup->ptpdShutdown(ptpClock); \
        exit(1); \
    }

#define IS_SET(data, bitpos) \
    ((data & ( 0x1 << bitpos )) == (0x1 << bitpos))

#define SET_FIELD(data, bitpos) \
    data << bitpos
#ifndef min
#define min(a,b)     (((a)<(b))?(a):(b))
#endif
#ifndef max
#define max(a,b)     (((a)>(b))?(a):(b))
#endif

#endif // _COMMON_H__




