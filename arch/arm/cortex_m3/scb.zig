pub const SCB_BASE: usize = 0xE000_ED00;

pub const CPUID: usize = SCB_BASE + 0x00;
pub const ICSR: usize = SCB_BASE + 0x04;
pub const VTOR: usize = SCB_BASE + 0x08;
pub const AIRCR: usize = SCB_BASE + 0x0C;
pub const SCR: usize = SCB_BASE + 0x10;
pub const CCR: usize = SCB_BASE + 0x14;

pub const SHPR1: usize = SCB_BASE + 0x18;
pub const SHPR2: usize = SCB_BASE + 0x1C;
pub const SHPR3: usize = SCB_BASE + 0x20;

pub const SHCSR: usize = SCB_BASE + 0x24;
pub const CFSR: usize = SCB_BASE + 0x28;
pub const HFSR: usize = SCB_BASE + 0x2C;
pub const MMFAR: usize = SCB_BASE + 0x34;
pub const BFAR: usize = SCB_BASE + 0x38;

pub const FaultStatus = struct {
    cfsr: u32,
    hfsr: u32,
    mmfar: u32,
    bfar: u32,
};

pub const CFSRBits = struct {
    pub const IACCVIOL: u5 = 0;
    pub const DACCVIOL: u5 = 1;
    pub const MUNSTKERR: u5 = 3;
    pub const MSTKERR: u5 = 4;
    pub const MMARVALID: u5 = 7;

    pub const IBUSERR: u5 = 8;
    pub const PRECISERR: u5 = 9;
    pub const IMPRECISERR: u5 = 10;
    pub const UNSTKERR: u5 = 11;
    pub const STKERR: u5 = 12;
    pub const BFARVALID: u5 = 15;

    pub const UNDEFINSTR: u5 = 16;
    pub const INVSTATE: u5 = 17;
    pub const INVPC: u5 = 18;
    pub const NOCP: u5 = 19;
    pub const UNALIGNED: u5 = 24;
    pub const DIVBYZERO: u5 = 25;
};

pub const ExceptionStackFrame = extern struct {
    r0: u32,
    r1: u32,
    r2: u32,
    r3: u32,
    r12: u32,
    lr: u32,
    pc: u32,
    xpsr: u32,
};

fn writeReg(address: usize, value: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(address);
    ptr.* = value;
}

fn readReg(address: usize) u32 {
    const ptr: *volatile u32 = @ptrFromInt(address);
    return ptr.*;
}

pub fn enableFaults() void {
    const ptr: *volatile u32 = @ptrFromInt(SHCSR);

    ptr.* |= (1 << 16) | (1 << 17) | (1 << 18);
}

pub fn disableFaults() void {
    const ptr: *volatile u32 = @ptrFromInt(SHCSR);

    ptr.* &= ~((1 << 16) | (1 << 17) | (1 << 18));
}

pub fn enableMemManage() void {
    const ptr: *volatile u32 = @ptrFromInt(SHCSR);
    ptr.* |= 1 << 16;
}

pub fn enableBusFault() void {
    const ptr: *volatile u32 = @ptrFromInt(SHCSR);
    ptr.* |= 1 << 17;
}

pub fn enableUsageFault() void {
    const ptr: *volatile u32 = @ptrFromInt(SHCSR);
    ptr.* |= 1 << 18;
}

pub fn getFaultStatus() FaultStatus {
    return .{
        .cfsr = readReg(CFSR),
        .hfsr = readReg(HFSR),
        .mmfar = readReg(MMFAR),
        .bfar = readReg(BFAR),
    };
}

pub fn isMMFARValid(cfsr: u32) bool {
    return (cfsr & (1 << 7)) != 0;
}

pub fn isBFARValid(cfsr: u32) bool {
    return (cfsr & (1 << 15)) != 0;
}

pub fn clearFaultStatus() void {
    const cfsr = readReg(CFSR);
    const hfsr = readReg(HFSR);

    writeReg(CFSR, cfsr);
    writeReg(HFSR, hfsr);
}

pub fn isMemManageEnabled() bool {
    return (readReg(SHCSR) & (1 << 16)) != 0;
}

pub fn isBusFaultEnabled() bool {
    return (readReg(SHCSR) & (1 << 17)) != 0;
}

pub fn isUsageFaultEnabled() bool {
    return (readReg(SHCSR) & (1 << 18)) != 0;
}

pub fn hasFault(status: u32, bit: u5) bool {
    return (status & (@as(u32, 1) << bit)) != 0;
}
