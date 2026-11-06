const AFIO_BASE: usize = 0x4001_0000;

const AFIO_EXTICR1: usize = AFIO_BASE + 0x08;
const AFIO_EXTICR2: usize = AFIO_BASE + 0x0C;
const AFIO_EXTICR3: usize = AFIO_BASE + 0x10;
const AFIO_EXTICR4: usize = AFIO_BASE + 0x14;

pub const GPIOPort = enum(u4) {
    A = 0,
    B = 1,
    C = 2,
    D = 3,
    E = 4,
};

fn readReg(address: usize) u32 {
    const reg: *volatile u32 = @ptrFromInt(address);
    return reg.*;
}

fn writeReg(address: usize, value: u32) void {
    const reg: *volatile u32 = @ptrFromInt(address);
    reg.* = value;
}

/// Connects a GPIO port pin to its corresponding EXTI line.
/// Example: configureEXTISource(.A, 0) connects PA0 to EXTI0.
pub fn configureEXTISource(port: GPIOPort, pin: u4) void {
    const register_index = pin / 4;
    const field_shift: u5 = @intCast((pin % 4) * 4);

    const register_address = switch (register_index) {
        0 => AFIO_EXTICR1,
        1 => AFIO_EXTICR2,
        2 => AFIO_EXTICR3,
        3 => AFIO_EXTICR4,
        else => unreachable,
    };

    const port_value: u32 = @backingInt(port);

    const mask: u32 = @as(u32, 0xF) << field_shift;

    var value = readReg(register_address);
    value &= ~mask;
    value |= port_value << field_shift;

    writeReg(register_address, value);
}
