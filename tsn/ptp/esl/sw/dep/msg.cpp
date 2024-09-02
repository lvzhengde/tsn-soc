/*-
 * Copyright (c) 2022-2023 Zhengde
 *
 * Copyright (c) 2011-2012 George V. Neville-Neil,
 *                         Steven Kreuzer, 
 *                         Martin Burnicki, 
 *                         Jan Breuer,
 *                         Gael Mace, 
 *                         Alexandre Van Kempen,
 *                         Inaqui Delgado,
 *                         Rick Ratzel,
 *                         National Instruments.
 * Copyright (c) 2009-2010 George V. Neville-Neil, 
 *                         Steven Kreuzer, 
 *                         Martin Burnicki, 
 *                         Jan Breuer,
 *                         Gael Mace, 
 *                         Alexandre Van Kempen
 *
 * Copyright (c) 2005-2008 Kendall Correll, Aidan Williams
 *
 * All Rights Reserved
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @file   msg.c
 * @author George Neville-Neil <gnn@neville-neil.com>
 * @date   Tue Jul 20 16:17:05 2010
 *
 * @brief  Functions to pack and unpack messages.
 *
 * See spec annex d
 */

#include "common.h"


#define PACK_SIMPLE( type ) \
void pack##type( void* from, void* to ) \
{ \
    *(type *)to = *(type *)from; \
} \
void unpack##type( void* from, void* to, PtpClock *ptpClock ) \
{ \
    pack##type( from, to ); \
}

#define PACK_ENDIAN( type, size ) \
void pack##type( void* from, void* to ) \
{ \
    *(type *)to = flip##size( *(type *)from ); \
} \
void unpack##type( void* from, void* to, PtpClock *ptpClock ) \
{ \
    pack##type( from, to ); \
}

#define PACK_LOWER_AND_UPPER( type ) \
void pack##type##Lower( void* from, void* to ) \
{ \
    *(char *)to = *(char *)to & 0xF0; \
    *(char *)to = *(char *)to | *(type *)from; \
} \
\
void pack##type##Upper( void* from, void* to ) \
{ \
    *(char *)to = *(char *)to & 0x0F; \
    *(char *)to = *(char *)to | (*(type *)from << 4); \
} \
\
void unpack##type##Lower( void* from, void* to, PtpClock *ptpClock ) \
{ \
    *(type *)to = *(char *)from & 0x0F; \
} \
\
void unpack##type##Upper( void* from, void* to, PtpClock *ptpClock ) \
{ \
    *(type *)to = *(char *)from & 0xF0; \
}

PACK_SIMPLE( Boolean )
PACK_SIMPLE( UInteger8 )
PACK_SIMPLE( Octet )
PACK_SIMPLE( Enumeration8 )
PACK_SIMPLE( Integer8 )

PACK_ENDIAN( Enumeration16, 16 )
PACK_ENDIAN( Integer16, 16 )
PACK_ENDIAN( UInteger16, 16 )
PACK_ENDIAN( Integer32, 32 )
PACK_ENDIAN( UInteger32, 32 )

PACK_LOWER_AND_UPPER( Enumeration4 )
PACK_LOWER_AND_UPPER( UInteger4 )
PACK_LOWER_AND_UPPER( Nibble )

/* The free function is intentionally empty. However, this simplifies
 * the procedure to deallocate complex data types
 */
#define FREE( type ) \
void free##type( void* x) \
{}

FREE ( Boolean )
FREE ( UInteger8 )
FREE ( Octet )
FREE ( Enumeration8 )
FREE ( Integer8 )
FREE ( Enumeration16 )
FREE ( Integer16 )
FREE ( UInteger16 )
FREE ( Integer32 )
FREE ( UInteger32 )
FREE ( Enumeration4 )
FREE ( UInteger4 )
FREE ( Nibble )

void
unpackUInteger48( void *buf, void *i, PtpClock *ptpClock)
{
    unpackUInteger32((Octet*)buf, &((UInteger48*)i)->lsb, ptpClock);
    unpackUInteger16((Octet*)buf + 4, &((UInteger48*)i)->msb, ptpClock);
}

void
packUInteger48( void *i, void *buf)
{
    packUInteger32(&((UInteger48*)i)->lsb, (Octet*)buf);
    packUInteger16(&((UInteger48*)i)->msb, (Octet*)buf + 4);
}

void
unpackInteger64( void *buf, void *i, PtpClock *ptpClock)
{
    unpackUInteger32((Octet*)buf, &((Integer64*)i)->lsb, ptpClock);
    unpackInteger32((Octet*)buf + 4, &((Integer64*)i)->msb, ptpClock);
}

void
packInteger64( void* i, void *buf )
{
    packUInteger32(&((Integer64*)i)->lsb, (Octet*)buf);
    packInteger32(&((Integer64*)i)->msb, (Octet*)buf + 4);
}

//constructor
msg::msg(ptpd *pApp)
{
    BASE_MEMBER_ASSIGN  
}


/* NOTE: the unpack functions for management messages can probably be refactored into a macro */
void
msg::unpackMMSlaveOnly( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
    int offset = 0;
    XMALLOC(m->tlv->dataField, sizeof(MMSlaveOnly));
    MMSlaveOnly* data = (MMSlaveOnly*)m->tlv->dataField;
    /* see src/def/README for a note on this X-macro */
    #define OPERATE( name, size, type ) \
        unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                  &data->name, ptpClock ); \
        offset = offset + size;
    #include "def/managementTLV/slaveOnly.def"

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->mMSlaveOnly_display(data, ptpClock);
    #endif /* PTPD_DBG */
}

/* NOTE: the pack functions for management messsages can probably be refactored into a macro */
UInteger16
msg::packMMSlaveOnly( MsgManagement* m, Octet *buf)
{
    int offset = 0;
    MMSlaveOnly* data = (MMSlaveOnly*)m->tlv->dataField;
    #define OPERATE( name, size, type ) \
        pack##type( &data->name,\
                buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
        offset = offset + size;
    #include "def/managementTLV/slaveOnly.def"

    /* return length */
    return offset;
}

void
msg::unpackMMClockDescription( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
    int offset = 0;
    XMALLOC(m->tlv->dataField, sizeof(MMClockDescription));
    MMClockDescription* data = (MMClockDescription*)m->tlv->dataField;
    memset(data, 0, sizeof(MMClockDescription));
    #define OPERATE( name, size, type ) \
        unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                  &data->name, ptpClock ); \
        offset = offset + size;
    #include "def/managementTLV/clockDescription.def"

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->mMClockDescription_display(data, ptpClock);
    #endif /* PTPD_DBG */
}

UInteger16
msg::packMMClockDescription( MsgManagement* m, Octet *buf)
{
    int offset = 0;
    Octet pad = 0;
    MMClockDescription* data = (MMClockDescription*)m->tlv->dataField;
    data->reserved = 0;
    #define OPERATE( name, size, type ) \
        pack##type( &data->name,\
                buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset); \
        offset = offset + size;
    #include "def/managementTLV/clockDescription.def"

    /* is the TLV length odd? TLV must be even according to Spec 5.3.8 */
    if(offset % 2) {
        /* add pad of 1 according to Table 41 to make TLV length even */
        packOctet(&pad, buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset);
        offset = offset + 1;
    }

    /* return length */
    return offset;
}

void
msg::freeMMClockDescription( MMClockDescription* data)
{
    #define OPERATE( name, size, type ) \
        free##type( &data->name);
    #include "def/managementTLV/clockDescription.def"
}

void
msg::unpackMMUserDescription( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
    int offset = 0;
    XMALLOC(m->tlv->dataField, sizeof(MMUserDescription));
    MMUserDescription* data = (MMUserDescription*)m->tlv->dataField;
    memset(data, 0, sizeof(MMUserDescription));
    #define OPERATE( name, size, type ) \
        unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                  &data->name, ptpClock ); \
        offset = offset + size;
    #include "def/managementTLV/userDescription.def"

    #ifdef PTPD_DBG
    /* mMUserDescription_display(data, ptpClock); */
    #endif /* PTPD_DBG */
}

UInteger16
msg::packMMUserDescription( MsgManagement* m, Octet *buf)
{
    int offset = 0;
    Octet pad = 0;
    MMUserDescription* data = (MMUserDescription*)m->tlv->dataField;
    #define OPERATE( name, size, type ) \
        pack##type( &data->name,\
                buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset); \
        offset = offset + size;
    #include "def/managementTLV/userDescription.def"

    /* is the TLV length odd? TLV must be even according to Spec 5.3.8 */
    if(offset % 2) {
        /* add pad of 1 according to Table 41 to make TLV length even */
        packOctet(&pad, buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset);
        offset = offset + 1;
    }

    /* return length */
    return offset;
}

void
msg::freeMMUserDescription( MMUserDescription* data)
{
    #define OPERATE( name, size, type ) \
        free##type( &data->name);
    #include "def/managementTLV/userDescription.def"
}

void msg::unpackMMInitialize( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMInitialize));
        MMInitialize* data = (MMInitialize*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/initialize.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMInitialize_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMInitialize( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMInitialize* data = (MMInitialize*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/initialize.def"

        /* return length*/
        return offset;
}

void msg::unpackMMDefaultDataSet( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMDefaultDataSet));
        MMDefaultDataSet* data = (MMDefaultDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/defaultDataSet.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMDefaultDataSet_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMDefaultDataSet( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMDefaultDataSet* data = (MMDefaultDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/defaultDataSet.def"

        /* return length*/
        return offset;
}

void msg::unpackMMCurrentDataSet( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMCurrentDataSet));
        MMCurrentDataSet* data = (MMCurrentDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/currentDataSet.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMCurrentDataSet_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMCurrentDataSet( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMCurrentDataSet* data = (MMCurrentDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/currentDataSet.def"

        /* return length*/
        return offset;
}

void msg::unpackMMParentDataSet( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMParentDataSet));
        MMParentDataSet* data = (MMParentDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/parentDataSet.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMParentDataSet_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMParentDataSet( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMParentDataSet* data = (MMParentDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/parentDataSet.def"

        /* return length*/
        return offset;
}

void msg::unpackMMTimePropertiesDataSet( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMTimePropertiesDataSet));
        MMTimePropertiesDataSet* data = (MMTimePropertiesDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/timePropertiesDataSet.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMTimePropertiesDataSet_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMTimePropertiesDataSet( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMTimePropertiesDataSet* data = (MMTimePropertiesDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/timePropertiesDataSet.def"

        /* return length*/
        return offset;
}

void msg::unpackMMPortDataSet( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMPortDataSet));
        MMPortDataSet* data = (MMPortDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/portDataSet.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMPortDataSet_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMPortDataSet( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMPortDataSet* data = (MMPortDataSet*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/portDataSet.def"

        /* return length*/
        return offset;
}

void msg::unpackMMPriority1( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMPriority1));
        MMPriority1* data = (MMPriority1*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/priority1.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMPriority1_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMPriority1( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMPriority1* data = (MMPriority1*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/priority1.def"

        /* return length*/
        return offset;
}

void msg::unpackMMPriority2( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMPriority2));
        MMPriority2* data = (MMPriority2*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/priority2.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMPriority2_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMPriority2( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMPriority2* data = (MMPriority2*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/priority2.def"

        /* return length*/
        return offset;
}

void msg::unpackMMDomain( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMDomain));
        MMDomain* data = (MMDomain*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/domain.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMDomain_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMDomain( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMDomain* data = (MMDomain*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/domain.def"

        /* return length*/
        return offset;
}

void msg::unpackMMLogAnnounceInterval( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMLogAnnounceInterval));
        MMLogAnnounceInterval* data = (MMLogAnnounceInterval*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/logAnnounceInterval.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMLogAnnounceInterval_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMLogAnnounceInterval( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMLogAnnounceInterval* data = (MMLogAnnounceInterval*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/logAnnounceInterval.def"

        /* return length*/
        return offset;
}

void msg::unpackMMAnnounceReceiptTimeout( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField,sizeof(MMAnnounceReceiptTimeout));
        MMAnnounceReceiptTimeout* data = (MMAnnounceReceiptTimeout*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/announceReceiptTimeout.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMAnnounceReceiptTimeout_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMAnnounceReceiptTimeout( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMAnnounceReceiptTimeout* data = (MMAnnounceReceiptTimeout*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/announceReceiptTimeout.def"

        /* return length*/
        return offset;
}

void msg::unpackMMLogSyncInterval( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMLogSyncInterval));
        MMLogSyncInterval* data = (MMLogSyncInterval*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/logSyncInterval.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMLogSyncInterval_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMLogSyncInterval( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMLogSyncInterval* data = (MMLogSyncInterval*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/logSyncInterval.def"

        /* return length*/
        return offset;
}

void msg::unpackMMVersionNumber( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMVersionNumber));
        MMVersionNumber* data = (MMVersionNumber*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/versionNumber.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMVersionNumber_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMVersionNumber( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMVersionNumber* data = (MMVersionNumber*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/versionNumber.def"

        /* return length*/
        return offset;
}

void msg::unpackMMTime( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMTime));
        MMTime* data = (MMTime*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/time.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMTime_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMTime( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMTime* data = (MMTime*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/time.def"

        /* return length*/
        return offset;
}

void msg::unpackMMClockAccuracy( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMClockAccuracy));
        MMClockAccuracy* data = (MMClockAccuracy*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/clockAccuracy.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMClockAccuracy_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMClockAccuracy( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMClockAccuracy* data = (MMClockAccuracy*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/clockAccuracy.def"

        /* return length*/
        return offset;
}

void msg::unpackMMUtcProperties( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMUtcProperties));
        MMUtcProperties* data = (MMUtcProperties*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/utcProperties.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMUtcProperties_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMUtcProperties( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMUtcProperties* data = (MMUtcProperties*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/utcProperties.def"

        /* return length*/
        return offset;
}

void msg::unpackMMTraceabilityProperties( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMTraceabilityProperties));
        MMTraceabilityProperties* data = (MMTraceabilityProperties*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/traceabilityProperties.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMTraceabilityProperties_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMTraceabilityProperties( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMTraceabilityProperties* data = (MMTraceabilityProperties*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/traceabilityProperties.def"

        /* return length*/
        return offset;
}

void msg::unpackMMDelayMechanism( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMDelayMechanism));
        MMDelayMechanism* data = (MMDelayMechanism*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/delayMechanism.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMDelayMechanism_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMDelayMechanism( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMDelayMechanism* data = (MMDelayMechanism*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/delayMechanism.def"

        /* return length*/
        return offset;
}

void msg::unpackMMLogMinPdelayReqInterval( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMLogMinPdelayReqInterval));
        MMLogMinPdelayReqInterval* data = (MMLogMinPdelayReqInterval*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/logMinPdelayReqInterval.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMLogMinPdelayReqInterval_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

UInteger16
msg::packMMLogMinPdelayReqInterval( MsgManagement* m, Octet *buf)
{
        int offset = 0;
        MMLogMinPdelayReqInterval* data = (MMLogMinPdelayReqInterval*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/logMinPdelayReqInterval.def"

        /* return length*/
        return offset;
}

void msg::unpackMMErrorStatus( Octet *buf, MsgManagement* m, PtpClock* ptpClock)
{
        int offset = 0;
        XMALLOC(m->tlv->dataField, sizeof(MMErrorStatus));
        MMErrorStatus* data = (MMErrorStatus*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                unpack##type( buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset,\
                              &data->name, ptpClock ); \
                offset = offset + size;
        #include "def/managementTLV/errorStatus.def"

        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMErrorStatus_display(data, ptpClock);
        #endif /* PTPD_DBG */
}

void
msg::freeMMErrorStatus( MMErrorStatus* data)
{
    #define OPERATE( name, size, type ) \
        free##type( &data->name);
    #include "def/managementTLV/errorStatus.def"
}

UInteger16
msg::packMMErrorStatus( MsgManagement* m, Octet *buf)
{
        int offset = 0;
    Octet pad = 0;
        MMErrorStatus* data = (MMErrorStatus*)m->tlv->dataField;
        #define OPERATE( name, size, type ) \
                pack##type( &data->name,\
                            buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset ); \
                offset = offset + size;
        #include "def/managementTLV/errorStatus.def"

    /* is the TLV length odd? TLV must be even according to Spec 5.3.8 */
    if(offset % 2) {
        /* add pad of 1 according to Table 41 to make TLV length even */
        packOctet(&pad, buf + MANAGEMENT_LENGTH + TLV_LENGTH + offset);
        offset = offset + 1;
    }

    /* return length*/
    return offset;
}



void
msg::unpackClockIdentity( Octet *buf, ClockIdentity *c, PtpClock *ptpClock)
{
    int i;
    for(i = 0; i < CLOCK_IDENTITY_LENGTH; i++) {
        unpackOctet((buf+i),&((*c)[i]), ptpClock);
    }
}

void msg::packClockIdentity( ClockIdentity *c, Octet *buf)
{
    int i;
    for(i = 0; i < CLOCK_IDENTITY_LENGTH; i++) {
        packOctet(&((*c)[i]),(buf+i));
    }
}

void
msg::freeClockIdentity( ClockIdentity *c) {
    /* nothing to free */
}

void
msg::unpackClockQuality( Octet *buf, ClockQuality *c, PtpClock *ptpClock)
{
    int offset = 0;
    ClockQuality* data = c;
    #define OPERATE( name, size, type) \
        unpack##type (buf + offset, &data->name, ptpClock); \
        offset = offset + size;
    #include "def/derivedData/clockQuality.def"
}

void
msg::packClockQuality( ClockQuality *c, Octet *buf)
{
    int offset = 0;
    ClockQuality *data = c;
    #define OPERATE( name, size, type) \
        pack##type (&data->name, buf + offset); \
        offset = offset + size;
    #include "def/derivedData/clockQuality.def"
}

void
msg::freeClockQuality( ClockQuality *c)
{
    /* nothing to free */
}

void
msg::unpackTimeInterval( Octet *buf, TimeInterval *t, PtpClock *ptpClock)
{
        int offset = 0;
        TimeInterval* data = t;
        #define OPERATE( name, size, type) \
                unpack##type (buf + offset, &data->name, ptpClock); \
                offset = offset + size;
        #include "def/derivedData/timeInterval.def"
}

void
msg::packTimeInterval( TimeInterval *t, Octet *buf)
{
        int offset = 0;
        TimeInterval *data = t;
        #define OPERATE( name, size, type) \
                pack##type (&data->name, buf + offset); \
                offset = offset + size;
        #include "def/derivedData/timeInterval.def"
}

void
msg::freeTimeInterval( TimeInterval *t)
{
    /* nothing to free */
}

void
msg::unpackTimestamp( Octet *buf, Timestamp *t, PtpClock *ptpClock)
{
        int offset = 0;
        Timestamp* data = t;
        #define OPERATE( name, size, type) \
                unpack##type (buf + offset, &data->name, ptpClock); \
                offset = offset + size;
        #include "def/derivedData/timestamp.def"
}

void
msg::packTimestamp( Timestamp *t, Octet *buf)
{
        int offset = 0;
        Timestamp *data = t;
        #define OPERATE( name, size, type) \
                pack##type (&data->name, buf + offset); \
                offset = offset + size;
        #include "def/derivedData/timestamp.def"
}

void
msg::freeTimestamp( Timestamp *t)
{
        /* nothing to free */
}


void
msg::unpackPortIdentity( Octet *buf, PortIdentity *p, PtpClock *ptpClock)
{
    int offset = 0;
    PortIdentity* data = p;
    #define OPERATE( name, size, type) \
        unpack##type (buf + offset, &data->name, ptpClock); \
        offset = offset + size;
    #include "def/derivedData/portIdentity.def"
}

void
msg::packPortIdentity( PortIdentity *p, Octet *buf)
{
    int offset = 0;
    PortIdentity *data = p;
    #define OPERATE( name, size, type) \
        pack##type (&data->name, buf + offset); \
        offset = offset + size;
    #include "def/derivedData/portIdentity.def"
}

void
msg::freePortIdentity( PortIdentity *p)
{
    /* nothing to free */
}

void
msg::unpackPortAddress( Octet *buf, PortAddress *p, PtpClock *ptpClock)
{
    unpackEnumeration16( buf, &p->networkProtocol, ptpClock);
    unpackUInteger16( buf+2, &p->addressLength, ptpClock);
    if(p->addressLength) {
        XMALLOC(p->addressField, p->addressLength);
        memcpy( p->addressField, buf+4, p->addressLength);
    } else {
        p->addressField = NULL;
    }
}

void
msg::packPortAddress(PortAddress *p, Octet *buf)
{
    packEnumeration16(&p->networkProtocol, buf);
    packUInteger16(&p->addressLength, buf+2);
    if(p->addressLength) {
        memcpy( buf+4, p->addressField, p->addressLength);
    }
}

void
msg::freePortAddress(PortAddress *p)
{
    if(p->addressField) {
        free(p->addressField);
        p->addressField = NULL;
    }
}

void
msg::unpackPTPText( Octet *buf, PTPText *s, PtpClock *ptpClock)
{
    unpackUInteger8( buf, &s->lengthField, ptpClock);
    if(s->lengthField) {
        XMALLOC(s->textField, s->lengthField);
        memcpy( s->textField, buf+1, s->lengthField);
    } else {
        s->textField = NULL;
    }
}

void
msg::packPTPText(PTPText *s, Octet *buf)
{
    packUInteger8(&s->lengthField, buf);
    if(s->lengthField) {
        memcpy( buf+1, s->textField, s->lengthField);
    }
}

void
msg::freePTPText(PTPText *s)
{
    if(s->textField) {
        free(s->textField);
        s->textField = NULL;
    }
}

void
msg::unpackPhysicalAddress( Octet *buf, PhysicalAddress *p, PtpClock *ptpClock)
{
    unpackUInteger16( buf, &p->addressLength, ptpClock);
    if(p->addressLength) {
        XMALLOC(p->addressField, p->addressLength);
        memcpy( p->addressField, buf+2, p->addressLength);
    } else {
        p->addressField = NULL;
    }
}

void
msg::packPhysicalAddress(PhysicalAddress *p, Octet *buf)
{
    packUInteger16(&p->addressLength, buf);
    if(p->addressLength) {
        memcpy( buf+2, p->addressField, p->addressLength);
    }
}

void
msg::freePhysicalAddress(PhysicalAddress *p)
{
    if(p->addressField) {
        free(p->addressField);
        p->addressField = NULL;
    }
}

void
msg::copyClockIdentity( ClockIdentity dest, ClockIdentity src)
{
    memcpy(dest, src, CLOCK_IDENTITY_LENGTH);
}

void
msg::copyPortIdentity( PortIdentity *dest, PortIdentity *src)
{
    copyClockIdentity(dest->clockIdentity, src->clockIdentity);
    dest->portNumber = src->portNumber;
}

void
msg::unpackMsgHeader(Octet *buf, MsgHeader *header, PtpClock *ptpClock)
{
    int offset = 0;
    MsgHeader* data = header;
    #define OPERATE( name, size, type) \
        unpack##type (buf + offset, &data->name, ptpClock); \
        offset = offset + size;
    #include "def/message/header.def"
}

void
msg::packMsgHeader(MsgHeader *h, Octet *buf)
{
    int offset = 0;

    /* set uninitalized bytes to zero */
    h->reserved0 = 0;
    h->reserved1 = 0;
    h->reserved2 = 0;

    #define OPERATE( name, size, type ) \
        pack##type( &h->name, buf + offset ); \
        offset = offset + size;
    #include "def/message/header.def"
}

void
msg::unpackManagementTLV(Octet *buf, MsgManagement *m, PtpClock* ptpClock)
{
    int offset = 0;
    Octet *pTLV = NULL;
    XMALLOC(pTLV, sizeof(ManagementTLV));
    m->tlv = (ManagementTLV*)pTLV;

    /* read the management TLV */
    #define OPERATE( name, size, type ) \
        unpack##type( buf + MANAGEMENT_LENGTH + offset, &m->tlv->name, ptpClock ); \
        offset = offset + size;
    #include "def/managementTLV/managementTLV.def"
}

void
msg::packManagementTLV(ManagementTLV *tlv, Octet *buf)
{
    int offset = 0;
    #define OPERATE( name, size, type ) \
        pack##type( &tlv->name, buf + MANAGEMENT_LENGTH + offset ); \
        offset = offset + size;
    #include "def/managementTLV/managementTLV.def"
}

void
msg::freeManagementTLV(MsgManagement *m)
{
        /* cleanup outgoing managementTLV */
        if(m->tlv) {
                if(m->tlv->dataField) {
                        if(m->tlv->tlvType == TLV_MANAGEMENT) {
                                freeMMTLV(m->tlv);
                        } else if(m->tlv->tlvType == TLV_MANAGEMENT_ERROR_STATUS) {
                                freeMMErrorStatusTLV(m->tlv);
                        }
                        free(m->tlv->dataField);
            m->tlv->dataField = NULL;
                }
                free(m->tlv);
        m->tlv = NULL;
        }
}

void
msg::packMsgManagement(MsgManagement *m, Octet *buf)
{
    int offset = 0;
    MsgManagement *data = m;

    /* set unitialized bytes to zero */
    m->reserved0 = 0;
    m->reserved1 = 0;

    #define OPERATE( name, size, type) \
        pack##type (&data->name, buf + offset); \
        offset = offset + size;
    #include "def/message/management.def"

}

void msg::unpackMsgManagement(Octet *buf, MsgManagement *m, PtpClock *ptpClock)
{
    int offset = 0;
    MsgManagement* data = m;
    #define OPERATE( name, size, type) \
        unpack##type (buf + offset, &data->name, ptpClock); \
        offset = offset + size;
    #include "def/message/management.def"

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgManagement_display(data);
    #endif /* PTPD_DBG */
}

/*Unpack Header from IN buffer to msgTmpHeader field */
void
msg::msgUnpackHeader(Octet * buf, MsgHeader * header)
{
    header->transportSpecific = (*(Nibble *) (buf + 0)) >> 4;
    header->messageType = (*(Enumeration4 *) (buf + 0)) & 0x0F;
    header->reserved0 = (*(UInteger4 *) (buf + 1)) & 0xF0;
    header->versionPTP = (*(UInteger4 *) (buf + 1)) & 0x0F;
    header->messageLength = flip16(*(UInteger16 *) (buf + 2));
    header->domainNumber = (*(UInteger8 *) (buf + 4));
    header->reserved1 = (*(Octet *) (buf + 5));
    header->flagField0 = (*(Octet *) (buf + 6));
    header->flagField1 = (*(Octet *) (buf + 7));
    memcpy(&header->correctionField.msb, (buf + 8), 4);
    memcpy(&header->correctionField.lsb, (buf + 12), 4);
    header->correctionField.msb = flip32(header->correctionField.msb);
    header->correctionField.lsb = flip32(header->correctionField.lsb);
    memcpy(&header->reserved2, (buf + 16), 4);
    header->reserved2 = flip32(header->reserved2);
    copyClockIdentity(header->sourcePortIdentity.clockIdentity, (buf + 20));
    header->sourcePortIdentity.portNumber =
        flip16(*(UInteger16 *) (buf + 28));
    header->sequenceId = flip16(*(UInteger16 *) (buf + 30));
    header->controlField = (*(UInteger8 *) (buf + 32));
    header->logMessageInterval = (*(Integer8 *) (buf + 33));

#ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgHeader_display(header);
#endif /* PTPD_DBG */
}

/*Pack header message into OUT buffer of ptpClock*/
void
msg::msgPackHeader(Octet * buf, PtpClock * ptpClock)
{
    Nibble transport = 0x10;    //802.1AS ethernet transport specific

    /* (spec annex D) */
    *(UInteger8 *) (buf + 0) = transport;
    *(UInteger4 *) (buf + 1) = ptpClock->versionNumber;
    *(UInteger8 *) (buf + 4) = ptpClock->domainNumber;

    /* TODO: this bit should have been active only for sync and PdelayResp */
    if (ptpClock->twoStepFlag)
        *(UInteger8 *) (buf + 6) = PTP_TWO_STEP;

    memset((buf + 8), 0, 8);
    copyClockIdentity((buf + 20), ptpClock->portIdentity.clockIdentity);
    *(UInteger16 *) (buf + 28) = flip16(ptpClock->portIdentity.portNumber);
    *(UInteger8 *) (buf + 33) = 0x7F;
    /* Default value(spec Table 24) */
}



/*Pack SYNC message into OUT buffer of ptpClock*/
void
msg::msgPackSync(Octet * buf, Timestamp * originTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);
    
    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x00;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(SYNC_LENGTH);
    *(UInteger16 *) (buf + 30) = flip16(ptpClock->sentSyncSequenceId);
    *(UInteger8 *) (buf + 32) = 0x00;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = ptpClock->logSyncInterval;
    memset((buf + 8), 0, 8);

    /* Sync message */
    *(UInteger16 *) (buf + 34) = flip16(originTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) = flip32(originTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) = flip32(originTimestamp->nanosecondsField);
}

/*Unpack Sync message from IN buffer */
void
msg::msgUnpackSync(Octet * buf, MsgSync * sync)
{
    sync->originTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    sync->originTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    sync->originTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));

#ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgSync_display(sync);
#endif /* PTPD_DBG */
}



/*Pack Announce message into OUT buffer of ptpClock*/
void
msg::msgPackAnnounce(Octet * buf, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);

    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x0B;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(ANNOUNCE_LENGTH);
    *(UInteger16 *) (buf + 30) = flip16(ptpClock->sentAnnounceSequenceId);
    *(UInteger8 *) (buf + 32) = 0x05;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = ptpClock->logAnnounceInterval;

    /* Announce message */
    memset((buf + 34), 0, 10);
    *(Integer16 *) (buf + 44) = flip16(ptpClock->currentUtcOffset);
    *(UInteger8 *) (buf + 47) = ptpClock->grandmasterPriority1;
    *(UInteger8 *) (buf + 48) = ptpClock->clockQuality.clockClass;
    *(Enumeration8 *) (buf + 49) = ptpClock->clockQuality.clockAccuracy;
    *(UInteger16 *) (buf + 50) =
        flip16(ptpClock->clockQuality.offsetScaledLogVariance);
    *(UInteger8 *) (buf + 52) = ptpClock->grandmasterPriority2;
    copyClockIdentity((buf + 53), ptpClock->grandmasterIdentity);
    *(UInteger16 *) (buf + 61) = flip16(ptpClock->stepsRemoved);
    *(Enumeration8 *) (buf + 63) = ptpClock->timeSource;
}

/*Unpack Announce message from IN buffer of ptpClock to msgtmp.Announce*/
void
msg::msgUnpackAnnounce(Octet * buf, MsgAnnounce * announce)
{
    announce->originTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    announce->originTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    announce->originTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));
    announce->currentUtcOffset = flip16(*(UInteger16 *) (buf + 44));
    announce->grandmasterPriority1 = *(UInteger8 *) (buf + 47);
    announce->grandmasterClockQuality.clockClass =
        *(UInteger8 *) (buf + 48);
    announce->grandmasterClockQuality.clockAccuracy =
        *(Enumeration8 *) (buf + 49);
    announce->grandmasterClockQuality.offsetScaledLogVariance =
        flip16(*(UInteger16 *) (buf + 50));
    announce->grandmasterPriority2 = *(UInteger8 *) (buf + 52);
    copyClockIdentity(announce->grandmasterIdentity, (buf + 53));
    announce->stepsRemoved = flip16(*(UInteger16 *) (buf + 61));
    announce->timeSource = *(Enumeration8 *) (buf + 63);

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgAnnounce_display(announce);
    #endif /* PTPD_DBG */
}

/*pack Follow_up message into OUT buffer of ptpClock*/
void
msg::msgPackFollowUp(Octet * buf, Timestamp * preciseOriginTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);
    
    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x08;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(FOLLOW_UP_LENGTH);
    *(UInteger16 *) (buf + 30) = flip16(ptpClock->sentSyncSequenceId);
    /* sentSyncSequenceId incremented after issueFollowUp in "issueSync" */
    *(UInteger8 *) (buf + 32) = 0x02;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = ptpClock->logSyncInterval;

    /* Follow_up message */
    *(UInteger16 *) (buf + 34) =
        flip16(preciseOriginTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) =
        flip32(preciseOriginTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) =
        flip32(preciseOriginTimestamp->nanosecondsField);
}

/*Unpack Follow_up message from IN buffer of ptpClock to msgtmp.follow*/
void
msg::msgUnpackFollowUp(Octet * buf, MsgFollowUp * follow)
{
    follow->preciseOriginTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    follow->preciseOriginTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    follow->preciseOriginTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgFollowUp_display(follow);
    #endif /* PTPD_DBG */
}


/*pack PdelayReq message into OUT buffer of ptpClock*/
void
msg::msgPackPDelayReq(Octet * buf, Timestamp * originTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);
    
    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x02;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(PDELAY_REQ_LENGTH);
    *(UInteger16 *) (buf + 30) = flip16(ptpClock->sentPDelayReqSequenceId);
    *(UInteger8 *) (buf + 32) = 0x05;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = 0x7F;
    /* Table 24 */
    memset((buf + 8), 0, 8);

    /* Pdelay_req message */
    *(UInteger16 *) (buf + 34) = flip16(originTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) = flip32(originTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) = flip32(originTimestamp->nanosecondsField);

    memset((buf + 44), 0, 10);
    /* RAZ reserved octets */
}

/*pack delayReq message into OUT buffer of ptpClock*/
void
msg::msgPackDelayReq(Octet * buf, Timestamp * originTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);

    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x01;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(DELAY_REQ_LENGTH);

#ifdef PTP_EXPERIMENTAL
    if(rtOpts.do_hybrid_mode)
        *(char *)(buf + 6) |= PTP_UNICAST;
#endif

    *(UInteger16 *) (buf + 30) = flip16(ptpClock->sentDelayReqSequenceId);
    *(UInteger8 *) (buf + 32) = 0x01;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = 0x7F;
    /* Table 24 */
    memset((buf + 8), 0, 8);

    /* Pdelay_req message */
    *(UInteger16 *) (buf + 34) = flip16(originTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) = flip32(originTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) = flip32(originTimestamp->nanosecondsField);
}

/*pack delayResp message into OUT buffer of ptpClock*/
void 
msg::msgPackDelayResp(Octet * buf, MsgHeader * header, Timestamp * receiveTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);
    
    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x09;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(DELAY_RESP_LENGTH);
    *(UInteger8 *) (buf + 4) = header->domainNumber;

#ifdef PTP_EXPERIMENTAL
    if(rtOpts.do_hybrid_mode)    
        *(char *)(buf + 6) |= PTP_UNICAST;
#endif

    memset((buf + 8), 0, 8);

    /* Copy correctionField of PdelayReqMessage */
    *(Integer32 *) (buf + 8) = flip32(header->correctionField.msb);
    *(Integer32 *) (buf + 12) = flip32(header->correctionField.lsb);

    *(UInteger16 *) (buf + 30) = flip16(header->sequenceId);

    *(UInteger8 *) (buf + 32) = 0x03;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = ptpClock->logMinDelayReqInterval;
    /* Table 24 */

    /* Pdelay_resp message */
    *(UInteger16 *) (buf + 34) =
        flip16(receiveTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) = flip32(receiveTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) = flip32(receiveTimestamp->nanosecondsField);
    copyClockIdentity((buf + 44), header->sourcePortIdentity.clockIdentity);
    *(UInteger16 *) (buf + 52) =
        flip16(header->sourcePortIdentity.portNumber);
}


/*pack PdelayResp message into OUT buffer of ptpClock*/
void 
msg::msgPackPDelayResp(Octet * buf, MsgHeader * header, Timestamp * requestReceiptTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);
    
    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x03;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(PDELAY_RESP_LENGTH);
    *(UInteger8 *) (buf + 4) = header->domainNumber;
    memset((buf + 8), 0, 8);

    *(UInteger32 *) (buf + 16) = flip32(header->reserved2);

    *(UInteger16 *) (buf + 30) = flip16(header->sequenceId);

    *(UInteger8 *) (buf + 32) = 0x05;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = 0x7F;
    /* Table 24 */

    /* Pdelay_resp message */
    *(UInteger16 *) (buf + 34) = flip16(requestReceiptTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) = flip32(requestReceiptTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) = flip32(requestReceiptTimestamp->nanosecondsField);
    copyClockIdentity((buf + 44), header->sourcePortIdentity.clockIdentity);
    *(UInteger16 *) (buf + 52) = flip16(header->sourcePortIdentity.portNumber);

}


/*Unpack delayReq message from IN buffer of ptpClock to msgtmp.req*/
void
msg::msgUnpackDelayReq(Octet * buf, MsgDelayReq * delayreq)
{
    delayreq->originTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    delayreq->originTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    delayreq->originTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgDelayReq_display(delayreq);
    #endif /* PTPD_DBG */

}


/*Unpack PdelayReq message from IN buffer of ptpClock to msgtmp.req*/
void
msg::msgUnpackPDelayReq(Octet * buf, MsgPDelayReq * pdelayreq)
{
    pdelayreq->originTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    pdelayreq->originTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    pdelayreq->originTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgPDelayReq_display(pdelayreq);
    #endif /* PTPD_DBG */

}


/*Unpack delayResp message from IN buffer of ptpClock to msgtmp.presp*/
void
msg::msgUnpackDelayResp(Octet * buf, MsgDelayResp * resp)
{
    resp->receiveTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    resp->receiveTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    resp->receiveTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));
    copyClockIdentity(resp->requestingPortIdentity.clockIdentity,
           (buf + 44));
    resp->requestingPortIdentity.portNumber =
        flip16(*(UInteger16 *) (buf + 52));

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgDelayResp_display(resp);
    #endif /* PTPD_DBG */
}


/*Unpack PdelayResp message from IN buffer of ptpClock to msgtmp.presp*/
void
msg::msgUnpackPDelayResp(Octet * buf, MsgPDelayResp * presp)
{
    presp->requestReceiptTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    presp->requestReceiptTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    presp->requestReceiptTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));
    copyClockIdentity(presp->requestingPortIdentity.clockIdentity,
           (buf + 44));
    presp->requestingPortIdentity.portNumber =
        flip16(*(UInteger16 *) (buf + 52));

    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->msgPDelayResp_display(presp);
    #endif /* PTPD_DBG */
}

/*pack PdelayRespfollowup message into OUT buffer of ptpClock*/
void 
msg::msgPackPDelayRespFollowUp(Octet * buf, MsgHeader * header, Timestamp * responseOriginTimestamp, PtpClock * ptpClock)
{
    msgPackHeader(buf, ptpClock);
    
    /* changes in header */
    *(char *)(buf + 0) = *(char *)(buf + 0) & 0xF0;
    /* RAZ messageType */
    *(char *)(buf + 0) = *(char *)(buf + 0) | 0x0A;
    /* Table 19 */
    *(UInteger16 *) (buf + 2) = flip16(PDELAY_RESP_FOLLOW_UP_LENGTH);
    *(UInteger16 *) (buf + 30) = flip16(ptpClock->PdelayReqHeader.sequenceId);
    *(UInteger8 *) (buf + 32) = 0x05;
    /* Table 23 */
    *(Integer8 *) (buf + 33) = 0x7F;
    /* Table 24 */

    /* Copy correctionField of PdelayReqMessage */
    *(Integer32 *) (buf + 8) = flip32(header->correctionField.msb);
    *(Integer32 *) (buf + 12) = flip32(header->correctionField.lsb);

    /* Pdelay_resp_follow_up message */
    *(UInteger16 *) (buf + 34) =
        flip16(responseOriginTimestamp->secondsField.msb);
    *(UInteger32 *) (buf + 36) =
        flip32(responseOriginTimestamp->secondsField.lsb);
    *(UInteger32 *) (buf + 40) =
        flip32(responseOriginTimestamp->nanosecondsField);
    copyClockIdentity((buf + 44), header->sourcePortIdentity.clockIdentity);
    *(UInteger16 *) (buf + 52) =
        flip16(header->sourcePortIdentity.portNumber);
}

/*Unpack PdelayResp message from IN buffer of ptpClock to msgtmp.presp*/
void
msg::msgUnpackPDelayRespFollowUp(Octet * buf, MsgPDelayRespFollowUp * prespfollow)
{
    prespfollow->responseOriginTimestamp.secondsField.msb =
        flip16(*(UInteger16 *) (buf + 34));
    prespfollow->responseOriginTimestamp.secondsField.lsb =
        flip32(*(UInteger32 *) (buf + 36));
    prespfollow->responseOriginTimestamp.nanosecondsField =
        flip32(*(UInteger32 *) (buf + 40));
    copyClockIdentity(prespfollow->requestingPortIdentity.clockIdentity,
           (buf + 44));
    prespfollow->requestingPortIdentity.portNumber =
        flip16(*(UInteger16 *) (buf + 52));

#ifdef PTPD_DBG
        m_pApp->m_ptr_display->msgPDelayRespFollowUp_display(prespfollow);
#endif /* PTPD_DBG */
}

/* Pack Management message into OUT buffer */
void
msg::msgPackManagementTLV(Octet *buf, MsgManagement *outgoing, PtpClock *ptpClock)
{
        DBGV("packing ManagementTLV message \n");

    UInteger16 lengthField = 0;

    switch(outgoing->tlv->managementId)
    {
    case MM_NULL_MANAGEMENT:
    case MM_SAVE_IN_NON_VOLATILE_STORAGE:
    case MM_RESET_NON_VOLATILE_STORAGE:
    case MM_ENABLE_PORT:
    case MM_DISABLE_PORT:
        lengthField = 0;
        break;
    case MM_CLOCK_DESCRIPTION:
        lengthField = packMMClockDescription(outgoing, buf);
        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMClockDescription_display(
                (MMClockDescription*)outgoing->tlv->dataField, ptpClock);
        #endif /* PTPD_DBG */
        break;
    case MM_USER_DESCRIPTION:
            lengthField = packMMUserDescription(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMUserDescription_display(
                            (MMUserDescription*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_INITIALIZE:
            lengthField = packMMInitialize(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMInitialize_display(
                            (MMInitialize*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_DEFAULT_DATA_SET:
            lengthField = packMMDefaultDataSet(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMDefaultDataSet_display(
                            (MMDefaultDataSet*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_CURRENT_DATA_SET:
            lengthField = packMMCurrentDataSet(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMCurrentDataSet_display(
                            (MMCurrentDataSet*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_PARENT_DATA_SET:
            lengthField = packMMParentDataSet(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMParentDataSet_display(
                            (MMParentDataSet*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_TIME_PROPERTIES_DATA_SET:
            lengthField = packMMTimePropertiesDataSet(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMTimePropertiesDataSet_display(
                            (MMTimePropertiesDataSet*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_PORT_DATA_SET:
            lengthField = packMMPortDataSet(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMPortDataSet_display(
                            (MMPortDataSet*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_PRIORITY1:
            lengthField = packMMPriority1(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMPriority1_display(
                            (MMPriority1*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_PRIORITY2:
            lengthField = packMMPriority2(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMPriority2_display(
                            (MMPriority2*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_DOMAIN:
            lengthField = packMMDomain(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMDomain_display(
                            (MMDomain*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_SLAVE_ONLY:
        lengthField = packMMSlaveOnly(outgoing, buf);
        #ifdef PTPD_DBG
        m_pApp->m_ptr_display->mMSlaveOnly_display(
                (MMSlaveOnly*)outgoing->tlv->dataField, ptpClock);
        #endif /* PTPD_DBG */
        break;
    case MM_LOG_ANNOUNCE_INTERVAL:
            lengthField = packMMLogAnnounceInterval(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMLogAnnounceInterval_display(
                            (MMLogAnnounceInterval*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_ANNOUNCE_RECEIPT_TIMEOUT:
            lengthField = packMMAnnounceReceiptTimeout(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMAnnounceReceiptTimeout_display(
                            (MMAnnounceReceiptTimeout*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_LOG_SYNC_INTERVAL:
            lengthField = packMMLogSyncInterval(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMLogSyncInterval_display(
                            (MMLogSyncInterval*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_VERSION_NUMBER:
            lengthField = packMMVersionNumber(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMVersionNumber_display(
                            (MMVersionNumber*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_TIME:
            lengthField = packMMTime(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMTime_display(
                            (MMTime*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_CLOCK_ACCURACY:
            lengthField = packMMClockAccuracy(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMClockAccuracy_display(
                            (MMClockAccuracy*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_UTC_PROPERTIES:
            lengthField = packMMUtcProperties(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMUtcProperties_display(
                            (MMUtcProperties*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_TRACEABILITY_PROPERTIES:
            lengthField = packMMTraceabilityProperties(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMTraceabilityProperties_display(
                            (MMTraceabilityProperties*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_DELAY_MECHANISM:
            lengthField = packMMDelayMechanism(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMDelayMechanism_display(
                            (MMDelayMechanism*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    case MM_LOG_MIN_PDELAY_REQ_INTERVAL:
            lengthField = packMMLogMinPdelayReqInterval(outgoing, buf);
            #ifdef PTPD_DBG
            m_pApp->m_ptr_display->mMLogMinPdelayReqInterval_display(
                            (MMLogMinPdelayReqInterval*)outgoing->tlv->dataField, ptpClock);
            #endif /* PTPD_DBG */
            break;
    default:
        DBGV("packing management msg: unsupported id \n");
    }

    /* set lengthField */
    outgoing->tlv->lengthField = lengthField;

    packManagementTLV((ManagementTLV*)outgoing->tlv, buf);
}

/* Pack ManagementErrorStatusTLV message into OUT buffer */
void
msg::msgPackManagementErrorStatusTLV(Octet *buf, MsgManagement *outgoing,
                PtpClock *ptpClock)
{
        DBGV("packing ManagementErrorStatusTLV message \n");

    UInteger16 lengthField = 0;

    lengthField = packMMErrorStatus(outgoing, buf);
    #ifdef PTPD_DBG
    m_pApp->m_ptr_display->mMErrorStatus_display((MMErrorStatus*)outgoing->tlv->dataField, ptpClock);
    #endif /* PTPD_DBG */

    /* set lengthField */
    outgoing->tlv->lengthField = lengthField;

    packManagementTLV((ManagementTLV*)outgoing->tlv, buf);
}

void
msg::freeMMTLV(ManagementTLV* tlv) {
    DBGV("cleanup managementTLV data\n");
    switch(tlv->managementId)
    {
    case MM_CLOCK_DESCRIPTION:
        DBGV("cleanup clock description \n");
        freeMMClockDescription((MMClockDescription*)tlv->dataField);
        break;
    case MM_USER_DESCRIPTION:
        DBGV("cleanup user description \n");
        freeMMUserDescription((MMUserDescription*)tlv->dataField);
        break;
    case MM_NULL_MANAGEMENT:
    case MM_SAVE_IN_NON_VOLATILE_STORAGE:
    case MM_RESET_NON_VOLATILE_STORAGE:
    case MM_INITIALIZE:
    case MM_DEFAULT_DATA_SET:
    case MM_CURRENT_DATA_SET:
    case MM_PARENT_DATA_SET:
    case MM_TIME_PROPERTIES_DATA_SET:
    case MM_PORT_DATA_SET:
    case MM_PRIORITY1:
    case MM_PRIORITY2:
    case MM_DOMAIN:
    case MM_SLAVE_ONLY:
    case MM_LOG_ANNOUNCE_INTERVAL:
    case MM_ANNOUNCE_RECEIPT_TIMEOUT:
    case MM_LOG_SYNC_INTERVAL:
    case MM_VERSION_NUMBER:
    case MM_ENABLE_PORT:
    case MM_DISABLE_PORT:
    case MM_TIME:
    case MM_CLOCK_ACCURACY:
    case MM_UTC_PROPERTIES:
    case MM_TRACEABILITY_PROPERTIES:
    case MM_DELAY_MECHANISM:
    case MM_LOG_MIN_PDELAY_REQ_INTERVAL:
    default:
        DBGV("no managementTLV data to cleanup \n");
    }
}

void
msg::freeMMErrorStatusTLV(ManagementTLV *tlv) {
    DBGV("cleanup managementErrorStatusTLV data \n");
    freeMMErrorStatus((MMErrorStatus*)tlv->dataField);
}

void
msg::msgPackManagement(Octet *buf, MsgManagement *outgoing, PtpClock *ptpClock)
{
    DBGV("packing management message \n");
    packMsgManagement(outgoing, buf);

}

/*Unpack Management message from IN buffer of ptpClock to msgtmp.manage*/
void
msg::msgUnpackManagement(Octet *buf, MsgManagement * manage, MsgHeader * header, PtpClock *ptpClock)
{
    unpackMsgManagement(buf, manage, ptpClock);

    if ( manage->header.messageLength > MANAGEMENT_LENGTH )
    {
        unpackManagementTLV(buf, manage, ptpClock);

        /* at this point, we know what managementTLV we have, so return and
         * let someone else handle the data */
        manage->tlv->dataField = NULL;
    }
    else /* no TLV attached to this message */
    {
        manage->tlv = NULL;
    }

}

/** 
 * Dump the most recent packet in the daemon
 * 
 * @param ptpClock The central clock structure
 */
void msg::msgDump(PtpClock *ptpClock)
{
    msgDebugHeader(&ptpClock->msgTmpHeader);
    switch (ptpClock->msgTmpHeader.messageType) {
    case SYNC:
        msgDebugSync(&ptpClock->msgTmp.sync);
        break;
    
    case ANNOUNCE:
        msgDebugAnnounce(&ptpClock->msgTmp.announce);
        break;
    
    case FOLLOW_UP:
        msgDebugFollowUp(&ptpClock->msgTmp.follow);
        break;
    
    case DELAY_REQ:
        msgDebugDelayReq(&ptpClock->msgTmp.req);
        break;
    
    case DELAY_RESP:
        msgDebugDelayResp(&ptpClock->msgTmp.resp);
        break;
    
    case MANAGEMENT:
        msgDebugManagement(&ptpClock->msgTmp.manage);
        break;
    
    default:
        NOTIFY("msgDump:unrecognized message\n");
        break;
    }
}

/** 
 * Dump a PTP message header
 * 
 * @param header a pre-filled msg header structure
 */

void msg::msgDebugHeader(MsgHeader *header)
{
    NOTIFY("msgDebugHeader: messageType %d\n", header->messageType);
    NOTIFY("msgDebugHeader: versionPTP %d\n", header->versionPTP);
    NOTIFY("msgDebugHeader: messageLength %d\n", header->messageLength);
    NOTIFY("msgDebugHeader: domainNumber %d\n", header->domainNumber);
    NOTIFY("msgDebugHeader: flags %02hhx %02hhx\n", 
           header->flagField0, header->flagField1);
    NOTIFY("msgDebugHeader: correctionfield %d\n", header->correctionField);
    NOTIFY("msgDebugHeader: sourcePortIdentity.clockIdentity "
           "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx%02hhx:%02hhx\n",
           header->sourcePortIdentity.clockIdentity[0], 
           header->sourcePortIdentity.clockIdentity[1], 
           header->sourcePortIdentity.clockIdentity[2], 
           header->sourcePortIdentity.clockIdentity[3], 
           header->sourcePortIdentity.clockIdentity[4], 
           header->sourcePortIdentity.clockIdentity[5], 
           header->sourcePortIdentity.clockIdentity[6], 
           header->sourcePortIdentity.clockIdentity[7]);
    NOTIFY("msgDebugHeader: sourcePortIdentity.portNumber %d\n",
           header->sourcePortIdentity.portNumber);
    NOTIFY("msgDebugHeader: sequenceId %d\n", header->sequenceId);
    NOTIFY("msgDebugHeader: controlField %d\n", header->controlField);
    NOTIFY("msgDebugHeader: logMessageIntervale %d\n", 
           header->logMessageInterval);

}

/** 
 * Dump the contents of a sync packet
 * 
 * @param sync A pre-filled MsgSync structure
 */

void msg::msgDebugSync(MsgSync *sync)
{
    NOTIFY("msgDebugSync: originTimestamp.seconds %u\n",
           sync->originTimestamp.secondsField);
    NOTIFY("msgDebugSync: originTimestamp.nanoseconds %d\n",
           sync->originTimestamp.nanosecondsField);
}

/** 
 * Dump the contents of a announce packet
 * 
 * @param sync A pre-filled MsgAnnounce structure
 */

void msg::msgDebugAnnounce(MsgAnnounce *announce)
{
    NOTIFY("msgDebugAnnounce: originTimestamp.seconds %u\n",
           announce->originTimestamp.secondsField);
    NOTIFY("msgDebugAnnounce: originTimestamp.nanoseconds %d\n",
           announce->originTimestamp.nanosecondsField);
    NOTIFY("msgDebugAnnounce: currentUTCOffset %d\n", 
           announce->currentUtcOffset);
    NOTIFY("msgDebugAnnounce: grandmasterPriority1 %d\n", 
           announce->grandmasterPriority1);
    NOTIFY("msgDebugAnnounce: grandmasterClockQuality.clockClass %d\n",
           announce->grandmasterClockQuality.clockClass);
    NOTIFY("msgDebugAnnounce: grandmasterClockQuality.clockAccuracy %d\n",
           announce->grandmasterClockQuality.clockAccuracy);
    NOTIFY("msgDebugAnnounce: "
           "grandmasterClockQuality.offsetScaledLogVariance %d\n",
           announce->grandmasterClockQuality.offsetScaledLogVariance);
    NOTIFY("msgDebugAnnounce: grandmasterPriority2 %d\n", 
           announce->grandmasterPriority2);
    NOTIFY("msgDebugAnnounce: grandmasterClockIdentity "
           "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx%02hhx:%02hhx\n",
           announce->grandmasterIdentity[0], 
           announce->grandmasterIdentity[1], 
           announce->grandmasterIdentity[2], 
           announce->grandmasterIdentity[3], 
           announce->grandmasterIdentity[4], 
           announce->grandmasterIdentity[5], 
           announce->grandmasterIdentity[6], 
           announce->grandmasterIdentity[7]);
    NOTIFY("msgDebugAnnounce: stepsRemoved %d\n", 
           announce->stepsRemoved);
    NOTIFY("msgDebugAnnounce: timeSource %d\n", 
           announce->timeSource);
}

/** 
 * NOT IMPLEMENTED
 * 
 * @param req 
 */
void msg::msgDebugDelayReq(MsgDelayReq *req) {}

/** 
 * Dump the contents of a followup packet
 * 
 * @param follow A pre-fille MsgFollowUp structure
 */
void msg::msgDebugFollowUp(MsgFollowUp *follow)
{
    NOTIFY("msgDebugFollowUp: preciseOriginTimestamp.seconds %u\n",
           follow->preciseOriginTimestamp.secondsField);
    NOTIFY("msgDebugFollowUp: preciseOriginTimestamp.nanoseconds %d\n",
           follow->preciseOriginTimestamp.nanosecondsField);
}

/** 
 * Dump the contents of a delay response packet
 * 
 * @param resp a pre-filled MsgDelayResp structure
 */
void msg::msgDebugDelayResp(MsgDelayResp *resp)
{
    NOTIFY("msgDebugDelayResp: delayReceiptTimestamp.seconds %u\n",
           resp->receiveTimestamp.secondsField);
    NOTIFY("msgDebugDelayResp: delayReceiptTimestamp.nanoseconds %d\n",
           resp->receiveTimestamp.nanosecondsField);
    NOTIFY("msgDebugDelayResp: requestingPortIdentity.clockIdentity "
           "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx%02hhx:%02hhx\n",
           resp->requestingPortIdentity.clockIdentity[0], 
           resp->requestingPortIdentity.clockIdentity[1], 
           resp->requestingPortIdentity.clockIdentity[2], 
           resp->requestingPortIdentity.clockIdentity[3], 
           resp->requestingPortIdentity.clockIdentity[4], 
           resp->requestingPortIdentity.clockIdentity[5], 
           resp->requestingPortIdentity.clockIdentity[6], 
           resp->requestingPortIdentity.clockIdentity[7]);
    NOTIFY("msgDebugDelayResp: requestingPortIdentity.portNumber %d\n",
           resp->requestingPortIdentity.portNumber);
}

/** 
 * Dump the contents of management packet
 * 
 * @param manage a pre-filled MsgManagement structure
 */

void msg::msgDebugManagement(MsgManagement *manage)
{
    NOTIFY("msgDebugDelayManage: targetPortIdentity.clockIdentity "
           "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx\n",
           manage->targetPortIdentity.clockIdentity[0], 
           manage->targetPortIdentity.clockIdentity[1], 
           manage->targetPortIdentity.clockIdentity[2], 
           manage->targetPortIdentity.clockIdentity[3], 
           manage->targetPortIdentity.clockIdentity[4], 
           manage->targetPortIdentity.clockIdentity[5], 
           manage->targetPortIdentity.clockIdentity[6], 
           manage->targetPortIdentity.clockIdentity[7]);
    NOTIFY("msgDebugDelayManage: targetPortIdentity.portNumber %d\n",
           manage->targetPortIdentity.portNumber);
    NOTIFY("msgDebugManagement: startingBoundaryHops %d\n",
           manage->startingBoundaryHops);
    NOTIFY("msgDebugManagement: boundaryHops %d\n", manage->boundaryHops);
    NOTIFY("msgDebugManagement: actionField %d\n", manage->actionField);
    NOTIFY("msgDebugManagement: tvl %s\n", manage->tlv);
}
