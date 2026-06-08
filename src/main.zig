const std = @import("std");
const Io = std.Io;

const mezzotext = @import("mezzotext");
const Canvas = mezzotext.Canvas;
const log = std.log.debug;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const io = init.io;

    var stdout_buffer: [12000]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var canvas = try Canvas.init(arena, 80, 40);

    canvas.drawBox(40, 10, 8, 4);
    canvas.drawCircle();
    canvas.drawBoxS(20, 10, 8, 4);

    // fraction
    canvas.setChar(5, 5, '2');
    canvas.setChar(5, 4, '-');
    canvas.setChar(5, 3, '3');

    try canvas.render(stdout_writer);
    try stdout_writer.flush();
}

test "fuzz example" {
    try std.testing.fuzz({}, {}, .{});
}
// ⠀⠀⣀⡤⠤⣄⡀⠀
// ⠀⡜⠁   ⠙⡄
// ⠀⢇    ⢀⠇
// ⠀⠈⠓⠦⠤⠖⠋⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀
