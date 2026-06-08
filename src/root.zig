const std = @import("std");
const Io = std.Io;

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

    pub fn drawBox(self: *Canvas, center_x: u32, center_y: u32, width: u32, height: u32) void {
        // 1. Cast parameters to signed integers to prevent underflow panics
        const cx: isize = @intCast(center_x);
        const cy: isize = @intCast(center_y);
        const w: isize = @intCast(width / 2);
        const h: isize = @intCast(height / 2);

        // 2. Calculate absolute bounds
        const left: usize = @intCast(cx - w);
        const right: usize = @intCast(cx + w);
        const top: usize = @intCast(cy - h);
        const bottom: usize = @intCast(cy + h);

        // 3. Draw Corners
        self.setChar(left, top, Char.box_tl);
        self.setChar(right, top, Char.box_tr);
        self.setChar(left, bottom, Char.box_bl);
        self.setChar(right, bottom, Char.box_br);

        // 4. Draw Vertical Edges
        var y = top + 1;
        while (y < bottom) : (y += 1) {
            self.setChar(left, y, Char.box_v);
            self.setChar(right, y, Char.box_v);
        }

        // 5. Draw Horizontal Edges
        var x = left + 1;
        while (x < right) : (x += 1) {
            self.setChar(x, top, Char.box_h);
            self.setChar(x, bottom, Char.box_h);
        }
    }

    pub fn drawBoxS(self: *Canvas, center_x: u32, center_y: u32, width: u32, height: u32) void {
        // 1. Cast parameters to signed integers to prevent underflow panics
        const cx: isize = @intCast(center_x);
        const cy: isize = @intCast(center_y);
        const w: isize = @intCast(width / 2);
        const h: isize = @intCast(height / 2);

        // 2. Calculate absolute bounds
        const left: usize = @intCast(cx - w);
        const right: usize = @intCast(cx + w);
        const top: usize = @intCast(cy - h);
        const bottom: usize = @intCast(cy + h);

        // 3. Draw Corners
        self.setChar(left, top, Char.sbox_tl);
        self.setChar(right, top, Char.sbox_tr);
        self.setChar(left, bottom, Char.sbox_bl);
        self.setChar(right, bottom, Char.sbox_br);

        // 4. Draw Vertical Edges
        var y = top + 1;
        while (y < bottom) : (y += 1) {
            self.setChar(left, y, Char.sbox_v);
            self.setChar(right, y, Char.sbox_v);
        }

        // 5. Draw Horizontal Edges
        var x = left + 1;
        while (x < right) : (x += 1) {
            self.setChar(x, top, Char.sbox_h);
            self.setChar(x, bottom, Char.sbox_h);
        }
    }

    pub fn drawCircle(self: *Canvas) void {
        const num_points = 200;
        const radius = 24.0;
        for (0..num_points) |i| {
            const t: f32 = @as(f32, @floatFromInt(i)) / num_points;
            const dtheta = t * 2 * std.math.pi;
            const y = (@sin(dtheta) * radius) + @as(f32, @floatFromInt(self.height)) * 2;
            const x = (@cos(dtheta) * radius) + @as(f32, @floatFromInt(self.width));
            self.setPixel(@round(x), @round(y));
        }
    }

    pub fn render(self: *Canvas, writer: anytype) !void {
        var char_buf: [4]u8 = undefined;

        for (self.buffer) |cell| {
            const bytes_written = try std.unicode.utf8Encode(cell, &char_buf);
            try writer.writeAll(char_buf[0..bytes_written]);
        }
    }
};

pub fn Vec2(comptime T: type) type {
    return struct { x: T, y: T };
}

pub const Char = struct {
    // Braille Canvas Anchor
    pub const empty: u21 = 0x2800;

    // Shading Density
    pub const shade_25: u21 = '░';
    pub const shade_50: u21 = '▒';
    pub const shade_75: u21 = '▓';
    pub const solid: u21 = '█';

    // Geometric Sub-blocks
    pub const block_upper: u21 = '▀';
    pub const block_lower: u21 = '▄';
    pub const block_left: u21 = '▌';
    pub const block_right: u21 = '▐';

    // Box Drawing (Rounded Geometry)
    pub const box_tl: u21 = '╭';
    pub const box_tr: u21 = '╮';
    pub const box_bl: u21 = '╰';
    pub const box_br: u21 = '╯';
    pub const box_h: u21 = '─';
    pub const box_v: u21 = '│';

    // Box Drawing (Orthogonal Geometry)
    pub const sbox_tl: u21 = '┌';
    pub const sbox_tr: u21 = '┐';
    pub const sbox_bl: u21 = '└';
    pub const sbox_br: u21 = '┘';
    pub const sbox_h: u21 = '─';
    pub const sbox_v: u21 = '│';

    // T-Junctions and Intersections
    pub const sbox_t_up: u21 = '┴';
    pub const sbox_t_down: u21 = '┬';
    pub const sbox_t_left: u21 = '┤';
    pub const sbox_t_right: u21 = '├';
    pub const sbox_cross: u21 = '┼';

    // Box Drawing (Double Line Geometry)
    pub const dbox_tl: u21 = '╔';
    pub const dbox_tr: u21 = '╗';
    pub const dbox_bl: u21 = '╚';
    pub const dbox_br: u21 = '╝';
    pub const dbox_h: u21 = '═';
    pub const dbox_v: u21 = '║';

    // Mathematical Operators and Set Theory
    pub const math_integral: u21 = '∫';
    pub const math_sum: u21 = '∑';
    pub const math_prod: u21 = '∏';
    pub const math_sqrt: u21 = '√';
    pub const math_approx: u21 = '≈';
    pub const math_neq: u21 = '≠';
    pub const math_leq: u21 = '≤';
    pub const math_geq: u21 = '≥';
    pub const math_inf: u21 = '∞';
    pub const math_intersect: u21 = '∩';
    pub const math_union: u21 = '∪';

    // Directional UI Vectors
    pub const arrow_up: u21 = '▲';
    pub const arrow_down: u21 = '▼';
    pub const arrow_left: u21 = '◀';
    pub const arrow_right: u21 = '▶';
};

pub const AsciiChar = struct {
    // Standard Space Boundary
    pub const empty: u21 = ' ';

    // Density Approximations
    pub const shade_25: u21 = '.';
    pub const shade_50: u21 = ':';
    pub const shade_75: u21 = '%';
    pub const solid: u21 = '#';

    // Sub-block Approximations
    pub const block_upper: u21 = '^';
    pub const block_lower: u21 = '_';
    pub const block_left: u21 = '[';
    pub const block_right: u21 = ']';

    pub const box_tl: u21 = '+';
    pub const box_tr: u21 = '+';
    pub const box_bl: u21 = '+';
    pub const box_br: u21 = '+';
    pub const box_h: u21 = '-';
    pub const box_v: u21 = '|';

    pub const sbox_tl: u21 = '+';
    pub const sbox_tr: u21 = '+';
    pub const sbox_bl: u21 = '+';
    pub const sbox_br: u21 = '+';
    pub const sbox_h: u21 = '-';
    pub const sbox_v: u21 = '|';

    pub const sbox_t_up: u21 = '+';
    pub const sbox_t_down: u21 = '+';
    pub const sbox_t_left: u21 = '+';
    pub const sbox_t_right: u21 = '+';
    pub const sbox_cross: u21 = '+';

    pub const dbox_tl: u21 = '+';
    pub const dbox_tr: u21 = '+';
    pub const dbox_bl: u21 = '+';
    pub const dbox_br: u21 = '+';
    pub const dbox_h: u21 = '=';
    pub const dbox_v: u21 = '|';

    // Mathematical Operator Approximations
    pub const math_integral: u21 = 'S';
    pub const math_sum: u21 = 'E';
    pub const math_prod: u21 = 'P';
    pub const math_sqrt: u21 = 'v';
    pub const math_approx: u21 = '~';
    pub const math_neq: u21 = '!';
    pub const math_leq: u21 = '<';
    pub const math_geq: u21 = '>';
    pub const math_inf: u21 = '8';
    pub const math_intersect: u21 = 'n';
    pub const math_union: u21 = 'u';

    // Directional UI Vectors
    pub const arrow_up: u21 = '^';
    pub const arrow_down: u21 = 'v';
    pub const arrow_left: u21 = '<';
    pub const arrow_right: u21 = '>';
};

pub const braille_dot_map = [4][2]u8{
    .{ 0x01, 0x08 }, // Top row
    .{ 0x02, 0x10 }, // Second row
    .{ 0x04, 0x20 }, // Third row
    .{ 0x40, 0x80 }, // Bottom row
};

test "basic add functionality" {
    try std.testing.expect(3 + 7 == 10);
}
