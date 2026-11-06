const exti = @import("../drivers/exti.zig");
const systick = @import("../drivers/systick.zig");

const EXTI5_TO_9_MASK: u32 = 0x03E0;
const EXTI10_TO_15_MASK: u32 = 0xFC00;

pub export fn NMI_Handler() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}

pub export fn HardFault_Handler() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}

pub export fn MemManage_Handler() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}

pub export fn BusFault_Handler() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}

pub export fn UsageFault_Handler() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}

pub export fn SVC_Handler() void {
    // TODO: Implement system call dispatch.
}

pub export fn PendSV_Handler() void {
    // TODO: Implement deferred processing.
}

pub export fn DebugMon_Handler() void {
    // TODO: Implement debug monitor handling.
}

pub export fn EXTI0_IRQHandler() callconv(.c) void {
    exti.handleInterrupt(.line0);
}

pub export fn EXTI1_IRQHandler() callconv(.c) void {
    exti.handleInterrupt(.line1);
}

pub export fn EXTI2_IRQHandler() callconv(.c) void {
    exti.handleInterrupt(.line2);
}

pub export fn EXTI3_IRQHandler() callconv(.c) void {
    exti.handleInterrupt(.line3);
}

pub export fn EXTI4_IRQHandler() callconv(.c) void {
    exti.handleInterrupt(.line4);
}

pub export fn EXTI9_5_IRQHandler() callconv(.c) void {
    exti.dispatchPending(EXTI5_TO_9_MASK);
}

pub export fn EXTI15_10_IRQHandler() callconv(.c) void {
    exti.dispatchPending(EXTI10_TO_15_MASK);
}

pub export fn SysTick_Handler() callconv(.c) void {
    systick.onInterrupt();
}

// pub export fn EXTI9_5_IRQHandler() callconv(.c) void {
//     const pending = exti.getPendingMask();
//     const enabled = exti.getInterruptMask();

//     const active = pending & enabled & 0x03E0;

//     var line: u4 = 5;

//     while (line <= 9) : (line += 1) {
//         const mask = @as(u32, 1) << line;

//         if ((active & mask) != 0) {
//             exti.handleInterrupt(@fromBackingInt(@intCast(line)));
//         }
//     }
// }

// pub export fn EXTI15_10_IRQHandler() callconv(.c) void {
//     const pending = exti.getPendingMask();
//     const enabled = exti.getInterruptMask();

//     const active = pending & enabled & 0xFC00;

//     var line: u4 = 10;

//     while (line <= 15) : (line += 1) {
//         const mask = @as(u32, 1) << line;

//         if ((active & mask) != 0) {
//             exti.handleInterrupt(@fromBackingInt(@intCast(line)));
//         }
//     }
// }
