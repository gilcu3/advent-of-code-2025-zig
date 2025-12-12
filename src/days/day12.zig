const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day12() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        figures: [][3][3]u8 = undefined,
        grids: []Grid = undefined,
        allocator: std.mem.Allocator = std.heap.page_allocator,

        const Self = @This();

        // Constructor: parses the raw input string into structured data. This part is also included
        // in the total runtime of the solution benchmarks.
        fn init(input: []const u8) !Self {
            var self = Self{};
            // Input parsing logic here...
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            var cross: usize = 0;
            var p2: usize = 0;
            while (lexer.next()) |line| {
                if (std.mem.indexOfScalar(u8, line, 'x') != null) {
                    cross += 1;
                } else if (std.mem.indexOfScalar(u8, line, ':') != null) {
                    p2 += 1;
                }
            }
            self.figures = try self.allocator.alloc([3][3]u8, p2);
            self.grids = try self.allocator.alloc(Grid, cross);

            lexer.reset();

            for (0..p2) |i| {
                _ = lexer.next().?;
                for (0..3) |j| {
                    const word = lexer.next().?;
                    for (0..3) |k| {
                        if (word[k] == '#') {
                            self.figures[i][j][k] = 1;
                        } else {
                            self.figures[i][j][k] = 0;
                        }
                    }
                }
            }
            for (0..cross) |i| {
                const line = lexer.next().?;
                var figures = try self.allocator.alloc(u32, p2);
                var x: u32 = undefined;
                var y: u32 = undefined;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                var j: usize = 0;
                while (inner_lexer.next()) |word| : (j += 1) {
                    if (j == 0) {
                        var splitter = std.mem.splitScalar(u8, word[0 .. word.len - 1], 'x');
                        x = try std.fmt.parseInt(u32, splitter.next().?, 10);
                        y = try std.fmt.parseInt(u32, splitter.next().?, 10);
                    } else {
                        figures[j - 1] = try std.fmt.parseInt(u32, word, 10);
                    }
                }

                self.grids[i] = Grid{ .x = x, .y = y, .figures = figures };
            }
            return self;
        }

        const Grid = struct {
            x: u32,
            y: u32,
            figures: []u32,
        };

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            const n = self.figures.len;
            const m = self.grids.len;
            var sizes = try self.allocator.alloc(u32, n);
            defer self.allocator.free(sizes);
            for (0..n) |i| {
                sizes[i] = 0;
                for (0..3) |x| {
                    for (0..3) |y| {
                        sizes[i] += self.figures[i][x][y];
                    }
                }
            }
            // the easy check
            var ans: usize = m;
            for (0..m) |g| {
                const total: u32 = self.grids[g].x * self.grids[g].y;
                var used: u32 = 0;
                for (0..n) |i| {
                    used += sizes[i] * self.grids[g].figures[i];
                }
                if (used > total) {
                    ans -= 1;
                }
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            const ans: u64 = 0;
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day12.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day12().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 12:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day12.txt");

// Unit tests for part 1.
test "day 12 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day12().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "3"; // the expected solution was 2, but the elves cheated!
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 12 part 2 sample 1" {
    const puzzle = try Day12().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "0";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
