const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m3 },
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    const firmware = b.addExecutable(.{
        .name = "firmware.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
        }),
    });

    // Use our custom linker script.
    firmware.setLinkerScript(b.path("link.ld"));

    // The linker script specifies ENTRY(Reset_Handler).
    firmware.entry = .disabled;

    // Generate firmware.elf.
    b.installArtifact(firmware);

    // Generate firmware.bin.
    const bin = firmware.addObjCopy(.{
        .format = .binary,
    });

    const install_bin = b.addInstallBinFile(
        bin.getOutput(),
        "firmware.bin",
    );

    b.getInstallStep().dependOn(&install_bin.step);
}
