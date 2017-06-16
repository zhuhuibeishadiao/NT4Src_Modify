/*++

Copyright (C) 1995 Microsoft Corporation

Module Name:

   perfutil.h

Abstract:

   This file supports routines used to parse and create performance monitor
   data structures. It actually supports performance object types with
   multiple instances.

Author:

   Stephane Plante (2/2/95)

Revisition History:


--*/

#ifndef _PERFUTIL_H_
#define _PERFUTIL_H_

// enable this define to log process heap data to the event log
#ifdef PROBE_HEAP_USAGE
#undef PROBE_HEAP_USAGE
#endif

//
// Utility Macro. This is used to resert a DWORD multiple of
// bytes for unicode string embeeded in the definitional data,
// viz., object instance names.
//

#define DWORD_MULTIPLE(x) (((x+sizeof(DWORD)-1)/sizeof(DWORD))*sizeof(DWORD))

// assumes dword is 4 bytes long and pointer is a dword in size
#define ALIGN_ON_DWORD(x) ((VOID *)( ((DWORD) x & 0x00000003) ? ( ((DWORD) x & 0xFFFFFFFC ) + 4) : ( (DWORD) x ) ))

extern WCHAR GLOBAL_STRING[];
extern WCHAR FOREIGN_STRING[];
extern WCHAR COSTLY_STRING[];
extern WCHAR NULL_STRING[];

#define QUERY_GLOBAL	0x1
#define QUERY_ITEMS	0x2
#define QUERY_FOREIGN	0x4
#define QUERY_COSTLY	0x8

//
// Function declerations
//

BOOL MonBuildInstanceDefinition( PERF_INSTANCE_DEFINITION *,
   PVOID *,
   DWORD,
   DWORD,
   DWORD,
   PUNICODE_STRING);

HANDLE
MonOpenEventLog(
   );

VOID
MonCloseEventLog(
   );

DWORD
GetQueryType(
   IN LPWSTR
   );

BOOL
IsNumberInUnicodeList(
   DWORD,
   LPWSTR
   );

//
// Structures
//

typedef struct _LOCAL_HEAP_INFO_BLOCK {
   DWORD	AllocatedEntries;
   DWORD	AllocatedBytes;
   DWORD	FreeEntries;
   DWORD	FreeBytes;
} LOCAL_HEAP_INFO, *PLOCAL_HEAP_INFO;

//
// Memory Probe Macro
//

#ifdef PROBE_HEAP_USAGE
#define HEAP_PROBE() { \
   DWORD dwHeapStatus[5]; \
   NTSTATUS CallStatus; \
   dwHeapStatus[4] == __LINE__; \
   if (!(CallStatus = memprobe(dwHeapStatus, 16L, NULL) ) ) { \
      REPORT_INFORMATION_DATA(TCP_HEAP_STATUS, LOG_DEBUG, \
   	 &dwHeapStatus, sizeof(dwHeapStatus)); \
   } else { \
      REPORT_ERROR_DATA(TCP_HEAP_STATUS, LOG_DEBUG, \
   	 &CallStatus, sizeof(DWORD) ); \
   } \
}
#else
#define HEAP_PROBE() ;
#endif // PROB_HEAP_USAGE

#endif // _PERFUTIL_H_