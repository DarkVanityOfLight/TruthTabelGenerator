const std = @import("std");

const ParseError = error{ IdentifierToLong, NoSuchIdentifier };

fn isKeyword(identifier: []const u8, keyword: []const u8) bool {
    return std.mem.eql(u8, identifier, keyword);
}

test "isKeyword" {
    try std.testing.expect(isKeyword("neg", "neg"));
    try std.testing.expect(!isKeyword("lor", "land"));
}

fn parse_ident(ident: []const u8) ![]const u8 {
    if (isKeyword(ident, "neg")) {
        return "NOT";
    } else if (isKeyword(ident, "lor")) {
        return "OR";
    } else if (isKeyword(ident, "land")) {
        return "AND";
    } else if (isKeyword(ident, "rightarrow") or isKeyword(ident, "implies")) {
        return "IMPLIES";
    } else {
        return ParseError.NoSuchIdentifier;
    }
}

test "parse_ident" {
    try std.testing.expect(std.mem.eql(u8, try parse_ident("neg"), "NOT"));
    try std.testing.expect(std.mem.eql(u8, try parse_ident("lor"), "OR"));
    try std.testing.expect(std.mem.eql(u8, try parse_ident("land"), "AND"));
    try std.testing.expect(std.mem.eql(u8, try parse_ident("rightarrow"), "IMPLIES"));
    try std.testing.expect(std.mem.eql(u8, try parse_ident("implies"), "IMPLIES"));
    try std.testing.expect(ParseError.NoSuchIdentifier == parse_ident("foo"));
}

pub fn parse_to_human_readable(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var builder = std.ArrayList(u8).init(allocator);

    var specialBuffer: [10]u8 = undefined;
    var specialBufferP: usize = 0;
    var control = false;
    for (input) |char| {
        switch (char) {
            '\\' => {
                control = true;
            },
            else => {
                if (control) {
                    if (specialBufferP > 9) {
                        return ParseError.IdentifierToLong;
                    }

                    specialBuffer[specialBufferP] = char;
                    specialBufferP += 1;

                    const readableident = parse_ident(specialBuffer[0..specialBufferP]);

                    if (readableident) |rident| {
                        for (rident) |c| {
                            try builder.append(c);
                        }
                        specialBufferP = 0;
                        control = false;
                    } else |err| switch (err) {
                        ParseError.NoSuchIdentifier => |e| {
                            std.debug.print("Error: {}\n", .{e});
                        },
                        else => unreachable,
                    }
                } else {
                    try builder.append(char);
                }
            },
        }
    }

    return builder.toOwnedSlice();
}

test "parse to parse_to_human_readable" {
    const alloc = std.testing.allocator;
    const readable = try parse_to_human_readable(alloc, "a \\rightarrow b \\implies c \\lor d \\land \\neg b");
    defer alloc.free(readable);

    try std.testing.expect(std.mem.eql(u8, "a IMPLIES b IMPLIES c OR d AND NOT b", readable));
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
