const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day04() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        words: [][]u8 = undefined,
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
            self.words = try self.allocator.alloc([]u8, line_count);
            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, '\n');

            while (lexer.next()) |line| : (i += 1) {
                self.words[i] = try self.allocator.alloc(u8, line.len);
                for (0..line.len) |j| {
                    self.words[i][j] = line[j];
                }
            }
            return self;
        }

        fn count_neighbors(self: Self, i: usize, j: usize) usize {
            const n = self.words.len;
            const m = self.words[0].len;
            var neig: usize = 0;
            for (0..3) |x| {
                for (0..3) |y| {
                    const di = i + x;
                    const dj = j + y;
                    if ((x != 1 or y != 1) and di > 0 and di <= n and dj > 0 and dj <= m and self.words[di - 1][dj - 1] == '@') {
                        neig += 1;
                    }
                }
            }
            return neig;
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            var ans: u32 = 0;
            const n = self.words.len;
            const m = self.words[0].len;
            for (0..n) |i| {
                for (0..m) |j| {
                    if (self.words[i][j] == '@') {
                        const neig = self.count_neighbors(i, j);
                        if (neig < 4) {
                            ans += 1;
                        }
                    }
                }
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u64 = 0;
            const n = self.words.len;
            const m = self.words[0].len;
            var changes = true;
            while (changes) {
                changes = false;
                for (0..n) |i| {
                    for (0..m) |j| {
                        if (self.words[i][j] == '@') {
                            const neig = self.count_neighbors(i, j);
                            if (neig < 4) {
                                self.words[i][j] = '.';
                                changes = true;
                                ans += 1;
                            }
                        }
                    }
                }
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        // Miscellaneous helper functions.
        fn helper_function() bool {}
        fn another_helper_function() bool {}
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day04.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day04().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 04:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day04.txt");

// Unit tests for part 1.
test "day 04 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day04().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "13";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 04 part 2 sample 1" {
    const puzzle = try Day04().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "43";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
