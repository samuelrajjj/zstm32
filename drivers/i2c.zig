const I2C_BASE: usize = 0x4000_5400;
const RCC_BASE: usize = 0x4002_1000;
const GPIOB_BASE: usize = 0x4001_0C00;

// I2C registers
const CR1 = reg(I2C_BASE + 0x00);
const CR2 = reg(I2C_BASE + 0x04);
const OAR1 = reg(I2C_BASE + 0x08);
const DR = reg(I2C_BASE + 0x10);
const SR1 = reg(I2C_BASE + 0x14);
const SR2 = reg(I2C_BASE + 0x18);
const CCR = reg(I2C_BASE + 0x1C);
const TRISE = reg(I2C_BASE + 0x20);

// RCC registers
const RCC_APB2ENR = reg(RCC_BASE + 0x18);
const RCC_APB1ENR = reg(RCC_BASE + 0x1C);

// GPIOB registers
const GPIOB_CRL = reg(GPIOB_BASE + 0x00);
const GPIOB_ODR = reg(GPIOB_BASE + 0x0C);

const CR1_PE: u32 = 1 << 0;
const CR1_START: u32 = 1 << 8;
const CR1_STOP: u32 = 1 << 9;
const CR1_ACK: u32 = 1 << 10;
const CR1_SWRST: u32 = 1 << 15;

const SR1_SB: u32 = 1 << 0;
const SR1_ADDR: u32 = 1 << 1;
const SR1_BTF: u32 = 1 << 2;
const SR1_RXNE: u32 = 1 << 6;
const SR1_TXE: u32 = 1 << 7;

const SR1_BERR: u32 = 1 << 8;
const SR1_ARLO: u32 = 1 << 9;
const SR1_AF: u32 = 1 << 10;
const SR1_OVR: u32 = 1 << 11;
const SR1_TIMEOUT: u32 = 1 << 14;

const SR1_ERROR_MASK: u32 =
    SR1_BERR | SR1_ARLO | SR1_AF |
    SR1_OVR | SR1_TIMEOUT;

const SR2_BUSY: u32 = 1 << 1;

const TIMEOUT: u32 = 1_000_000;

pub const I2cError = error{
    Timeout,
    Nack,
    BusError,
    ArbitrationLost,
    Overrun,
};

fn reg(address: usize) *volatile u32 {
    return @ptrFromInt(address);
}

// --------------------------------------------------
// Error handling
// --------------------------------------------------

fn clearErrors() void {
    // Write zero to error flags to clear them.
    SR1.* = ~SR1_ERROR_MASK;
}

fn waitFor(mask: u32) I2cError!void {
    var count: u32 = TIMEOUT;

    while (count > 0) : (count -= 1) {
        const status = SR1.*;

        if ((status & SR1_ERROR_MASK) != 0) {
            if ((status & SR1_ARLO) != 0) {
                clearErrors();
                return error.ArbitrationLost;
            }

            if ((status & SR1_AF) != 0) {
                clearErrors();
                return error.Nack;
            }

            if ((status & SR1_BERR) != 0) {
                clearErrors();
                return error.BusError;
            }

            if ((status & SR1_OVR) != 0) {
                clearErrors();
                return error.Overrun;
            }

            if ((status & SR1_TIMEOUT) != 0) {
                clearErrors();
                return error.Timeout;
            }
        }

        if ((status & mask) == mask) {
            return;
        }
    }

    return error.Timeout;
}

fn waitBusIdle() I2cError!void {
    var count: u32 = TIMEOUT;

    while (count > 0) : (count -= 1) {
        if ((SR2.* & SR2_BUSY) == 0) {
            return;
        }
    }

    return error.Timeout;
}

fn clearAddressFlag() void {
    // ADDR is cleared by reading SR1 followed by SR2.
    const sr1 = SR1.*;
    const sr2 = SR2.*;

    _ = sr1;
    _ = sr2;
}

fn abortTransfer() void {
    CR1.* |= CR1_STOP;
    CR1.* |= CR1_ACK;
    clearErrors();
}

// --------------------------------------------------
// Initialization
// --------------------------------------------------

pub fn init() void {
    // Enable AFIO and GPIOB clocks.
    RCC_APB2ENR.* |= (1 << 0) | (1 << 3);

    // Enable I2C1 clock.
    RCC_APB1ENR.* |= (1 << 21);

    // Release PB6 and PB7 high before configuring.
    GPIOB_ODR.* |= (1 << 6) | (1 << 7);

    // PB6 and PB7: Alternate Function Open Drain,
    // 50 MHz output mode (CNF=11, MODE=11).
    GPIOB_CRL.* =
        (GPIOB_CRL.* & ~(@as(u32, 0xFF) << 24)) |
        (@as(u32, 0xFF) << 24);

    // Reset I2C1.
    CR1.* = CR1_SWRST;
    CR1.* = 0;

    // APB1 peripheral clock = 36 MHz.
    // FREQ[5:0] = 36.
    CR2.* = 36;

    // Standard mode: 100 kHz.
    // CCR = PCLK1 / (2 * I2C_speed)
    //     = 36 MHz / 200 kHz
    //     = 180.
    CCR.* = 180;

    // Standard-mode maximum rise time:
    // TRISE = 36 MHz * 1000 ns + 1 = 37.
    TRISE.* = 37;

    // OAR1 bit 14 must be kept at 1.
    OAR1.* = 1 << 14;

    // Enable peripheral.
    CR1.* = CR1_PE;

    // Enable ACK by default.
    CR1.* |= CR1_ACK;
}

// --------------------------------------------------
// START and STOP
// --------------------------------------------------

pub fn start() I2cError!void {
    try waitBusIdle();

    CR1.* |= CR1_START;

    try waitFor(SR1_SB);
}

pub fn stop() void {
    CR1.* |= CR1_STOP;
}

// --------------------------------------------------
// Low-level byte operations
// --------------------------------------------------

pub fn writeByte(value: u8) I2cError!void {
    DR.* = value;

    try waitFor(SR1_TXE);
}

pub fn readByte() I2cError!u8 {
    try waitFor(SR1_RXNE);

    return @truncate(DR.*);
}

// --------------------------------------------------
// Device probing
// --------------------------------------------------

pub fn probe(address: u7) I2cError!void {
    errdefer abortTransfer();

    try start();

    const address_byte: u8 =
        @as(u8, @intCast(address)) << 1;

    try writeByte(address_byte);

    try waitFor(SR1_ADDR);

    clearAddressFlag();

    stop();

    try waitBusIdle();
}

// --------------------------------------------------
// Register write
// --------------------------------------------------

pub fn writeRegister(
    address: u7,
    register: u8,
    value: u8,
) I2cError!void {
    errdefer abortTransfer();

    try start();

    // Slave address + WRITE bit.
    const address_byte: u8 =
        @as(u8, @intCast(address)) << 1;

    try writeByte(address_byte);

    try waitFor(SR1_ADDR);

    clearAddressFlag();

    // Register address.
    try writeByte(register);

    try waitFor(SR1_BTF);

    // Register data.
    try writeByte(value);

    try waitFor(SR1_BTF);

    stop();
}

// --------------------------------------------------
// Register read - repeated START
// --------------------------------------------------

pub fn readRegister(
    address: u7,
    register: u8,
) I2cError!u8 {
    errdefer abortTransfer();

    // Make sure ACK is enabled before receiving.
    CR1.* |= CR1_ACK;

    // First START: address the sensor for writing.
    try start();

    const address_write: u8 =
        @as(u8, @intCast(address)) << 1;

    try writeByte(address_write);

    try waitFor(SR1_ADDR);

    clearAddressFlag();

    // Send the register address.
    try writeByte(register);

    try waitFor(SR1_BTF);

    // Repeated START.
    CR1.* |= CR1_START;

    try waitFor(SR1_SB);

    // Address + READ bit.
    const address_read: u8 =
        (@as(u8, @intCast(address)) << 1) | 1;

    try writeByte(address_read);

    try waitFor(SR1_ADDR);

    // Single-byte receive sequence:
    // Disable ACK before clearing ADDR.
    CR1.* &= ~CR1_ACK;

    clearAddressFlag();

    // Generate STOP immediately after ADDR is cleared.
    stop();

    // Receive the byte.
    const value = try readByte();

    // Restore ACK for the next transaction.
    CR1.* |= CR1_ACK;

    return value;
}

// --------------------------------------------------
// I2C bus scanner
// --------------------------------------------------

pub fn scan(found: []u7) I2cError!usize {
    var found_count: usize = 0;

    var address: u7 = 0x08;

    while (address < 0x78) : (address += 1) {
        probe(address) catch |err| {
            switch (err) {
                error.Nack => continue,
                else => return err,
            }
        };

        if (found_count < found.len) {
            found[found_count] = address;
        }

        found_count += 1;
    }

    return found_count;
}
