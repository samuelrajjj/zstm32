const handlers = @import("../interrupts/handlers.zig");
const startup = @import("startup.zig");

// Linker-defined initial stack address.
// The address of this symbol is 0x20005000.
extern var _estack: u8;

// Default handler for unimplemented exceptions and IRQs.
pub export fn Default_Handler() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}
// Each vector entry occupies exactly 4 bytes on Cortex-M3.
pub const VectorEntry = ?*const anyopaque;

// Vector table layout:
//
// Entry 0: Initial MSP
// Entries 1-58: Exception and external IRQ handlers
//
pub const VectorTable = extern struct {
    initial_stack: *anyopaque,
    vectors: [58]VectorEntry,
};

// The complete STM32F103C8T6 vector table.
//
// 16 core exception slots + 43 external IRQ slots = 59 entries.
// First entry is stored separately from the handler entries.
pub export const vector_table: VectorTable align(256) linksection(".isr_vector") = .{

    // Initial Main Stack Pointer.
    .initial_stack = @ptrCast(&_estack),

    .vectors = .{

        // --------------------------------
        // Core exceptions: vector 1-15
        // --------------------------------

        @ptrCast(&startup.Reset_Handler), // 1: Reset
        @ptrCast(&handlers.NMI_Handler), // 2: NMI
        @ptrCast(&handlers.HardFault_Handler), // 3: HardFault
        @ptrCast(&handlers.MemManage_Handler), // 4: MemManage
        @ptrCast(&handlers.BusFault_Handler), // 5: BusFault
        @ptrCast(&handlers.UsageFault_Handler), // 6: UsageFault

        null, // 7: Reserved
        null, // 8: Reserved
        null, // 9: Reserved
        null, // 10: Reserved

        @ptrCast(&handlers.SVC_Handler), // 11: SVCall
        @ptrCast(&handlers.DebugMon_Handler), // 12: DebugMonitor
        null, // 13: Reserved
        @ptrCast(&handlers.PendSV_Handler), // 14: PendSV
        @ptrCast(&handlers.SysTick_Handler), // 15: SysTick

        // --------------------------------
        // External interrupts: IRQ 0-42
        // --------------------------------

        @ptrCast(&Default_Handler), // 0: WWDG
        @ptrCast(&Default_Handler), // 1: PVD
        @ptrCast(&Default_Handler), // 2: TAMPER
        @ptrCast(&Default_Handler), // 3: RTC
        @ptrCast(&Default_Handler), // 4: FLASH
        @ptrCast(&Default_Handler), // 5: RCC

        @ptrCast(&handlers.EXTI0_IRQHandler), // 6: EXTI0
        @ptrCast(&handlers.EXTI1_IRQHandler), // 7: EXTI1
        @ptrCast(&handlers.EXTI2_IRQHandler), // 8: EXTI2
        @ptrCast(&handlers.EXTI3_IRQHandler), // 9: EXTI3
        @ptrCast(&handlers.EXTI4_IRQHandler), // 10: EXTI4

        @ptrCast(&Default_Handler), // 11: DMA1_Channel1
        @ptrCast(&Default_Handler), // 12: DMA1_Channel2
        @ptrCast(&Default_Handler), // 13: DMA1_Channel3
        @ptrCast(&Default_Handler), // 14: DMA1_Channel4
        @ptrCast(&Default_Handler), // 15: DMA1_Channel5
        @ptrCast(&Default_Handler), // 16: DMA1_Channel6
        @ptrCast(&Default_Handler), // 17: DMA1_Channel7

        @ptrCast(&Default_Handler), // 18: ADC1_2

        @ptrCast(&Default_Handler), // 19: USB_HP_CAN1_TX
        @ptrCast(&Default_Handler), // 20: USB_LP_CAN1_RX0
        @ptrCast(&Default_Handler), // 21: CAN1_RX1
        @ptrCast(&Default_Handler), // 22: CAN1_SCE

        @ptrCast(&handlers.EXTI9_5_IRQHandler), // 23: EXTI9_5

        @ptrCast(&Default_Handler), // 24: TIM1_BRK
        @ptrCast(&Default_Handler), // 25: TIM1_UP
        @ptrCast(&Default_Handler), // 26: TIM1_TRG_COM
        @ptrCast(&Default_Handler), // 27: TIM1_CC

        @ptrCast(&Default_Handler), // 28: TIM2
        @ptrCast(&Default_Handler), // 29: TIM3
        @ptrCast(&Default_Handler), // 30: TIM4

        @ptrCast(&Default_Handler), // 31: I2C1_EV
        @ptrCast(&Default_Handler), // 32: I2C1_ER
        @ptrCast(&Default_Handler), // 33: I2C2_EV
        @ptrCast(&Default_Handler), // 34: I2C2_ER

        @ptrCast(&Default_Handler), // 35: SPI1
        @ptrCast(&Default_Handler), // 36: SPI2

        @ptrCast(&Default_Handler), // 37: USART1
        @ptrCast(&Default_Handler), // 38: USART2
        @ptrCast(&Default_Handler), // 39: USART3

        @ptrCast(&handlers.EXTI15_10_IRQHandler), // 40: EXTI15_10
        @ptrCast(&Default_Handler), // 41: RTCAlarm
        @ptrCast(&Default_Handler), // 42: USBWakeup
    },
};

// Compile-time layout validation.
comptime {
    if (@sizeOf(VectorEntry) != 4) {
        @compileError("Vector entries must be 32-bit");
    }

    if (@sizeOf(VectorTable) != 236) {
        @compileError("STM32F103 vector table must be 236 bytes");
    }

    if (@alignOf(VectorTable) != 4) {
        @compileError("Unexpected vector table structure alignment");
    }
}
