/* constants_dep.h */

#ifndef CONSTANTS_DEP_H
#define CONSTANTS_DEP_H

/**
*\file
* \brief Plateform-dependent constants definition
*
* This header defines all includes and constants which are plateform-dependent
*
* ptpdv2 is only implemented for linux, NetBSD and FreeBSD
 */

/* platform dependent */


#include <climits>

#define IFACE_NAME_LENGTH         128
#define MAXHOSTNAMELEN            128

#define DEFAULT_IFACE_NAME        "eth-ptpv2"

#define CLOCK_IDENTITY_LENGTH 8

#define SUBDOMAIN_ADDRESS_LENGTH  4
#define PORT_ADDRESS_LENGTH       2
#define PTP_UUID_LENGTH           6
#define CLOCK_IDENTITY_LENGTH     8
#define FLAG_FIELD_LENGTH         2

#define PACKET_SIZE  300 //ptpdv1 value kept because of use of TLV...

#define MM_STARTING_BOUNDARY_HOPS  0x7fff

/* others */

/* bigger screen size constants */
#define SCREEN_BUFSZ  228
#define SCREEN_MAXSZ  180

/* default size for string buffers */
#define BUF_SIZE  1000


#define NANOSECONDS_MAX 999999999

#define SECONDS_MAX     ((1<<48)-1)

#define CLOCK_PERIOD   (6.4)     //unit in nanoseconds

#define PPM_DIV            ((1e-6) * CLOCK_PERIOD * (1 << DOT_POS))

#define MAX_FREQ_VARIANCE  (100)     //in PPM

#define DOT_POS            (26)      //position of fractional point

#define INITIAL_TICK   ((uint32_t)(CLOCK_PERIOD * (1 << DOT_POS) + 0.5))

#define PTP_SYNCE      (1)       //if SyncE, frequency of signal clock for linkpartner equal to that of local device

/**
 * modify the tick increment value, because changing clock period 
 * in a small quantum is inaccurate in SystemC/Verilatro simulation.
 * the larger tick_inc, the larger effective frequency
 */
#if PTP_SYNCE  //SyncE
#define FREQ_DIFF        (0)     //0 PPM
#define LP_INITIAL_TICK  (INITIAL_TICK)
#else   //not SyncE
#define FREQ_DIFF        (10.0)  //10 PPM
#define LP_INITIAL_TICK  ((uint32_t)(INITIAL_TICK*(1.0 + FREQ_DIFF*1e-6)))
#endif  //PTP_SYNCE

#define ADJ_FREQ_MAX   ((int32_t)(MAX_FREQ_VARIANCE * (1e-6) * CLOCK_PERIOD * (1 << DOT_POS) + 0.5))

#define PI_UNIT        (1e9/(CLOCK_PERIOD * (1 << DOT_POS)) / 2.0)   //corresponding to f_clk/2

#define DEFAULT_AP     (3.0 * PI_UNIT)  

#define DEFAULT_AI     (15.0 * PI_UNIT)       

#define DEFAULT_DELAY_S       (6)

#define OFM_DELAY_LEN         (30)

#define WAIT_TX               (10)    //wait tx finishing, in microseconds

#define MIN_TX_GUARD_INTERVAL (25)    //minimum guard interval between tx mesages

// limit operator messages to once every X seconds
#define OPERATOR_MESSAGES_INTERVAL 300.0

#define MAXTIMESTR 32

#define NET_ADDRESS_LENGTH 16 /* for IPv4 dotted-decimal */

//#define DISPLAY_CLOCK_ID_INFO_ONLY 1   //display information for clock_id = x only

#endif /*CONSTANTS_DEP_H_*/
