const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day03() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        words: [][]const u8 = undefined,
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
            self.words = try self.allocator.alloc([]const u8, line_count);
            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, '\n');

            while (lexer.next()) |line| : (i += 1) {
                self.words[i] = line;
            }
            return self;
        }

        fn find_best(word: []const u8) u32 {
            const n = word.len;

            var mx1: usize = 0;
            for (0..n - 1) |i| {
                if (word[mx1] < word[i]) {
                    mx1 = i;
                }
            }
            var mx2 = n - 1;
            for (mx1 + 1..n) |i| {
                if (word[mx2] < word[i]) {
                    mx2 = i;
                }
            }
            return (word[mx1] - '0') * 10 + (word[mx2] - '0');
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            var ans: u32 = 0;
            for (0..self.words.len) |i| {
                const word = self.words[i];
                const cur = Self.find_best(word);
                ans += cur;
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        fn find_best2(self: Self, word: []const u8, k: usize) u64 {
            const n = word.len;
            var mx = self.allocator.alloc(usize, k) catch {
                std.debug.panic("Out of memory allocating words", .{});
            };
            defer self.allocator.free(mx);
            for (0..k) |d| {
                mx[d] = 0;
                if (d > 0) {
                    mx[d] = mx[d - 1] + 1;
                }
                for (mx[d] + 1..n - (k - d - 1)) |i| {
                    if (word[mx[d]] < word[i]) {
                        mx[d] = i;
                    }
                }
            }
            var ans: u64 = 0;
            for (0..k) |d| {
                ans = ans * 10 + (word[mx[d]] - '0');
            }
            return ans;
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u64 = 0;
            for (0..self.words.len) |i| {
                const word = self.words[i];
                const cur = self.find_best2(word, 12);
                ans += cur;
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day03.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day03().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 03:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day03.txt");

// Unit tests for part 1.
test "day 03 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day03().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "357";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 03 part 2 sample 1" {
    const puzzle = try Day03().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "3121910778619";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
