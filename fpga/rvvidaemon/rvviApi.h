/*
 * Copyright (c) 2005-2023 Imperas Software Ltd., www.imperas.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#pragma once

/*! \file rvviApi.h
 *  \brief RVVI interface, C API header.
**/

#include <stdint.h>

typedef uint32_t bool_t;

#define RVVI_API_VERSION_MAJOR 1
#define RVVI_API_VERSION_MINOR 34
#define RVVI_TRUE 1
#define RVVI_FALSE 0
#define RVVI_INVALID_INDEX -1
#define RVVI_MEMORY_PRIVILEGE_READ 1
#define RVVI_MEMORY_PRIVILEGE_WRITE 2
#define RVVI_MEMORY_PRIVILEGE_EXEC 4
#define RVVI_API_VERSION ((RVVI_API_VERSION_MAJOR << 24) | RVVI_API_VERSION_MINOR)

typedef enum {
    RVVI_METRIC_RETIRES = 0,
    RVVI_METRIC_TRAPS = 1,
    RVVI_METRIC_MISMATCHES = 2,
    RVVI_METRIC_COMPARISONS_PC = 3,
    RVVI_METRIC_COMPARISONS_GPR = 4,
    RVVI_METRIC_COMPARISONS_FPR = 5,
    RVVI_METRIC_COMPARISONS_CSR = 6,
    RVVI_METRIC_COMPARISONS_VR = 7,
    RVVI_METRIC_COMPARISONS_INSBIN = 8,
    RVVI_METRIC_CYCLES = 9,
    RVVI_METRIC_ERRORS = 10,
    RVVI_METRIC_WARNINGS = 11,
    RVVI_METRIC_FATALS = 12,
} rvviMetricE;

#ifdef __cplusplus
extern "C" {
#endif

/*! \brief Check the compiled RVVI API version.
 *
 *  Makes sure the RVVI implementation linked with matches the versions defined in this header file. This should be called before any other RVVI API function. If this function returns RVVI_FALSE, no other RVVI API function should be called.
 *
 *  \param version Should be set to RVVI_API_VERSION.
 *
 *  \return RVVI_TRUE if versions matches otherwise RVVI_FALSE.
**/
extern bool_t rvviVersionCheck(
    uint32_t version);

/*! \brief Initialize the DV reference model.
 *
 *  \param programPath File path of the ELF file to be executed. This parameter can be NULL if required.
 *
 *  \return RVVI_TRUE if the reference was initialized successfully else RVVI_FALSE.
 *
 *  \note The reference model will begin execution from the entry point of the provided ELF file but can be overridden by the rvviRefPcSet() function.
**/
extern bool_t rvviRefInit(
    const char *programPath);

/*! \brief Force the PC of the reference model to be particular value.
 *
 *  \param hartId The hart to change the PC register of.
 *  \param address The address to change the PC register to.
 *
 *  \return RVVI_TRUE on success else RVVI_FALSE.
**/
extern bool_t rvviRefPcSet(
    uint32_t hartId,
    uint64_t address);

/*! \brief Shutdown the reference module releasing any used resources.
 *
 *  \return Returns RVVI_TRUE if shutdown was successful else RVVI_FALSE.
**/
extern bool_t rvviRefShutdown(void);

/*! \brief Notify the reference that a CSR is considered volatile.
 *
 *  \param hartId The hart that will have its CSR made volatile.
 *  \param csrIndex Index of the CSR register to be considered volatile (0x0 to 0xfff).
 *
 *  \return Returns RVVI_TRUE if operation was successful else RVVI_FALSE.
**/
extern bool_t rvviRefCsrSetVolatile(
    uint32_t hartId,
    uint32_t csrIndex);

/*! \brief Notify the reference that a memory region is volatile.
 *
 *  \param addressLow Lower address of the volatile memory region
 *  \param addressHigh Upper address of the volatile memory region (inclusive)
 *
 *  \return Returns RVVI_TRUE if operation was successful else RVVI_FALSE.
**/
extern bool_t rvviRefMemorySetVolatile(
    uint64_t addressLow,
    uint64_t addressHigh);

/*! \brief Lookup a net on the reference model and return its index.
 *
 *  \param name The net name to locate.
 *
 *  \return Unique index for this net or RVVI_INVALID_INDEX if it was not found.
 *
 *  \note Please consult the model datasheet for a list of valid net names.
 *  \note See also, rvviRefNetSet().
**/
extern uint64_t rvviRefNetIndexGet(
    const char *name);

/*! \brief Extract a byte from the reference models vector register.
 *
 *  \param hartId The hart to extract the vector register byte from.
 *  \param vrIndex The vector register index (0 to 31).
 *  \param byteIndex The byte offset into the vector register (note 0 is LSB).
 *
 *  \return Byte that has been extracted from the vector register.
**/
extern uint8_t rvviRefVrGet(
    uint32_t hartId,
    uint32_t vrIndex,
    uint32_t byteIndex);

/*! \brief Notify RVVI that a byte in the DUTs vector register has changed.
 *
 *  \param hartId The hart that has updated its vector register.
 *  \param vrIndex The vector register index (0 to 31).
 *  \param byteIndex The byte offset into the vector register (note 0 is LSB).
 *  \param data New byte value in the DUTs vector register.
**/
extern void rvviDutVrSet(
    uint32_t hartId,
    uint32_t vrIndex,
    uint32_t byteIndex,
    uint8_t data);

/*! \brief Notify RVVI that a DUT floating point register has been written to.
 *
 *  \param hartId The hart that has updated its FPR.
 *  \param fprIndex The FPR index within the register file (0 to 31).
 *  \param value The value that has been written.
**/
extern void rvviDutFprSet(
    uint32_t hartId,
    uint32_t fprIndex,
    uint64_t value);

/*! \brief Notify RVVI that a DUT GPR has been written to.
 *
 *  \param hartId The hart that has updated its GPR.
 *  \param gprIndex The GPR index within the register file.
 *  \param value The value that has been written.
**/
extern void rvviDutGprSet(
    uint32_t hartId,
    uint32_t gprIndex,
    uint64_t value);

/*! \brief Notify RVVI that a DUT CSR has been written to.
 *
 *  \param hartId The hart that has updated its CSR.
 *  \param csrIndex The CSR index (0x0 to 0xfff).
 *  \param value The value that has been written.
**/
extern void rvviDutCsrSet(
    uint32_t hartId,
    uint32_t csrIndex,
    uint64_t value);

/*! \brief Place a net in a specific net group.
 *
 *  \param netIndex The net index returned prior by rvviRefNetIndexGet().
 *  \param group The group index to place this net into.
**/
extern void rvviRefNetGroupSet(
    uint64_t netIndex,
    uint32_t group);

/*! \brief Propagate a net change to the reference model.
 *
 *  \param netIndex The net index returned prior by rvviRefNetIndexGet().
 *  \param value The new value to set the net state to.
 *  \param when Time of arrival of this net, in simulation time. The `when` parameter may be measured in simulation time or cycles. It allows the RVVI-API to know which net changes have arrived at the same time.
**/
extern void rvviRefNetSet(
    uint64_t netIndex,
    uint64_t value,
    uint64_t when);

/*! \brief Read the state of a net on the reference model.
 *
 *  \param netIndex The net index returned prior by rvviRefNetIndexGet().
 *
 *  \return The value present on the specified net.
**/
extern uint64_t rvviRefNetGet(
    uint64_t netIndex);

/*! \brief Notify the reference that a DUT instruction has retired.
 *
 *  \param hartId The hart that has retired an instruction.
 *  \param dutPc The address of the instruction that has retired.
 *  \param dutInsBin The binary instruction representation.
 *  \param debugMode True if this instruction was executed in debug mode.
**/
extern void rvviDutRetire(
    uint32_t hartId,
    uint64_t dutPc,
    uint64_t dutInsBin,
    bool_t debugMode);

/*! \brief Notify the reference that the DUT received a trap.
 *
 *  \param hartId The hart that has retired an instruction.
 *  \param dutPc The address of the instruction that has retired.
 *  \param dutInsBin The binary instruction representation.
**/
extern void rvviDutTrap(
    uint32_t hartId,
    uint64_t dutPc,
    uint64_t dutInsBin);

/*! \brief Invalidate the reference models LR/SC reservation.
 *
 *  \param hartId The hart of which the LR/SC reservation will be made invalid.
**/
extern void rvviRefReservationInvalidate(
    uint32_t hartId);

/*! \brief Step the reference model until the next event.
 *
 *  \param hartId The ID of the hart that is being stepped.
 *
 *  \return Returns RVVI_TRUE if the step was successful else RVVI_FALSE.
**/
extern bool_t rvviRefEventStep(
    uint32_t hartId);

/*! \brief Compare all GPR register values between reference and DUT.
 *
 *  \param hartId The ID of the hart that is being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefGprsCompare(
    uint32_t hartId);

/*! \brief Compare GPR registers that have been written to between the reference and DUT. This can be seen as a super set of the rvviRefGprsCompare function. This comparator will also flag differences in the set of registers that have been written to.
 *
 *  \param hartId The ID of the hart that is being compared.
 *  \param ignoreX0 RVVI_TRUE to not compare writes to the x0 register, which may be treated as a special case, otherwise RVVI_FALSE.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefGprsCompareWritten(
    uint32_t hartId,
    bool_t ignoreX0);

/*! \brief Compare retired instruction bytes between reference and DUT.
 *
 *  \param hartId The ID of the hart that is being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefInsBinCompare(
    uint32_t hartId);

/*! \brief Compare program counter for the retired instructions between DUT and the the reference model.
 *
 *  \param hartId The ID of the hart that is being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefPcCompare(
    uint32_t hartId);

/*! \brief Compare a CSR value between DUT and the the reference model.
 *
 *  \param hartId The ID of the hart that is being compared.
 *  \param csrIndex The index of the CSR register being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefCsrCompare(
    uint32_t hartId,
    uint32_t csrIndex);

/*! \brief Enable or disable comparison of a specific CSR during rvviRefCsrsCompare.
 *
 *  \param hartId The ID of the hart that this should apply to.
 *  \param csrIndex The index of the CSR to enable or disable comparison of.
 *  \param enableState RVVI_TRUE to enable comparison or RVVI_FALSE to disable.
**/
extern void rvviRefCsrCompareEnable(
    uint32_t hartId,
    uint32_t csrIndex,
    bool_t enableState);

/*! \brief Specify a bitmask to direct bit level CSR comparisons.
 *
 *  \param hartId The ID of the hart that this should apply to.
 *  \param csrIndex The index of the CSR to control the comparison of.
 *  \param mask Bitmask to enable or disable bits during CSR compare operations. Bits set to 1 will be compared and 0 bits are ignored.
**/
extern void rvviRefCsrCompareMask(
    uint32_t hartId,
    uint32_t csrIndex,
    uint64_t mask);

/*! \brief Compare all CSR values between DUT and the the reference model.
 *
 *  This function will compare the value of all CSRs between the reference and the DUT. Note that specific CSRs can be removed from this comparison by using the rvviRefCsrCompareEnable function.
 *
 *  \param hartId The ID of the hart that is being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefCsrsCompare(
    uint32_t hartId);

/*! \brief Compare all RVV vector register values between reference and DUT.
 *
 *  \param hartId The ID of the hart that is being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefVrsCompare(
    uint32_t hartId);

/*! \brief Compare all floating point register values between reference and DUT.
 *
 *  \param hartId The ID of the hart that is being compared.
 *
 *  \return RVVI_FALSE if there are any mismatches, otherwise RVVI_TRUE.
**/
extern bool_t rvviRefFprsCompare(
    uint32_t hartId);

/*! \brief Write to the GPR of a hart in the reference model.
 *
 *  \param hartId The hart to write the GPR of.
 *  \param gprIndex Index of the GPR register to write.
 *  \param gprValue Value to write into the GPR register.
**/
extern void rvviRefGprSet(
    uint32_t hartId,
    uint32_t gprIndex,
    uint64_t gprValue);

/*! \brief Read a GPR value from a hart in the reference model.
 *
 *  \param hartId The hart to retrieve the GPR from.
 *  \param gprIndex Index of the GPR register to read.
 *
 *  \return GPR value read from the reference model.
**/
extern uint64_t rvviRefGprGet(
    uint32_t hartId,
    uint32_t gprIndex);

/*! \brief Read a GPR written mask from the last rvviRefEventStep.
 *
 *  Each bit index in the mask returned indicates if the corresponding GPR has been written to by the reference model. Ie, if bit 3 is set, then X3 was written to.
 *
 *  \param hartId The hart to retrieve the GPR written mask from.
 *
 *  \return The GPR written mask.
**/
extern uint32_t rvviRefGprsWrittenGet(
    uint32_t hartId);

/*! \brief Return the program counter of a hart in the reference model.
 *
 *  \param hartId The hart to retrieve the PC from.
 *
 *  \return The program counter of the specified hart.
**/
extern uint64_t rvviRefPcGet(
    uint32_t hartId);

/*! \brief Read a CSR value from a hart in the reference model.
 *
 *  \param hartId The hart to retrieve the CSR from.
 *  \param csrIndex Index of the CSR register to read (0x0 to 0xfff).
 *
 *  \return The CSR register value read from the specified hart.
**/
extern uint64_t rvviRefCsrGet(
    uint32_t hartId,
    uint32_t csrIndex);

/*! \brief Return the binary representation of the previously retired instruction.
 *
 *  \param hartId The hart to retrieve the instruction from.
 *
 *  \return The instruction bytes.
**/
extern uint64_t rvviRefInsBinGet(
    uint32_t hartId);

/*! \brief Write the value of a floating point register for a hart in the reference model.
 *
 *  \param hartId The hart to retrieve the FPR register from.
 *  \param fprIndex Index of the floating point register to read.
 *  \param fprValue The bit pattern to be written into the floating point register.
**/
extern void rvviRefFprSet(
    uint32_t hartId,
    uint32_t fprIndex,
    uint64_t fprValue);

/*! \brief Read a floating point register value from a hart in the reference model.
 *
 *  \param hartId The hart to retrieve the FPR register from.
 *  \param fprIndex Index of the floating point register to read.
 *
 *  \return The FPR register value read from the specified hart.
**/
extern uint64_t rvviRefFprGet(
    uint32_t hartId,
    uint32_t fprIndex);

/*! \brief Notify RVVI that the DUT has been written to memory.
 *
 *  \param hartId The hart that issued the data bus write.
 *  \param address The address the hart is writing to.
 *  \param value The value placed on the data bus.
 *  \param byteEnableMask The byte enable mask provided for this write.
 *
 *  \note Bus writes larger than 64bits should be reported using multiple calls to this function.
 *  \note byteEnableMask bit 0 corresponds to address+0, bEnMask bit 1 corresponds to address+1, etc.
**/
extern void rvviDutBusWrite(
    uint32_t hartId,
    uint64_t address,
    uint64_t value,
    uint64_t byteEnableMask);

/*! \brief Write data to the reference models physical memory space.
 *
 *  \param hartId The hart to write from the perspective of.
 *  \param address The address being written to.
 *  \param data The data byte being written into memory.
 *  \param size Size of the data being written in bytes (1 to 8).
**/
extern void rvviRefMemoryWrite(
    uint32_t hartId,
    uint64_t address,
    uint64_t data,
    uint32_t size);

/*! \brief Read data from the reference models physical memory space.
 *
 *  \param hartId The hart to read from the perspective of.
 *  \param address The address being read from.
 *  \param size Size of the data being read in bytes (1 to 8).
 *
 *  \return The data that has been read from reference memory.
**/
extern uint64_t rvviRefMemoryRead(
    uint32_t hartId,
    uint64_t address,
    uint32_t size);

/*! \brief Disassemble an arbitrary instruction encoding.
 *
 *  \param hartId Hart with the ISA we are disassembling for.
 *  \param address Address of the instruction in memory.
 *  \param insBin The raw instruction that should be disassembled.
 *
 *  \return Null terminated string containing the disassembly.
**/
extern const char *rvviDasmInsBin(
    uint32_t hartId,
    uint64_t address,
    uint64_t insBin);

/*! \brief Return the name of a CSR in the reference model.
 *
 *  \param hartId Hart with the CSR we are looking up the name of.
 *  \param csrIndex The index of the CSR we are looking up (0x0 to 0xfff inclusive).
 *
 *  \return Null terminated string containing the CSR name.
**/
extern const char *rvviRefCsrName(
    uint32_t hartId,
    uint32_t csrIndex);

/*! \brief Return the ABI name of a GPR in the reference model.
 *
 *  \param hartId Hart with the GPR we are looking up the name of.
 *  \param gprIndex The index of the GPR we are looking up (0 to 31 inclusive).
 *
 *  \return Null terminated string containing the GPR ABI name.
**/
extern const char *rvviRefGprName(
    uint32_t hartId,
    uint32_t gprIndex);

/*! \brief Check if a CSR is present in the reference model.
 *
 *  \param hartId Hart with the CSR we are checking the presence of.
 *  \param csrIndex The index of the CSR we are checking for (0x0 to 0xfff inclusive).
 *
 *  \return RVVI_TRUE if the CSR is present in the reference model else RVVI_FALSE.
**/
extern bool_t rvviRefCsrPresent(
    uint32_t hartId,
    uint32_t csrIndex);

/*! \brief Check if floating point registers are present in the reference model.
 *
 *  \param hartId Hart Id we are checking for the presence of floating point registers.
 *
 *  \return RVVI_TRUE if the floating point registers are present in the reference model else RVVI_FALSE.
**/
extern bool_t rvviRefFprsPresent(
    uint32_t hartId);

/*! \brief Check if vector registers are present in the reference model.
 *
 *  \param hartId Hart Id we are checking for the presence of vector registers.
 *
 *  \return RVVI_TRUE if the vector registers are present in the reference model else RVVI_FALSE.
**/
extern bool_t rvviRefVrsPresent(
    uint32_t hartId);

/*! \brief Return the name of a FPR in the reference model.
 *
 *  \param hartId Hart with the FPR we are looking up the name of.
 *  \param fprIndex The index of the FPR we are looking up (0 to 31 inclusive).
 *
 *  \return Null terminated string containing the FPR name.
**/
extern const char *rvviRefFprName(
    uint32_t hartId,
    uint32_t fprIndex);

/*! \brief Return the name of a vector register in the reference model.
 *
 *  \param hartId Hart with the VR we are looking up the name of.
 *  \param vrIndex The index of the VR we are looking up (0 to 31 inclusive).
 *
 *  \return Null terminated string containing the VR name.
**/
extern const char *rvviRefVrName(
    uint32_t hartId,
    uint32_t vrIndex);

/*! \brief Return a string detailing the last RVVI-API error.
 *
 *  \return The error string or an empty string if no error has occurred.
**/
extern const char *rvviErrorGet(void);

/*! \brief Query a verification metric from the reference model.
 *
 *  \param metric An enumeration identifying the metric to query and return.
 *
 *  \return The scalar quantity that has been queried.
**/
extern uint64_t rvviRefMetricGet(
    rvviMetricE metric);

/*! \brief Set the value of a CSR in the reference model.
 *
 *  \param hartId The hart which we are modifying the CSR of.
 *  \param csrIndex The index of the CSR we are modifying (0x0 to 0xfff inclusive).
 *  \param value The value to write into the CSR.
**/
extern void rvviRefCsrSet(
    uint32_t hartId,
    uint32_t csrIndex,
    uint64_t value);

/*! \brief Dump the current register state of a hart in the reference model.
 *
 *  \param hartId The hart which we should dump the register state of.
**/
extern void rvviRefStateDump(
    uint32_t hartId);

/*! \brief Load an additional program into the address space of the processor.
 *
 *  \param programPath File path of the ELF file to be loaded into memory.
 *
 *  \return RVVI_TRUE if the program was loaded successfully otherwise RVVI_FALSE
**/
extern bool_t rvviRefProgramLoad(
    const char *programPath);

/*! \brief Apply fine grain control over a CSRs volatility in the reference model.
 *
 *  \param hartId The hart that will have its CSR volatility adjusted.
 *  \param csrIndex Index of the CSR register to have its volatility modified (0x0 to 0xfff).
 *  \param csrMask Bitmask specifying volatility, set bits will be treated as volatile, clear bits are not
 *
 *  \return Returns RVVI_TRUE if operation was successful else RVVI_FALSE.
**/
extern bool_t rvviRefCsrSetVolatileMask(
    uint32_t hartId,
    uint32_t csrIndex,
    uint64_t csrMask);

/*! \brief Pass the current testbench cycle count to the RVVI implementation.
 *
 *  \param cycleCount The current cycle count of the DUT. This value is directly related to, and must be consistent with, the `when` parameter for rvviRefNetSet().
**/
extern void rvviDutCycleCountSet(
    uint64_t cycleCount);

/*! \brief Pass a vendor specific integer configuration parameter to the RVVI implementation.
 *
 *  \param configParam The configuration option that is to have its associated value set. This is vendor specific and not defined as part of the RVVI-API.
 *  \param value An integer containing the data that should be passed to the configuration option.
 *
 *  \return Returns RVVI_TRUE if operation was successful else RVVI_FALSE.
**/
extern bool_t rvviRefConfigSetInt(
    uint64_t configParam,
    uint64_t value);

/*! \brief Pass a vendor specific string configuration parameter to the RVVI implementation.
 *
 *  \param configParam The configuration option that is to have its associated value set. This is vendor specific and not defined as part of the RVVI-API.
 *  \param value A string containing the data that should be passed to the configuration option.
 *
 *  \return Returns RVVI_TRUE if operation was successful else RVVI_FALSE.
**/
extern bool_t rvviRefConfigSetString(
    uint64_t configParam,
    const char *value);

/*! \brief Given the name of a CSR, its unique index/address will be returned.
 *
 *  \param hartId HartId of the hart containing the CSR we are looking up the index of.
 *  \param csrName The CSR name for which the CSR index should be retrieved.
 *
 *  \return Returns the CSR index if the operation was successful else RVVI_INVALID_INDEX.
**/
extern uint32_t rvviRefCsrIndex(
    uint32_t hartId,
    const char *csrName);

/*! \brief Set the privilege mode for a region of the address space.
 *
 *  \param addrLo Lower address defining the memory region.
 *  \param addrHi Upper address defining the memory region (inclusive).
 *  \param access Access flags for this memory region; a combination of RVVI_PRIV_... flags or 0.
 *
 *  \return Returns RVVI_TRUE if operation was successful else RVVI_FALSE.
**/
extern bool_t rvviRefMemorySetPrivilege(
    uint64_t addrLo,
    uint64_t addrHi,
    uint32_t access);

/*! \brief Update a byte in one of the reference models vector registers.
 *
 *  \param hartId The hart that should have its vector register updated.
 *  \param vrIndex The vector register index (0 to 31).
 *  \param byteIndex The byte offset into the vector register (note 0 is LSB).
 *  \param data New byte value to be written into the vector register.
**/
extern void rvviRefVrSet(
    uint32_t hartId,
    uint32_t vrIndex,
    uint32_t byteIndex,
    uint8_t data);

#ifdef __cplusplus
}  // extern "C"
#endif

