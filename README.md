# ⚡ ZSTM32

### A bare-metal STM32 firmware framework.

**Building embedded systems from the registers up.**

ZSTM32 is an experimental, low-level embedded firmware project focused on building reusable hardware abstraction layers and peripheral drivers for STM32 microcontrollers using the Zig programming language.

The project starts with the **STM32F103C8T6 Blue Pill** and aims to develop a clean, modular, and extensible firmware architecture without depending on vendor-provided HAL libraries.

Instead of treating hardware abstraction as a black box, this project explores the underlying hardware registers, clock systems, peripheral configurations, interrupts, and communication protocols by implementing them from scratch.

> Learn the hardware. Understand the registers. Build the abstraction.

---

## 🎯 Project Goals

The primary objective is to develop a reusable STM32 firmware ecosystem with a focus on low-level programming, hardware control, and software architecture.

- Implement peripheral drivers directly using memory-mapped registers.
- Build a modular Hardware Abstraction Layer (HAL).
- Explore bare-metal programming using Zig.
- Understand ARM Cortex-M architecture and interrupt handling.
- Develop reusable and type-safe peripheral interfaces.
- Minimize dependencies on vendor SDKs and external frameworks.
- Explore portability across different STM32 microcontroller families.

This project is also an opportunity to explore how Zig can be used for modern embedded systems development.

## 🔧 Hardware Platform

The initial development platform is the STM32F103C8T6 Blue Pill.

| Component             | Specification           |
| --------------------- | ----------------------- |
| Development board     | STM32F103C8T6 Blue Pill |
| Microcontroller       | STM32F103C8T6           |
| Architecture          | ARM Cortex-M3           |
| Maximum clock         | 72 MHz                  |
| Flash                 | 64 KB                   |
| SRAM                  | 20 KB                   |
| Programming interface | SWD                     |
| Debugger              | ST-Link V2              |

Additional hardware and microcontroller platforms may be introduced as the project evolves.

## 🛠️ Technology Stack

| Technology             | Purpose                  |
| ---------------------- | ------------------------ |
| Zig                    | Firmware implementation  |
| ARM Cortex-M3          | Target processor         |
| STM32 Reference Manual | Peripheral documentation |
| STM32 Datasheet        | Hardware specifications  |
| OpenOCD                | Flashing and debugging   |
| ST-Link                | Hardware programming     |
| ARM ELF tools          | Firmware inspection      |

**Target configuration:**

- Architecture: `thumb`
- Operating environment: `freestanding`
- ABI: `eabi`
- CPU: `cortex_m3`
- Build system: Zig Build System

## 🏗️ Architecture

The project follows a layered architecture to separate application logic from hardware-specific implementation.

```text
              APPLICATION LAYER
          ┌────────────────────────┐
          │  GPIO / Sensor / UART   │
          │  Embedded Applications │
          └────────────┬───────────┘
                       │
                       ▼
           HARDWARE ABSTRACTION LAYER
          ┌────────────────────────┐
          │       STM32 HAL        │
          ├────────────────────────┤
          │ RCC  │ PIO  │ AFIO     │
          │ EXTI │ NVIC │ I2C      │
          │ SPI  │ USART│ TIMERS   │
          └────────────┬───────────┘
                       │
                       ▼
             REGISTER ACCESS LAYER
          ┌────────────────────────┐
          │ Memory-Mapped Registers│
          │ Bit Manipulation       │
          │ Peripheral Addresses   │
          └────────────┬───────────┘
                       │
                       ▼
                STM32 HARDWARE
          ┌────────────────────────┐
          │     STM32F103C8T6      │
          │     ARM Cortex-M3      │
          └────────────────────────┘
```

The intention is to keep register-level operations independent from higher-level peripheral interfaces wherever practical.

## 📦 Driver Development

The framework is being developed incrementally, starting with fundamental microcontroller peripherals.

### Core Drivers

| Peripheral | Description                          | Status            |
| ---------- | ------------------------------------ | ----------------- |
| RCC        | Reset and Clock Control              | 🟡 In development |
| GPIO       | General-Purpose Input/Output         | 🟡 In development |
| AFIO       | Alternate Function I/O               | 🟡 In development |
| EXTI       | External Interrupt Controller        | 🟡 In development |
| NVIC       | Nested Vectored Interrupt Controller | 🟡 In development |

### Communication Drivers

| Peripheral | Description                 | Status    |
| ---------- | --------------------------- | --------- |
| USART      | Serial communication        | ⬜ Planned |
| I2C        | Inter-Integrated Circuit    | ⬜ Planned |
| SPI        | Serial Peripheral Interface | ⬜ Planned |

### Timing and Advanced Peripherals

| Peripheral  | Description                 | Status    |
| ----------- | --------------------------- | --------- |
| SysTick     | System timer                | ⬜ Planned |
| TIM         | General-purpose timers      | ⬜ Planned |
| PWM         | Pulse Width Modulation      | ⬜ Planned |
| DMA         | Direct Memory Access        | ⬜ Planned |
| ADC         | Analog-to-Digital Converter | ⬜ Planned |
| WWDG / IWDG | Watchdog timers             | ⬜ Planned |

*Status reflects the current development roadmap and will be updated as implementation and hardware validation progress.*

## 🚀 Getting Started

### Prerequisites

Install the following development tools:

- [Zig](https://ziglang.org/download/) — Firmware compiler.
- [OpenOCD](https://openocd.org/) — Debugging and programming.
- [ST-Link](https://www.st.com/en/development-tools/stsw-link009.html) — Hardware debugger/programmer.
- ARM ELF utilities — Firmware inspection.

The project currently targets Zig 0.17.0. Use the version specified by the project when building.

### Clone the repository

```bash
git clone https://github.com/samuelrajjj/zstm32.git

cd zstm32
```

### Build the firmware

```bash
zig build
```

The build configuration and individual examples will evolve alongside the project.

### Flashing and debugging

Connect the STM32F103C8T6 Blue Pill through an ST-Link programmer using the SWD interface.

OpenOCD can be used to establish a debugging connection and program the target.

The exact flashing commands will be documented alongside the corresponding firmware examples.

## 🧪 Development Philosophy

This project follows a hardware-first learning and development approach.

Every peripheral driver begins with understanding its hardware documentation.

The general development workflow is:

1. Study the relevant peripheral in the reference manual.
2. Understand its registers, bit fields, and memory addresses.
3. Implement register-level operations in Zig.
4. Design a reusable peripheral interface.
5. Compile for the target ARM architecture.
6. Flash the firmware onto the microcontroller.
7. Validate functionality on actual hardware.
8. Refine the implementation and document the results.

The objective is not simply to make the code compile. The objective is to understand why it works.

## 🗺️ Roadmap

### Phase 1 — Bare-Metal Foundations

- [x] Initial bare-metal Zig development.
- [x] STM32F103C8T6 target configuration.
- [x] Initial firmware compilation and flashing.
- [x] LED blink application.
- [x] Initial peripheral driver development.

### Phase 2 — Peripheral Abstraction

- [x] RCC register-level foundations.
- [x] GPIO configuration and control.
- [x] AFIO configuration.
- [x] EXTI and NVIC foundations.
- [ ] Complete interrupt handling architecture.
- [ ] Shared EXTI line management.
- [ ] Safe interrupt callback design.
- [ ] GPIO debouncing utilities.

### Phase 3 — Communication Interfaces

- [ ] USART driver.
- [ ] I2C driver.
- [ ] SPI driver.
- [ ] Sensor communication examples.

### Phase 4 — Timing and Advanced Peripherals

- [ ] SysTick implementation.
- [ ] General-purpose timers.
- [ ] PWM generation.
- [ ] DMA implementation.
- [ ] ADC implementation.

### Phase 5 — Framework Architecture

- [ ] Reusable peripheral interfaces.
- [ ] Hardware-independent application layer.
- [ ] Error handling architecture.
- [ ] Compile-time peripheral configuration.
- [ ] Documentation and examples.
- [ ] Automated testing where practical.

### Phase 6 — Future Hardware Support

- [ ] Explore STM32F4 series support.
- [ ] Explore STM32H7 series support.
- [ ] Investigate Cortex-M4F and Cortex-M7 features.
- [ ] Explore RTOS integration.
- [ ] Investigate flight-controller applications.

*The roadmap is experimental and subject to change as the project develops.*

## 📚 Documentation and Learning Resources

The following resources are useful for understanding the hardware and software involved:

- [Zig Official Documentation](https://ziglang.org/documentation/)
- [STM32F103x8/xB Datasheet](https://www.st.com/resource/en/datasheet/stm32f103c8.pdf)
- [STM32F1 Reference Manual – RM0008](https://www.st.com/resource/en/reference_manual/cd00171190.pdf)
- [ARM Cortex-M3 Technical Reference Manual](https://developer.arm.com/documentation/ddi0337/latest)
- [OpenOCD Documentation](https://openocd.org/doc/html/)

## 🤝 Contributions

Contributions, discussions, suggestions, and technical feedback are welcome.

If you're interested in:

- Embedded systems development.
- Zig programming.
- ARM Cortex-M architecture.
- Bare-metal firmware.
- Register-level peripheral drivers.
- Microcontroller hardware abstraction.

Feel free to explore the repository, open an issue, or suggest improvements.

This project is actively evolving, and contributions that improve correctness, portability, documentation, and architecture are appreciated.

## 📌 Project Status

**ZSTM32 is an experimental work in progress.**

The initial target is the STM32F103C8T6 Blue Pill. The project is being developed incrementally, with an emphasis on understanding hardware behavior and validating implementations on physical devices.

It is not yet intended to be a production-ready replacement for established STM32 development frameworks.

## 📄 License

License information will be added as the project matures.

---

## ✍️ Author

**Samuel Raj**

Interested in embedded systems, low-level programming, operating systems, and systems engineering.

Building things from the ground up, one register at a time.

---