const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn Day09() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        points: []Point2D = undefined,
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
            self.points = try self.allocator.alloc(Point2D, line_count);
            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, '\n');
            var p: [2]u32 = .{ 0, 0 };
            while (lexer.next()) |line| : (i += 1) {
                var lexer_line = std.mem.tokenizeScalar(u8, line, ',');
                var j: usize = 0;
                while (lexer_line.next()) |term| : (j += 1) {
                    p[j] = try std.fmt.parseInt(u32, term, 10);
                }
                self.points[i] = Point2D{ .x = p[0], .y = p[1] };
            }
            return self;
        }

        // Part 1 solution.
        fn part1(self: Self) ![]const u8 {
            var ans: u64 = 0;
            const n = self.points.len;
            for (0..n) |i| {
                for (i + 1..n) |j| {
                    const cur = area(self.points[i], self.points[j]);
                    if (cur > ans) {
                        ans = cur;
                    }
                }
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        fn pointOutsidePolygon(self: Self, p: Point2D) bool {
            const n = self.points.len;
            // in border
            for (0..n) |i| {
                const j = (i + 1) % n;
                const c1 = self.points[i];
                const c2 = self.points[j];
                if (c1.x == c2.x and c1.x == p.x) {
                    if (inBetweenEq(c1.y, c2.y, p.y)) {
                        return false;
                    }
                } else if (c1.y == c2.y and c1.y == p.y) {
                    if (inBetweenEq(c1.x, c2.x, p.x)) {
                        return false;
                    }
                }
            }

            var cc: usize = 0;
            const inf = Point2D{ .x = p.x, .y = 10000000 };
            for (0..n) |i| {
                const j = (i + 1) % n;
                const c1 = self.points[i];
                const c2 = self.points[j];
                // correctly counting edge intersections is the tricky part
                if (segmentIntersect(c1, c2, p, inf)) {
                    cc += 1;
                } else if (segmentIntersectAligned(c1, c2, p, inf)) {
                    if (oppositeSides(c1, c2, self.points[(i + n - 1) % n], self.points[(j + 1) % n])) {
                        cc += 1;
                    }
                }
            }
            return cc % 2 == 0;
        }

        fn segmentIntersectPolygon(self: Self, p1: Point2D, p2: Point2D) bool {
            const n = self.points.len;
            for (0..n) |i| {
                const j = (i + 1) % n;
                const c1 = self.points[i];
                const c2 = self.points[j];
                if (segmentIntersect(c1, c2, p1, p2)) {
                    return true;
                }
            }
            return false;
        }

        fn rectangleInsidePolygon(self: Self, p1: Point2D, p2: Point2D) bool {
            const xx: [2]u32 = .{ p1.x, p2.x };
            const yy: [2]u32 = .{ p1.y, p2.y };

            for (0..2) |x| {
                for (0..2) |y| {
                    if (self.pointOutsidePolygon(Point2D{ .x = xx[x], .y = yy[y] })) {
                        return false;
                    }
                    if (x == 0 and self.segmentIntersectPolygon(Point2D{ .x = xx[x], .y = yy[y] }, Point2D{ .x = xx[x + 1], .y = yy[y] })) {
                        return false;
                    }
                    if (y == 0 and self.segmentIntersectPolygon(Point2D{ .x = xx[x], .y = yy[y] }, Point2D{ .x = xx[x], .y = yy[y + 1] })) {
                        return false;
                    }
                }
            }
            return true;
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u64 = 0;
            const n = self.points.len;
            for (0..n) |i| {
                for (i + 1..n) |j| {
                    const cur = area(self.points[i], self.points[j]);
                    if (cur > ans and self.rectangleInsidePolygon(self.points[i], self.points[j])) {
                        ans = cur;
                    }
                }
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

const Point2D = struct {
    x: u32,
    y: u32,
};

fn abs(a: i64) u64 {
    if (a < 0) {
        return @intCast(-a);
    } else {
        return @intCast(a);
    }
}

fn area(a: Point2D, b: Point2D) u64 {
    const dx: i64 = @as(i64, a.x) - @as(i64, b.x);
    const dy: i64 = @as(i64, a.y) - @as(i64, b.y);
    return (abs(dx) + 1) * (abs(dy) + 1);
}

fn inBetween(p1: u32, p2: u32, p: u32) bool {
    if (p1 < p and p < p2) return true;
    if (p2 < p and p < p1) return true;
    return false;
}

fn inBetweenEq(p1: u32, p2: u32, p: u32) bool {
    if (p1 <= p and p <= p2) return true;
    if (p2 <= p and p <= p1) return true;
    return false;
}

fn segmentIntersect(c1: Point2D, c2: Point2D, p1: Point2D, p2: Point2D) bool {
    if (c1.x == c2.x and p1.y == p2.y) {
        if (inBetween(c1.y, c2.y, p1.y) and inBetween(p1.x, p2.x, c1.x)) {
            return true;
        }
    } else if (c1.y == c2.y and p1.x == p2.x) {
        if (inBetween(c1.x, c2.x, p1.x) and inBetween(p1.y, p2.y, c1.y)) {
            return true;
        }
    }
    return false;
}

fn oppositeSides(c1: Point2D, c2: Point2D, p1: Point2D, p2: Point2D) bool {
    if (c1.x == c2.x) {
        return inBetween(p1.x, p2.x, c1.x);
    } else if (c1.y == c2.y) {
        return inBetween(p1.y, p2.y, c1.y);
    }
    // should never happen
    return false;
}
fn segmentIntersectAligned(c1: Point2D, c2: Point2D, p1: Point2D, p2: Point2D) bool {
    if (c1.x == c2.x and p1.x == p2.x and c1.x == p1.x) {
        return inBetweenEq(c1.y, c2.y, p1.y) or inBetweenEq(c1.y, c2.y, p2.y) or inBetweenEq(p1.y, p2.y, c1.y) or inBetweenEq(p1.y, p2.y, c2.y);
    } else if (c1.y == c2.y and p1.y == p2.y and c1.y == p1.y) {
        return inBetweenEq(c1.x, c2.x, p1.x) or inBetweenEq(c1.x, c2.x, p2.x) or inBetweenEq(p1.x, p2.x, c1.x) or inBetweenEq(p1.x, p2.x, c2.x);
    }
    return false;
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day09.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day09().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 09:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day09.txt");

// Unit tests for part 1.
test "day 09 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day09().init(sample_input);
    const result = try puzzle.part1();
    // Use expected result from puzzle description
    const expected_result = "50";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 09 part 2 sample 1" {
    const puzzle = try Day09().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "24";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
