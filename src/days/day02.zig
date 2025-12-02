const std = @import("std");

fn Day02() type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator = std.heap.page_allocator,

        left: []u64 = undefined,
        right: []u64 = undefined,

        fn init(input: []const u8) !Self {
            var self = Self{};

            var lexer = std.mem.tokenizeScalar(u8, input, ',');
            var line_count: usize = 0;
            while (lexer.next()) |_| {
                line_count += 1;
            }

            self.left = try self.allocator.alloc(u64, line_count);
            self.right = try self.allocator.alloc(u64, line_count);

            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, ',');

            while (lexer.next()) |line| : (i += 1) {
                var lexer_i = std.mem.tokenizeScalar(u8, line, '-');
                self.left[i] = try std.fmt.parseInt(u64, lexer_i.next().?, 10);

                self.right[i] = try std.fmt.parseInt(u64, lexer_i.next().?, 10);
            }

            return self;
        }

        fn is_palindrome(self: *Self, n: u64) bool {
            const digits = std.fmt.allocPrint(self.allocator, "{d}", .{n}) catch unreachable;
            defer self.allocator.free(digits);
            if (digits.len % 2 == 0) {
                const k = digits.len / 2;
                for (0..k) |i| {
                    if (digits[i] != digits[i + k]) {
                        return false;
                    }
                }
                return true;
            } else {
                return false;
            }
        }

        fn part1(self: *Self) []const u8 {
            var ans: u64 = 0;
            for (0..self.left.len) |i| {
                const ini = self.left[i];
                const end = self.right[i];
                for (ini..end + 1) |a| {
                    if (self.is_palindrome(a)) {
                        ans += a;
                    }
                }
            }

            return std.fmt.allocPrint(self.allocator, "{d}", .{ans}) catch unreachable;
        }

        fn is_invalid(self: *Self, n: u64) bool {
            const digits = std.fmt.allocPrint(self.allocator, "{d}", .{n}) catch unreachable;
            defer self.allocator.free(digits);
            for (1..digits.len / 2 + 1) |d| {
                if (digits.len % d == 0) {
                    var found = true;
                    for (0..digits.len - d) |i| {
                        if (digits[i] != digits[i + d]) {
                            found = false;
                            break;
                        }
                    }
                    if (found) {
                        return true;
                    }
                }
            }
            return false;
        }

        fn part2(self: *Self) []const u8 {
            var ans: u64 = 0;
            for (0..self.left.len) |i| {
                const ini = self.left[i];
                const end = self.right[i];
                for (ini..end + 1) |a| {
                    if (self.is_invalid(a)) {
                        ans += a;
                    }
                }
            }

            return std.fmt.allocPrint(self.allocator, "{d}", .{ans}) catch unreachable;
        }
    };
}

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day02.txt");
    var puzzle = try Day02().init(input);
    const time0 = timer.read();

    const result1 = puzzle.part1();
    const time1 = timer.read();

    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }
    return .{ time0, time1, time2 };
}

const sample_input = @embedFile("./sample-data/day02.txt");

test "day 01 part 1 sample 1" {
    var puzzle = try Day02().init(sample_input);
    const result = puzzle.part1();
    const expected_result = "1227775554";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

test "day 01 part 2 sample 1" {
    var puzzle = try Day02().init(sample_input);
    const result = puzzle.part2();
    const expected_result = "4174379265";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
