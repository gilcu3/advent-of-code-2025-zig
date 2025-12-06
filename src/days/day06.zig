const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day06() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        lines: [][]const u8 = undefined,
        operands: [][]u64 = undefined,
        ops: []u8 = undefined,
        n: usize = 0,
        allocator: std.mem.Allocator = std.heap.page_allocator,

        const Self = @This();

        // Constructor: parses the raw input string into structured data. This part is also included
        // in the total runtime of the solution benchmarks.
        fn init(input: []const u8) !Self {
            var self = Self{};
            // Input parsing logic here...
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            var line_count: usize = 0;
            while (lexer.next()) |_| {
                line_count += 1;
            }
            self.lines = try self.allocator.alloc([]const u8, line_count);
            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, '\n');
            self.operands = try self.allocator.alloc([]u64, self.lines.len - 1);
            while (lexer.next()) |line| : (i += 1) {
                self.lines[i] = line;
                if (i == 0) {
                    var line_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                    while (line_lexer.next()) |_| {
                        self.n += 1;
                    }
                }
                if (i < line_count - 1) {
                    self.operands[i] = try self.allocator.alloc(u64, self.n);
                } else {
                    self.ops = try self.allocator.alloc(u8, self.n);
                }
            }

            return self;
        }

        fn parse_part1(self: Self) !void {
            var i: usize = 0;

            for (self.lines) |line| {
                var line_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                var j: usize = 0;

                while (line_lexer.next()) |term| : (j += 1) {
                    if (i < self.lines.len - 1) {
                        self.operands[i][j] = try std.fmt.parseInt(u64, term, 10);
                    } else {
                        self.ops[j] = term[0];
                    }
                }
                i += 1;
            }
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            try self.parse_part1();
            var ans: u64 = 0;
            for (0..self.n) |j| {
                if (self.ops[j] == '*') {
                    var cur: u64 = 1;
                    for (0..self.operands.len) |i| {
                        cur *= self.operands[i][j];
                    }
                    ans += cur;
                } else {
                    var cur: u64 = 0;
                    for (0..self.operands.len) |i| {
                        cur += self.operands[i][j];
                    }
                    ans += cur;
                }
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        fn parse_part2(self: Self) !void {
            const nl = self.lines.len - 1;
            var line_lexer = std.mem.tokenizeScalar(u8, self.lines[nl], ' ');
            var jj: usize = 0;
            while (line_lexer.next()) |term| : (jj += 1) {
                self.ops[jj] = term[0];
            }

            const m: usize = self.lines[0].len;

            var on: usize = 0;
            var res: u64 = 0;
            if (self.ops[on] == '*') res = 1;
            for (0..m) |i| {
                var cur: u64 = 0;
                for (0..nl) |j| {
                    if (self.lines[j][i] != ' ') {
                        cur = cur * 10 + (self.lines[j][i] - '0');
                    }
                }
                if (cur != 0) {
                    if (self.ops[on] == '*') {
                        res *= cur;
                    } else {
                        res += cur;
                    }
                }
                if (cur == 0 or i == m - 1) {
                    self.operands[0][on] = res;
                    on += 1;
                    if (i != m - 1) {
                        if (self.ops[on] == '*') {
                            res = 1;
                        } else {
                            res = 0;
                        }
                    }
                }
            }
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            try self.parse_part2();
            var ans: u64 = 0;
            for (0..self.n) |j| {
                // horrifying trick to make both solutions reuse the same
                // initial memory allocation
                ans += self.operands[0][j];
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day06.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day06().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 06:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day06.txt");

// Unit tests for part 1.
test "day 06 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day06().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "4277556";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 06 part 2 sample 1" {
    const puzzle = try Day06().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "3263827";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
