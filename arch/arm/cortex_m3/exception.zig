pub const Exception = enum(u8) {
    nmi = 2,
    hard_fault = 3,
    memory_management = 4,
    bus_fault = 5,
    usage_fault = 6,
    svcall = 11,
    debug_monitor = 12,
    pendsv = 14,
    systick = 15,
};
