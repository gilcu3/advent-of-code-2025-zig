const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day05() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        ranges: [][2]u64 = undefined,
        ids: []u64 = undefined,
        allocator: std.mem.Allocator = std.heap.page_allocator,

        const Self = @This();

        // Constructor: parses the raw input string into structured data. This part is also included
        // in the total runtime of the solution benchmarks.
        fn init(input: []const u8) !Self {
            var self = Self{};
            // Input parsing logic here...
            var lexer = std.mem.splitScalar(u8, input, '\n');
            var range_count: usize = 0;
            var second: bool = false;
            var ids_count: usize = 0;
            while (lexer.next()) |line| {
                if (line.len == 0) {
                    second = true;
                    continue;
                }
                if (!second) {
                    range_count += 1;
                } else {
                    ids_count += 1;
                }
            }
            self.ranges = try self.allocator.alloc([2]u64, range_count);
            self.ids = try self.allocator.alloc(u64, ids_count);
            var i: usize = 0;
            lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                if (i < range_count) {
                    var inner_lexer = std.mem.tokenizeScalar(u8, line, '-');
                    const n1 = inner_lexer.next().?;
                    self.ranges[i][0] = try std.fmt.parseInt(u64, n1, 10);
                    const n2 = inner_lexer.next().?;
                    self.ranges[i][1] = try std.fmt.parseInt(u64, n2, 10);
                } else if (i > range_count) {
                    self.ids[i - range_count - 1] = try std.fmt.parseInt(u64, line, 10);
                }
            }
            return self;
        }

        fn compareRanges(_: void, lhs: [2]u64, rhs: [2]u64) bool {
            if (lhs[0] != rhs[0]) return lhs[0] < rhs[0];
            return lhs[1] < rhs[1];
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            var ans: u32 = 0;
            std.mem.sortUnstable([2]u64, self.ranges, {}, Self.compareRanges);
            std.mem.sortUnstable(u64, self.ids, {}, std.sort.asc(u64));
            const n = self.ranges.len;
            const m = self.ids.len;
            var i: usize = 0;
            var j: usize = 0;
            var last: u64 = 0;
            while (i < n or j < m) {
                if (i == n) {
                    for (self.ids[j..m]) |e| {
                        if (e >= last) break;
                        ans += 1;
                    }
                    break;
                }
                while (j < m and self.ids[j] < self.ranges[i][0]) {
                    if (self.ids[j] < last) {
                        ans += 1;
                    }
                    j += 1;
                }
                while (j < m and self.ids[j] <= self.ranges[i][1]) {
                    ans += 1;
                    j += 1;
                }
                last = @max(last, self.ranges[i][1] + 1);
                i += 1;
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u64 = 0;
            std.mem.sortUnstable([2]u64, self.ranges, {}, Self.compareRanges);
            const n = self.ranges.len;
            var i: usize = 0;
            var last: u64 = 0;
            while (i < n) {
                if (self.ranges[i][0] >= last) {
                    ans += self.ranges[i][1] - self.ranges[i][0] + 1;
                    last = self.ranges[i][1] + 1;
                } else if (self.ranges[i][1] >= last) {
                    ans += self.ranges[i][1] - last + 1;
                    last = self.ranges[i][1] + 1;
                }
                i += 1;
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day05.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day05().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 05:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day05.txt");

// Unit tests for part 1.
test "day 05 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day05().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "3";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 05 part 2 sample 1" {
    const puzzle = try Day05().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "14";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
