/// Save the current interrupt mask and disable
/// configurable-priority interrupts.
///
/// Returns the previous PRIMASK state.
/// Save PRIMASK and disable configurable interrupts.
pub fn enter() u32 {
    var previous: u32 = undefined;

    asm volatile ("mrs %[result], PRIMASK"
        : [result] "=r" (previous),
    );

    asm volatile ("cpsid i" ::: .{ .memory = true });

    return previous;
}

/// Restore the previous PRIMASK state.
pub fn exit(previous: u32) void {
    asm volatile ("msr PRIMASK, %[value]"
        :
        : [value] "r" (previous),
        : .{ .memory = true });
}
