const std = @import("std");

const ParseError = error{ IdentifierToLong, NoSuchIdentifier };

fn try_parse_ident(ident: []const u8) []const u8 {
    switch (ident) {}
}

pub fn parse_to_human_readable(input: []const u8) !std.mem.Buffer {
    var out = std.mem.Buffer.init(input.len);

    var specialBuffer: [10]u8 = u8{};
    var specialBufferP: usize = 0;
    var control = false;
    for (input) |char| {
        switch (char) {
            '\\' => {
                control = true;
            },
            else => {
                if (control) {
                    specialBuffer[specialBufferP] = char;
                    specialBufferP += 1;
                    if (specialBufferP >= 9) {
                        return ParseError.IdentifierToLong;
                    }
                }
            },
        }
    }

    return out;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
