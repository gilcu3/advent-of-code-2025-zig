const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    const results_path = args[1];

    const benchmark_output = try std.fs.cwd().readFileAlloc(allocator, results_path, std.math.maxInt(usize));

    const readme_path = "README.md";
    const readme_file = try std.fs.cwd().openFile(readme_path, .{ .mode = .read_write });
    defer readme_file.close();

    const readme_content = try readme_file.readToEndAlloc(allocator, std.math.maxInt(usize));

    const marker = "<!--- benchmarking table --->";

    const start_idx = mem.indexOf(u8, readme_content, marker) orelse {
        std.log.err("Could not find start marker '{s}'", .{marker});
        return;
    };

    const insert_pos = start_idx + marker.len;

    const end_idx = mem.indexOfPos(u8, readme_content, insert_pos, marker) orelse {
        std.log.err("Could not find end marker '{s}'", .{marker});
        return;
    };

    var new_readme = std.ArrayList(u8).init(allocator);
    defer new_readme.deinit();

    try new_readme.appendSlice(readme_content[0..insert_pos]);

    try new_readme.appendSlice("\n\n");
    try new_readme.appendSlice(benchmark_output);
    try new_readme.appendSlice("\n");

    try new_readme.appendSlice(readme_content[end_idx..]);

    try readme_file.seekTo(0);
    try readme_file.setEndPos(0);
    try readme_file.writeAll(new_readme.items);

    std.debug.print("Successfully updated README.md with benchmarks\n", .{});
}
