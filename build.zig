const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const run_all = b.step("run", "Run all days");
    const bench_all = b.step("bench", "Benchmark all days");
    const test_all = b.step("test", "Test all days");

    var last_run_step: ?*std.Build.Step = null;
    var last_bench_step: ?*std.Build.Step = null;

    const day_option = b.option(usize, "ay", "");

    for (1..26) |day| {
        const day_zig_file_str = b.fmt("src/days/day{d:0>2}.zig", .{day});
        const day_zig_file = b.path(day_zig_file_str);
        if (std.fs.cwd().access(day_zig_file_str, .{ .mode = .read_only }) == error.FileNotFound) {
            continue;
        }
        const run_exe = b.addExecutable(.{
            .name = b.fmt("run-day{d:0>2}-Debug", .{day}),
            .root_source_file = b.path("src/run.zig"),
            .target = target,
            .optimize = optimize,
        });
        run_exe.root_module.addAnonymousImport("day", .{ .root_source_file = day_zig_file });
        b.installArtifact(run_exe);

        const bench_exe = b.addExecutable(.{
            .name = b.fmt("bench-day{d:0>2}-Debug", .{day}),
            .root_source_file = b.path("src/bench.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        });
        bench_exe.root_module.addAnonymousImport("day", .{ .root_source_file = day_zig_file });
        b.installArtifact(bench_exe);

        const unit_test = b.addTest(.{ .root_source_file = day_zig_file, .target = target });

        if (day_option == null or day_option == day) {
            const run_cmd = b.addRunArtifact(run_exe);
            if (last_run_step) |last| {
                run_cmd.step.dependOn(last);
            }
            last_run_step = &run_cmd.step;

            const bench_cmd = b.addRunArtifact(bench_exe);
            if (last_bench_step) |last| {
                bench_cmd.step.dependOn(last);
            }
            last_bench_step = &bench_cmd.step;

            const test_cmd = b.addRunArtifact(unit_test);
            test_all.dependOn(&test_cmd.step);
        }
    }
    if (last_run_step) |last| run_all.dependOn(last);
    if (last_bench_step) |last| bench_all.dependOn(last);
}
