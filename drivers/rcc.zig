const stm32f103c8 = @import("stm32f103c8.zig");

const RCC_APB2ENR: *volatile u32 = @ptrFromInt(0x40021018);
const FLASH_ACR: *volatile u32 = @ptrFromInt(0x40022000);

const CR_HSION: u32 = 1 << 0;
const CR_HSIRDY: u32 = 1 << 1;
const CR_HSEON: u32 = 1 << 16;
const CR_HSERDY: u32 = 1 << 17;
const CR_PLLON: u32 = 1 << 24;
const CR_PLLRDY: u32 = 1 << 25;

const CFGR_SW_MASK: u32 = 0b11;
const CFGR_SW_HSI: u32 = 0b00;
const CFGR_SW_PLL: u32 = 0b10;
const CFGR_SWS_MASK: u32 = 0b11 << 2;
const CFGR_SWS_PLL: u32 = 0b10 << 2;

const CFGR_HPRE_MASK: u32 = 0b1111 << 4;
const CFGR_PPRE1_MASK: u32 = 0b111 << 8;
const CFGR_PPRE2_MASK: u32 = 0b111 << 11;
const CFGR_PLLSRC: u32 = 1 << 16;
const CFGR_PLLXTPRE: u32 = 1 << 17;
const CFGR_PLLMUL_MASK: u32 = 0b1111 << 18;

const FLASH_LATENCY_MASK: u32 = 0b111;
const FLASH_LATENCY_2: u32 = 0b010;
const FLASH_PREFETCH_ENABLE: u32 = 1 << 4;

const WAIT_LIMIT: u32 = 1_000_000;

pub const PllMultiplier = enum(u4) {
    x2 = 0b0000,
    x3 = 0b0001,
    x4 = 0b0010,
    x5 = 0b0011,
    x6 = 0b0100,
    x7 = 0b0101,
    x8 = 0b0110,
    x9 = 0b0111,
    x10 = 0b1000,
    x11 = 0b1001,
    x12 = 0b1010,
    x13 = 0b1011,
    x14 = 0b1100,
    x15 = 0b1101,
    x16 = 0b1110,
};

pub const AhbPrescaler = enum(u4) {
    div1 = 0b0000,
    div2 = 0b1000,
    div4 = 0b1001,
    div8 = 0b1010,
    div16 = 0b1011,
    div64 = 0b1100,
    div128 = 0b1101,
    div256 = 0b1110,
    div512 = 0b1111,
};

pub const ApbPrescaler = enum(u3) {
    div1 = 0b000,
    div2 = 0b100,
    div4 = 0b101,
    div8 = 0b110,
    div16 = 0b111,
};

pub const ClockConfig = struct {
    hse_hz: u32 = 8_000_000,
    pll_multiplier: PllMultiplier = .x9,
    ahb_prescaler: AhbPrescaler = .div1,
    apb1_prescaler: ApbPrescaler = .div2,
    apb2_prescaler: ApbPrescaler = .div1,
};

pub const ClockError = error{
    HsiNotReady,
    HseNotReady,
    PllNotReady,
    ClockSwitchFailed,
    InvalidClockConfiguration,
};

pub const Rcc = struct {
    regs: *volatile stm32f103c8.RCC_RB,

    pub fn initHandle() Rcc {
        return .{
            .regs = stm32f103c8.RCC,
        };
    }

    fn waitForSet(self: *const Rcc, mask: u32) bool {
        var count: u32 = 0;
        while (count < WAIT_LIMIT) : (count += 1) {
            if ((self.regs.*.CR & mask) == mask) return true;
        }
        return false;
    }

    fn waitForClear(self: *const Rcc, mask: u32) bool {
        var count: u32 = 0;
        while (count < WAIT_LIMIT) : (count += 1) {
            if ((self.regs.*.CR & mask) == 0) return true;
        }
        return false;
    }

    fn selectHsi(self: *const Rcc) ClockError!void {
        self.regs.*.CR |= CR_HSION;

        if (!self.waitForSet(CR_HSIRDY)) {
            return error.HsiNotReady;
        }

        // Select HSI as SYSCLK before changing PLL configuration.
        self.regs.*.CFGR =
            (self.regs.*.CFGR & ~CFGR_SW_MASK) | CFGR_SW_HSI;

        var count: u32 = 0;
        while (count < WAIT_LIMIT) : (count += 1) {
            if ((self.regs.*.CFGR & CFGR_SWS_MASK) == 0) return;
        }

        return error.ClockSwitchFailed;
    }

    pub fn configure(self: *const Rcc, config: ClockConfig) ClockError!void {
        // This implementation uses HSE directly as the PLL source.
        // The multiplier is limited to x2..x9 for this first version.
        const multiplier: u32 = @backingInt(config.pll_multiplier);
        if (config.hse_hz == 0 or multiplier > 0b0111) {
            return error.InvalidClockConfiguration;
        }

        const sysclk_hz: u64 =
            @as(u64, config.hse_hz) * (@as(u64, multiplier) + 2);

        if (sysclk_hz > 72_000_000 or
            sysclk_hz > 36_000_000 and config.apb1_prescaler == .div1)
        {
            return error.InvalidClockConfiguration;
        }

        // Ensure the internal oscillator is running and switch to it.
        try self.selectHsi();

        // The PLL must be disabled before changing its configuration.
        self.regs.*.CR &= ~CR_PLLON;
        if (!self.waitForClear(CR_PLLRDY)) {
            return error.PllNotReady;
        }

        // Enable HSE and wait for its ready flag.
        self.regs.*.CR |= CR_HSEON;
        if (!self.waitForSet(CR_HSERDY)) {
            return error.HseNotReady;
        }

        // Two Flash wait states are required above 48 MHz.
        // Prefetch is enabled for reliable execution at 72 MHz.
        FLASH_ACR.* = (FLASH_ACR.* & ~FLASH_LATENCY_MASK) |
            FLASH_LATENCY_2 | FLASH_PREFETCH_ENABLE;

        // Configure AHB/APB prescalers and HSE -> PLL multiplier.
        var cfgr = self.regs.*.CFGR;

        cfgr &= ~(CFGR_HPRE_MASK | CFGR_PPRE1_MASK |
            CFGR_PPRE2_MASK | CFGR_PLLSRC |
            CFGR_PLLXTPRE | CFGR_PLLMUL_MASK);

        cfgr |=
            (@as(u32, @backingInt(config.ahb_prescaler)) << 4) |
            (@as(u32, @backingInt(config.apb1_prescaler)) << 8) |
            (@as(u32, @backingInt(config.apb2_prescaler)) << 11) |
            CFGR_PLLSRC |
            (@as(u32, @backingInt(config.pll_multiplier)) << 18);

        self.regs.*.CFGR = cfgr;

        // Start PLL and wait for lock.
        self.regs.*.CR |= CR_PLLON;
        if (!self.waitForSet(CR_PLLRDY)) {
            return error.PllNotReady;
        }

        // Switch SYSCLK to PLL.
        self.regs.*.CFGR =
            (self.regs.*.CFGR & ~CFGR_SW_MASK) | CFGR_SW_PLL;

        var count: u32 = 0;
        while (count < WAIT_LIMIT) : (count += 1) {
            if ((self.regs.*.CFGR & CFGR_SWS_MASK) == CFGR_SWS_PLL) {
                return;
            }
        }

        return error.ClockSwitchFailed;
    }

    pub fn enableApb2(self: *const Rcc, mask: u32) void {
        self.regs.*.APB2ENR |= mask;
    }

    pub fn enableApb1(self: *const Rcc, mask: u32) void {
        self.regs.*.APB1ENR |= mask;
    }

    pub fn enableAhb(self: *const Rcc, mask: u32) void {
        self.regs.*.AHBENR |= mask;
    }
};

pub fn RccEnableGpio(port: usize) void {
    switch (port) {
        @intFromPtr(stm32f103c8.GPIOA) => RCC_APB2ENR.* |= @as(u32, 1) << 2,
        @intFromPtr(stm32f103c8.GPIOB) => RCC_APB2ENR.* |= @as(u32, 1) << 3,
        @intFromPtr(stm32f103c8.GPIOC) => RCC_APB2ENR.* |= @as(u32, 1) << 4,
        @intFromPtr(stm32f103c8.GPIOD) => RCC_APB2ENR.* |= @as(u32, 1) << 5,
        else => {},
    }
}

pub fn RccDisableGpio(port: usize) void {
    switch (port) {
        @intFromPtr(stm32f103c8.GPIOA) => RCC_APB2ENR.* &= ~(@as(u32, 1) << 2),
        @intFromPtr(stm32f103c8.GPIOB) => RCC_APB2ENR.* &= ~(@as(u32, 1) << 3),
        @intFromPtr(stm32f103c8.GPIOC) => RCC_APB2ENR.* &= ~(@as(u32, 1) << 4),
        @intFromPtr(stm32f103c8.GPIOD) => RCC_APB2ENR.* &= ~(@as(u32, 1) << 5),
        else => {},
    }
}
