const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day11() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        edges: [][][]const u8 = undefined,
        nodes: [][]const u8 = undefined,
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
            self.nodes = try self.allocator.alloc([]const u8, line_count);
            self.edges = try self.allocator.alloc([][]const u8, line_count);
            var i: usize = 0;
            lexer.reset();

            while (lexer.next()) |line| : (i += 1) {
                var line_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                var j: usize = 0;
                var degree: usize = 0;
                while (line_lexer.next()) |_| {
                    degree += 1;
                }
                degree -= 1;
                line_lexer.reset();
                self.edges[i] = try self.allocator.alloc([]const u8, degree);
                while (line_lexer.next()) |word| : (j += 1) {
                    if (j == 0) {
                        self.nodes[i] = word[0 .. word.len - 1];
                    } else {
                        self.edges[i][j - 1] = word;
                    }
                }
            }
            return self;
        }

        fn bfs_count(self: Self, n: usize, edges: [][]usize, start: usize, end: usize) !u64 {
            var queue = try self.allocator.alloc(usize, n);
            defer self.allocator.free(queue);

            var dp = try self.allocator.alloc(u64, n);
            defer self.allocator.free(dp);

            var seen = try self.allocator.alloc(bool, n);
            defer self.allocator.free(seen);

            var degree = try self.allocator.alloc(usize, n);
            defer self.allocator.free(degree);

            for (0..n) |i| {
                degree[i] = 0;
                dp[i] = 0;
                seen[i] = false;
            }
            dp[start] = 1;

            var front: usize = 0;
            var back: usize = 0;
            queue[back] = start;
            back += 1;

            while (front < back) {
                const cur = queue[front];
                front += 1;
                if (cur < edges.len) {
                    for (edges[cur]) |a| {
                        degree[a] += 1;
                        if (!seen[a]) {
                            seen[a] = true;
                            queue[back] = a;
                            back += 1;
                        }
                    }
                }
            }

            front = 0;
            back = 0;
            queue[back] = start;
            back += 1;

            while (front < back) {
                const cur = queue[front];
                front += 1;
                if (cur == end) {
                    break;
                }
                if (cur < edges.len) {
                    for (edges[cur]) |a| {
                        dp[a] += dp[cur];
                        degree[a] -= 1;
                        if (degree[a] == 0) {
                            queue[back] = a;
                            back += 1;
                        }
                    }
                }
            }
            // std.debug.print("{} {} {any}\n", .{ start, end, dp });
            return dp[end];
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            var map = std.StringHashMap(usize).init(self.allocator);
            const n = self.nodes.len;
            var idx: usize = 0;
            var start: usize = undefined;
            var end: usize = undefined;
            for (0..n) |i| {
                if (std.mem.eql(u8, self.nodes[i], "you")) {
                    start = idx;
                }
                if (std.mem.eql(u8, self.nodes[i], "out")) {
                    end = idx;
                }
                try map.put(self.nodes[i], idx);
                idx += 1;
            }
            for (0..n) |i| {
                for (0..self.edges[i].len) |j| {
                    if (map.get(self.edges[i][j]) == null) {
                        if (std.mem.eql(u8, self.edges[i][j], "out")) {
                            end = idx;
                        }
                        try map.put(self.edges[i][j], idx);
                        idx += 1;
                    }
                }
            }

            var edges = try self.allocator.alloc([]usize, self.edges.len);
            defer self.allocator.free(edges);
            for (0..n) |i| {
                edges[i] = try self.allocator.alloc(usize, self.edges[i].len);

                for (0..self.edges[i].len) |j| {
                    edges[i][j] = map.get(self.edges[i][j]).?;
                }
            }
            const ans: u64 = try self.bfs_count(idx, edges, start, end);
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var map = std.StringHashMap(usize).init(self.allocator);
            const n = self.nodes.len;
            var idx: usize = 0;
            var svr: usize = undefined;
            var out: usize = undefined;
            var dac: usize = undefined;
            var fft: usize = undefined;
            for (0..n) |i| {
                if (std.mem.eql(u8, self.nodes[i], "svr")) {
                    svr = idx;
                }
                if (std.mem.eql(u8, self.nodes[i], "out")) {
                    out = idx;
                }
                if (std.mem.eql(u8, self.nodes[i], "dac")) {
                    dac = idx;
                }
                if (std.mem.eql(u8, self.nodes[i], "fft")) {
                    fft = idx;
                }
                try map.put(self.nodes[i], idx);
                idx += 1;
            }
            for (0..n) |i| {
                for (0..self.edges[i].len) |j| {
                    if (map.get(self.edges[i][j]) == null) {
                        if (std.mem.eql(u8, self.edges[i][j], "out")) {
                            out = idx;
                        }
                        if (std.mem.eql(u8, self.edges[i][j], "dac")) {
                            dac = idx;
                        }
                        if (std.mem.eql(u8, self.edges[i][j], "fft")) {
                            fft = idx;
                        }
                        try map.put(self.edges[i][j], idx);
                        idx += 1;
                    }
                }
            }

            var edges = try self.allocator.alloc([]usize, self.edges.len);
            defer self.allocator.free(edges);
            for (0..n) |i| {
                edges[i] = try self.allocator.alloc(usize, self.edges[i].len);

                for (0..self.edges[i].len) |j| {
                    edges[i][j] = map.get(self.edges[i][j]).?;
                }
            }
            var ans: u64 = 0;
            ans += try self.bfs_count(idx, edges, svr, dac) * try self.bfs_count(idx, edges, dac, fft) * try self.bfs_count(idx, edges, fft, out);
            ans += try self.bfs_count(idx, edges, svr, fft) * try self.bfs_count(idx, edges, fft, dac) * try self.bfs_count(idx, edges, dac, out);
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day11.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day11().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 11:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input1 = @embedFile("./sample-data/day11-1.txt");

// Unit tests for part 1.
test "day 11 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day11().init(sample_input1);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "5";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

const sample_input2 = @embedFile("./sample-data/day11-2.txt");

// Unit tests for part 2.
test "day 11 part 2 sample 2" {
    const puzzle = try Day11().init(sample_input2);
    const result = try puzzle.part2();
    const expected_result = "2";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
