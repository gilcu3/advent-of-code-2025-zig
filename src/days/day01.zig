const std = @import("std");

fn Day01() type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator = std.heap.page_allocator,

        steps: []u32 = undefined,
        ops: []u8 = undefined,

        fn init(input: []const u8) !Self {
            var self = Self{};

            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            var line_count: usize = 0;
            while (lexer.next()) |_| {
                line_count += 1;
            }

            self.ops = try self.allocator.alloc(u8, line_count);
            self.steps = try self.allocator.alloc(u32, line_count);

            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, '\n');

            while (lexer.next()) |line| : (i += 1) {
                self.ops[i] = line[0];
                self.steps[i] = try std.fmt.parseInt(u32, line[1..], 10);
            }

            return self;
        }

        fn part1(self: *Self) ![]const u8 {
            var ans: u64 = 0;
            var cur: u64 = 50;
            for (0..self.ops.len) |i| {
                if (self.ops[i] == 'L') {
                    cur = (cur + 100 - self.steps[i] % 100) % 100;
                } else {
                    cur = (cur + self.steps[i]) % 100;
                }
                if (cur == 0) {
                    ans += 1;
                }
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        fn part2(self: *Self) ![]const u8 {
            var ans: u64 = 0;
            var cur: u64 = 50;
            for (0..self.ops.len) |i| {
                var times: u64 = self.steps[i] / 100;
                const oldcur = cur;
                if (self.ops[i] == 'L') {
                    cur = (cur + 100 - self.steps[i] % 100) % 100;
                    if ((oldcur < cur and oldcur != 0) or cur == 0) {
                        times += 1;
                    }
                } else {
                    cur = (cur + self.steps[i]) % 100;
                    if (oldcur > cur) {
                        times += 1;
                    }
                }
                ans += times;
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day01.txt");
    var puzzle = try Day01().init(input);
    const time0 = timer.read();

    const result1 = try puzzle.part1();
    const time1 = timer.read();

    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }
    return .{ time0, time1, time2 };
}

const sample_input = @embedFile("./sample-data/day01.txt");

test "day 01 part 1 sample 1" {
    var puzzle = try Day01().init(sample_input);
    const result = try puzzle.part1();
    const expected_result = "3";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

test "day 01 part 2 sample 1" {
    var puzzle = try Day01().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "6";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
