/**
 * @file   ptpd_dep.h
 * 
 * @brief  External definitions for inclusion elsewhere.
 * 
 * 
 */

#ifndef PTPD_DEP_H_
#define PTPD_DEP_H_

#define PTPD_TLM_SIM       //SystemC TLM simulation

#define RUNTIME_DEBUG

#ifdef RUNTIME_DEBUG
#undef PTPD_DBGV
#define PTPD_DBGV
#endif

#ifdef DBG_SIGUSR2_CHANGE_DOMAIN
#ifdef DBG_SIGUSR2_CHANGE_DEBUG

#error "Cannot compile with both DBG_SIGUSR2_CHANGE_DOMAIN and DBG_SIGUSR2_CHANGE_DEBUG"

#endif
#endif


 /** \name System messages*/
 /**\{*/

#define MESSAGE this->m_pApp->m_ptr_sys->message

// Syslog ordering. We define extra debug levels above LOG_DEBUG for internal use - but message() doesn't pass these to SysLog

#define LOG_EMERG    0
#define LOG_ALERT    1
#define LOG_CRIT     2
#define LOG_ERR      3
#define LOG_WARNING  4
#define LOG_NOTICE   5
#define LOG_INFO     6

// extended from <sys/syslog.h>
#define LOG_DEBUG    7
#define LOG_DEBUG1   7
#define LOG_DEBUG2   8
#define LOG_DEBUG3   9
#define LOG_DEBUGV   9


#define EMERGENCY(x, ...) MESSAGE(LOG_EMERG, x, ##__VA_ARGS__)
#define ALERT(x, ...)     MESSAGE(LOG_ALERT, x, ##__VA_ARGS__)
#define CRITICAL(x, ...)  MESSAGE(LOG_CRIT, x, ##__VA_ARGS__)
#define ERROR_(x, ...)  MESSAGE(LOG_ERR, x, ##__VA_ARGS__)
#define PERROR(x, ...)    MESSAGE(LOG_ERR, x "      (strerror: %m)\n", ##__VA_ARGS__)
#define WARNING(x, ...)   MESSAGE(LOG_WARNING, x, ##__VA_ARGS__)
#define NOTIFY(x, ...) MESSAGE(LOG_NOTICE, x, ##__VA_ARGS__)
#define NOTICE(x, ...)    MESSAGE(LOG_NOTICE, x, ##__VA_ARGS__)
#define INFO(x, ...)   MESSAGE(LOG_INFO, x, ##__VA_ARGS__)


// enable this line to show debug numbers in nanoseconds instead of microseconds 
// #define DEBUG_IN_NS

#define DBG_UNIT_US (1000)
#define DBG_UNIT_NS (1)

#ifdef DEBUG_IN_NS
#define DBG_UNIT DBG_UNIT_NS
#else
#define DBG_UNIT DBG_UNIT_US
#endif


/** \}*/

/** \name Debug messages*/
 /**\{*/

#ifdef PTPD_DBGV
#undef PTPD_DBG
#undef PTPD_DBG2
#define PTPD_DBG
#define PTPD_DBG2

#define DBGV(x, ...) MESSAGE(LOG_DEBUGV, x, ##__VA_ARGS__)
#else
#define DBGV(x, ...)
#endif

/*
 * new debug level DBG2:
 * this is above DBG(), but below DBGV() (to avoid changing hundreds of lines)
 */


#ifdef PTPD_DBG2
#undef PTPD_DBG
#define PTPD_DBG
#define DBG2(x, ...) MESSAGE(LOG_DEBUG2, x, ##__VA_ARGS__)
#else
#define DBG2(x, ...)
#endif

#ifdef PTPD_DBG
#define DBG(x, ...) MESSAGE(LOG_DEBUG, x, ##__VA_ARGS__)
#else
#define DBG(x, ...)
#endif

/** \}*/

/** \name Endian corrections*/
 /**\{*/

#define PTPD_LSBF   //little endian


#endif /*PTPD_DEP_H_*/
