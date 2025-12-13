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

        fn calcGcd(a: i64, b: i64) i64 {
            return @intCast(std.math.gcd(@abs(a), @abs(b)));
        }

        fn calcLcm(a: i64, b: i64) i64 {
            if (a == 0 or b == 0) return 0;
            const g = calcGcd(a, b);
            return @divExact(a, g) * b;
        }

        fn simplifyRow(row: []i64) !void {
            var common_divisor: i64 = 0;

            for (row) |val| {
                if (val == 0) continue;
                if (common_divisor == 0) {
                    common_divisor = val;
                } else {
                    common_divisor = calcGcd(common_divisor, val);
                }
            }

            if (common_divisor > 1) {
                for (0..row.len) |i| {
                    row[i] = @divExact(row[i], common_divisor);
                }
            }
        }

        fn rec3(i: usize, n: usize, m: usize, matrix: [][]i64, top: []u32, cur: u32, best: u32) u32 {
            if (i == m) {
                var nbest = cur;
                for (0..n) |j| {
                    if (matrix[j][j] == 0) {
                        break;
                    }
                    if (@mod(matrix[j][m], matrix[j][j]) != 0) return best;
                    const v = @divExact(matrix[j][m], matrix[j][j]);
                    if (v < 0 or v > top[j])
                        return best;
                    nbest += @intCast(v);
                    if (nbest >= best) return best;
                }
                return nbest;
            }

            var nbest: u32 = best;
            for (0..top[i] + 1) |v| {
                if (cur + v >= best) break;
                for (0..n) |j| {
                    matrix[j][m] -= matrix[j][i] * @as(i64, @intCast(v));
                }
                const ans = Self.rec3(i + 1, n, m, matrix, top, cur + @as(u32, @intCast(v)), nbest);
                if (ans < nbest) {
                    nbest = ans;
                }
                for (0..n) |j| {
                    matrix[j][m] += matrix[j][i] * @as(i64, @intCast(v));
                }
            }

            return nbest;
        }

        fn solve2(self: Self, eqs: [][]u32, results: []i32) !u32 {
            const n = results.len;
            const m = eqs.len;
            var matrix: [][]i64 = try self.allocator.alloc([]i64, n);

            var top: []u32 = try self.allocator.alloc(u32, m);

            for (0..m) |i| {
                top[i] = 10000000;
                for (eqs[i]) |a| {
                    top[i] = @min(top[i], @as(u32, @intCast(results[a])));
                }
            }

            for (0..n) |i| {
                matrix[i] = try self.allocator.alloc(i64, m + 1);
                for (0..m) |j| {
                    matrix[i][j] = 0;
                }
                matrix[i][m] = results[i];
            }
            for (0..m) |i| {
                for (eqs[i]) |a| {
                    matrix[a][i] = 1;
                }
            }

            const aug_width = m + 1;

            var used_rows: usize = n;
            for (0..n) |pivot_idx| {
                var pivot_row: usize = undefined;
                var pivot_column: usize = undefined;
                var finished = true;
                for (pivot_idx..n) |x| {
                    for (pivot_idx..m) |y| {
                        if (matrix[x][y] != 0) {
                            pivot_row = x;
                            pivot_column = y;
                            finished = false;
                            break;
                        }
                    }
                    if (!finished) break;
                }
                if (finished) {
                    used_rows = pivot_idx;
                    break;
                }

                if (pivot_column != pivot_idx) {
                    for (0..n) |r| {
                        const temp = matrix[r][pivot_idx];
                        matrix[r][pivot_idx] = matrix[r][pivot_column];
                        matrix[r][pivot_column] = temp;
                    }
                    const temp = top[pivot_idx];
                    top[pivot_idx] = top[pivot_column];
                    top[pivot_column] = temp;
                }

                if (pivot_row != pivot_idx) {
                    for (0..aug_width) |c| {
                        const temp = matrix[pivot_idx][c];
                        matrix[pivot_idx][c] = matrix[pivot_row][c];
                        matrix[pivot_row][c] = temp;
                    }
                }

                var pivot_val = matrix[pivot_idx][pivot_idx];
                if (pivot_val < 0) {
                    for (0..m + 1) |j| {
                        matrix[pivot_idx][j] *= -1;
                    }
                    pivot_val *= -1;
                }

                for (0..n) |target_row| {
                    if (target_row == pivot_idx) continue;

                    const target_val = matrix[target_row][pivot_idx];
                    if (target_val == 0) continue;

                    const common_multiple = calcLcm(pivot_val, target_val);
                    const pivot_mult = @divExact(common_multiple, pivot_val);
                    const target_mult = @divExact(common_multiple, target_val);

                    for (0..aug_width) |c| {
                        const val_t = matrix[target_row][c];
                        const val_p = matrix[pivot_idx][c];
                        matrix[target_row][c] = (val_t * target_mult) - (val_p * pivot_mult);
                    }

                    try simplifyRow(matrix[target_row]);
                }
            }

            const ans = Self.rec3(used_rows, n, m, matrix, top, 0, 10000000);

            defer self.allocator.free(matrix);
            for (0..n) |i| {
                defer self.allocator.free(matrix[i]);
            }

            return ans;
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u32 = 0;
            for (0..self.light.len) |t| {
                const cur = try self.solve2(self.switches[t], self.jolts[t]);

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
