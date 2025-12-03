const std = @import("std");
const puzzle = @import("day"); // Injected by build.zig

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

    var mean_results: [3]f64 = .{0} ** 3;

    const iterations = 100;
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

    const total_time = mean_results[0] + mean_results[1] + mean_results[2];

    std.debug.print("| Parsing     | Part 1      | Part 2      | Total       |\n", .{});
    std.debug.print("| ----------- | ----------- | ----------- | ----------- |\n", .{});
    std.debug.print("|{s} |{s} |{s} |{s} |\n", .{
        get_human_time(allocator, mean_results[0]), get_human_time(allocator, mean_results[1]), get_human_time(allocator, mean_results[2]), get_human_time(allocator, total_time),
    });
}

fn to_f64(x: anytype) f64 {
    return @floatFromInt(x);
}
