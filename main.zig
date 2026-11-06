const vector_table = @import("startup/vector_table.zig");
const rcc = @import("drivers/rcc.zig");
const gpio = @import("drivers/gpio.zig");
const nvic = @import("arch/arm/cortex_m3/nvic.zig");
const afio = @import("drivers/afio.zig");
const exti = @import("drivers/exti.zig");
const systick = @import("drivers/systick.zig");
const debounce = @import("drivers/debounce.zig");

comptime {
    _ = vector_table.vector_table;
}

extern var _estack: u32;
extern var _sidata: u32;
extern var _sdata: u32;
extern var _edata: u32;
extern var _sbss: u32;
extern var _ebss: u32;

fn delay(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        asm volatile ("" ::: .{ .memory = true });
    }
}

var gpio_a: gpio.GpioPort = undefined;
var gpio_c: gpio.GpioPort = undefined;

var button_debouncer: debounce.Debouncer = undefined;

fn onButtonEdge() callconv(.c) void {
    const pin_high = gpio_a.read(0);

    button_debouncer.observe(
        pin_high,
        systick.millis(),
    );
}

fn onButtonChanged() callconv(.c) void {
    if (gpio_a.read(0)) {
        // PA0 HIGH → LED OFF
        gpio_c.set(13);
    } else {
        // PA0 LOW → LED ON
        gpio_c.reset(13);
    }
}

pub export fn firmwareMain() callconv(.c) void {
    const clock = rcc.Rcc.initHandle();
    // Default Config:
    // SYSCLK = 72 MHz
    // HCLK   = 72 MHz
    // PCLK1  = 36 MHz
    // PCLK2  = 72 MHz
    clock.configure(.{}) catch {
        while (true) {}
    };

    // Enable AFIO clock on APB2.
    clock.enableApb2(1 << 0);

    gpio_a = gpio.GpioPort.init(.A);
    gpio_c = gpio.GpioPort.init(.C);

    // PA0: input pull-up.
    gpio_a.configurePin(0, .{
        .input = .{ .pull = .up },
    });

    // PC13: output.
    gpio_c.configurePin(13, .{
        .output = .{
            .speed = .mhz_2,
            .driver = .push_pull,
        },
    });

    // Start the 1 ms timebase.
    systick.init(72_000_000) catch {
        while (true) {}
    };

    const initial_state = gpio_a.read(0);

    button_debouncer = debounce.Debouncer.init(
        initial_state,
        systick.millis(),
        25,
    );

    // Blue Pill LED is active-low.
    if (initial_state) {
        gpio_c.set(13);
    } else {
        gpio_c.reset(13);
    }

    // Keep the NVIC IRQ disabled during configuration.
    nvic.disableIRQ(.EXTI0);

    // Connect PA0 to EXTI0.
    afio.configureEXTISource(.A, 0);

    // Configure EXTI0.
    exti.maskInterrupt(.line0, true);
    exti.configureTrigger(.line0, .both);
    exti.clearPending(.line0);

    // Register application callback.
    exti.registerCallback(.line0, onButtonEdge);

    // Clear any stale NVIC pending state.
    nvic.clearPending(.EXTI0);

    // Configure and enable NVIC.
    nvic.setPriority(.EXTI0, .p5);
    nvic.enableIRQ(.EXTI0);

    // Finally allow EXTI0 interrupt delivery.
    exti.maskInterrupt(.line0, false);

    // No polling required!
    while (true) {
        asm volatile ("wfi");

        if (button_debouncer.poll(systick.millis())) |pin_high| {
            if (pin_high) {
                // Released: HIGH -> LED OFF.
                gpio_c.set(13);
            } else {
                // Pressed: LOW -> LED ON.
                gpio_c.reset(13);
            }
        }
    }
}

// pub export fn firmwareMain() callconv(.c) void {
//     const clock = rcc.Rcc.initHandle();
//     // Default Config:
//     // SYSCLK = 72 MHz
//     // HCLK   = 72 MHz
//     // PCLK1  = 36 MHz
//     // PCLK2  = 72 MHz
//     clock.configure(.{}) catch {
//         while (true) {}
//     };
//     nvic.enableIRQ(.EXTI0);

//     var gpio_a = gpio.GpioPort.init(gpio.GPIO_PORT.A);
//     var gpio_c = gpio.GpioPort.init(gpio.GPIO_PORT.C);

//     gpio_a.configurePin(0, .{
//         .input = .{ .pull = .up },
//     });

//     gpio_c.configurePin(13, .{ .output = .{
//         .speed = .mhz_2,
//         .driver = .push_pull,
//     } });

//     gpio_c.set(13);

//     while (true) {
//         gpio_c.reset(13);
//         delay(5_000_000);
//         gpio_c.set(13);
//         delay(5_000_000);
//     }
// }

// export fn _reset() callconv(.c) noreturn {
//     // Copy initialized data from flash to SRAM.
//     var src: [*]const u32 = @ptrCast(&_sidata);
//     var dst: [*]u32 = @ptrCast(&_sdata);
//     const data_end: [*]u32 = @ptrCast(&_edata);

//     while (@intFromPtr(dst) < @intFromPtr(data_end)) : ({
//         src += 1;
//         dst += 1;
//     }) {
//         dst[0] = src[0];
//     }

//     // Zero-initialize .bss.
//     dst = @ptrCast(&_sbss);
//     const bss_end: [*]u32 = @ptrCast(&_ebss);

//     while (@intFromPtr(dst) < @intFromPtr(bss_end)) : (dst += 1) {
//         dst[0] = 0;
//     }

//     main();
// }
