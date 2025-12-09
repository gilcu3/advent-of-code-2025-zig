const std = @import("std");
// const puzzle = @import("day"); // Injected by build.zig
const manifest = @import("manifest");

fn get_human_time(allocator: std.mem.Allocator, n: f64) []const u8 {
    if (n < std.time.ns_per_us) {
        return std.fmt.allocPrint(allocator, "{d: >9.3} ns", .{n}) catch unreachable;
    } else if (n < std.time.ns_per_ms) {
        return std.fmt.allocPrint(allocator, "{d: >9.3} us", .{n / std.time.ns_per_us}) catch unreachable;
    } else if (n < std.time.ns_per_s) {
        return std.fmt.allocPrint(allocator, "{d: >9.3} ms", .{n / std.time.ns_per_ms}) catch unreachable;
    } else {
        return std.fmt.allocPrint(allocator, "{d: >10.3} s", .{n / std.time.ns_per_s}) catch unreachable;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("| Days        | Parsing     | Part 1      | Part 2      | Total       |\n", .{});
    try stdout.print("| ----------- | ----------- | ----------- | ----------- | ----------- |\n", .{});

    var total_time: f64 = 0;

    inline for (manifest.modules) |entry| {
        const name = entry.name;
        const puzzle = entry.m;

        const day_num = try std.fmt.parseInt(u8, name[3..], 10);

        var mean_results: [4]f64 = .{0} ** 4;

        const iterations = 1;
        var timer = try std.time.Timer.start();
        for (1..(iterations + 1)) |i| {
            const results = try puzzle.run(allocator, false);
            mean_results[0] += (to_f64(results[0]) - mean_results[0]) / to_f64(i);
            mean_results[1] += (to_f64(results[1] - results[0]) - mean_results[1]) / to_f64(i);
            mean_results[2] += (to_f64(results[2] - results[1]) - mean_results[2]) / to_f64(i);
            _ = arena.reset(.retain_capacity);
            const time0 = timer.read();
            if (time0 > std.time.ns_per_s * 10) {
                break;
            }
        }

        mean_results[3] = mean_results[0] + mean_results[1] + mean_results[2];

        total_time += mean_results[3];

        try stdout.print("| Day {d: >2}      |", .{day_num});
        for (0..4) |i| {
            try stdout.print("{s} |", .{get_human_time(allocator, mean_results[i])});
        }
        try stdout.print("\n", .{});
    }

    try stdout.print("\n**Total:** {s}\n", .{get_human_time(allocator, total_time)});
}

fn to_f64(x: anytype) f64 {
    return @floatFromInt(x);
}
