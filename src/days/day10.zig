const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day10() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        light: [][]u8 = undefined,
        switches: [][][]u32 = undefined,
        jolts: [][]i32 = undefined,
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
            self.light = try self.allocator.alloc([]u8, line_count);
            self.switches = try self.allocator.alloc([][]u32, line_count);
            self.jolts = try self.allocator.alloc([]u32, line_count);

            var i: usize = 0;
            lexer.reset();

            while (lexer.next()) |line| : (i += 1) {
                var line_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                var swn: usize = 0;
                while (line_lexer.next()) |_| {
                    swn += 1;
                }
                line_lexer.reset();
                self.switches[i] = try self.allocator.alloc([]u32, swn - 2);
                var j: usize = 0;
                while (line_lexer.next()) |word| : (j += 1) {
                    if (j == 0) {
                        self.light[i] = try self.allocator.alloc(u8, word.len - 2);
                        for (1..word.len - 1) |k| {
                            self.light[i][k - 1] = word[k];
                        }
                    } else if (word[0] == '{') {
                        var inner_lexer = std.mem.tokenizeScalar(u8, word[1 .. word.len - 1], ',');

                        self.jolts[i] = try self.allocator.alloc(i32, self.light[i].len);
                        var k: usize = 0;
                        while (inner_lexer.next()) |sw| : (k += 1) {
                            self.jolts[i][k] = try std.fmt.parseInt(i32, sw, 10);
                        }
                    } else {
                        var inner_lexer = std.mem.tokenizeScalar(u8, word[1 .. word.len - 1], ',');
                        var switch_count: usize = 0;
                        while (inner_lexer.next()) |_| {
                            switch_count += 1;
                        }
                        self.switches[i][j - 1] = try self.allocator.alloc(u32, switch_count);

                        inner_lexer.reset();
                        var k: usize = 0;
                        while (inner_lexer.next()) |sw| : (k += 1) {
                            self.switches[i][j - 1][k] = try std.fmt.parseInt(u32, sw, 10);
                        }
                    }
                }
            }
            for (0..self.light.len) |ii| {
                for (0..self.light[ii].len) |j| {
                    if (self.light[ii][j] == '#') {
                        self.light[ii][j] = 1;
                    } else {
                        self.light[ii][j] = 0;
                    }
                }
            }
            return self;
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            var ans: u32 = 0;

            for (0..self.light.len) |t| {
                const n = self.switches[t].len;
                const k = self.light[t].len;
                const total = @as(u32, 1) << @intCast(n);
                var light = try self.allocator.alloc(u8, k);
                defer self.allocator.free(light);
                var cur: u32 = 1000000;
                for (0..total) |mask| {
                    for (0..k) |i| {
                        light[i] = self.light[t][i];
                    }
                    var s: u32 = 0;
                    for (0..n) |i| {
                        if (((@as(u32, 1) << @intCast(i)) & mask) != 0) {
                            s += 1;
                            for (self.switches[t][i]) |a| {
                                light[a] = 1 - light[a];
                            }
                        }
                    }
                    var good = true;
                    for (0..k) |i| {
                        if (light[i] != 0) {
                            good = false;
                            break;
                        }
                    }
                    if (good and cur > s) {
                        cur = s;
                    }
                }
                ans += cur;
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        fn binpos(eqs: [][]u32, results: []i32, ii: usize) bool {
            const n = eqs.len - ii;
            const total = @as(u32, 1) << @intCast(n);
            const k = results.len;
            var tmp: [20]u32 = .{0} ** 20;
            for (0..total) |mask| {
                for (0..k) |i| {
                    tmp[i] = @as(u32, @intCast(results[i])) % 2;
                }
                for (0..n) |i| {
                    if (((@as(u32, 1) << @intCast(i)) & mask) != 0) {
                        for (eqs[i + ii]) |a| {
                            tmp[a] = 1 - tmp[a];
                        }
                    }
                }
                var good = true;
                for (0..k) |i| {
                    if (tmp[i] != 0) {
                        good = false;
                        break;
                    }
                }
                if (good) {
                    return true;
                }
            }
            return false;
        }

        fn rec(self: Self, eqs: [][]u32, results: []i32, degree: []usize, i: usize, current: u32, best: u32) u32 {
            if (current > best) {
                return best;
            }

            var sum: u32 = 0;

            var mx: u32 = 0;

            for (results) |a| {
                sum += @intCast(a);
                mx = @max(mx, @as(u32, @intCast(a)));
            }
            if (current + mx > best) {
                return best;
            }

            if (sum == 0) {
                return current;
            }

            if (i == eqs.len) {
                return best;
            }
            for (0..results.len) |j| {
                if (results[j] > 0 and degree[j] == 0)
                    return best;
            }

            if (!Self.binpos(eqs, results, i)) {
                return best;
            }

            var deg1 = false;
            var val: u32 = 0;
            for (eqs[i]) |a| {
                if (degree[a] == 1) {
                    if (deg1 and val != results[a]) {
                        return best;
                    }
                    deg1 = true;
                    val = @intCast(results[a]);
                }
            }
            var cbest = best;
            var a0: usize = 0;
            var b0: usize = sum;
            if (deg1) {
                a0 = val;
                b0 = val;
            }

            for (a0..b0 + 1) |t| {
                var poss = true;
                for (eqs[i]) |a| {
                    results[a] -= @intCast(t);
                    degree[a] -= 1;
                    if (results[a] < 0) {
                        poss = false;
                    }
                }
                if (poss) {
                    const cur = self.rec(eqs, results, degree, i + 1, current + @as(u32, @intCast(t)), cbest);
                    if (cur < cbest) {
                        cbest = cur;
                    }
                }

                for (eqs[i]) |a| {
                    results[a] += @intCast(t);
                    degree[a] += 1;
                }
                if (!poss) break;
            }

            return cbest;
        }

        fn compareRanges(_: void, lhs: []u32, rhs: []u32) bool {
            if (lhs.len != rhs.len) {
                return lhs.len > rhs.len;
            }
            for (0..lhs.len) |i| {
                if (lhs[i] != rhs[i]) {
                    return lhs[i] < rhs[i];
                }
            }
            return false;
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u32 = 0;

            var degree = try self.allocator.alloc(usize, 20);
            defer self.allocator.free(degree);

            for (0..self.light.len) |t| {
                const k = self.light[t].len;

                for (0..k) |i| {
                    degree[i] = 0;
                }
                for (0..self.switches[t].len) |i| {
                    std.mem.sortUnstable(u32, self.switches[t][i], {}, std.sort.asc(u32));
                    for (self.switches[t][i]) |a| {
                        degree[a] += 1;
                    }
                }
                std.mem.sortUnstable([]u32, self.switches[t], {}, Self.compareRanges);

                var timer = try std.time.Timer.start();
                const cur = rec(self, self.switches[t], self.jolts[t], degree, 0, 0, 1000000);
                const time0 = @as(f64, @floatFromInt(timer.read())) / 1000000000;
                if (time0 > 1) {
                    std.debug.print("#{d}\nswitches: {d}\njolts: {any}\n", .{ t, k, self.jolts[t] });
                    for (0..self.switches[t].len) |i| {
                        std.debug.print("{any}\n", .{self.switches[t][i]});
                    }
                    std.debug.print("{d} {d}\n", .{ time0, cur });
                }

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
    const input = @embedFile("./data/day10.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day10().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 10:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day10.txt");

// Unit tests for part 1.
test "day 10 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day10().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "7";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 10 part 2 sample 1" {
    const puzzle = try Day10().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "33";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
