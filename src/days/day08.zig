const std = @import("std");

pub const UnionFind = struct {
    parent: []usize,
    size: []usize,

    pub fn init(allocator: std.mem.Allocator, n: usize) !UnionFind {
        var parent = try allocator.alloc(usize, n);
        var size = try allocator.alloc(usize, n);

        for (0..n) |i| {
            parent[i] = i;
            size[i] = 1;
        }

        return UnionFind{
            .parent = parent,
            .size = size,
        };
    }

    pub fn deinit(self: *UnionFind, allocator: std.mem.Allocator) void {
        allocator.free(self.parent);
        allocator.free(self.size);
    }

    // Find with path compression
    pub fn find(self: *UnionFind, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.find(self.parent[x]);
        }
        return self.parent[x];
    }

    // Union by size, returns true if merged, false if already in same set
    pub fn join(self: *UnionFind, a: usize, b: usize) bool {
        const rootA = self.find(a);
        const rootB = self.find(b);
        if (rootA == rootB) return false;

        if (self.size[rootA] < self.size[rootB]) {
            self.parent[rootA] = rootB;
            self.size[rootB] += self.size[rootA];
        } else {
            self.parent[rootB] = rootA;
            self.size[rootA] += self.size[rootB];
        }
        return true;
    }
};

const Point3D = struct {
    x: u32,
    y: u32,
    z: u32,

    pub fn squaredDistance(a: Point3D, b: Point3D) u64 {
        const dx: i64 = @as(i64, a.x) - @as(i64, b.x);
        const dy: i64 = @as(i64, a.y) - @as(i64, b.y);
        const dz: i64 = @as(i64, a.z) - @as(i64, b.z);
        return @intCast(dx * dx + dy * dy + dz * dz);
    }
};

fn Day08() type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        points: []Point3D = undefined,
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
            self.points = try self.allocator.alloc(Point3D, line_count);
            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, input, '\n');
            var p: [3]u32 = .{ 0, 0, 0 };
            while (lexer.next()) |line| : (i += 1) {
                var lexer_line = std.mem.tokenizeScalar(u8, line, ',');
                var j: usize = 0;
                while (lexer_line.next()) |term| : (j += 1) {
                    p[j] = try std.fmt.parseInt(u32, term, 10);
                }
                self.points[i] = Point3D{ .x = p[0], .y = p[1], .z = p[2] };
            }
            return self;
        }
        const Pair = struct {
            distance: u64,
            index1: usize,
            index2: usize,
        };

        fn comparePairs(_: void, lhs: Pair, rhs: Pair) bool {
            if (lhs.distance != rhs.distance) return lhs.distance < rhs.distance;
            if (lhs.index1 != rhs.index1) return lhs.index1 < rhs.index1;
            return lhs.index2 < rhs.index2;
        }

        fn get_distances(self: Self) ![]Pair {
            const n = self.points.len;
            const m = n * (n - 1) / 2;
            var distances = try self.allocator.alloc(Pair, m);

            var di: usize = 0;
            for (0..n - 1) |i| {
                for (i + 1..n) |j| {
                    const d2 = Point3D.squaredDistance(self.points[i], self.points[j]);
                    distances[di] = Pair{ .distance = d2, .index1 = i, .index2 = j };
                    di += 1;
                }
            }
            std.mem.sortUnstable(Pair, distances, {}, Self.comparePairs);
            return distances;
        }

        // Part 1 solution.
        fn part1(self: Self, connections: usize) ![]const u8 {
            const n = self.points.len;
            const distances = try self.get_distances();
            defer self.allocator.free(distances);
            var uf = try UnionFind.init(self.allocator, n);
            defer uf.deinit(self.allocator);
            for (0..connections) |i| {
                _ = uf.join(distances[i].index1, distances[i].index2);
            }

            var sets = try self.allocator.alloc(usize, n);
            defer self.allocator.free(sets);
            for (0..n) |i| {
                if (uf.find(i) == i) {
                    sets[i] = uf.size[i];
                } else {
                    sets[i] = 0;
                }
            }
            var ans: u64 = 1;
            for (0..3) |_| {
                var mx: usize = 0;
                var mxi: usize = 0;
                for (0..n) |i| {
                    if (sets[i] > mx) {
                        mxi = i;
                        mx = sets[i];
                    }
                }
                ans *= mx;
                sets[mxi] = 0;
            }

            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }

        // Part 2 solution.
        fn part2(self: Self) ![]const u8 {
            var ans: u64 = 0;
            const n = self.points.len;
            const distances = try self.get_distances();
            defer self.allocator.free(distances);
            var uf = try UnionFind.init(self.allocator, n);
            defer uf.deinit(self.allocator);
            for (0..distances.len) |i| {
                const joined = uf.join(distances[i].index1, distances[i].index2);
                if (joined and uf.size[uf.find(distances[i].index1)] == n) {
                    ans = @as(u64, self.points[distances[i].index1].x) * @as(u64, self.points[distances[i].index2].x);
                    break;
                }
            }
            return try std.fmt.allocPrint(self.allocator, "{d}", .{ans});
        }
    };
}

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/day08.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = try Day08().init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = try puzzle.part1(1000);
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Day 08:\nPart 1: {s}\nPart 2: {s}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input = @embedFile("./sample-data/day08.txt");

// Unit tests for part 1.
test "day 08 part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = try Day08().init(sample_input);
    const result = try puzzle.part1(10);
    // Use expected result from puzzle description
    const expected_result = "40";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}

// Unit tests for part 2.
test "day 08 part 2 sample 1" {
    const puzzle = try Day08().init(sample_input);
    const result = try puzzle.part2();
    const expected_result = "25272";
    try std.testing.expectEqualSlices(u8, expected_result, result);
}
