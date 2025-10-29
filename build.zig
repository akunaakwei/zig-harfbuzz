const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Linkage type for the library") orelse .static;
    const hb_have_freetype = b.option(bool, "HB_HAVE_FREETYPE", "Enable freetype interop helpers") orelse false;
    const hb_have_icu = b.option(bool, "HB_HAVE_ICU", "Enable icu unicode functions") orelse false;

    const harfbuzz_dep = b.dependency("harfbuzz", .{});
    const maybe_freetype_dep = freetype_dep: {
        if (!hb_have_freetype)
            break :freetype_dep null;

        break :freetype_dep b.lazyDependency("freetype2", .{
            .target = target,
            .optimize = optimize,
        });
    };
    const maybe_icu_dep = icu_dep: {
        if (!hb_have_icu)
            break :icu_dep null;

        break :icu_dep b.lazyDependency("icu", .{
            .target = target,
            .optimize = optimize,
        });
    };

    const harfbuzz = b.addLibrary(.{
        .name = "harfbuzz",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });
    if (maybe_freetype_dep) |freetype_dep| {
        const freetype = freetype_dep.artifact("freetype");
        harfbuzz.linkLibrary(freetype);
        harfbuzz.root_module.addCMacro("HAVE_FREETYPE", "1");
    }
    if (maybe_icu_dep) |icu_dep| {
        const icuuc = icu_dep.artifact("icuuc");
        harfbuzz.linkLibrary(icuuc);
        harfbuzz.root_module.addCMacro("HAVE_ICU", "1");
        harfbuzz.addCSourceFile(.{
            .file = harfbuzz_dep.path("src/hb-icu.cc"),
        });
    }
    harfbuzz.addCSourceFile(.{
        .file = harfbuzz_dep.path("src/harfbuzz.cc"),
    });
    b.installArtifact(harfbuzz);
}
