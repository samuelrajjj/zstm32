const base: usize = 0xE000_E000;
const AIRCR: usize = 0xE000_ED0C;

const ISER: usize = base + 0x100;
const ICER: usize = base + 0x180;
const ISPR: usize = base + 0x200;
const ICPR: usize = base + 0x280;
const IABR: usize = base + 0x300;
const IPR: usize = base + 0x400;

pub const IRQn = enum(u8) {
    WWDG = 0,
    PVD = 1,
    TAMPER = 2,
    RTC = 3,
    FLASH = 4,
    RCC = 5,

    EXTI0 = 6,
    EXTI1 = 7,
    EXTI2 = 8,
    EXTI3 = 9,
    EXTI4 = 10,

    DMA1_Channel1 = 11,
    DMA1_Channel2 = 12,
    DMA1_Channel3 = 13,
    DMA1_Channel4 = 14,
    DMA1_Channel5 = 15,
    DMA1_Channel6 = 16,
    DMA1_Channel7 = 17,

    ADC1_2 = 18,

    USB_HP_CAN_TX = 19,
    USB_LP_CAN_RX0 = 20,
    CAN_RX1 = 21,
    CAN_SCE = 22,

    EXTI9_5 = 23,

    TIM1_BRK = 24,
    TIM1_UP = 25,
    TIM1_TRG_COM = 26,
    TIM1_CC = 27,

    TIM2 = 28,
    TIM3 = 29,
    TIM4 = 30,

    I2C1_EV = 31,
    I2C1_ER = 32,
    I2C2_EV = 33,
    I2C2_ER = 34,

    SPI1 = 35,
    SPI2 = 36,

    USART1 = 37,
    USART2 = 38,
    USART3 = 39,

    EXTI15_10 = 40,

    RTCAlarm = 41,

    USBWakeup = 42,

    // TIM8_BRK = 43,
    // TIM8_UP = 44,
    // TIM8_TRG_COM = 45,
    // TIM8_CC = 46,

    // ADC3 = 47,

    // FSMC = 48,

    // SDIO = 49,

    // TIM5 = 50,

    // SPI3 = 51,

    // UART4 = 52,
    // UART5 = 53,

    // TIM6 = 54,
    // TIM7 = 55,

    // DMA2_Channel1 = 56,
    // DMA2_Channel2 = 57,
    // DMA2_Channel3 = 58,
    // DMA2_Channel4_5 = 59,
};

pub const Priority = enum(u4) {
    p0 = 0,
    p1 = 1,
    p2 = 2,
    p3 = 3,
    p4 = 4,
    p5 = 5,
    p6 = 6,
    p7 = 7,
    p8 = 8,
    p9 = 9,
    p10 = 10,
    p11 = 11,
    p12 = 12,
    p13 = 13,
    p14 = 14,
    p15 = 15,
};

pub const PriorityGroup = enum(u3) {
    group0 = 0,
    group1 = 1,
    group2 = 2,
    group3 = 3,
    group4 = 4,
    group5 = 5,
    group6 = 6,
    group7 = 7,
};

fn writeReg(address: usize, value: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(address);
    ptr.* = value;
}

fn readReg(address: usize) u32 {
    const ptr: *volatile u32 = @ptrFromInt(address);
    return ptr.*;
}

pub fn enableIRQ(irq: IRQn) void {
    const n: u32 = @backingInt(irq);

    const address = ISER + @as(usize, @intCast(n / 32)) * 4;
    const bit: u32 = @as(u32, 1) << @intCast(n % 32);

    writeReg(address, bit);
}

pub fn disableIRQ(irq: IRQn) void {
    const n: u32 = @backingInt(irq);

    const address = ICER + @as(usize, @intCast(n / 32)) * 4;
    const bit: u32 = @as(u32, 1) << @intCast(n % 32);

    writeReg(address, bit);
}

pub fn setPending(irq: IRQn) void {
    const n: u32 = @backingInt(irq);

    const address = ISPR + @as(usize, @intCast(n / 32)) * 4;
    const bit: u32 = @as(u32, 1) << @intCast(n % 32);

    writeReg(address, bit);
}

pub fn clearPending(irq: IRQn) void {
    const n: u32 = @backingInt(irq);

    const address = ICPR + @as(usize, @intCast(n / 32)) * 4;
    const bit: u32 = @as(u32, 1) << @intCast(n % 32);

    writeReg(address, bit);
}

pub fn isActive(irq: IRQn) bool {
    const n: u32 = @backingInt(irq);

    const address = IABR + @as(usize, @intCast(n / 32)) * 4;
    const bit: u32 = @as(u32, 1) << @intCast(n % 32);

    return (readReg(address) & bit) != 0;
}

pub fn setPriority(irq: IRQn, priority: Priority) void {
    const n: usize = @backingInt(irq);
    const address = IPR + n;

    const ptr: *volatile u8 = @ptrFromInt(address);

    ptr.* = @as(u8, @backingInt(priority)) << 4;
}

pub fn getPriority(irq: IRQn) Priority {
    const n: usize = @backingInt(irq);
    const address = IPR + n;

    const ptr: *volatile u8 = @ptrFromInt(address);

    return @fromBackingInt(@intCast(ptr.* >> 4));
}

pub fn setPriorityGrouping(group: PriorityGroup) void {
    const current = readReg(AIRCR);

    const VECTKEY: u32 = 0x5FA << 16;

    const value =
        (current & (1 << 15)) |
        (@as(u32, @backingInt(group)) << 8) |
        VECTKEY;

    writeReg(AIRCR, value);
}

pub fn getPriorityGrouping() PriorityGroup {
    const value = readReg(AIRCR);
    const group: u3 = @truncate((value >> 8) & 0x7);

    return @fromBackingInt(@intCast(group));
}
