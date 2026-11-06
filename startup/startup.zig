extern var _sidata: u32;
extern var _sdata: u32;
extern var _edata: u32;

extern var _sbss: u32;
extern var _ebss: u32;

fn initializeData() void {
    var src: usize = @intFromPtr(&_sidata);
    var dst: usize = @intFromPtr(&_sdata);

    const end: usize = @intFromPtr(&_edata);

    while (dst < end) : ({
        src += 4;
        dst += 4;
    }) {
        const source: *const u32 = @ptrFromInt(src);
        const destination: *u32 = @ptrFromInt(dst);

        destination.* = source.*;
    }
}

fn initializeBss() void {
    var dst: usize = @intFromPtr(&_sbss);
    const end: usize = @intFromPtr(&_ebss);

    while (dst < end) : (dst += 4) {
        const ptr: *u32 = @ptrFromInt(dst);
        ptr.* = 0;
    }
}

extern const vector_table: anyopaque;

fn configureVectorTable() void {
    const vtor: *volatile u32 = @ptrFromInt(0xE000_ED08);

    vtor.* = @intCast(@intFromPtr(&vector_table));

    asm volatile ("dsb");
    asm volatile ("isb");
}

extern fn firmwareMain() callconv(.c) void;

pub export fn Reset_Handler() noreturn {
    configureVectorTable();

    initializeData();
    initializeBss();

    firmwareMain();

    while (true) {
        asm volatile ("nop");
    }
}
