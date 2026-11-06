const critical = @import("../arch/arm/cortex_m3/critical_section.zig");

pub const Debouncer = struct {
    stable_state: bool,
    candidate_state: bool,
    candidate_since_ms: u32,
    debounce_ms: u32,

    pub fn init(
        initial_state: bool,
        now_ms: u32,
        debounce_ms: u32,
    ) Debouncer {
        return .{
            .stable_state = initial_state,
            .candidate_state = initial_state,
            .candidate_since_ms = now_ms,
            .debounce_ms = debounce_ms,
        };
    }

    /// Called whenever EXTI detects a GPIO transition.
    pub fn observe(
        self: *Debouncer,
        new_state: bool,
        now_ms: u32,
    ) void {
        const previous = critical.enter();
        defer critical.exit(previous);

        if (new_state != self.candidate_state) {
            self.candidate_state = new_state;
            self.candidate_since_ms = now_ms;
        }
    }

    /// Check whether the candidate state has remained
    /// stable long enough.
    ///
    /// Returns null if there is no new stable state.
    /// Otherwise returns the new stable GPIO state.
    pub fn poll(
        self: *Debouncer,
        now_ms: u32,
    ) ?bool {
        const previous = critical.enter();
        defer critical.exit(previous);

        if (self.candidate_state != self.stable_state and
            (now_ms -% self.candidate_since_ms) >= self.debounce_ms)
        {
            self.stable_state = self.candidate_state;
            return self.stable_state;
        }

        return null;
    }
};
