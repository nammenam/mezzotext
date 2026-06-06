const std = @import("std");
const Io = std.Io;

const mezzotext = @import("mezzotext");

pub const Char = struct {
    pub const empty: u21 = 0x2800;

    // Shading
    pub const shade_25: u21 = '░';
    pub const shade_50: u21 = '▒';
    pub const shade_75: u21 = '▓';
    pub const solid: u21 = '█';

    // Box Drawing (Rounded)
    pub const box_tl: u21 = '╭';
    pub const box_tr: u21 = '╮';
    pub const box_bl: u21 = '╰';
    pub const box_br: u21 = '╯';
    pub const box_h: u21 = '─';
    pub const box_v: u21 = '│';
};

pub const braille_dot_map = [4][2]u8{
    .{ 0x01, 0x08 }, // Top row
    .{ 0x02, 0x10 }, // Second row
    .{ 0x04, 0x20 }, // Third row
    .{ 0x40, 0x80 }, // Bottom row
};

pub const Canvas = struct {
    buffer: []u21,
    width: usize,
    height: usize,

    pub fn init(allocator: std.mem.Allocator, w: usize, h: usize) !Canvas {
        const buf = try allocator.alloc(u21, (w + 1) * h);

        @memset(buf, Char.empty);

        for (0..h) |y| {
            buf[y * (w + 1) + w] = '\n';
        }

        return Canvas{
            .buffer = buf,
            .width = w,
            .height = h,
        };
    }

    pub fn setChar(self: *Canvas, cell_x: usize, cell_y: usize, char: u21) void {
        if (cell_x >= self.width or cell_y >= self.height) return;

        const stride = self.width + 1; // Add stride
        self.buffer[cell_y * stride + cell_x] = char;
    }

    pub fn setPixel(self: *Canvas, pixel_x: usize, pixel_y: usize) void {
        const cell_x = pixel_x / 2;
        const cell_y = pixel_y / 4;

        if (cell_x >= self.width or cell_y >= self.height) return;

        const local_x = pixel_x % 2;
        const local_y = pixel_y % 4;
        const dot_bit = braille_dot_map[local_y][local_x];

        const stride = self.width + 1; // Add stride
        const index = cell_y * stride + cell_x;

        var current_char = self.buffer[index];
        if (current_char < 0x2800 or current_char > 0x28FF) {
            current_char = Char.empty;
        }

        self.buffer[index] = current_char | dot_bit;
    }

    pub fn render(self: *Canvas, writer: anytype) !void {
        var char_buf: [4]u8 = undefined;

        for (self.buffer) |cell| {
            const bytes_written = try std.unicode.utf8Encode(cell, &char_buf);
            try writer.writeAll(char_buf[0..bytes_written]);
        }
    }
};

pub fn main(init: std.process.Init) !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const io = init.io;

    var stdout_buffer: [12000]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var canvas = try Canvas.init(arena, 60, 30);

    // 1. Draw a UI box around the edges
    canvas.setChar(0, 0, Char.box_tl);
    canvas.setChar(49, 0, Char.box_tr);
    // ... loop edges ...

    // 2. Draw a high-resolution diagonal line using Braille math
    for (0..100) |i| {
        canvas.setPixel(i, i);
    }
    try canvas.render(stdout_writer);
    try stdout_writer.flush();
}

test "fuzz example" {
    try std.testing.fuzz({}, {}, .{});
}

// TODO: add cli args
// take in file with drawing commands or start tui mode
// choose to output to stdout or file
