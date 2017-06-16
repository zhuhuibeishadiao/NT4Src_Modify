#if defined(DUO) && defined(R4000)
/*++

Copyright (c) 1991  Microsoft Corporation

Module Name:

    d4reset.s

Abstract:

    This module is the start of the flash prom code. This code will
    be the first run upon reset. It contains the self-test and
    initialization.

Author:

    Lluis Abello (lluis)  8-Jan-91

Environment:

    Executes in kernal mode.

Notes:

    ***** IMPORTANT *****

    This module must be linked such that it resides in the
    first page of the rom.

Revision History:


--*/
//
// include header file
//
#include <ksmips.h>
#include <duoprom.h>
#include "dmaregs.h"
#include "selfmap.h"
#include "led.h"
#include "j4reset.h"


#define  TlbInit    PROM_ENTRY(10)



//TEMPTEMP

#define COPY_ENTRY 6

.text
.set noreorder
.set noat


        ALTERNATE_ENTRY(ResetVector)
/*++

Routine Description:

    This routine will provide the jump vectors located
    at the targets of the processor exception vectors.

    N.B. This routine must be located at the start of ROM which
    is the location of the reset vector.

Arguments:

    None.

Return Value:

    None.

--*/
//
// this instruction must be loaded at location 0 in the
// rom. This will appear as BFC00000 to the processor
//
        b       ResetException
        nop

//
// This is the jump table for rom routines that other
// programs can call. They are placed here so that they
// will be unlikely to move.
//
//
// This becomes PROM_ENTRY(2) as defined in ntmips.h
//
        .align  4
        nop
//
// Entries 4 to 7 are used for the ROM Version and they
// must be zero in this file.
//

//
// This becomes PROM_ENTRYS(8,9...)
//
        .align 6
        nop                             // entry 8
        nop
        nop                             // entry 9
        nop
        b       InvalidateDCache        // entry 10
        nop
        b       InvalidateSCache        // entry 11
        nop
        b       InvalidateICache        // entry 12
        nop
        nop                             // entry 13
        nop
        b       PutLedDisplay           // entry 14
        nop
        nop                             // entry 15
        nop
        nop                             // entry 16
        nop

RomRemoteSpeedValues:
//
// This table contains the default values for the remote speed regs.
//
        .byte REMSPEED1                 // ethernet
        .byte REMSPEED2                 // SCSI
        .byte REMSPEED3                 // SCSI
        .byte REMSPEED4                 // RTC
        .byte REMSPEED5                 // Kbd/Mouse
        .byte REMSPEED6                 // Serial port 1
        .byte REMSPEED7                 // Serial port 2
        .byte REMSPEED8                 // Parallel
        .byte REMSPEED9                 // NVRAM
        .byte REMSPEED10                // Int src reg
        .byte REMSPEED11                // PROM
        .byte REMSPEED12                // New dev
        .byte REMSPEED13                // New dev
        .byte REMSPEED14                // LED

        .align  4

//
// New TLB Entries can be added to the following table
// The format of the table is:
//      entryhi; entrylo0; entrylo1; pagemask
//
#define TLB_HI      0
#define TLB_LO0     4
#define TLB_LO1     8
#define TLB_MASK   12

TlbEntryTable:

//
// 256KB Base PROM  Read only
// 256KB Flash PROM Read/Write
//

        .word   ((PROM_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((PROM_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + (2 << ENTRYLO_C)


        .word   (((PROM_PHYSICAL_BASE+0x40000) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (2 << ENTRYLO_C) + (1 << ENTRYLO_D)

        .word   (PAGEMASK_256KB << PAGEMASK_PAGEMASK)

//
// I/O Device space non-cached, valid, dirty
//
        .word   ((DEVICE_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((DEVICE_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (1 << ENTRYLO_G)            // set global bit even if page not used
        .word   (PAGEMASK_64KB << PAGEMASK_PAGEMASK)
//
// video control 2MB non-cached read/write.
//
        .word   ((VIDEO_CONTROL_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((VIDEO_CONTROL_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((VIDEO_CONTROL_PHYSICAL_BASE+0x100000) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_1MB << PAGEMASK_PAGEMASK)
//
// extended video control 2MB non-cached read/write.
//
        .word   ((EXTENDED_VIDEO_CONTROL_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((EXTENDED_VIDEO_CONTROL_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)

        .word   (((EXTENDED_VIDEO_CONTROL_PHYSICAL_BASE+0x100000) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_1MB << PAGEMASK_PAGEMASK)
//
// video memory space 8Mb non-cached read/write
//
        .word   ((VIDEO_MEMORY_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((VIDEO_MEMORY_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((VIDEO_MEMORY_PHYSICAL_BASE+0x400000) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_4MB << PAGEMASK_PAGEMASK)
//
// EISA I/O 16Mb non-cached read/write
// EISA MEM 16Mb non-cached read/write
//
        .word   ((EISA_IO_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((EISA_IO_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   ((0x100000) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_16MB << PAGEMASK_PAGEMASK)
//
// EISA I/O page 0 non-cached read/write
// EISA I/O page 1 non-cached read/write
//
        .word   ((EISA_EXTERNAL_IO_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((0 >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((EISA_IO_PHYSICAL_BASE + 1 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_4KB << PAGEMASK_PAGEMASK)
//
// EISA I/O page 2 non-cached read/write
// EISA I/O page 3 non-cached read/write
//
        .word   (((EISA_EXTERNAL_IO_VIRTUAL_BASE + 2 * PAGE_SIZE) >> 13) << ENTRYHI_VPN2)
        .word   (((EISA_IO_PHYSICAL_BASE + 2 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((EISA_IO_PHYSICAL_BASE + 3 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_4KB << PAGEMASK_PAGEMASK)
//
// EISA I/O page 4 non-cached read/write
// EISA I/O page 5 non-cached read/write
//
        .word   (((EISA_EXTERNAL_IO_VIRTUAL_BASE + 4 * PAGE_SIZE) >> 13) << ENTRYHI_VPN2)
        .word   (((EISA_IO_PHYSICAL_BASE + 4 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) +\
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((EISA_IO_PHYSICAL_BASE + 5 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_4KB << PAGEMASK_PAGEMASK)
//
// EISA I/O page 6 non-cached read/write
// EISA I/O page 7 non-cached read/write
//
        .word   (((EISA_EXTERNAL_IO_VIRTUAL_BASE + 6 * PAGE_SIZE) >> 13) << ENTRYHI_VPN2)
        .word   (((EISA_IO_PHYSICAL_BASE + 6 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + \
                (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((EISA_IO_PHYSICAL_BASE + 7 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_4KB << PAGEMASK_PAGEMASK)
//
// EISA I/O pages 8,9,a,b non-cached read/write
// EISA I/O pages c,d,e,f non-cached read/write
//
        .word   (((EISA_EXTERNAL_IO_VIRTUAL_BASE + 8 * PAGE_SIZE) >> 13) << ENTRYHI_VPN2)
        .word   (((EISA_IO_PHYSICAL_BASE + 8 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (((EISA_IO_PHYSICAL_BASE + 12 * PAGE_SIZE) >> 12) << ENTRYLO_PFN) + \
                (1 << ENTRYLO_G) + (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_16KB << PAGEMASK_PAGEMASK)
//
// Map 64KB of memory for the video prom code&data cached.
//
        .word   ((VIDEO_PROM_CODE_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((VIDEO_PROM_CODE_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                  (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (3 << ENTRYLO_C)
        .word   (1 << ENTRYLO_G)        // set global bit even if page not used
        .word   (PAGEMASK_64KB << PAGEMASK_PAGEMASK)

//
// Map 4kb of exclusive memory and 4Kb of shared
//
        .word   ((EXCLUSIVE_PAGE_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   ((EXCLUSIVE_PAGE_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                  (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (4 << ENTRYLO_C)
        .word   ((SHARED_PAGE_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                  (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (5 << ENTRYLO_C)
        .word   (PAGEMASK_4KB << PAGEMASK_PAGEMASK)


//
// Map PCR for kernel debugger.
//
        .word   ((PCR_VIRTUAL_BASE >> 13) << ENTRYHI_VPN2)
        .word   (1 << ENTRYLO_G)        // set global bit even if page not used
        .word   ((PCR_PHYSICAL_BASE >> 12) << ENTRYLO_PFN) + (1 << ENTRYLO_G) + \
                  (1 << ENTRYLO_V) + (1 << ENTRYLO_D) + (2 << ENTRYLO_C)
        .word   (PAGEMASK_4KB << PAGEMASK_PAGEMASK)

TlbEntryEnd:
        .byte   0



//
// these next vectors should be loaded at PROM_BASE + 0x200, 0x300,
// and 0x380. They are for the TLBmiss, cache_error, and
// common exceptions respectively.
//
        .align 9
        LEAF_ENTRY(UserTlbMiss200)
UserTlbMiss:
        li      k0,KSEG1_BASE
        lw      k0,0x1018(k0)           // Load address of UTBMiss handler
        nop
        jal     k1,k0                   // jump to handler saving return
        nop                             // address in k1
        mtc0    k0,epc                  // Handler returns return address in K0
        nop                             // 2 cycle Hazard
        nop
        eret                            // restore from exception
        .end    UserTlbMiss200


ParityError:
//
//  Change kseg0 coherency to non cached.
//
        mfc0    k0,config               // get config register
        li      k1,~(7 << CONFIG_K0)    // mask to clear Kseg0 coherency bits
        and     k0,k0,k1                // clear bits
        ori     k0,(2 << CONFIG_K0)     // make kseg0 non cached
	mtc0	k0,config		//
//
// Copy the copy routines to memory
//
        la      a0,MemoryRoutines       // source
        la      a1,MemoryRoutines-LINK_ADDRESS+KSEG1_BASE // destination location
        la      t2,EndMemoryRoutines    // end
        bal     DataCopy                // copy code to memory
	subu	a2,t2,a0		// length of code
//
// Copy the firmware from PROM to memory.
//
        la      s0,Decompress-LINK_ADDRESS+KSEG1_BASE
					// address of decompression routine in cached space
	la	a0,end			// end of this file is start of selftest
        li      a1,RAM_TEST_DESTINATION_ADDRESS
                                        // destination is uncached link address.
        jal     s0                      // jump to decompress
        nop

//
//      Initialize the stack to the low memory and Call Rom tests.
//
	li	t0,RAM_TEST_DESTINATION_ADDRESS // address of copied code
	li	sp,RAM_TEST_STACK_ADDRESS | KSEG1_BASE // init stack non cached
        move    a1,s5                   // Pass cacheerr register as 2nd arg
        jal     t0                      // jump to self-test in memory
        li      a0,3                    // pass cause of exception as argument.

//
// This becomes the entry point of a Cache Error Exception.
// It should be located at offset 0x300
//
        .align 8
/*++
ParityHandler();
Routine Description:

        This routine is called as a result of a Cache Error exception
        It copies the firmware to memory and jumps to it where error
        information is printed.

Arguments:

        None.

Return Value:

        Does not return

--*/
        LEAF_ENTRY(ParityHandler300)
        //
        // Should save state.
	//
	li	k0,(1<<PSR_BEV) | (1 << PSR_CU1) | (1<<PSR_ERL)
	mtc0	k0,psr			// initialize psr
	nop
	li	k0,(1<<PSR_BEV) | (1 << PSR_CU1)
        nop
        mtc0    k0,psr                  // Clear ERL bit

//
// TMPTMP
// Reinitialize tlb. Should save state somewhere.
// Copy the tlb table to memory. And call the map routine in the base prom.
//
        la      t0, TlbEntryTable       // Load address of table in prom
        la      t1, TlbEntryEnd         //
        li      a1, KSEG1_BASE+0x400    // Destination address.
10:
        lw      v0,0(t0)                // Load from prom
        sw      v0,0(a1)                // store into memory
        addiu   t0,t0,4                 // next source
        bne     t0,t1,10b               // branch if not end
        addiu   a1,a1,4                 // next dest address

        li      a0,KSEG1_BASE+0x400     // base of table in memory
        li      k0,TlbInit              // Get address of TLB init in base prom
        jal     k0                      // Go to reinitialize the tlb
        li      a2,COPY_ENTRY+1         // tlb index
        li      t0,TRANSFER_VECTOR      // get address of transfer vector
        sw      v0,4(t0)                // set next free TB entry index.
        mfc0    s5,cacheerr             // Load cache error register
	bal	PutLedDisplay
	ori	a0,zero,LED_PARITY	//
        b       ParityError
	nop

        .end    ParityHandler300
//
// This becomes the entry point of a General Exception.
// It should be located at offset 380
//
/*++
GeneralExceptionHandler();
Routine Description:

        This routine is called as a result of a General Exception
        The address of the General Exception Handler is loaded from the
        ArcVector and the handler is called.

        For DUO. A DBE can mean memory ECC error.

Arguments:

        None

Return Value:

        None

--*/
        .align 7
        LEAF_ENTRY(GeneralException380)
        mfc0    k0,cause                // read cause register.
        li      k1,XCODE_DATA_BUS_ERROR //
        andi    k0,R4000_XCODE_MASK     // Extract xcode bits
        beq     k1,k0,BusError          // Branch if DBE
        li      k1,XCODE_INSTRUCTION_BUS_ERROR //
        beq     k1,k0,BusError          // Branch if IBE
CallArcGEHandler:                       //
        li      k0,KSEG1_BASE
        lw      k0,0x1014(k0)           // Load address of GE handler
        nop
        jal     k1,k0                   // jump to handler saving return
        nop                             // address in k1
        mtc0    k0,epc                  // Handler returns return address in K0
        nop                             // 2 cycle Hazard
        nop
        eret                            // restore from exception
        nop
BusError:
        //
        // If this is actually an ECC Error then call the Cache Error Handler
        // Otherwise call the ARC GE Exception Handler.
        //
        li      k0,DMA_VIRTUAL_BASE     // load base address of MCT_ADR
        lw      k0,DmaNMISource(k0)     // Read the interrupt source register.
        li      k1,1                    // Memory Error bit
        bne     k0,k1,CallArcGEHandler  // If Bit Not set Call the Arc Handler

//
// This is an ECC error.
//
DuoEccHandler:
        li      k0,DMA_VIRTUAL_BASE     // load base address of MCT_ADR
        lw      k1,DmaMemoryFailedAddress(k0)   // read MFAR to clear bit
        lw      k1,DmaEccDiagnostic(k0) // clear error in parity diag reg.
        mfc0    k0,epc                  // get address of exception
        li      k1,0xFFFFFFF0           // mask to align address of exception
        and     k0,k1,k0                // align epc
        la      k1,ExpectedParityException  // get address where exception is expected
        bne     k0,k1,CallArcGEHandler  // if not equal call ARC handler
        addiu   k1,0x10                 // set exception return address 4 instructions further
        mtc0    k1,epc                  // move into epc
        addiu   v1,zero,1               // set return value to 1.
        nop                             // fill second cycle hazard
        eret                            // return
                                        // Return.
        .end    GeneralException380

        ALTERNATE_ENTRY(ResetException)
/*++

Routine Description:

    This is the handler for the reset exception. It first checks the cause
    of the exception. If it is an NMI, then control is passed to the
    exception dispatch routine. Otherwise the machine is initialized.

    The basic  are:
    1) Map the I/O devices.
    2) Test the processor.
    3) Test the MCTADR
    4) Map ROM. Perform a ROM checksum.
    5) Test a portion of Memory
    6) Test TLB
    7) Copy routines to memory
    8) Initialize caches
    9) Initialize stack for C language calls and other stack operations
    10) Copy selftest and firmware code to memory and jump to it.

    N.B. This routine must be loaded into the first page of rom.

Arguments:

    None.

Return Value:

    None.

--*/

//
// If the exception is a hard reset, the TLB has been initialized by the
// base prom to map all the system resources.
// If it's a soft reset, the only device we know is mapped is the flash prom
// since this code is being fetched from it.
//

//
// Check cause of exception, if SR bit in PSR is set treat it as a soft reset
// or an NMI, otherwise it's a cold reset.
//
        mfc0    k0,psr                  // get cause register
        li      k1,(1<<PSR_SR)          // bit indicates soft reset.
        mtc0    zero,watchlo            // initialize the watch
        mtc0    zero,watchhi            // address registers
        and     k1,k1,k0                // mask PSR with SR bit
        li      k0,(1<<PSR_BEV) | (1 << PSR_CU1) | (1<<PSR_ERL)
        mtc0    k0,psr                  // Clear interrupt bit while ERL still set
        nop
        beq     k1,zero,10f             // branch if cold reset
        move    s5,zero                 // clear s5 to indicate cold reset
        ori     s5,zero,1               // set s5 to 1 to indicate soft reset
10:
        li      k0,(1<<PSR_BEV) | (1 << PSR_CU1)
        nop
        mtc0    k0,psr                  // Clear ERL bit

//
// TMPTMP
// Reinitialize tlb. Should save state somewhere.
// Copy the tlb table to memory. And call the map routine in the base prom.
//
        la      t0, TlbEntryTable       // Load address of table in prom
        la      t1, TlbEntryEnd         //
        li      a1, KSEG1_BASE+0x400    // Destination address.
10:
        lw      v0,0(t0)                // Load from prom
        sw      v0,0(a1)                // store into memory
        addiu   t0,t0,4                 // next source
        bne     t0,t1,10b               // branch if not end
        addiu   a1,a1,4                 // next dest address

        li      a0,KSEG1_BASE+0x400     // base of table in memory
        li      k0,TlbInit              // Get address of TLB init in base prom
        jal     k0                      // Go to reinitialize the tlb
        li      a2,COPY_ENTRY+1         // tlb index

        li      t0,TRANSFER_VECTOR      // get address of transfer vector
        sw      v0,4(t0)                // set next free TB entry index.
        beq     s5,zero,Reset           // branch if cold reset
        li      k0,DMA_VIRTUAL_BASE     // load base address of MCT_ADR
        lw      k1,DmaNMISource(k0)     // Read the interrupt source register.
        andi    k0,k1,(1<<3)            // test for NMI
        beq     k0,zero,Reset           // if bit not set this is a Soft Reset
                                        // otherwise is an NMI

        //
        // Nmi Handler jump to firmware to print message.
        //
        li      k0,DMA_VIRTUAL_BASE        // load base address of MCT_ADR
        lw      k1,DmaWhoAmI(k0)           // Read who am I
        beq     k1,zero,ProcessorANMI      // Processor B dies here in a loop.
        lw      zero,DmaIpInterruptAcknowledge(k0)// read IP Ack register to clear pending interrupts
        li      k1,(1 << 4)                // IP interrupt enable bit
        sw      k1,DmaInterruptEnable(k0)  // Enable IP interrupts.
5:
        mfc0    k0,cause                        // get cause register
        li      k1,1<<14                        // mask to test IP interrupt
        and     k0,k1                           // and them
        beq     k0,zero,5b                      // Keep looping if not set
        li      k1,DMA_VIRTUAL_BASE             // load DMA base
        lw      k1,DmaIpInterruptAcknowledge(k1)// read IP Ack register to clear it
30:
        mfc0    k0,cause                        // get cause register
        li      k1,1<<14                        // mask to test IP interrupt
        and     k0,k1                           // and them
        bne     k0,zero,30b                     // Keep looping if still set

        bal     InvalidateICache                // Invalidate the instruction cache
        nop
        bal     FlushDCache                     // Flush the data cache
        nop

        li      k0,RAM_TEST_LINK_ADDRESS        // address of copied code
        li      sp,RAM_TEST_STACK_ADDRESS_B     // init stack
        mfc0    a1,errorepc                     // pass cause of exception as argument.
        jal     k0                              // jump to self-test in memory
        li      a0,2                            // set exception cause to 2=NMI

ProcessorANMI:

        bal     PutLedDisplay              // set a dash in the LED
        ori     a0,zero,LED_NMI            //

        //
        // Copy the copy routines to memory
        //

        la      a0,MemoryRoutines       // source
        la      a1,MemoryRoutines-LINK_ADDRESS+KSEG1_BASE // destination location
        la      t2,EndMemoryRoutines    // end
        bal     DataCopy                // copy code to memory
        sub     a2,t2,a0                // length of code

        la      t2,InvalidateICache-LINK_ADDRESS+KSEG1_BASE // non-cached space
        jal     t2                      // Invalidate the instruction cache
        nop
        la      k0,NMI                  // Join common code
        mfc0    s6,errorepc             // get error epc
        j       k0                      // running at PROM Vaddress.
        li      s5,2

Reset:
//
// Initialize PSR to BEV and COP1 enabled. It's important to clear ERL since
// the ErrorEPC is undefined and further exceptions will set ERL or EXL
// according to the nature of the exception.
//
        li      k0,(1<<PSR_BEV) | (1 << PSR_CU1)
        mtc0    k0,psr
        nop
        nop

//
// Set the primary instruction cache block size to 32 bytes
// Set the primary data cache block size to 32 bytes
//
//

        mfc0    t0,config
        li      t1, (1 << CONFIG_IB) + (1 << CONFIG_DB) + (0 << CONFIG_CU) + \
                    (3 << CONFIG_K0)
        li      t2, 0xFFFFFFC0
        and     t0,t0,t2                // clear soft bits in config
        or      t0,t0,t1                // set soft bits in config
        mtc0    t0,config
        nop
        nop

        bal     PutLedDisplay           // BLANK the LED
        ori     a0,zero,LED_BLANK<<TEST_SHIFT

        beq     s5,1,SkipProcessorTest  // Skip processor test if softreset
        nop
        bal     PutLedDisplay           // Show processor test is staring
        ori     a0,zero,LED_PROCESSOR_TEST
        bal     ProcessorTest           // Test the processor
        nop
        move    s5,zero                 // clear s5 to indicate cold reset

SkipProcessorTest:
        li      t0,DMA_VIRTUAL_BASE     // load base address of MCT_ADR
        lw      s6,DmaWhoAmI(t0)        // s6 = processor number.
        bne     s6,zero,ProcessorBReset
        nop
        bal     PutLedDisplay           // Show MCT_ADR reset test is starting
        ori     a0,zero,LED_MCTADR_RESET
        bal     MctadrResetTest
        nop

        bal     PutLedDisplay           // Show MCT_ADR register test is starting
        ori     a0,zero,LED_MCTADR_REG
        bal     MctadrRegisterTest
        nop

        beq     s5,1,SkipRomChecksum    // Skip checksum if softreset
        nop
//
// Perform a ROM Checksum.
//
        bal     PutLedDisplay           // Display in the LED that
        ori     a0,zero,LED_ROM_CHECKSUM // ROM Checksum is being executed
        li      a0,PROM_VIRTUAL_BASE    // address of PROM
        li      t0,ROM_SIZE
        add     a1,a0,t0                // end of loop address
        move    t0,zero                 // init sum register

RomCheckSum:
        lw      t1,0(a0)                // fetch word
        lw      t2,4(a0)                // fetch second word
        addu    t0,t0,t1                // calculate checksum add from ofs 0
        lw      t1,8(a0)
        addu    t0,t0,t2                // calculate checksum add from ofs 4
        lw      t2,0xC(a0)
        addu    t0,t0,t1                // calculate checksum add from ofs 8
        addiu   a0,a0,16                // compute next address
        bne     a0,a1,RomCheckSum       // check end of loop condition
        addu    t0,t0,t2                // calculate checksum add from ofs c

//
// if test passes, jump to next part of initialization code.
//
        beq     t0,zero,TestMemory      // Branch if calculated checksum is correct
        move    s5,zero                 // clear s5 this tells to run selftest
        lui     a0,LED_BLINK            // otherwise hang
        bal     PutLedDisplay           // by calling PutLedDisplay
        ori     a0,a0,LED_ROM_CHECKSUM  // blinking the test number

SkipRomChecksum:
TestMemory:
        bal     PutLedDisplay           // call PutLedDisplay to show that
        ori     a0,zero,LED_MEMORY_TEST_1 // Mem test is starting

        bal     SizeMemory              // start by sizing the memory.
        nop                             //

//
// Call memory test routine to test small portion of memory.
// a0 is start of tested memory. a1 is length in bytes to test
//
//
// Disable Parity exceptions for the first memory test. Otherwise
// if something is wrong with the memory we jump to the moon.
//
// DUO ECC diag register resets to zero which forces good ecc to be
// written during read modify write cycles.
//
        li      t0, (1<<PSR_DE) | (1 << PSR_CU1) | (1 << PSR_BEV)
        mtc0    t0,psr
        nop

        li      a0,KSEG1_BASE           // start of mem test
        ori     a1,zero,MEMTEST_SIZE    // length to test in bytes
        ctc1    zero,fsr                // clear floating status
        nop
        bal     WriteNoXorAddressTest
        move    a2,zero                 // xor pattern zero
        bal     CheckNoXorAddressTest
        ori     a3,zero,LED_MEMORY_TEST_1 // set Test/Subtest ID
//
// Do the same flipping all bits
//
        bal     WriteAddressTest
        li      a2,-1                   // Xor pattern = FFFFFFFF
        bal     CheckAddressTest
        nop
//
// Do the same flipping some bits to be sure parity bits are flipped in each byte
//
        lui     a2,0x0101
        bal     WriteAddressTest
        ori     a2,a2,0x0101            // Xor pattern = 01010101
        bal     CheckAddressTest
        nop

//
// The next step is to copy a number of routines to memory so they can
// be executed more quickly. Calculate the arguments for DataCopy call:
// a0 is source of data, a1 is dest, a2 is length in bytes
//
        la      a0,MemoryRoutines       // source
        la      a1,MemoryRoutines-LINK_ADDRESS+KSEG1_BASE // destination location
        la      t2,EndMemoryRoutines    // end
        bal     DataCopy                // copy code to memory
        sub     a2,t2,a0                // length of code

//
// Call cache initialization routine in non-cached memory
//
        bal     PutLedDisplay           // display that cache init
        ori     a0,zero,LED_CACHE_INIT  // is starting
        la      s1,R4000CacheInit-LINK_ADDRESS+KSEG1_BASE // non-cached address
        jal     s1                      // initialize caches
        nop

/*
//
// TMPTMP
//
//        li      t0, (1<<PSR_DE) | (1 << PSR_CU1) | (1 << PSR_BEV)
//        mtc0    t0,psr

        bal     PutLedDisplay
        ori     a0,zero,0x11
        li      a0,KSEG1_BASE+(1<<20)          // start of memory to write non cached
        li      a1,KSEG1_BASE+(2<<20)          // start of memory to write non cached
        li      t0,0xF0F0F0F0                  //
        li      t1,0xAAAAAAAA                  //
        li      t2,0x55555555                  //
        li      t3,0x0F0F0F0F                  //
10:
        sw      t0,0x0(a0)
        sw      t1,0x4(a0)
        sw      t2,0x8(a0)
        sw      t3,0xC(a0)
        addiu   a0,a0,0x10
        bne     a0,a1,10b
        nop

        bal     PutLedDisplay
        ori     a0,zero,0x22

        li      t0,0xF0F0F0F0                  //
        li      t1,0xAAAAAAAA                  //
        li      t2,0x55555555                  //
        li      t3,0x0F0F0F0F                  //

        li      a0,KSEG0_BASE+(1<<20)          // start of memory to write non cached
        li      a1,KSEG0_BASE+(2<<20)          // start of memory to write non cached
10:
        lw      v0,0x0(a0)
        bne     v0,t0,20f
        move    v1,v0
        lw      v0,0x4(a0)
        bne     v0,t1,20f
        move    v1,v0
        lw      v0,0x8(a0)
        bne     v0,t2,20f
        move    v1,v0
        lw      v0,0xC(a0)
        bne     v0,t3,20f
        move    v1,v0
        addiu   a0,a0,0x10
        bne     a0,a1,10b
        nop
        b       30f
        nop

20:
        li      t0,KSEG1_BASE
        sw      v1,0(t0)
        sw      v1,8(t0)
        sw      v1,0x10(t0)
        sw      v1,0x18(t0)
        lui     a0,LED_BLINK            // otherwise hang
        bal     PutLedDisplay           // by calling PutLedDisplay
        ori     a0,a0,0x69              // blink a 69

30:

//        lui     a0,LED_BLINK            // otherwise hang
//        bal     PutLedDisplay           // by calling PutLedDisplay
//        ori     a0,a0,0xFF              // blink a FF
*/

/*
        bal     PutLedDisplay
        ori     a0,zero,0x11
        li      a0,KSEG1_BASE+(1<<20)          // start of memory to write non cached
        li      a1,(1<<20)          // start of memory to write non cached
        la      s1,WriteNoXorAddressTest-LINK_ADDRESS+KSEG1_BASE // address of routine in memory non cached
        jal     s1                      // Write and therefore init mem.
        move    a2,zero

        bal     PutLedDisplay
        ori     a0,zero,0x22
        li      a0,KSEG0_BASE+(1<<20)          // start of memory to write non cached
        li      a1,(1<<20)                     // start of memory to write non cached
        la      s1,WriteNoXorAddressTest-LINK_ADDRESS+KSEG1_BASE // address of routine in memory non cached
        jal     s1                      // Write and therefore init mem.
        move    a2,zero

        bal     PutLedDisplay
        ori     a0,zero,0x33
        li      a0,KSEG0_BASE+(1<<20)          // start of memory to write non cached
        li      a1,(1<<20)          // start of memory to write non cached
        la      s1,CheckNoXorAddressTest-LINK_ADDRESS+KSEG1_BASE // address of routine in memory non cached
        jal     s1                      // Write and therefore init mem.
        move    a2,zero
        bal     PutLedDisplay
        ori     a0,a0,0x44
*/

//
// End TMPTMP
//

//
// call routine now in cached memory to test bigger portion of memory
//
        bal     PutLedDisplay           // display that memory test
        ori     a0,zero,LED_WRITE_MEMORY_2 // is starting
        li      a0,KSEG1_BASE+MEMTEST_SIZE // start of memory to write non cached
        li      a1,FW_TOP_ADDRESS-MEMTEST_SIZE  // test the memory needed to copy the code
                                                // to memory, the stack and the video prom.
        la      s1,WriteNoXorAddressTest-LINK_ADDRESS+KSEG0_BASE // address of routine in memory cached
        jal     s1                      // Write and therefore init mem.
        move    a2,zero                 // xor pattern
        la      s2,CheckNoXorAddressTest-LINK_ADDRESS+KSEG0_BASE // address of routine in memory
        jal     s2                      // Check written memory
        ori     a3,zero,LED_READ_MEMORY_2 // load LED value if memory test fails
        la      s1,WriteAddressTest-LINK_ADDRESS+KSEG0_BASE // address of routine cached
        li      a0,KSEG0_BASE+MEMTEST_SIZE // start of memory now cached
        li      a2,0xDFFFFFFF           // to flipp all bits
        jal     s1                      // Write second time now cached.
        la      s2,CheckAddressTest-LINK_ADDRESS+KSEG0_BASE // address of routine in memory
        jal     s2                      // check also cached.
        nop
        lui     a2,0x0101
        jal     s1                      // Write third time cached.
        ori     a2,a2,0x0101            // flipping some bits
        jal     s2                      // check also cached.
        nop

//
// if we come back, the piece of memory is tested and therefore initialized.
//

        //
        // Do not force Correct ECC Data to be written during Read Modify
        // Write Cycles any more. Since from now on memory is always cached.
        // Or already initialized.
        //
        li      t1,0xEE0000             // Do not Force Correct ECC on rmw
                                        // ECC correction Enabled.
                                        // ECC correction occurs without notification
        mtc1    t1,f0                   //
        mtc1    zero,f1                 // zero error bits
        li      t0,DMA_VIRTUAL_BASE     // Get base address of MCTADR
        sdc1    f0,DmaEccDiagnostic(t0) // Write ECC Diagnostic register

//
// If an NMI occurred. s6 contains the erorrepc.
// the Tlb has already been initialized and the I cache flushed.
// Copy the firmware to memory and display a message from there.
//

NMI:
//
// Invalidate the data caches so that the firmware can be copied to
// noncached space without a conflict.
//

        bal     InvalidateDCache
        nop
        bal     InvalidateSCache
        nop

//
// Copy the firmware.
//
        la      s0,Decompress-LINK_ADDRESS+KSEG0_BASE
					// address of decompression routine in cached space
	la	a0,end			// end of this file is start of selftest
        li      a1,RAM_TEST_DESTINATION_ADDRESS
                                        // destination is uncached link address.
        jal     s0                      // jump to decompress
        nop
        bal     InvalidateICache        // Invalidate the instruction cache
        nop

//
// Flush the data cache
//
        bal     FlushDCache
        nop

//
//      Initialize the stack to the low memory and Call Rom tests.
//
        li      t0,RAM_TEST_LINK_ADDRESS // address of copied code
        li      sp,RAM_TEST_STACK_ADDRESS // init stack
        move    a1,s6                   // pass cause of exception as argument.
        jal     t0                      // jump to self-test in memory
        move    a0,s5                   // pass cause of exception as argument.
99:
        b       99b                     // hang if we get here.
        nop                             //


//
// This is the initialization code for processor B.
// At this point the processor has:
//
//  - Initialized the TLB.
//  - Initialized the config register.
//  - Run the processor selftest
//
// The system has already been initialized by processor A.
// Only the caches need to be initialized.
//
//
ProcessorBReset:

//
// Call cache initialization routine in non-cached memory
//
        bal     PutLedDisplay               // display that cache init
        ori     a0,zero,LED_CACHE_INIT      // is starting
        la      s1,R4000CacheInit-LINK_ADDRESS+KSEG1_BASE // non-cached address
        jal     s1                          // initialize caches
        nop
        li      t0,RAM_TEST_LINK_ADDRESS    // address of copied code
        li      sp,RAM_TEST_STACK_ADDRESS_B // init stack
        move    a1,s6
        jal     t0                          // jump to self-test in memory
        move    a0,s5                       // pass cause of exception as argument.
99:
        b       99b                         // hang if we get here.
        nop                                 //


//
// Routines between MemoryRoutines and EndMemoryRoutines are copied
// into memory to run them cached.
//

        .align 4                            // Align it to 16 bytes boundary so that
        ALTERNATE_ENTRY(MemoryRoutines)     // DataCopy doesn't need to check alignments
/*++
VOID
PutLedDisplay(
    a0 - display value.
    )
Routine Description:

    This routine will display in the LED the value specified as argument
    a0.

    bits [31:16] specify the mode.
    bits [7:4]   specify the Test number.
    bits [3:0]   specify the Subtest number.

    The mode can be:

        LED_NORMAL          Display the Test number
        LED_BLINK           Loop displaying Test - Dot - Subtest
        LED_LOOP_ERROR      Display the Test number with the dot iluminated

    N.B. This routine must reside in the first page of ROM because it is
    called before mapping the rom!!

Arguments:

    a0 value to display.

    Note: The value of the argument is preserved

Return Value:

    If a0 set to LED_BLINK does not return.

--*/
        LEAF_ENTRY(PutLedDisplay)
        li      t0,DIAGNOSTIC_VIRTUAL_BASE  // load address of display
LedBlinkLoop:
        srl     t1,a0,16                    // get upper bits of a0 in t1
        srl     t3,a0,4                     // get test number
        li      t4,LED_LOOP_ERROR           //
        bne     t1,t4, DisplayTestID
        andi    t3,t3,0xF                   // clear other bits.
        ori     t3,t3,LED_DECIMAL_POINT     // Set decimal point
DisplayTestID:
        li      t4,LED_BLINK                // check if need to hung
        sb      t3,0(t0)                    // write test ID to led.
        beq     t1,t4, ShowSubtestID
        nop
        j       ra                          // return to caller.
        nop

ShowSubtestID:
        li      t2,LED_DELAY_LOOP           // get delay value.
TestWait:
        bne     t2,zero,TestWait            // loop until zero
        addiu   t2,t2,-1                    // decrement counter
        li      t3,LED_DECIMAL_POINT+LED_BLANK
        sb      t3,0(t0)                    // write decimal point
        li      t2,LED_DELAY_LOOP/2         // get delay value.
DecPointWait:
        bne     t2,zero,DecPointWait        // loop until zero
        addiu   t2,t2,-1                    // decrement counter
        andi    t3,a0,0xF                   // get subtest number
        sb      t3,0(t0)                    // write subtest in LED
        li      t2,LED_DELAY_LOOP           // get delay value.
SubTestWait:
        bne     t2,zero,SubTestWait         // loop until zero
        addiu   t2,t2,-1                    // decrement counter
        b       LedBlinkLoop                // go to it again
        nop
        .end    PutLedDisplay

        LEAF_ENTRY(InvalidateICache)
/*++

Routine Description:

    This routine invalidates the contents of the instruction cache.

    The instruction cache is invalidated by writing an invalid tag to
    each cache line, therefore nothing is written back to memory.

Arguments:

    None.

Return Value:

    None.

--*/
//
// invalid state
//
        mfc0    t5,config               // read config register
        li      t0,(PRIMARY_CACHE_INVALID << TAGLO_PSTATE)
        mtc0    t0,taglo                // set tag registers to invalid
        mtc0    zero,taghi

        srl     t0,t5,CONFIG_IC         // compute instruction cache size
        and     t0,t0,0x7               //
        addu    t0,t0,12                //
        li      t6,1                    //
        sll     t6,t6,t0                // t6 = I cache size
        srl     t0,t5,CONFIG_IB         // compute instruction cache line size
        and     t0,t0,1                 //
        li      t7,16                   //
        sll     t7,t7,t0                // t7 = I cache line size
//
// store tag to all icache lines
//
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,t6                // get last index address
        subu    t0,t0,t7
WriteICacheTag:
        cache   INDEX_STORE_TAG_I,0(t1) // store tag in Instruction cache
        bne     t1,t0,WriteICacheTag    // loop
        addu    t1,t1,t7                // increment index
        j       ra
        nop
        .end    InvalidateICache


        LEAF_ENTRY(InvalidateDCache)
/*++

Routine Description:

    This routine invalidates the contents of the D cache.

    Data cache is invalidated by writing an invalid tag to each cache
    line, therefore nothing is written back to memory.

Arguments:

    None.

Return Value:

    None.

--*/
//
// invalid state
//
        mfc0    t5,config               // read config register for cache size
        li      t0, (PRIMARY_CACHE_INVALID << TAGLO_PSTATE)
        mtc0    t0,taglo                // set tag to invalid
        mtc0    zero,taghi
        srl     t0,t5,CONFIG_DC         // compute data cache size
        and     t0,t0,0x7               //
        addu    t0,t0,12                //
        li      t6,1                    //
        sll     t6,t6,t0                // t6 = data cache size
        srl     t0,t5,CONFIG_DB         // compute data cache line size
        and     t0,t0,1                 //
        li      t7,16                   //
        sll     t7,t7,t0                //  t7 = data cache line size

//
// store tag to all Dcache
//
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t2,t1,t6                // add cache size
        subu    t2,t2,t7                // adjust for cache line size.
WriteDCacheTag:
        cache   INDEX_STORE_TAG_D,0(t1) // store tag in Data cache
        bne     t1,t2,WriteDCacheTag    // loop
        addu    t1,t1,t7                // increment index by cache line
        j       ra
        nop
        .end    InvalidateDCache


        LEAF_ENTRY(FlushDCache)
/*++

Routine Description:

        This routine flushes the whole contents of the Dcache

Arguments:

    None.

Return Value:

    None.

--*/
        mfc0    t5,config               // read config register
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        srl     t0,t5,CONFIG_DC         // compute data cache size
        and     t0,t0,0x7               //
        addu    t0,t0,12                //
        li      t6,1                    //
        sll     t6,t6,t0                // t6 = data cache size
        srl     t0,t5,CONFIG_DB         // compute data cache line size
        and     t0,t0,1                 //
        li      t7,16                   //
        sll     t7,t7,t0                //  t7 = data cache line size
        addu    t0,t1,t6                // compute last index address
        subu    t0,t0,t7
FlushDCacheTag:
        cache   INDEX_WRITEBACK_INVALIDATE_D,0(t1)      // Invalidate  data cache
        bne     t1,t0,FlushDCacheTag        // loop
        addu    t1,t1,t7                    // increment index

//
// check for a secondary cache.
//

        li      t1,(1 << CONFIG_SC)
        and     t0,t5,t1
        bne     t0,zero,10f             // if non-zero no secondary cache

        li      t6,SECONDARY_CACHE_SIZE // t6 = secondary cache size
        srl     t0,t5,CONFIG_SB         // compute secondary cache line size
        and     t0,t0,3                 //
        li      t7,16                   //
        sll     t7,t7,t0                // t7 = secondary cache line size
//
// invalidate all secondary lines
//
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,t6                // get last index address
        subu    t0,t0,t7
FlushSDCacheTag:
        cache   INDEX_WRITEBACK_INVALIDATE_SD,0(t1)     // invalidate secondary cache
        bne     t1,t0,FlushSDCacheTag   // loop
        addu    t1,t1,t7                // increment index
10:
        j       ra
        nop
        .end    FlushDCache


        LEAF_ENTRY(InvalidateSCache)
/*++

Routine Description:

    This routine invalidates the contents of the secondary cache.

    The secondary cache is invalidated by writing an invalid tag to
    each cache line, therefore nothing is written back to memory.

Arguments:

    None.

Return Value:

    None.

--*/
        mfc0    t5,config               // read config register

//
// check for a secondary cache.
//

        li      t1,(1 << CONFIG_SC)
        and     t0,t5,t1
        bne     t0,zero,NoSecondaryCache        // if non-zero no secondary cache

        li      t0,(SECONDARY_CACHE_INVALID << TAGLO_SSTATE)
        mtc0    t0,taglo                // set tag registers to invalid
        mtc0    zero,taghi

        li      t6,SECONDARY_CACHE_SIZE // t6 = secondary cache size
        srl     t0,t5,CONFIG_SB         // compute secondary cache line size
        and     t0,t0,3                 //
        li      t7,16                   //
        sll     t7,t7,t0                // t7 = secondary cache line size
//
// store tag to all secondary lines
//
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,t6                // get last index address
        subu    t0,t0,t7
WriteSICacheTag:
        cache   INDEX_STORE_TAG_SD,0(t1) // store tag in secondary cache
        bne     t1,t0,WriteSICacheTag   // loop
        addu    t1,t1,t7                // increment index

NoSecondaryCache:
        j       ra
        nop
        .end    InvalidateSCache


        LEAF_ENTRY(InitDataCache)
/*++

Routine Description:

    This routine initializes the data fields of the primary and
    secondary data caches.

Arguments:

    None.

Return Value:

    None.

--*/
        mfc0    t5,config               // read config register

//
// check for a secondary cache.
//

        li      t1,(1 << CONFIG_SC)
        and     t0,t5,t1
        bne     t0,zero,NoSecondaryCache1 // if non-zero no secondary cache

        li      t6,SECONDARY_CACHE_SIZE // t6 = secondary cache size
        srl     t0,t5,CONFIG_SB         // compute secondary cache line size
        and     t0,t0,3                 //
        li      t7,16                   //
        sll     t7,t7,t0                // t7 = secondary cache line size
//
// store tag to all secondary lines
//
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,t6                // get last index address
        subu    t0,t0,t7

WriteSCacheTag:
        cache   CREATE_DIRTY_EXCLUSIVE_SD,0(t1) // store tag in secondary cache
        bne     t1,t0,WriteSCacheTag    // loop
        addu    t1,t1,t7                // increment index

//
// store data to all secondary lines. 1MB
//
        mtc1    zero,f0                 // zero f0
        mtc1    zero,f1                 // zero f1
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,t6                // get last index address
        subu    t0,t0,t7

WriteSCacheData:
        //
        // Init Data 64 bytes per loop.
        //

        // TMPTMP
        move    t2,t1
        // TMPTMP


        // TMPTMP
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,0(t1)                // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,8(t1)                // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,16(t1)               // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,24(t1)               // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,32(t1)               // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,40(t1)               // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,48(t1)               // write

        // TMPTMP
        addiu   t2,t2,8
        mtc1    t2,f0
        mtc1    t2,f1
        // TMPTMP

        sdc1    f0,56(t1)               // write
        bne     t1,t0,WriteSCacheData   // loop
        addu    t1,t1,t7                // increment index

//
// TMPTMP
//

        li      t1, (1 << PSR_CU1) | (1 << PSR_BEV)
        mtc0    t1,psr
        nop
        nop

        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,t6                // get last index address
        subu    t0,t0,t7

10:
        ldc1    f0,0(t1)
        ldc1    f0,8(t1)
        ldc1    f0,16(t1)
        ldc1    f0,24(t1)
        ldc1    f0,32(t1)
        ldc1    f0,40(t1)
        ldc1    f0,48(t1)
        ldc1    f0,56(t1)

        bne     t1,t0,10b               // loop
        addu    t1,t1,t7                // increment index


//
// END
//

//
// Flush the primary data cache to the secondary cache
//
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        srl     t0,t5,CONFIG_DC         // compute data cache size
        and     t0,t0,0x7               //
        addu    t0,t0,12                //
        li      t6,1                    //
        sll     t6,t6,t0                // t6 = data cache size
        srl     t0,t5,CONFIG_DB         // compute data cache line size
        and     t0,t0,1                 //
        li      t7,16                   //
        sll     t7,t7,t0                //  t7 = data cache line size
        addu    t0,t1,t6                // compute last index address
        subu    t0,t0,t7
FlushPDCacheTag:
        cache   INDEX_WRITEBACK_INVALIDATE_D,0(t1) // Invalidate  data cache
        bne     t1,t0,FlushPDCacheTag   // loop
        addu    t1,t1,t7                // increment index

        j       ra                      // return
        nop

NoSecondaryCache1:

        srl     t0,t5,CONFIG_DC         // compute data cache size
        and     t0,t0,0x7               //
        addu    t0,t0,12                //
        li      t6,1                    //
        sll     t6,t6,t0                // t6 = data cache size
        srl     t0,t5,CONFIG_DB         // compute data cache line size
        and     t0,t0,1                 //
        li      t7,16                   //
        sll     t7,t7,t0                //  t7 = data cache line size

//
// create dirty exclusive to all Dcache
//
        mtc1    zero,f0                 // zero f0
        mtc1    zero,f1                 // zero f1
        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t2,t1,t6                // add cache size
        subu    t2,t2,t7                // adjust for cache line size.
WriteDCacheDe:
        cache   CREATE_DIRTY_EXCLUSIVE_D,0(t1) // store tag in Data cache
        nop
        sdc1    f0,0(t1)                // write
        sdc1    f0,8(t1)                // write
        bne     t1,t2,WriteDCacheDe     // loop
        addu    t1,t1,t7                // increment index by cache line

        j       ra                      // return
        nop
        .end    InitDataCache

        LEAF_ENTRY(R4000CacheInit)
/*++

Routine Description:

    This routine will initialize the cache tags and data for the
    primary data cache, primary instruction cache, and the secondary cache
    (if present).

    Subroutines are called to invalidate all of the tags in the
    instruction and data caches.

Arguments:

    None.

Return Value:

    None.

--*/
        move    s0,ra                   // save ra.

//
// Disable Cache Error exceptions.
//

        li      t0, (1<<PSR_DE) | (1 << PSR_CU1) | (1 << PSR_BEV)
        mtc0    t0,psr

//
// Invalidate the caches
//

        bal     InvalidateICache
        nop

        bal     InvalidateDCache
        nop

        bal     InvalidateSCache
        nop

//
// Initialize the data cache(s)
//

        bal     InitDataCache
        nop

//
// Fill the Icache,  all icache lines
//

        mfc0    t5,config               // read config register
        nop
        srl     t0,t5,CONFIG_IC         // compute instruction cache size
        and     t0,t0,0x7               //
        addu    t0,t0,12                //
        li      s1,1                    //
        sll     s1,s1,t0                // s1 = I cache size
        srl     t0,t5,CONFIG_IB         // compute instruction cache line size
        and     t0,t0,1                 //
        li      s2,16                   //
        sll     s2,s2,t0                // s2 = I cache line size

        li      t1,KSEG0_BASE+(1<<20)   // get virtual address to index cache
        addu    t0,t1,s1                // add I cache size
        subu    t0,t0,s2                // sub line size.
FillICache:
        cache   INDEX_FILL_I,0(t1)      // Fill I cache from memory
        bne     t1,t0,FillICache        // loop
        addu    t1,t1,s2                // increment index

//
// Invalidate the caches again
//
        bal     InvalidateICache
        nop

        bal     InvalidateDCache
        nop

        bal     InvalidateSCache
        nop

//
// Enable cache error exception.
//
        mfc0    t0,config
        li      t1, (1 << CONFIG_IB) + (1 << CONFIG_DB) + (0 << CONFIG_CU) + \
                    (5 << CONFIG_K0)
        li      t2, 0xFFFFFFC0
        and     t0,t0,t2                // clear soft bits in config
        or      t0,t0,t1                // set soft bits in config
        mtc0    t0,config
        nop

        li      t1, (1 << PSR_CU1) | (1 << PSR_BEV)
        mtc0    t1,psr
        nop
        nop
        nop
        move    ra,s0                   // move return address back to ra
        j       ra                      // return from routine
        nop
        .end    R4000CacheInit


/*++
VOID
WriteAddressTest(
    StartAddress
    Size
    Xor pattern
    )
Routine Description:

    This routine will store the address of each location xored with
    the Pattern into each location.

Arguments:

    a0 - supplies start of memory area to test
    a1 - supplies length of memory area in bytes
    a2 - supplies the pattern to Xor with.

    Note: the values of the arguments are preserved.

Return Value:

    This routine returns no value.
--*/
        LEAF_ENTRY(WriteAddressTest)
        add     t1,a0,a1                // t1 = last address.
        xor     t0,a0,a2                // t0 value to write
        move    t2,a0                   // t2=current address
writeaddress:
        sw      t0,0(t2)                // store
        addiu   t2,t2,4                 // compute next address
        xor     t0,t2,a2                // next pattern
        sw      t0,0(t2)
        addiu   t2,t2,4                 // compute next address
        xor     t0,t2,a2                // next pattern
        sw      t0,0(t2)
        addiu   t2,t2,4                 // compute next address
        xor     t0,t2,a2                // next pattern
        sw      t0,0(t2)
        addiu   t2,t2,4                 // compute next address
        bne     t2,t1, writeaddress     // check for end condition
        xor     t0,t2,a2                // value to write
        j       ra
        nop
        .end    WriteAddressTest

/*++
VOID
WriteNoXorAddressTest(
    StartAddress
    Size
    )
Routine Description:

    This routine will store the address of each location
    into each location.

Arguments:

    a0 - supplies start of memory area to test
    a1 - supplies length of memory area in bytes

    Note: the values of the arguments are preserved.

Return Value:

    This routine returns no value.
--*/
        LEAF_ENTRY(WriteNoXorAddressTest)
        nop
        nop
        nop
        nop
        add     t1,a0,a1                // t1 = last address.
        addiu   t1,t1,-4
        move    t2,a0                   // t2=current address
writenoXoraddress:
        sw      t2,0(t2)                // store first address
        addiu   t2,t2,4                 // compute next address
        sw      t2,0(t2)                // store first address
        addiu   t2,t2,4                 // compute next address
        sw      t2,0(t2)                // store first address
        addiu   t2,t2,4                 // compute next address
        sw      t2,0(t2)                // store
        bne     t2,t1, writenoXoraddress // check for end condition
        addiu   t2,t2,4                 // compute next address
        j       ra
        nop
        .end    WriteNoXorAddressTest


/*++
VOID
CheckAddressTest(
    StartAddress
    Size
    Xor pattern
    LedDisplayValue
    )
Routine Description:


    This routine will check that each location contains it's address
    xored with the Pattern as written by WriteAddressTest. The memory
    is read cached or non cached according to the address specified by a0.
    if WriteAddressTest used a KSEG1_ADR to write the data and this
    routine is called to read KSEG0_ADR in order to read the data cached,
    then the XOR_PATTERN Must be such that:

    KSEG0_ADR ^ KSEG0_XOR = KSEG1_ADR ^ KSEG1_XOR

    Examples:

        If XorPattern with which WriteAddressTest was called is KSEG1_XOR
        then the XorPattern this routine needs is KSEG0_XOR:

    KSEG1_XOR     Written    KSEG0_XOR    So that
    0x00000000  0xA00000000  0x20000000   0x8000000 ^ 0x2000000  = 0xA0000000
    0xFFFFFFFF  0x5F0000000  0xDFFFFFFF   0x8000000 ^ 0xDF00000  = 0x5F000000
    0x01010101  0xA10000000  0x21010101   0x8000000 ^ 0x2100000  = 0xA1000000

    This allows to write non cached to initialize memory and check the same
    data trough cached addresses.

Arguments:

    a0 - supplies start of memory area to test
    a1 - supplies length of memory area in bytes
    a2 - supplies the pattern to Xor with.
    a3 - suplies the value to display in the led in case of failure

    Note: the values of the arguments are preserved.

Return Value:

    Returns a zero if no error is found.

    If errors are found, this routine behaves different depending
    on where the caller resides:
    - If the caller is executing in KSEG0 or KSEG1 returns 1
    - If the caller is executing im ROM_VIRT addresses the
    routine hangs blinking the LED or looping if the loop on error
    bit is set in the config register.

--*/
        LEAF_ENTRY(CheckAddressTest)
        move    t3,a0                   // t3 first address.
        add     t2,t3,a1                // last address.
checkaddress:
        lw      t1,0(t3)                // load from first location
        xor     t0,t3,a2                // first expected value
        bne     t1,t0,PatternFail
        addiu   t3,t3,4                 // compute next address
        lw      t1,0(t3)                // load from first location
        xor     t0,t3,a2                // first expected value
        bne     t1,t0,PatternFail
        addiu   t3,t3,4                 // compute next address
        lw      t1,0(t3)                // load from first location
        xor     t0,t3,a2                // first expected value
        bne     t1,t0,PatternFail
        addiu   t3,t3,4                 // compute next address
        lw      t1,0(t3)                // load from first location
        xor     t0,t3,a2                // first expected value
        bne     t1,t0,PatternFail       // check last one.
        addiu   t3,t3,4                 // compute next address
        bne     t3,t2, checkaddress     // check for end condition
        move    v0,zero                 // set return value to zero.
        j       ra                      // return a zero to the caller

PatternFail:
        //
        // check if we are in loop on error
        //
        li      t0,DIAGNOSTIC_VIRTUAL_BASE  // get base address of diag register
        lb      t0,0(t0)                    // read register value.
        li      t1,LOOP_ON_ERROR_MASK       // get value to compare
        andi    t0,DIAGNOSTIC_MASK          // mask diagnostic bits.
        li      v0,PROM_ENTRY(14)           // load address of PutLedDisplay
        beq     t1,t0,10f                   // brnach if loop on error.
        move    s8,a0                       // save register a0
        lui     t0,LED_BLINK                // get LED blink code
        jal     v0                          // Blink LED and hang.
        or      a0,a3,t0                    // pass a3 as argument in a0
10:
        lui     t0,LED_LOOP_ERROR           // get LED LOOP_ERROR code
        jal     v0                          // Set LOOP ON ERROR on LED
        or      a0,a3,t0                    // pass a3 as argument in a0
        b       CheckAddressTest            // Loop back to test again.
        move    a0,s8                       // restoring arguments.
        .end    CheckAddressTest

/*++
VOID
CheckNoXorAddressTest(
    StartAddress
    Size
    not used
    LedDisplayValue
    )
Routine Description:

    This routine will check that each location contains it's address.
    as written by WriteNoXorAddressTest.

Arguments:

    Note: the values of the arguments are preserved.

    a0 - supplies start of memory area to test
    a1 - supplies length of memory area in bytes
    a2 - Not used
    a3 - suplies the value to display in the led in case of failure

Return Value:

    This routine returns no value.
    The routine hangs blinking the LED or looping if the loop on error
    bit is set in the config register.
--*/
        LEAF_ENTRY(CheckNoXorAddressTest)
        addiu   t3,a0,-4                // t3 first address-4
        add     t2,a0,a1                // last address.
        addiu   t2,t2,-8                // adjust
        move    t1,t3                   // get copy of t3 just for first check
checkaddressNX:
        bne     t1,t3,PatternFailNX
        lw      t1,4(t3)                // load from first location
        addiu   t3,t3,4                 // compute next address
        bne     t1,t3,PatternFailNX
        lw      t1,4(t3)                // load from next location
        addiu   t3,t3,4                 // compute next address
        bne     t1,t3,PatternFailNX
        lw      t1,4(t3)                // load from next  location
        addiu   t3,t3,4                 // compute next address
        bne     t1,t3,PatternFailNX     // check
        lw      t1,4(t3)                // load from next location
        bne     t3,t2, checkaddressNX   // check for end condition
        addiu   t3,t3,4                 // compute next address
        bne     t1,t3,PatternFailNX     // check last
        nop
        j       ra                      // return a zero to the caller
        move    v0,zero                 //
PatternFailNX:
        //
        // check if we are in loop on error
        //
        li      t0,DIAGNOSTIC_VIRTUAL_BASE  // get base address of diag register
        lb      t0,0(t0)                    // read register value.
        li      t1,LOOP_ON_ERROR_MASK       // get value to compare
        andi    t0,DIAGNOSTIC_MASK          // mask diagnostic bits.
        li      v0,PROM_ENTRY(14)           // load address of PutLedDisplay
        beq     t1,t0,10f                   // brnach if loop on error.
        move    s8,a0                       // save register a0
        lui     t0,LED_BLINK                // get LED blink code
        jal     v0                          // Blink LED and hang.
        or      a0,a3,t0                    // pass a3 as argument in a0
10:
        lui     t0,LED_LOOP_ERROR           // get LED LOOP_ERROR code
        jal     v0                          // Set LOOP ON ERROR on LED
        or      a0,a3,t0                    // pass a3 as argument in a0
        b       CheckNoXorAddressTest       // Loop back to test again.
        move    a0,s8                       // restoring arguments.
        .end    CheckNoXorAddressTest


/*++
VOID
ZeroMemory(
    ULONG   StartAddress
    ULONG   Size
    );
Routine Description:

    This routine will zero a range of memory.

Arguments:

    a0 - supplies start of memory
    a1 - supplies length of memory in bytes

Return Value:

    None.

--*/
        LEAF_ENTRY(ZeroMemory)
        add     a1,a1,a0                        // Compute End address
        addiu   a1,a1,-4                        // adjust address
ZeroMemoryLoop:
        sw      zero,0(a0)                      // zero memory.
        bne     a0,a1,ZeroMemoryLoop            // loop until done.
        addiu   a0,a0,4                         // compute next address
        j       ra                              // return
        nop
        ALTERNATE_ENTRY(ZeroMemoryEnd)
        nop
        .end    ZeroMemory

//++
//
//PULONG
//Decompress(
//        IN PULONG InputImage,
//        IN PULONG OutputImage
//        )
//
//
//Routine Description:
//
//    This routine decompresses the input image.
//
//Arguments:
//
//    InputImage (a0) - byte pointer to the image to be decompressed.
//    OutputImage (a1) - byte pointer to the area to write decompressed image.
//
//    N.B. The first ULONG of the InputImage contains the decompressed length in bytes.
//    See romcomp.c for a description of method.
//
//Return Value:
//
//    None.
//
//--

.set reorder
        LEAF_ENTRY(Decompress)

        lw      a2,(a0)                 // get the target size.
        srl     a2,a2,2                 // get size of output in words/symbols.
        addiu   a0,a0,4                 // address of next word
        move    a3,a1                   // stash output image base

//
// Calculate the offset width from the size.  Assume size > 2 ULONG.
//
#define SHORT_INDEX_WIDTH 10

        li      t8,1                    // start at two
        srl     t0,a2,1                 // offset must only span half the image.
5:
        addiu   t8,t8,1                 // next bit
        srl     t1,t0,t8                // shift off low bits
        bgtz    t1,5b                   // quit when we find the highest set bit.

//
// Set the symbol register bit count to zero so that on the first iteration of the loop we will
// get the first symbol longword.  Add one to the symbol count to allow for first loop entry.
//

        li      t1,0                    // number of valid bits
        addiu   a2,a2,1                 // increment symbol count

//
// Loop, decompressing the data.  There is always at least one bit in the register at this point.
//

10:

//
// Decrement the symbol count and exit the loop when done.
//

        addiu   a2,a2,-1                // decrement symbol count
        beq     zero,a2,99f             // return

//
// Load symbol register if it is empty.
//

        bne     zero,t1,12f             // check for lack of bits
        lw      t0,(a0)                 // get the next word
        addiu   a0,a0,4                 // address of next word
        li      t1,32                   // number of valid bits
12:

//
// Test first bit of symbol
//

        andi    t2,t0,0x1               // test the low bit
        addiu   t1,t1,-1                // decrement bit count
        srl     t0,t0,1                 // shift symbol
        bne     zero,t1,20f             // check for lack of bits
        lw      t0,(a0)                 // get the next word
        addiu   a0,a0,4                 // address of next word
        li      t1,32                   // number of valid bits
20:
        bne     zero,t2,50f             // if not zero then this is an index

30:

//
// First bit of symbol is zero, this is the zero or unique case.  Check the next bit.
//

        andi    t2,t0,0x1               // test the low bit
        addiu   t1,t1,-1                // decrement bit count
        srl     t0,t0,1                 // shift symbol
        bne     zero,t2,40f             // if not zero then this is a unique word symbol

//
// This is the zero case. 0b00
//

        sw      zero,(a1)               // store the zero
        addiu   a1,a1,4                 // increment the output image pointer
        b       10b                     // go get the next symbol.

//
// The symbol is a unique word. 0b10.  Get the next 32 bits and write them to the output.
//
// The symbol register contains 0 to 31 bits of the word to be written.  Get the next
// word, shift and merge it with the existing symbol to produce a complete word.  The remainder
// of the new word becomes the next symbol register contents.
//
// Note that since we read a new word we don't have to decrement the bit counter since it runs
// mod 32.
//

40:
        lw      t3,(a0)                 // get next word
        addiu   a0,a0,4                 // address of next word

        sll     t2,t3,t1                // shift it by the bit count
        or      t0,t0,t2                // put it in with the existing contents of the symbol register

        sw      t0,(a1)                 // store the word
        addiu   a1,a1,4                 // increment the output image pointer

        li      t2,32                   // get shift count for new word to make new symbol register
        subu    t2,t2,t1                //
        srl     t0,t3,t2                // new contents of symbol register.  For bit count zero case
                                        // this is a nop

        b       10b                     // go get the next symbol.

//
// This is the index case. 0bX1.  Now the next bit determines whether the offset is relative(1) or
// absolute(0).  Stash the next bit for when we use the offset.
//

50:
        andi    t4,t0,0x1               // get the relative/absolute bit
        addiu   t1,t1,-1                // decrement bit count
        srl     t0,t0,1                 // shift symbol
        bne     zero,t1,55f             // check for lack of bits
        lw      t0,(a0)                 // get the next word
        addiu   a0,a0,4                 // address of next word
        li      t1,32                   // number of valid bits
55:

//
// Get the next bit.  This tells us whether we have a long(0) or a short(1) index.
//

        andi    t2,t0,0x1               // test the low bit
        addiu   t1,t1,-1                // decrement bit count
        srl     t0,t0,1                 // shift symbol
        bne     zero,t1,60f             // check for lack of bits
        lw      t0,(a0)                 // get the next word
        addiu   a0,a0,4                 // address of next word
        li      t1,32                   // number of valid bits
60:
        li      t5,SHORT_INDEX_WIDTH    // preload with short index width
        bne     zero,t2,70f             // if not zero then this is a short index.
        move    t5,t8                   // use long index width

//
// Get the index based on the width.  If the currently available bits are less than the
// number that we need then we must read another word.
//
70:
        li      t7,0                    // zero the remainder
        sub     t2,t5,t1                // get difference between what we need and what we have
        blez    t2,75f                  // if we got what we need

        lw      t6,(a0)                 // get next word
        addiu   a0,a0,4                 // address of next word
        sll     t7,t6,t1                // shift new bits into position
        or      t0,t0,t7                // move new bits into symbol register
        srl     t7,t6,t2                // adjust remainder
        addiu   t1,t1,32                // pre-bias the bit count for later decrement.

75:
        li      t3,1                    // grab a one
        sll     t3,t3,t5                // shift it by number of bits we will extract
        addiu   t3,t3,-1                // make a mask
        and     t2,t0,t3                // grab the index
        sll     t2,t2,2                 // make it a byte index
        srl     t0,t0,t5                // shift out bits we used.
        or      t0,t0,t7                // merge in remainder if any.
        sub     t1,t1,t5                // decrement the bit count, correct regardless

//
// Use index to write output based on the absolute(0)/relative(1) bit.
//
80:
        bne     zero,t4,85f             // test for the relative case.
        addu    t3,a3,t2                // address by absolute
        b       87f                     // go move the word
85:
        subu    t3,a1,t2                // address by relative

//
// Move the byte.
//
87:
        lw      t2,(t3)                 // get the word
        sw      t2,(a1)                 // store the word
        addiu   a1,a1,4                 // increment output pointer
        b       10b                     // go do next symbol

//
// Return
//

99:

        j       ra                      // return

        .end    Decompress
.set noreorder

/*++
VOID
DataCopy(
    ULONG SourceAddress
    ULONG DestinationAddress
    ULONG Length
    );
Routine Description:

    This routine will copy data from one location to another
    Source, destination, and length must be dword aligned.

    For DUO since 64 bit reads from the prom are not supported, the
    reads and writes are done word by word.

Arguments:

    a0 - supplies source of data
    a1 - supplies destination of data
    a2 - supplies length of data in bytes

Return Value:

    None.
--*/


        LEAF_ENTRY(DataCopy)

        add     a2,a2,a0                        // get last address
CopyLoop:
        lw      t0, 0(a0)                       // load 1st word
        lw      t1, 4(a0)                       // load 2nd word
        lw      t2, 8(a0)                       // load 3rd word
        lw      t3,12(a0)                       // load 4th word
        addiu   a0,a0,16                        // increment source pointer
        sw      t0, 0(a1)                       // load 1st word
        sw      t1, 4(a1)                       // load 2nd word
        sw      t2, 8(a1)                       // load 3rd word
        sw      t3,12(a1)                       // load 4th word
        bne     a0,a2,CopyLoop                  // loop until address=last address
        addiu   a1,a1,16                        // increment destination pointer
        j       ra                              // return
        nop
        .align 4                                // Align it to 16 bytes boundary so that
        ALTERNATE_ENTRY(EndMemoryRoutines)      // DataCopy doesn't need to check alignments
        nop
        .end    DataCopy

/*++
VOID
ProcessorTest(
    VOID
    );

Routine Description:

    This routine tests the processor. Test uses all registers and almost all
    the instructions.

    N.B. This routine destroys the values in all of the registers.

Arguments:

    None.

Return Value:

    None, but will hang flashing the led if an error occurs.

--*/
        LEAF_ENTRY(ProcessorTest)
        lui     a0,0x1234               // a0=0x12340000
        ori     a1,a0,0x4321            // a1=0x12344321
        add     a2,zero,a0              // a2=0x12340000
        addiu   a3,zero,-0x4321         // a3=0xFFFFBCDF
        subu    AT,a2,a3                // AT=0x12344321
        bne     a1,AT,ProcessorError    // branch if no match match
        andi    v0,a3,0xFFFF            // v0=0x0000BCDF
        ori     v1,v0,0xFFFF            // v1=0x0000FFFF
        sll     t0,v1,16                // t0=0xFFFF0000
        xor     t1,t0,v1                // t1=0xFFFFFFFF
        sra     t2,t0,16                // t2=0xFFFFFFFF
        beq     t1,t2,10f               // if eq good
        srl     t3,t0,24                // t3=0x000000FF
        j       ProcessorError          // if wasn't eq error.
10:     sltu    s0,t0,v1                // S0=0 because t0 > v1
        bgtz    s0,ProcessorError       // if s0 > zero error
        or      t4,AT,v0                // t4=X
        bltz    s0,ProcessorError       // if s0 < zero error
        nor     t5,v0,AT                // t5=~X
        and     t6,t4,t5                // t6=0
        move    s0,ra                   // save ra in s0
        bltzal  t6,ProcessorError       // if t6 < 0  error, load ra in case
        nop
RaAddress:
        //la      t7,RaAddress - LINK_ADDRESS + RESET_VECTOR // get expected address in ra
        la      t7,RaAddress            // get expected address in ra
        bne     ra,t7,ProcessorError    // error if don't match
        move    ra,s0                   // put ra back
        ori     s1,zero,0x100           // load constant
        mult    s1,t3                   // 0x100*0xFF
        mfhi    s3                      // s3=0
        mflo    s2                      // s2=0xFF00
        blez    s3,10f                  // branch if correct
        sll     s4,t3,zero              // move t3 into s4
        addiu   s4,100                  // change value in s4 to produce an error
10:     divu    s5,s2,s4                // divide 0xFF00/0xFF
        nop
        nop
        mfhi    s6                      // remainder s6=0
        bne     s5,s1,ProcessorError
        nop
        blez    s6,10f                  // branch if no error
        nop
        j       ProcessorError
10:     sub     s7,s5,s4                // s7=1
        mthi    s7
        mtlo    AT
        xori    gp,s5,0x2566            // gp=0x2466
        move    s0,sp                   // save sp for now
        srl     sp,gp,s7                // sp=0x1233
        mflo    s8                      // s8=0x12344321
        mfhi    k0                      // k0=1
        ori     k1,zero,16              // k1=16
        sra     k1,s8,k1                // k1=0x1234
        add     AT,sp,k0                // AT=0x1234
        bne     k1,AT,ProcessorError    // branch on error
        nop
#ifdef  R4001
        //
        // Some extra stuff added to verify that the R4000 bug is fixed
        // If it hangs a minus sign will be displayed in the LED
        //
        li      t0,DIAGNOSTIC_VIRTUAL_BASE
        li      t1,0xB                  // value to display '-' in the LED
        sw      t1,0(t0)                // write to the LED should be sb
        lw      t2,8(t0)                // do something
        sll     t5,t0,t1                // 2 cycle instruction
#endif
        j       ra                      // return
        nop
ProcessorError:
        lui     a0,LED_BLINK            // blink also means that
        bal     PutLedDisplay           // the routine hangs.
        ori     a0,LED_PROCESSOR_TEST   // displaying this value.
        .end    ProcessorTest


/*++
VOID
MctadrReset(
    VOID
    );

Routine Description:

    This routine tests the reset values of the MP_ADR asic.

Arguments:

    None.

Return Value:

    None, but will hang flashing the led if an error occurs.

--*/
        LEAF_ENTRY(MctadrResetTest)
        move    s0,ra                       // save return address.
//
// Test the mctadr reset values.
//
MctadrReset:
        li      t0,DMA_VIRTUAL_BASE         // Get base address of MP_ADR
        lw      v0,DmaConfiguration(t0)     // Check Config reset value
        li      t1,CONFIG_RESET_MP_ADR_REV1 // Check for REV1 ASIC, i.e. DUO
        bne     v0,t1,MctadrResetError
        lw      v0,DmaRevisionLevel(t0)     // Get revision level register
        bne     v0,zero,MctadrResetError    // If not REV1 Error

        addiu   t1,t0,DmaInterruptEnable    //
                                            // enable register in REV2
        li      v0,0x1f                     // MCTADR interrupt enable mask
        sw      v0,0(t1)                    // Enable all interrupts in MCTADR

10:
        lw      v0,DmaInvalidAddress(t0)
        lw      v1,DmaTranslationBase(t0)
        bne     v0,zero,MctadrResetError    // Check LFAR reset value
        lw      v0,DmaTranslationLimit(t0)
        bne     v1,zero,MctadrResetError    // Check Ttable base reset value
        lw      v1,DmaRemoteFailedAddress(t0)
        bne     v0,zero,MctadrResetError    // Check TT limit reset value
        lw      v0,DmaMemoryFailedAddress(t0)
        bne     v1,zero,MctadrResetError    // Check RFAR reset value
        lw      v1,DmaChannelInterruptAcknowledge(t0)
        bne     v0,zero,MctadrResetError    // Check MFAR reset value
        addiu   t1,t0,DmaRemoteSpeed0       // address of REM_SPEED 0
        bne     v1,zero,MctadrResetError    // Check Channel Interrup Ack reset value
        addiu   t2,t0,DmaRemoteSpeed14      // address of REM_SPEED 14
        lw      v0,0(t1)                    // read register
        li      t3,REMSPEED_RESET           //
        addiu   t1,t1,8                     // next register address.
NextRemSpeed:
        bne     v0,t3,MctadrResetError      // Check Rem speed reg reset value
        lw      v0,0(t1)                    // read next rem speed
        bne     t1,t2,NextRemSpeed
        addiu   t1,t1,8                     // next register address.
        bne     v0,t3,MctadrResetError      // Check last Rem speed reg reset value
        addiu   t1,t0,DmaChannel0Mode       // address of first channel register
        addiu   t2,t0,DmaChannel3Address    // address of last channel register
        lw      v0,0(t1)                    // read register
        addiu   t1,t1,8                     // next register address.
NextChannelReg:
        bne     v0,zero,MctadrResetError    // Check channel reg reset value
        lw      v0,0(t1)                    // read next channel
        bne     t1,t2,NextChannelReg
        addiu   t1,t1,8                     // next register address.
        bne     v0,zero,MctadrResetError    // Check last  channel reg reset value

        lw      v0,DmaArbitrationControl(t0)
        bne     v0,zero,MctadrResetError    // check IO arbitration reset value
        lw      v1,DmaErrortype(t0)         // read eisa/ethernet error reg
        lw      v0,DmaRefreshRate(t0)
        bne     v1,zero,MctadrResetError    // check Eisa error type reset value
        li      t1,REFRRATE_RESET
        bne     v0,t1,MctadrResetError      // check Refresh rate reset value
        lw      v0,DmaSystemSecurity(t0)
        li      t1,SECURITY_RESET
        bne     v0,t1,MctadrResetError      // check Security reg reset value
        lw      v0,DmaEisaInterruptAcknowledge(t0)  // read register but don't check

        addiu   t1,t0,DmaIoCacheLowByteMask0// address of first bytemask register
        addiu   t2,t0,DmaIoCacheHighByteMask7// address of last Byte Mask register.
        lw      v0,0(t1)                    // read register
        addiu   t1,t1,8                     // next register address.
NextByteMaskReg:
        bne     v0,zero,MctadrResetError    // Check ByteMask reg reset value
        lw      v0,0(t1)                    // read next register
        bne     t1,t2,NextByteMaskReg       // Loop
        addiu   t1,t1,8                     // next register address.
        j       s0                          // return to caller
MctadrResetError:
        li      t0,DIAGNOSTIC_VIRTUAL_BASE // get base address of diag register
        lb      t0,0(t0)                // read register value.
        li      t1,LOOP_ON_ERROR_MASK   // get value to compare
        andi    t0,DIAGNOSTIC_MASK      // mask diagnostic bits.
        beq     t1,t0,10f               // branch if loop on error.
        ori     a0,zero,LED_MCTADR_RESET// load LED display value.
        lui     t0,LED_BLINK            // get LED blink code
        bal     PutLedDisplay           // Blink LED and hang.
        or      a0,a0,t0                // pass argument in a0
10:
        lui     t0,LED_LOOP_ERROR       // get LED LOOP_ERROR code
        bal     PutLedDisplay           // Set LOOP ON ERROR on LED
        or      a0,a0,t0                // pass argument in a0
        b       MctadrReset
        nop
        .end    MctadrResetTest

/*++
VOID
MctadrRegisterTest(
    VOID
    );

Routine Description:

    This routine tests the MP_ADR registers.

Arguments:

    None.

Return Value:

    None, but will hang flashing the led if an error occurs.

--*/
        LEAF_ENTRY(MctadrRegisterTest)
        move    s0,ra                   // save return address.
//
// Check the data path between R4K and Mctadr by writing to Byte mask reg.
//
MctadrReg:
        li      t0,DMA_VIRTUAL_BASE
        li      t1,0x5                          // 2Mb Video Map Prom
        sw      t1,DmaConfiguration(t0)         // Init Global Config
        lw      v0,DmaConfiguration(t0)         // Read Configuration
        bne     v0,t1,MctadrRegError            // check GLOBAL CONFIG
        li      t1,1
        sw      t1,DmaIoCacheLogicalTag0(t0)           // Set LFN=zero, Offset=0 , Direction=READ from memory, Valid
        li      t2,0x55555555
        sw      t2,DmaIoCacheLowByteMask0(t0)   // write pattern to LowByte mask
        li      t3,0xAAAAAAAA
        sw      t3,DmaIoCacheHighByteMask0(t0)  // write pattern to HighByte mask
        lw      v0,DmaIoCacheLowByteMask0(t0)   // Read LowByte mask
        lw      v1,DmaIoCacheHighByteMask0(t0)  // Read HighByte mask
        bne     v0,t2,MctadrRegError            //
        sw      t1,DmaIoCachePhysicalTag0(t0)   // PFN=0 and Valid
        bne     v1,t3,MctadrRegError            //
        sw      t3,DmaIoCacheLowByteMask0(t0)   // write pattern to LowByte mask
        sw      t2,DmaIoCacheHighByteMask0(t0)  // write pattern to HighByte mask
        li      t2,0xFFFFFFFF                   // expected value
        lw      v0,DmaIoCacheLowByteMask0(t0)   // Read LowByte mask
        bne     v0,t2,MctadrRegError            // Check byte mask
        lw      v1,DmaIoCacheHighByteMask0(t0)  // Read HighByte mask
        bne     v1,t2,MctadrRegError            // Check byte mask
        li      a0,0xA0000000                   // get memory address zero.
        sw      zero,0(a0)                      // write address zero -> flushes buffers
        lw      v0,DmaIoCacheLowByteMask0(t0)   // Read LowByte mask
        bne     v0,zero,MctadrRegError          // Check byte mask was cleared.
        lw      v1,DmaIoCacheHighByteMask0(t0)  // Read HighByte mask
        bne     v1,zero,MctadrRegError          // Check byte mask was cleared.

        li      t4,MEMORY_REFRESH_RATE          //
        sw      t4,DmaRefreshRate(t0)           //
        li      t2,0x15555000                   //
        sw      t2,DmaTranslationBase(t0)       // write base of Translation Table
        li      t3,0xAAA0
        sw      t3,DmaTranslationLimit(t0)      // write to TT_limit
        lw      v1,DmaTranslationBase(t0)       // read TT Base
        lw      v0,DmaTranslationLimit(t0)      // read  TT_limit
        bne     v1,t2,MctadrRegError            // check TT-BASE
        lw      v1,DmaRefreshRate(t0)
        bne     v0,t3,MctadrRegError            // check TT-LIMIT
        li      t2,0x5550
        bne     v1,t4,MctadrRegError            // check REFRESH Rate
        li      t1,0xAAAA000
        sw      t1,DmaTranslationBase(t0)       // write to Translation Base
        sw      t2,DmaTranslationLimit(t0)      // write to Translation Limit
        lw      v0,DmaTranslationBase(t0)       // read TT Base
        lw      v1,DmaTranslationLimit(t0)      // read  TT limit
        bne     v0,t1,MctadrRegError            // check TT Base
        li      t1,TT_BASE_ADDRESS              // Init translation table base address
        sw      t1,DmaTranslationBase(t0)       // Initialize TT Base
        bne     v1,t2,MctadrRegError            // check TT Limit
        nop
        sw      zero,DmaTranslationLimit(t0)    // clear TT Limit

//
// Initialize remote speed registers.
//
        addiu   t1,t0,DmaRemoteSpeed1   // address of REM_SPEED 1
        la      a1,RomRemoteSpeedValues // - LINK_ADDRESS + RESET_VECTOR //
        addiu   t2,a1,14                // addres of last value
WriteNextRemSpeed:
        lbu     v0,0(a1)                // load init value for rem speed
        addiu   a1,a1,1                 // compute next address
        sw      v0,0(t1)                // write to rem speed reg
        bne     a1,t2,WriteNextRemSpeed // check for end condition
        addiu   t1,t1,8                 // next register address
        addiu   a1,t2,-14               // address of first value for rem speed register
        addiu   t1,t0,DmaRemoteSpeed1   // address of REM_SPEED 1
        lbu     v1,0(a1)                // read expected value
CheckNextRemSpeed:
        lw      v0,0(t1)                // read register
        addiu   a1,a1,1                 // address of next value
        bne     v0,v1,MctadrRegError    // check register
        addiu   t1,t1,8                 // address of next register
        bne     a1,t2,CheckNextRemSpeed // check for end condition
        lbu     v1,0(a1)                // read expected value

//
// Initialize the IO Arb register
//
        li      v0,2
        sw      v0,DmaArbitrationControl(t0)
//
// Now test the DMA channel registers
//
        addiu   t1,t0,DmaChannel0Mode   // address of channel 0
        addiu   t2,t1,4*DMA_CHANNEL_GAP // last address of channel regs
        li      a0,0x15                 // Mode
        li      a1,0x2                  // enable
        li      a2,0xAAAAA              // byte count
        li      a3,0x555555             // address
WriteNextChannel:
        sw      a0,0(t1)                // write mode
        sw      a1,0x8(t1)              // write enable
        sw      a2,0x10(t1)             // write byte count
        sw      a3,0x18(t1)             // write address
        addiu   t1,t1,DMA_CHANNEL_GAP   // compute address of next channel
        addiu   a2,a2,1                 // change addres
        bne     t1,t2,WriteNextChannel
        addiu   a3,a3,-1                // change Byte count
//
// Check channel regs.
//
        addiu   t1,t0,DmaChannel0Mode   // address of channel 0
        addiu   t2,t1,4*DMA_CHANNEL_GAP // last address of channel regs
        li      a2,0xAAAAA              // byte count
        li      a3,0x555555             // address
CheckNextChannel:
        lw      t4,0x0(t1)              // read mode
        lw      t5,0x8(t1)              // read enable
        bne     t4,a0,MctadrRegError    // check mode
        lw      t4,0x10(t1)             // read byte count
        bne     t5,a1,MctadrRegError    // check enable
        lw      t5,0x18(t1)             // read address
        bne     t4,a2,MctadrRegError    // check abyte count
        addiu   a2,a2,1                 // next expected byte count
        bne     t5,a3,MctadrRegError    // check address
        addiu   t1,t1,DMA_CHANNEL_GAP   // next channel address
        bne     t1,t2,CheckNextChannel
        addiu   a3,a3,-1
//
// Now do a second test on DMA channel registers
//
        addiu   t1,t0,DmaChannel0Mode   // address of channel 0
        addiu   t2,t1,4*DMA_CHANNEL_GAP // last address of channel regs
        li      a0,0x2A                 // Mode
        li      a2,0x55555              // byte count
        li      a3,0xAAAAAA             // address
WriteNextChannel2:
        sw      a0,0(t1)                // write mode
        sw      a2,0x10(t1)             // write byte count
        sw      a3,0x18(t1)             // write address
        addiu   t1,t1,DMA_CHANNEL_GAP   // compute address of next channel
        addiu   a2,a2,1                 // change addres
        bne     t1,t2,WriteNextChannel2
        addiu   a3,a3,-1                // change Byte count
//
// Check channel regs.
//
        addiu   t1,t0,DmaChannel0Mode   // address of channel 0
        addiu   t2,t1,4*DMA_CHANNEL_GAP // last address of channel regs
        li      a2,0x55555              // byte count
        li      a3,0xAAAAAA             // address
CheckNextChannel2:
        lw      t4,0x0(t1)              // read mode
        lw      t5,0x10(t1)             // read byte count
        bne     t4,a0,MctadrRegError    // check mode
        lw      t4,0x18(t1)             // read address
        bne     t5,a2,MctadrRegError    // check abyte count
        addiu   a2,a2,1                 // next expected byte count
        bne     t4,a3,MctadrRegError    // check address
        addiu   t1,t1,DMA_CHANNEL_GAP   // next channel address
        bne     t1,t2,CheckNextChannel2
        addiu   a3,a3,-1
//
// Now zero the channel registers
//
        addiu   t1,t0,DmaChannel0Mode   // address of channel 0
        addiu   t2,t1,4*DMA_CHANNEL_GAP // last address of channel regs
ZeroChannelRegs:
        addiu   t1,t1,8
        sw      zero,-8(t1)             // clear reg
        bne     t1,t2,ZeroChannelRegs
        nop                             //R4KFIX
        addiu   t1,t0,DmaChannel0Mode   // address of channel 0
        addiu   t2,t1,4*DMA_CHANNEL_GAP // last address of channel regs
CheckZeroedChannelRegs:
        lw      a0,0(t1)
        bne     a0,zero,MctadrRegError  // check
        addiu   t1,t1,8                 // next channel
        bne     t1,t2,CheckZeroedChannelRegs
        nop
        j       s0                      // return to caller.
MctadrRegError:
        li      t0,DIAGNOSTIC_VIRTUAL_BASE // get base address of diag register
        lb      t0,0(t0)                // read register value.
        li      t1,LOOP_ON_ERROR_MASK   // get value to compare
        andi    t0,DIAGNOSTIC_MASK      // mask diagnostic bits.
        beq     t1,t0,10f               // branch if loop on error.
        ori     a0,zero,LED_MCTADR_REG  // load LED display value.
        lui     t0,LED_BLINK            // get LED blink code
        bal     PutLedDisplay           // Blink LED and hang.
        or      a0,a0,t0                // pass argument in a0
10:
        lui     t0,LED_LOOP_ERROR       // get LED LOOP_ERROR code
        bal     PutLedDisplay           // Set LOOP ON ERROR on LED
        or      a0,a0,t0                // pass argument in a0
        b       MctadrReg
        nop
        .end    MctadrRegisterTest

/*

        LEAF_ENTRY(SizeMemory)
        .set noat
        .set noreorder
        li      t0,DMA_VIRTUAL_BASE+DmaMemoryConfig0
        li      t1,0x5
        sw      t1,0x0(t0)
        li      t1,0x1000005
        sw      t1,0x8(t0)
        li      t1,0x2000005
        sw      t1,0x10(t0)
        li      t1,0x3000005
        sw      t1,0x18(t0)
        j       ra
        nop
ExpectedParityException:
        .end
        LEAF_ENTRY(SizeMemory)
        .set noat
        .set noreorder
        li      t0,DMA_VIRTUAL_BASE+DmaMemoryConfig0
        li      t1,0xD
        sw      t1,0x0(t0)
        li      t1,0x200000D
        sw      t1,0x8(t0)
        li      t1,0x400000D
        sw      t1,0x10(t0)
        li      t1,0x600000D
        sw      t1,0x18(t0)
        j       ra
        nop
ExpectedParityException:
        .end
*/

/*++
SizeMemory(
    );
Routine Description:

    This routine sizes the memory and writes the proper value into
    the GLOBAL CONFIG register.  The way memory is sized is the following:

        For Each of the four Memory Groups:
          ConfigurationRegister is set to 0xE

          ID0 is written to offset 0 from base of bank
          ID4 is written to offset 4MB from base of bank
          ID20 is written to offset 20MB from base of bank
            if ID20 is found at offset 0 the current bank has 1MB SIMMs.
            if ID0 is found at offset 0 and ID20 is found at offset 4,
                the current bank has 4MB SIMMs.
            if ID0 is found at offset 0 and ID4 is found at offset 4
                and ID20 is found at offset 20, the current bank has 16MB SIMMs.
            if data does not match or a parity exception is taken
               then memory is not present in that bank.

          Once The size of the first side is determined, the second side
          is checked.


Arguments:

        None.

Return Value:

        If the installed memory is inconsistent, does not return
        and the LED flashes A.E

--*/

#define MEM_ID0     0x0A0A0A0A
#define MEM_ID4     0xF5F5F5F5
#define MEM_ID20    0xA0A0A0A0

        LEAF_ENTRY(SizeMemory)
        .set noat
        .set noreorder

//
// Size Memory for DUO
//
#define SIZE_1MBIT   0x0000             // Low byte. Shift value
#define SIZE_4MBIT   0x0102             // High byte configuration value.
#define SIZE_16MBIT  0x0204
//
// Size memory for duo.
//
        li      t1,MEM_ID0              // get ID0
        li      t3,MEM_ID4              // get ID4
        li      t5,MEM_ID20             // get ID20
        li      s0,8                    // counts how many banks left to check
        li      s1,DMA_VIRTUAL_BASE+DmaMemoryConfig0


DSizeGroup:
        li      t0,0xA0000000           // get address 0MB
        li      t2,0xA0400000           // get address 4MB
        li      t4,0xA1400000           // get address 20MB
        li      a2,0xE                  // Memory Config Full Enable Value
        sw      a2,0(s1)                // Store it.

DSizeBank:
        li      a1,SIZE_1MBIT           // set current bank to 1 MB by default
        sw      t1,0x0(t0)              // fill whole memory line at base of bank
        sw      t1,0x4(t0)
        sw      t1,0x8(t0)
        sw      t1,0xC(t0)
        sw      t3,0x0(t2)              // fill whole memory line at base of bank + 4MB
        sw      t3,0x4(t2)
        sw      t3,0x8(t2)
        sw      t3,0xC(t2)
        sw      t5,0x0(t4)              // fill whole memory line at base of bank + 20MB
        sw      t5,0x4(t4)
        sw      t5,0x8(t4)
        sw      t5,0xC(t4)
        //
        // Check written data
        //
        move    v1,zero                 // init v1 to zero
        .align  4                       // align address so that Parity Handler
                                        // can easily determine if it happened here
ExpectedParityException:
        lw      t6,0x0(t0)              // read whole memory line.
        lw      t7,0x4(t0)              // the four words must be identical
        lw      t8,0x8(t0)              //
        lw      t9,0xC(t0)              //
ParityExceptionReturnAddress:
        bne     v1,zero,10f             // if v1!=0 Parity exception occurred.
        move    a0,zero                 // tells that bank not present
        bne     t6,t7,10f               // check for consistency
        nop
        bne     t6,t8,10f               // check for consistency
        nop
        bne     t6,t9,10f               // check for consistency
        nop
        beq     t6,t5,10f               // If ID20 is found at 0MB
        li      a0,0x4                  // bank is present and SIMMS are 1 MB
        bne     t6,t1,10f               // if neither ID20 nor ID0 is found we are in trouble
        move    a0,zero                 // no memory in bank
        li      a0,0x4                  // bank is present

        //
        // ID written at Address 0 has been correctly checked
        // Now check the ID written at address 4MB
        //
        lw      t6,0x0(t2)              // read the whole memory line.
        lw      t7,0x4(t2)              // the four words must be identical
        bne     t6,t7,WrongMemory       // check for consistency
        lw      t8,0x8(t2)              //
        bne     t6,t8,WrongMemory       // check for consistency
        lw      t9,0xC(t2)              //
        bne     t6,t9,WrongMemory       // check for consistency
        nop
        beq     t6,t5,10f               // If ID20 is found at 4MB
        li      a1,SIZE_4MBIT           // bank is present and SIMMS are 4 MB
        bne     t6,t3,WrongMemory       // if neither ID20 nor ID4 is found we are in trouble
        nop
        //
        // ID written at Address 4MB has been correctly checked
        // Now check the ID written at address 20MB
        //
        lw      t6,0x0(t4)              // read the whole memory line.
        lw      t7,0x4(t4)              // the four words must be identical
        bne     t6,t7,WrongMemory       // check for consistency
        lw      t8,0x8(t4)              //
        bne     t6,t8,WrongMemory       // check for consistency
        lw      t9,0xC(t4)              //
        bne     t6,t9,WrongMemory       // check for consistency
        nop
        bne     t6,t5,WrongMemory       // if ID20 is not found we are in trouble
        nop
        li      a1,SIZE_16MBIT          // If all matches SIMMs are 16MB

10:     //
        // a0 has the value 0 if no memory in bank, 4 if memory in bank
        //
        // The lower byte of a1 has the amount the constant 4MB should be
        // left shifted by to get the nex address.
        // The second byte of a12 has the matching value for the SIMM
        // size bits of the Configuration register.
        //

        andi    AT,s0,1                 // Check if first side
        bne     AT,zero,GroupDone       // Branch if second side
        addiu   s0,s0,-1                // Decrement Bank counter

        //
        // First Side.
        //
        beq     a0,zero,GroupNotPresent // No memory present in this group

        move    a3,a0                   // Save bank presence bit.
        move    v0,a1                   // Save first side SIMM size

        //
        // Increment Base addresses by half the maximum size of a bank.
        //
        li      AT,0x4000000            // 64MB
        addu    t0,AT                   // get Next bank address + 0MB
        addu    t2,AT                   // get Next bank address + 4MB
        addu    t4,AT                   // get Next bank address +20MB
        b       DSizeBank               // Repeat for second side.
        nop

GroupNotPresent:
        sw      zero,0x0(s1)            // Disable current bank
        b       NextGroup
        addiu   s0,s0,-1                // Skip 2nd side of non exitent Group.


GroupDone:

        //
        // We are done with the current group.
        // a1 and v0 have the SIMM size.
        // a3 has first side presence bit a0 has second size presence bit.
        //
        beq     a0,zero,SingleSidedBank // if a0 is zero no memory found in
        nop                             // the second side. Don't check
                                        // consistency between sizes.
        bne     a1,v0,WrongMemory       // Both sides must have same size.
SingleSidedBank:
        sll     a0,1                    // shift enable second side bit.
        or      a3,a0,a3                // or in first side presence.
        srl     v0,8                    // Get SIMM size config value.
        or      a3,v0                   // or in with bank presence

        //
        // Set base of the sized bank up so that next bank
        // can be sized as if it started at offset zero.
        // When code gets here s0 has the value 6,4,2,0
        // shift it left by 26 bits to make the base of the bank
        // at address 6*64MB,4*64Mb,2*64MB,0MB
        //
        sll     AT,s0,26                // set base of bank to avoid colision between banks
        or      a3,AT,a3                // or physical base address.
        sw      a3,0x0(s1)              // Store into config register

NextGroup:
        bne     s0,zero,DSizeGroup      // Repeat for next group.
        addiu   s1,s1,8                 // Next configuration register.

        //
        // The four groups have been sized and it's SIMM type and size
        // value stored in the configuration register.
        // Set their base addresses sorting them from big to small
        //
        // Mask = 0;
        // BaseAddress = 0;
        // do {
        //     BiggestSize = 0;
        //     BiggestIndex = 0;
        //     for (t2=0; t2 < 4; t2++) {
        //         if (Mask & (1 << t2)) {
        //             continue;
        //         }
        //         if (GroupSize[Config[t2]] == 0) {
        //             Mask |= 1 << t2;
        //             continue;
        //         }
        //         if (GroupSize[Config[t2]] > BiggestSize) {
        //              BiggestSize = GroupSize[Config[t2]];
        //              BiggestIndex = t2;
        //         }
        //     }
        //     Config[BiggestIndex] = Config[BiggestIndex]&0xF + BaseAddress;
        //     Mask |= 1 << BiggestIndex;
        //     BaseAddress += BiggestSize;
        //  } while (Mask != 0xF);
        //
        //
        // t0 = BiggestSize
        // a3 = Biggest index
        // a1 = Mask. Each bit indicates that group has been dealth with
        // a2 = BaseAddress
        //

        la      v0,MemoryGroupSize      // Address of table
        li      v1,DMA_VIRTUAL_BASE+DmaMemoryConfig0    // Address of first config register
        move    a2,zero                 // base address of group
        move    a1,zero                 // mask register
Loop:
        move    t2,zero                 // loop count
        move    a3,zero                 // biggest group index
        move    t0,zero                 // size of biggest group

ReadNextGroup:
        li      t4,1
        sll     t4,t4,t2                // set Nth bit for iteration N
        nop
        and     t5,a1,t4                // test if bit set in mask
        beq     t5,zero,10f             // if not set read current group config
        nop
        b       ForEachGroup
        addiu   t2,t2,1                 // Increment group index

10:
        sll     t3,t2,3                 // multiply loop count by 8
        addu    t3,t3,v1                // add to base of config registers
        lw      a0,0x0(t3)              // read config register
        andi    a0,0xF                  // extract SIMM type bits
        addu    a0,a0,v0                // add to base of table
        lbu     a0,0(a0)                // index table to get size in MB
        beq     a0,zero,SizeZeroGroup   // if zero set mask bit for this group
        sltu    t1,t0,a0                // Branch if the size of the biggest group is
        bne     t1,zero,BiggerFound     // smaller than the current group
        nop
        b       ForEachGroup            // Go for next group
        addiu   t2,t2,1                 // Increment index

BiggerFound:
        //
        // The current group is the biggest found so far
        //
        move    t0,a0                   // set biggest group to current
        move    a3,t2                   // save biggest group index
        b       ForEachGroup
        addiu   t2,t2,1                 // next group index.


SizeZeroGroup:
        //
        // Or Nth bit to tell that this group doesn't
        // need to be dealth with since it's size is zero
        //
        or      a1,a1,t4
        addiu   t2,t2,1                 // increment group index

ForEachGroup:
        li      t1,4                    // last group
        bne     t2,t1,ReadNextGroup     // if not last group repeat

        //
        //  The four groups where checked.
        //  t0 has the size of the biggest found.
        //  a3 has the index of the biggest found.
        //  Set the current base to the config register
        //  Increment the base by the size of the register
        //
        sll     t3,a3,3                 // multiply index by 8
        addu    t3,t3,v1                // add to base of config registers
        lw      a0,0x0(t3)              // read config register
        andi    a0,0xF                  // extract SIMM type bits
        or      a0,a2                   // or in the current base address
        sw      a0,0(t3)                // store
        sll     t0,20                   // shift size in MB to address
        addu    a2,a2,t0                // add size to current base

        li      t4,1                    // get a 1
        sll     t4,t4,a3                // set Nth bit for biggest found N
        or      a1,a1,t4                // or into mask of processed groups
        li      t1,0xF                  //
        bne     t1,a1,Loop              // if not all bits set in the mask Loop
        nop
        j       ra                      // return to caller.
        nop

WrongMemory:
        //
        // Control reaches here if the memory can't be sized.
        //
        lui     a0,LED_BLINK            // Hang
        bal     PutLedDisplay           // blinking the error code
        ori     a0,a0,LED_WRONG_MEMORY  // in the LED
        .end    SizeMemory


//
// This table indexed with the low 4 bits of the MemoryGroup config register,
// returns the size of memory installed in the group in Megabytes.
//
//
MemoryGroupSize:
.byte   0           // No SIMM installed
.byte   0           // No SIMM installed
.byte   0           // No SIMM installed
.byte   0           // No SIMM installed
.byte   4           // Single Sided 4MB
.byte  16           // Single Sided 16MB
.byte  64           // Single Sided 64MB
.byte   0           // Single Sided reserved
.byte   0           // Reserved
.byte   0           // Reserved
.byte   0           // Reserved
.byte   0           // Reserved
.byte   8           // Double Sided 4MB
.byte  32           // Double Sided 16MB
.byte 128           // Double Sided 64MB
.byte   0           // Double Sided reserved

#endif  // DUO && R4000
