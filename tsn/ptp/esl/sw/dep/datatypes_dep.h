#ifndef DATATYPES_DEP_H_
#define DATATYPES_DEP_H_

/**
*\file
* \brief Implementation specific datatype

 */
/* FIXME: shouldn't uint32_t and friends be used here? */
//typedef enum {FALSE=0, TRUE} Boolean;
#define FALSE 0
#define TRUE  1
typedef int Boolean;
typedef char Octet;
typedef signed char Integer8;
typedef int16_t Integer16;
typedef int32_t Integer32;
typedef unsigned char UInteger8;
typedef uint16_t UInteger16;
typedef uint32_t UInteger32;
typedef unsigned short Enumeration16;
typedef unsigned char Enumeration8;
typedef unsigned char Enumeration4;
typedef unsigned char Enumeration4Upper;
typedef unsigned char Enumeration4Lower;
typedef unsigned char UInteger4;
typedef unsigned char UInteger4Upper;
typedef unsigned char UInteger4Lower;
typedef unsigned char Nibble;
typedef unsigned char NibbleUpper;
typedef unsigned char NibbleLower;

/**
* \brief Implementation specific of UInteger48 type
 */
typedef struct {
    uint32_t lsb;     /* FIXME: shouldn't uint32_t and uint16_t be used here? */
    uint16_t msb;
} UInteger48;

/**
* \brief Implementation specific of Integer64 type
 */
typedef struct {
    uint32_t lsb;     /* FIXME: shouldn't uint32_t and int32_t be used here? */
    int32_t  msb;
} Integer64;

/**
* \brief Struct used to average the offset from master
*
* The FIR filtering of the offset from master input is a simple, two-sample average
 */
typedef struct {
    Integer32  nsec_prev, y;
} offset_from_master_filter;

/**
* \brief Struct used to average the one way delay
*
* It is a variable cutoff/delay low-pass, infinite impulse response (IIR) filter.
*
*  The one-way delay filter has the difference equation: s*y[n] - (s-1)*y[n-1] = x[n]/2 + x[n-1]/2, where increasing the stiffness (s) lowers the cutoff and increases the delay.
 */
typedef struct {
    Integer32  nsec_prev, y;
    Integer32  s_exp;
} one_way_delay_filter;

/**
* \brief Struct used to store network datas
* only useful for PTP over UDP/IPv4
 */

#include <arpa/inet.h>

typedef struct {
    //UDP/IPv4 related address
    Integer32 eventSock, generalSock, multicastAddr, peerMulticastAddr,unicastAddr;

    /* used by IGMP refresh */
    struct in_addr interfaceAddr;

#ifdef PTP_EXPERIMENTAL
    /* used for Hybrid mode */
    Integer32 lastRecvAddr;
#endif

} NetPath;

//struct for timestamp and its identification
typedef struct {
    uint64_t seconds;
    uint32_t nanoseconds;
    uint16_t frac_nanoseconds;
    unsigned char sourcePortIdentity[10];
    unsigned char flagField[2];
    unsigned char majorSdoId;
    unsigned char messageType;
    unsigned char minorVersionPTP;
    unsigned char versionPTP;
    uint16_t sequenceId;
} TimestampIdentity;

#endif /*DATATYPES_DEP_H_*/
