pub const FLASH_BASE: usize = 0x08000000;
pub const SYSMEM_BASE: usize = 0x1FFFF000;
pub const OPTBYTES_BASE: usize = 0x1FFFF800;
pub const SRAM_BASE: usize = 0x20000000;
pub const SRAM_SIZE: usize = 20 * 1024;
pub const SRAM_END: usize = SRAM_BASE + SRAM_SIZE - 1;

// AHB & APB Peripherals
pub const AHB_BASE: usize = 0x40018000;
pub const APB2_BASE: usize = 0x40010000;
pub const APB1_BASE: usize = 0x40000000;

// RCC Peripherals
pub const RCC_BASE: usize = 0x40021000;
pub const RCC_RB = extern struct {
    CR: u32, // 0x00
    CFGR: u32, // 0x04
    CIR: u32, // 0x08
    APB2RSTR: u32, // 0x0C
    APB1RSTR: u32, // 0x10
    AHBENR: u32, // 0x14
    APB2ENR: u32, // 0x18
    APB1ENR: u32, // 0x1C
    BDCR: u32, // 0x20
    CSR: u32, // 0x24
};

// GPIO Peripherals
pub const GPIO_BASE: usize = APB2_BASE + 0x800; // 0x40010800

pub const GPIOA_BASE: usize = GPIO_BASE + 0x0000;
pub const GPIOB_BASE: usize = GPIO_BASE + 0x0400;
pub const GPIOC_BASE: usize = GPIO_BASE + 0x0800;
pub const GPIOD_BASE: usize = GPIO_BASE + 0x0C00;

pub const GPIO_RB = extern struct {
    CRL: u32, // 0x00
    CRH: u32, // 0x04
    IDR: u32, // 0x08
    ODR: u32, // 0x0C
    BSRR: u32, // 0x10
    BRR: u32, // 0x14
    LCKR: u32, // 0x18
};

// USAGE
pub const RCC: *volatile RCC_RB = @ptrFromInt(RCC_BASE);

pub const GPIOA: *volatile GPIO_RB = @ptrFromInt(GPIOA_BASE);
pub const GPIOB: *volatile GPIO_RB = @ptrFromInt(GPIOB_BASE);
pub const GPIOC: *volatile GPIO_RB = @ptrFromInt(GPIOC_BASE);
pub const GPIOD: *volatile GPIO_RB = @ptrFromInt(GPIOD_BASE);
