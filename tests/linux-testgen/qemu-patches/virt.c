/*
 * QEMU RISC-V VirtIO Board
 *
 * Copyright (c) 2017 SiFive, Inc.
 *
 * RISC-V machine with 16550a UART and VirtIO MMIO
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2 or later, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "qemu/osdep.h"
#include "qemu/units.h"
#include "qemu/log.h"
#include "qemu/error-report.h"
#include "qapi/error.h"
#include "hw/boards.h"
#include "hw/loader.h"
#include "hw/sysbus.h"
#include "hw/qdev-properties.h"
#include "hw/char/serial.h"
#include "target/riscv/cpu.h"
#include "hw/riscv/riscv_hart.h"
#include "hw/riscv/virt.h"
#include "hw/riscv/boot.h"
#include "hw/riscv/numa.h"
#include "hw/intc/sifive_clint.h"
#include "hw/intc/sifive_plic.h"
#include "hw/misc/sifive_test.h"
#include "chardev/char.h"
#include "sysemu/arch_init.h"
#include "sysemu/device_tree.h"
#include "sysemu/sysemu.h"
#include "hw/pci/pci.h"
#include "hw/pci-host/gpex.h"
#include "hw/display/ramfb.h"

static const MemMapEntry virt_memmap[] = {
    [VIRT_MROM] =        {     0x1000,        0xf000 },
    [VIRT_CLINT] =       {  0x2000000,       0x10000 },
    [VIRT_PLIC] =        {  0xc000000, VIRT_PLIC_SIZE(VIRT_CPUS_MAX * 2) },
    [VIRT_UART0] =       { 0x10000000,         0x100 },
    [VIRT_DRAM] =        { 0x80000000,           0x0 },
};

/* PCIe high mmio is fixed for RV32 */
#define VIRT32_HIGH_PCIE_MMIO_BASE  0x300000000ULL
#define VIRT32_HIGH_PCIE_MMIO_SIZE  (4 * GiB)

/* PCIe high mmio for RV64, size is fixed but base depends on top of RAM */
#define VIRT64_HIGH_PCIE_MMIO_SIZE  (16 * GiB)

#define VIRT_FLASH_SECTOR_SIZE (256 * KiB)

static void create_fdt(RISCVVirtState *s, const MemMapEntry *memmap,
                       uint64_t mem_size, const char *cmdline, bool is_32_bit)
{
    void *fdt;
    //int i, cpu, socket;
    int cpu, socket;
    MachineState *mc = MACHINE(s);
    uint64_t addr, size;
    uint32_t *clint_cells, *plic_cells;
    unsigned long clint_addr, plic_addr;
    uint32_t plic_phandle[MAX_NODES];
    uint32_t cpu_phandle, intc_phandle;
    uint32_t phandle = 1, plic_mmio_phandle = 1;
    char *mem_name, *cpu_name, *core_name, *intc_name;
    char *name, *clint_name, *plic_name, *clust_name;

    if (mc->dtb) {
        fdt = mc->fdt = load_device_tree(mc->dtb, &s->fdt_size);
        if (!fdt) {
            error_report("load_device_tree() failed");
            exit(1);
        }
        goto update_bootargs;
    } else {
        fdt = mc->fdt = create_device_tree(&s->fdt_size);
        if (!fdt) {
            error_report("create_device_tree() failed");
            exit(1);
        }
    }

    qemu_fdt_setprop_string(fdt, "/", "model", "riscv-virtio,qemu");
    qemu_fdt_setprop_string(fdt, "/", "compatible", "riscv-virtio");
    qemu_fdt_setprop_cell(fdt, "/", "#size-cells", 0x2);
    qemu_fdt_setprop_cell(fdt, "/", "#address-cells", 0x2);

    qemu_fdt_add_subnode(fdt, "/soc");
    qemu_fdt_setprop(fdt, "/soc", "ranges", NULL, 0);
    qemu_fdt_setprop_string(fdt, "/soc", "compatible", "simple-bus");
    qemu_fdt_setprop_cell(fdt, "/soc", "#size-cells", 0x2);
    qemu_fdt_setprop_cell(fdt, "/soc", "#address-cells", 0x2);

    qemu_fdt_add_subnode(fdt, "/cpus");
    qemu_fdt_setprop_cell(fdt, "/cpus", "timebase-frequency",
                          SIFIVE_CLINT_TIMEBASE_FREQ);
    qemu_fdt_setprop_cell(fdt, "/cpus", "#size-cells", 0x0);
    qemu_fdt_setprop_cell(fdt, "/cpus", "#address-cells", 0x1);
    qemu_fdt_add_subnode(fdt, "/cpus/cpu-map");

    for (socket = (riscv_socket_count(mc) - 1); socket >= 0; socket--) {
        clust_name = g_strdup_printf("/cpus/cpu-map/cluster%d", socket);
        qemu_fdt_add_subnode(fdt, clust_name);

        plic_cells = g_new0(uint32_t, s->soc[socket].num_harts * 4);
        clint_cells = g_new0(uint32_t, s->soc[socket].num_harts * 4);

        for (cpu = s->soc[socket].num_harts - 1; cpu >= 0; cpu--) {
            cpu_phandle = phandle++;

            cpu_name = g_strdup_printf("/cpus/cpu@%d",
                s->soc[socket].hartid_base + cpu);
            qemu_fdt_add_subnode(fdt, cpu_name);
            if (is_32_bit) {
                qemu_fdt_setprop_string(fdt, cpu_name, "mmu-type", "riscv,sv32");
            } else {
                qemu_fdt_setprop_string(fdt, cpu_name, "mmu-type", "riscv,sv48");
            }
            name = riscv_isa_string(&s->soc[socket].harts[cpu]);
            qemu_fdt_setprop_string(fdt, cpu_name, "riscv,isa", name);
            g_free(name);
            qemu_fdt_setprop_string(fdt, cpu_name, "compatible", "riscv");
            qemu_fdt_setprop_string(fdt, cpu_name, "status", "okay");
            qemu_fdt_setprop_cell(fdt, cpu_name, "reg",
                s->soc[socket].hartid_base + cpu);
            qemu_fdt_setprop_string(fdt, cpu_name, "device_type", "cpu");
            riscv_socket_fdt_write_id(mc, fdt, cpu_name, socket);
            qemu_fdt_setprop_cell(fdt, cpu_name, "phandle", cpu_phandle);

            intc_name = g_strdup_printf("%s/interrupt-controller", cpu_name);
            qemu_fdt_add_subnode(fdt, intc_name);
            intc_phandle = phandle++;
            qemu_fdt_setprop_cell(fdt, intc_name, "phandle", intc_phandle);
            qemu_fdt_setprop_string(fdt, intc_name, "compatible",
                "riscv,cpu-intc");
            qemu_fdt_setprop(fdt, intc_name, "interrupt-controller", NULL, 0);
            qemu_fdt_setprop_cell(fdt, intc_name, "#interrupt-cells", 1);

            clint_cells[cpu * 4 + 0] = cpu_to_be32(intc_phandle);
            clint_cells[cpu * 4 + 1] = cpu_to_be32(IRQ_M_SOFT);
            clint_cells[cpu * 4 + 2] = cpu_to_be32(intc_phandle);
            clint_cells[cpu * 4 + 3] = cpu_to_be32(IRQ_M_TIMER);

            plic_cells[cpu * 4 + 0] = cpu_to_be32(intc_phandle);
            plic_cells[cpu * 4 + 1] = cpu_to_be32(IRQ_M_EXT);
            plic_cells[cpu * 4 + 2] = cpu_to_be32(intc_phandle);
            plic_cells[cpu * 4 + 3] = cpu_to_be32(IRQ_S_EXT);

            core_name = g_strdup_printf("%s/core%d", clust_name, cpu);
            qemu_fdt_add_subnode(fdt, core_name);
            qemu_fdt_setprop_cell(fdt, core_name, "cpu", cpu_phandle);

            g_free(core_name);
            g_free(intc_name);
            g_free(cpu_name);
        }

        addr = memmap[VIRT_DRAM].base + riscv_socket_mem_offset(mc, socket);
        size = riscv_socket_mem_size(mc, socket);
        mem_name = g_strdup_printf("/memory@%lx", (long)addr);
        qemu_fdt_add_subnode(fdt, mem_name);
        qemu_fdt_setprop_cells(fdt, mem_name, "reg",
            addr >> 32, addr, size >> 32, size);
        qemu_fdt_setprop_string(fdt, mem_name, "device_type", "memory");
        riscv_socket_fdt_write_id(mc, fdt, mem_name, socket);
        g_free(mem_name);

        clint_addr = memmap[VIRT_CLINT].base +
            (memmap[VIRT_CLINT].size * socket);
        clint_name = g_strdup_printf("/soc/clint@%lx", clint_addr);
        qemu_fdt_add_subnode(fdt, clint_name);
        qemu_fdt_setprop_string(fdt, clint_name, "compatible", "riscv,clint0");
        qemu_fdt_setprop_cells(fdt, clint_name, "reg",
            0x0, clint_addr, 0x0, memmap[VIRT_CLINT].size);
        qemu_fdt_setprop(fdt, clint_name, "interrupts-extended",
            clint_cells, s->soc[socket].num_harts * sizeof(uint32_t) * 4);
        riscv_socket_fdt_write_id(mc, fdt, clint_name, socket);
        g_free(clint_name);

        plic_phandle[socket] = phandle++;
        plic_addr = memmap[VIRT_PLIC].base + (memmap[VIRT_PLIC].size * socket);
        plic_name = g_strdup_printf("/soc/plic@%lx", plic_addr);
        qemu_fdt_add_subnode(fdt, plic_name);
        qemu_fdt_setprop_cell(fdt, plic_name,
            "#address-cells", FDT_PLIC_ADDR_CELLS);
        qemu_fdt_setprop_cell(fdt, plic_name,
            "#interrupt-cells", FDT_PLIC_INT_CELLS);
        qemu_fdt_setprop_string(fdt, plic_name, "compatible", "riscv,plic0");
        qemu_fdt_setprop(fdt, plic_name, "interrupt-controller", NULL, 0);
        qemu_fdt_setprop(fdt, plic_name, "interrupts-extended",
            plic_cells, s->soc[socket].num_harts * sizeof(uint32_t) * 4);
        qemu_fdt_setprop_cells(fdt, plic_name, "reg",
            0x0, plic_addr, 0x0, memmap[VIRT_PLIC].size);
        qemu_fdt_setprop_cell(fdt, plic_name, "riscv,ndev", VIRTIO_NDEV);
        riscv_socket_fdt_write_id(mc, fdt, plic_name, socket);
        qemu_fdt_setprop_cell(fdt, plic_name, "phandle", plic_phandle[socket]);
        g_free(plic_name);

        g_free(clint_cells);
        g_free(plic_cells);
        g_free(clust_name);
    }

    for (socket = 0; socket < riscv_socket_count(mc); socket++) {
        if (socket == 0) {
            plic_mmio_phandle = plic_phandle[socket];
        }
    }

    riscv_socket_fdt_write_distance_matrix(mc, fdt);

    name = g_strdup_printf("/soc/uart@%lx", (long)memmap[VIRT_UART0].base);
    qemu_fdt_add_subnode(fdt, name);
    qemu_fdt_setprop_string(fdt, name, "compatible", "ns16550a");
    qemu_fdt_setprop_cells(fdt, name, "reg",
        0x0, memmap[VIRT_UART0].base,
        0x0, memmap[VIRT_UART0].size);
    qemu_fdt_setprop_cell(fdt, name, "clock-frequency", 3686400);
    qemu_fdt_setprop_cell(fdt, name, "interrupt-parent", plic_mmio_phandle);
    qemu_fdt_setprop_cell(fdt, name, "interrupts", UART0_IRQ);

    qemu_fdt_add_subnode(fdt, "/chosen");
    qemu_fdt_setprop_string(fdt, "/chosen", "stdout-path", name);
    g_free(name);

update_bootargs:
    if (cmdline) {
        qemu_fdt_setprop_string(fdt, "/chosen", "bootargs", cmdline);
    }
}

static void virt_machine_init(MachineState *machine)
{
    const MemMapEntry *memmap = virt_memmap;
    RISCVVirtState *s = RISCV_VIRT_MACHINE(machine);
    MemoryRegion *system_memory = get_system_memory();
    MemoryRegion *main_mem = g_new(MemoryRegion, 1);
    MemoryRegion *mask_rom = g_new(MemoryRegion, 1);
    char *plic_hart_config, *soc_name;
    size_t plic_hart_config_len;
    target_ulong start_addr = memmap[VIRT_DRAM].base;
    target_ulong firmware_end_addr, kernel_start_addr;
    uint32_t fdt_load_addr;
    uint64_t kernel_entry;
    DeviceState *mmio_plic;
    int i, j, base_hartid, hart_count;

    /* Check socket count limit */
    if (VIRT_SOCKETS_MAX < riscv_socket_count(machine)) {
        error_report("number of sockets/nodes should be less than %d",
            VIRT_SOCKETS_MAX);
        exit(1);
    }

    /* Initialize sockets */
    mmio_plic = NULL;
    for (i = 0; i < riscv_socket_count(machine); i++) {
        if (!riscv_socket_check_hartids(machine, i)) {
            error_report("discontinuous hartids in socket%d", i);
            exit(1);
        }

        base_hartid = riscv_socket_first_hartid(machine, i);
        if (base_hartid < 0) {
            error_report("can't find hartid base for socket%d", i);
            exit(1);
        }

        hart_count = riscv_socket_hart_count(machine, i);
        if (hart_count < 0) {
            error_report("can't find hart count for socket%d", i);
            exit(1);
        }

        soc_name = g_strdup_printf("soc%d", i);
        object_initialize_child(OBJECT(machine), soc_name, &s->soc[i],
                                TYPE_RISCV_HART_ARRAY);
        g_free(soc_name);
        object_property_set_str(OBJECT(&s->soc[i]), "cpu-type",
                                machine->cpu_type, &error_abort);
        object_property_set_int(OBJECT(&s->soc[i]), "hartid-base",
                                base_hartid, &error_abort);
        object_property_set_int(OBJECT(&s->soc[i]), "num-harts",
                                hart_count, &error_abort);
        sysbus_realize(SYS_BUS_DEVICE(&s->soc[i]), &error_abort);

        /* Per-socket CLINT */
        sifive_clint_create(
            memmap[VIRT_CLINT].base + i * memmap[VIRT_CLINT].size,
            memmap[VIRT_CLINT].size, base_hartid, hart_count,
            SIFIVE_SIP_BASE, SIFIVE_TIMECMP_BASE, SIFIVE_TIME_BASE,
            SIFIVE_CLINT_TIMEBASE_FREQ, true);

        /* Per-socket PLIC hart topology configuration string */
        plic_hart_config_len =
            (strlen(VIRT_PLIC_HART_CONFIG) + 1) * hart_count;
        plic_hart_config = g_malloc0(plic_hart_config_len);
        for (j = 0; j < hart_count; j++) {
            if (j != 0) {
                strncat(plic_hart_config, ",", plic_hart_config_len);
            }
            strncat(plic_hart_config, VIRT_PLIC_HART_CONFIG,
                plic_hart_config_len);
            plic_hart_config_len -= (strlen(VIRT_PLIC_HART_CONFIG) + 1);
        }

        /* Per-socket PLIC */
        s->plic[i] = sifive_plic_create(
            memmap[VIRT_PLIC].base + i * memmap[VIRT_PLIC].size,
            plic_hart_config, base_hartid,
            VIRT_PLIC_NUM_SOURCES,
            VIRT_PLIC_NUM_PRIORITIES,
            VIRT_PLIC_PRIORITY_BASE,
            VIRT_PLIC_PENDING_BASE,
            VIRT_PLIC_ENABLE_BASE,
            VIRT_PLIC_ENABLE_STRIDE,
            VIRT_PLIC_CONTEXT_BASE,
            VIRT_PLIC_CONTEXT_STRIDE,
            memmap[VIRT_PLIC].size);
        g_free(plic_hart_config);

        /* Try to use different PLIC instance based device type */
        if (i == 0) {
            mmio_plic = s->plic[i];
        }
    }

    if (riscv_is_32bit(&s->soc[0])) {
#if HOST_LONG_BITS == 64
        /* limit RAM size in a 32-bit system */
        if (machine->ram_size > 10 * GiB) {
            machine->ram_size = 10 * GiB;
            error_report("Limiting RAM size to 10 GiB");
        }
#endif
    }

    /* register system main memory (actual RAM) */
    memory_region_init_ram(main_mem, NULL, "riscv_virt_board.ram",
                           machine->ram_size, &error_fatal);
    memory_region_add_subregion(system_memory, memmap[VIRT_DRAM].base,
        main_mem);

    /* create device tree */
    create_fdt(s, memmap, machine->ram_size, machine->kernel_cmdline,
               riscv_is_32bit(&s->soc[0]));

    /* boot rom */
    memory_region_init_rom(mask_rom, NULL, "riscv_virt_board.mrom",
                           memmap[VIRT_MROM].size, &error_fatal);
    memory_region_add_subregion(system_memory, memmap[VIRT_MROM].base,
                                mask_rom);

    if (riscv_is_32bit(&s->soc[0])) {
        firmware_end_addr = riscv_find_and_load_firmware(machine,
                                    "opensbi-riscv32-generic-fw_dynamic.bin",
                                    start_addr, NULL);
    } else {
        firmware_end_addr = riscv_find_and_load_firmware(machine,
                                    "opensbi-riscv64-generic-fw_dynamic.bin",
                                    start_addr, NULL);
    }

    if (machine->kernel_filename) {
        kernel_start_addr = riscv_calc_kernel_start_addr(&s->soc[0],
                                                         firmware_end_addr);

        kernel_entry = riscv_load_kernel(machine->kernel_filename,
                                         kernel_start_addr, NULL);

        if (machine->initrd_filename) {
            hwaddr start;
            hwaddr end = riscv_load_initrd(machine->initrd_filename,
                                           machine->ram_size, kernel_entry,
                                           &start);
            qemu_fdt_setprop_cell(machine->fdt, "/chosen",
                                  "linux,initrd-start", start);
            qemu_fdt_setprop_cell(machine->fdt, "/chosen", "linux,initrd-end",
                                  end);
        }
    } else {
       /*
        * If dynamic firmware is used, it doesn't know where is the next mode
        * if kernel argument is not set.
        */
        kernel_entry = 0;
    }

    /* Compute the fdt load address in dram */
    fdt_load_addr = riscv_load_fdt(memmap[VIRT_DRAM].base,
                                   machine->ram_size, machine->fdt);
    /* load the reset vector */
    riscv_setup_rom_reset_vec(machine, &s->soc[0], start_addr,
                              virt_memmap[VIRT_MROM].base,
                              virt_memmap[VIRT_MROM].size, kernel_entry,
                              fdt_load_addr, machine->fdt);

   serial_mm_init(system_memory, memmap[VIRT_UART0].base,
        0, qdev_get_gpio_in(DEVICE(mmio_plic), UART0_IRQ), 399193,
        serial_hd(0), DEVICE_LITTLE_ENDIAN);

}

static void virt_machine_instance_init(Object *obj)
{
}

static void virt_machine_class_init(ObjectClass *oc, void *data)
{
    MachineClass *mc = MACHINE_CLASS(oc);

    mc->desc = "RISC-V VirtIO board";
    mc->init = virt_machine_init;
    mc->max_cpus = VIRT_CPUS_MAX;
    mc->default_cpu_type = TYPE_RISCV_CPU_BASE;
    mc->pci_allow_0_address = true;
    mc->possible_cpu_arch_ids = riscv_numa_possible_cpu_arch_ids;
    mc->cpu_index_to_instance_props = riscv_numa_cpu_index_to_props;
    mc->get_default_cpu_node_id = riscv_numa_get_default_cpu_node_id;
    mc->numa_mem_supported = true;

    machine_class_allow_dynamic_sysbus_dev(mc, TYPE_RAMFB_DEVICE);
}

static const TypeInfo virt_machine_typeinfo = {
    .name       = MACHINE_TYPE_NAME("virt"),
    .parent     = TYPE_MACHINE,
    .class_init = virt_machine_class_init,
    .instance_init = virt_machine_instance_init,
    .instance_size = sizeof(RISCVVirtState),
};

static void virt_machine_init_register_types(void)
{
    type_register_static(&virt_machine_typeinfo);
}

type_init(virt_machine_init_register_types)

