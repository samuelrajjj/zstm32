const critical = @import("../arch/arm/cortex_m3/critical_section.zig");

const EXTI_BASE: usize = 0x4001_0400;

const IMR: usize = EXTI_BASE + 0x00;
const EMR: usize = EXTI_BASE + 0x04;
const RTSR: usize = EXTI_BASE + 0x08;
const FTSR: usize = EXTI_BASE + 0x0C;
const SWIER: usize = EXTI_BASE + 0x10;
const PR: usize = EXTI_BASE + 0x14;

pub const Line = enum(u4) {
    line0 = 0,
    line1 = 1,
    line2 = 2,
    line3 = 3,
    line4 = 4,
    line5 = 5,
    line6 = 6,
    line7 = 7,
    line8 = 8,
    line9 = 9,
    line10 = 10,
    line11 = 11,
    line12 = 12,
    line13 = 13,
    line14 = 14,
    line15 = 15,
};

pub const Trigger = enum {
    rising,
    falling,
    both,
};

fn readReg(address: usize) u32 {
    const reg: *volatile u32 = @ptrFromInt(address);
    return reg.*;
}

fn writeReg(address: usize, value: u32) void {
    const reg: *volatile u32 = @ptrFromInt(address);
    reg.* = value;
}

fn modifyReg(address: usize, set_mask: u32, clear_mask: u32) void {
    const previous = critical.enter();
    defer critical.exit(previous);

    var value = readReg(address);
    value &= ~clear_mask;
    value |= set_mask;

    writeReg(address, value);
}
// fn modifyReg(address: usize, set_mask: u32, clear_mask: u32) void {
//     var value = readReg(address);
//     value &= ~clear_mask;
//     value |= set_mask;
//     writeReg(address, value);
// }

fn bitMask(line: Line) u32 {
    return @as(u32, 1) << @backingInt(line);
}

/// Enable or disable interrupt delivery for an EXTI line.
pub fn maskInterrupt(line: Line, masked: bool) void {
    const mask = bitMask(line);

    if (masked) {
        modifyReg(IMR, 0, mask);
    } else {
        modifyReg(IMR, mask, 0);
    }
}

/// Enable or disable event delivery for an EXTI line.
pub fn maskEvent(line: Line, masked: bool) void {
    const mask = bitMask(line);

    if (masked) {
        modifyReg(EMR, 0, mask);
    } else {
        modifyReg(EMR, mask, 0);
    }
}

/// Configure edge detection for an EXTI line.
pub fn configureTrigger(line: Line, trigger: Trigger) void {
    const mask = bitMask(line);

    switch (trigger) {
        .rising => {
            modifyReg(RTSR, mask, 0);
            modifyReg(FTSR, 0, mask);
        },
        .falling => {
            modifyReg(RTSR, 0, mask);
            modifyReg(FTSR, mask, 0);
        },
        .both => {
            modifyReg(RTSR, mask, 0);
            modifyReg(FTSR, mask, 0);
        },
    }
}

/// Clear an EXTI pending flag.
/// PR is write-one-to-clear: write the bit directly.
pub fn clearPending(line: Line) void {
    writeReg(PR, bitMask(line));
}

/// Check whether an EXTI line has a pending interrupt.
pub fn isPending(line: Line) bool {
    return (readReg(PR) & bitMask(line)) != 0;
}

/// Generate a software interrupt request.
pub fn generateSoftwareInterrupt(line: Line) void {
    writeReg(SWIER, bitMask(line));
}

pub fn getPendingMask() u32 {
    return readReg(PR) & 0xFFFF;
}

pub fn getInterruptMask() u32 {
    return readReg(IMR) & 0xFFFF;
}

pub const Callback = *const fn () callconv(.c) void;

var callbacks: [16]?Callback = .{
    null, null, null, null,
    null, null, null, null,
    null, null, null, null,
    null, null, null, null,
};

/// Register an application callback for an EXTI line.
/// Register callbacks before enabling the corresponding NVIC IRQ.
pub fn registerCallback(line: Line, callback: Callback) void {
    const previous = critical.enter();
    defer critical.exit(previous);

    callbacks[@backingInt(line)] = callback;
}
// pub fn registerCallback(line: Line, callback: Callback) void {
//     callbacks[@backingInt(line)] = callback;
// }

/// Remove the callback associated with an EXTI line.
pub fn unregisterCallback(line: Line) void {
    const previous = critical.enter();
    defer critical.exit(previous);

    callbacks[@backingInt(line)] = null;
}
// pub fn unregisterCallback(line: Line) void {
//     callbacks[@backingInt(line)] = null;
// }

/// Handle one EXTI line after its interrupt has been received.
pub fn handleInterrupt(line: Line) void {
    if (!isPending(line)) return;

    // Acknowledge the hardware interrupt first.
    clearPending(line);

    // Obtain a consistent callback pointer.
    const previous = critical.enter();

    const callback = callbacks[@backingInt(line)];

    critical.exit(previous);

    // Execute application code outside the critical section.
    if (callback) |cb| {
        cb();
    }
}
// pub fn handleInterrupt(line: Line) void {
//     if (!isPending(line)) return;

//     // Clear the hardware pending flag before calling application code.
//     clearPending(line);

//     if (callbacks[@backingInt(line)]) |callback| {
//         callback();
//     }
// }

/// Dispatch all currently pending and unmasked lines
/// belonging to a shared EXTI interrupt group.
pub fn dispatchPending(group_mask: u32) void {
    const active = getPendingMask() &
        getInterruptMask() &
        group_mask;

    var remaining = active;

    while (remaining != 0) {
        // Find the least significant set bit.
        const bit_index: u5 = @intCast(@ctz(remaining));

        // Remove that bit from our local snapshot.
        remaining &= remaining - 1;

        const line: Line = @fromBackingInt(@intCast(
            @as(u4, @intCast(bit_index)),
        ));

        handleInterrupt(line);
    }
}
