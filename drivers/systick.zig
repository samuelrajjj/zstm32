const SYST_CSR: usize = 0xE000_E010;
const SYST_RVR: usize = 0xE000_E014;
const SYST_CVR: usize = 0xE000_E018;

var tick_count: u32 = 0;

fn readReg(address: usize) u32 {
    const ptr: *volatile u32 = @ptrFromInt(address);
    return ptr.*;
}

fn writeReg(address: usize, value: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(address);
    ptr.* = value;
}

fn tickCounter() *volatile u32 {
    return @ptrCast(&tick_count);
}

pub const SysTickError = error{
    InvalidClock,
};

/// Configure SysTick to generate an interrupt every millisecond.
pub fn init(core_clock_hz: u32) SysTickError!void {
    const cycles_per_ms = core_clock_hz / 1000;

    if (cycles_per_ms == 0 or cycles_per_ms > 0x0100_0000) {
        return error.InvalidClock;
    }

    // Disable SysTick during configuration.
    writeReg(SYST_CSR, 0);

    // 24-bit reload register.
    writeReg(SYST_RVR, cycles_per_ms - 1);

    // Clear current counter value.
    writeReg(SYST_CVR, 0);

    // Give SysTick a low interrupt priority.
    const priority: *volatile u8 = @ptrFromInt(0xE000_ED23);
    priority.* = 0xF0;

    // ENABLE | TICKINT | CLKSOURCE
    writeReg(SYST_CSR, 0b111);
}

/// Called by the SysTick interrupt handler.
pub fn onInterrupt() void {
    tickCounter().* +%= 1;
}

/// Return elapsed milliseconds since SysTick initialization.
pub fn millis() u32 {
    return tickCounter().*;
}
