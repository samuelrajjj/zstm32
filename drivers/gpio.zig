const stm32f103c8 = @import("stm32f103c8.zig");
const rcc = @import("rcc.zig");

const RCC_APB2ENR: *volatile u32 = @ptrFromInt(0x40021018);

pub const Pull = enum { up, down };
pub const InputConfig = union(enum) {
    analog,
    floating,
    pull: Pull,
};

pub const OutputSpeed = enum(u2) {
    mhz_10 = 0b01,
    mhz_2 = 0b10,
    mhz_50 = 0b11,
};
pub const OutputDriver = enum(u2) {
    push_pull = 0b00,
    open_drain = 0b01,
    alternate_push_pull = 0b10,
    alternate_open_drain = 0b11,
};
pub const OutputConfig = struct {
    speed: OutputSpeed,
    driver: OutputDriver = .push_pull,
};

pub const PinConfig = union(enum) {
    input: InputConfig,
    output: OutputConfig,
};

pub const GPIO_PORT = enum {
    A,
    B,
    C,
    D,
};

pub const GpioPort = struct {
    regs: *volatile stm32f103c8.GPIO_RB,
    p: GPIO_PORT,

    pub fn init(port: GPIO_PORT) GpioPort {
        const rb = switch (port) {
            .A => stm32f103c8.GPIOA,
            .B => stm32f103c8.GPIOB,
            .C => stm32f103c8.GPIOC,
            .D => stm32f103c8.GPIOD,
        };
        rcc.RccEnableGpio(@intFromPtr(rb));
        return .{
            .regs = rb,
            .p = port,
        };
    }

    pub fn configurePin(self: *const GpioPort, pin: u4, config: PinConfig) void {
        const shift: u5 = @as(u5, pin % 8) * 4;
        const mask: u32 = ~(@as(u32, 0xF) << shift);

        var mode_bits: u32 = 0;
        var cnf_bits: u32 = 0;

        switch (config) {
            .input => |input| {
                mode_bits = 0b00;
                switch (input) {
                    .analog => {
                        cnf_bits = 0b00;
                    },
                    .floating => {
                        cnf_bits = 0b01;
                    },
                    .pull => |pull| {
                        cnf_bits = 0b10;
                        const bit = @as(u32, 1) << pin;
                        switch (pull) {
                            .up => self.regs.*.BSRR = bit,
                            .down => self.regs.*.BRR = bit,
                        }
                    },
                }
            },

            .output => |output| {
                mode_bits = @backingInt(output.speed);
                cnf_bits = @backingInt(output.driver);
            },
        }

        const config_bits = (cnf_bits << 2) | mode_bits;

        if (pin < 8) {
            self.regs.*.CRL =
                (self.regs.*.CRL & mask) | (config_bits << shift);
        } else {
            self.regs.*.CRH =
                (self.regs.*.CRH & mask) | (config_bits << shift);
        }
    }

    pub fn set(self: *const GpioPort, pin: u4) void {
        self.regs.*.BSRR = @as(u32, 1) << pin;
    }

    pub fn reset(self: *const GpioPort, pin: u4) void {
        self.regs.*.BRR = @as(u32, 1) << pin;
    }

    pub fn read(self: *const GpioPort, pin: u4) bool {
        return (self.regs.*.IDR & (@as(u32, 1) << pin)) != 0;
    }
};
