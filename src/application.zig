const std = @import("std");
const builtin = @import("builtin");
pub const glfw = @import("zglfw");
pub const gl = @import("gl");

pub const APPINFOTAG = enum {
    struct_type,
    c_uint_type,
};

const FLAGS = struct {
    // the "all" property is useless in zig because union behaves differently in C
    // which was not an intended feature for union.
    all: c_uint = 0,
    fullscreen: c_uint = 0,
    vsync: c_uint = 0,
    cursor: c_uint = 0,
    stereo: c_uint = 0,
    debug: c_uint = 0,
    robust: c_uint = 0,
};

const APPINFO = struct {
    title: [128]u8 = undefined,
    windowWidth: c_int = 800,
    windowHeight: c_int = 600,
    majorVersion: c_int = 4,
    minorversion: c_int = 3,
    samples: c_int = 0,
    flags: FLAGS,
};

pub var info = APPINFO{ .flags = FLAGS{} };
pub var window: *glfw.Window = undefined;

var allocator: std.mem.allocator = undefined;
var procs: gl.ProcTable = undefined;

// public virtual functions
// these two emulate the constructor and destructor
pub var construct: *const fn () callconv(.c) void = virtual_void;
pub var destruct: *const fn () callconv(.c) void = virtual_void;
pub var init: *const fn () anyerror!void = virtual_init;

// others are the original methods
pub var start_up: *const fn () callconv(.c) void = virtual_void;
pub var render: *const fn (f64) callconv(.c) void = virtual_f64_void;
pub var shutdown: *const fn () callconv(.c) void = virtual_void;
pub var on_resize: *const fn (*glfw.Window, c_int, c_int) callconv(.c) void = virtual_win_2c_int_void;
pub var on_key: *const fn (*glfw.Window, glfw.Key, c_int, glfw.Action, glfw.Mods) callconv(.c) void = virtual_win_key_void;
pub var on_mouse_button: *const fn (*glfw.Window, glfw.MouseButton, glfw.Action, glfw.Mods) callconv(.c) void = virtual_win_mbtn_void;
pub var on_mouse_move: *const fn (*glfw.Window, f64, f64) callconv(.c) void = virtual_win_mmove_void;
pub var on_mouse_wheel: *const fn (*glfw.Window, f64, f64) callconv(.c) void = virtual_win_mmove_void;
pub var get_mouse_position: *const fn (*glfw.Window, *c_int, *c_int) callconv(.c) void = virtual_win_c_int_void;
pub var glfw_onResize: *const fn (*glfw.Window, c_int, c_int) callconv(.c) void = virtual_win_2c_int_void;

// placeholder functions
fn virtual_init() anyerror!void {
    return error.OperationNotSupportedError;
}

fn virtual_void() callconv(.c) void {}

fn virtual_f64_void(_: f64) callconv(.c) void {}

fn virtual_win_c_int_void(_: *glfw.Window, _: c_int) callconv(.c) void {}

fn virtual_win_2c_int_void(_: *glfw.Window, _: c_int, _: c_int) callconv(.c) void {}

fn virtual_win_key_void(_: *glfw.Window, _: glfw.Key, _: c_int, _: glfw.Action, _: glfw.Mods) callconv(.c) void {}

fn virtual_win_mbtn_void(_: *glfw.Window, _: glfw.MouseButton, _: glfw.Action, _: glfw.Mods) callconv(.c) void {}

fn virtual_win_mmove_void(_: *glfw.Window, _: f64, _: f64) callconv(.c) void {}

fn virtual_2c_int_ptr_void(_: *glfw.Window, _: *c_int, _: *c_int) callconv(.c) void {}

// concrete functions:
// pub fn set_v_sync(enable: bool) void {}

pub fn set_window_title(title: [:0]const u8) void {
    glfw.setWindowTitle(window, title);
}

pub fn init_default() void {
    std.mem.copyForwards(u8, &info.title, "OpenGL SuperBible Example");
    info.windowWidth = 800;
    info.windowHeight = 600;

    // this is the zig version of
    // #ifdef __APPLE__
    if (comptime builtin.target.os.tag == .macos) {
        info.majorVersion = 3;
        info.minorversion = 2;
    }

    if (comptime builtin.mode == .Debug) {
        info.flags.debug = 1;
    }
}

pub fn run() void {
    var running = true;

    glfw.init() catch {
        std.log.err("GLFW initialization failed\n", .{});
        return;
    };
    defer glfw.terminate();

    init() catch |unknown_err| {
        if (unknown_err != error.OperationNotSupportedError) {
            std.log.err("Overridden APPINFO init function failed, using the default operation...\n", .{});
        }
        init_default();
    };

    glfw.windowHint(glfw.WindowHint.context_version_major, info.majorVersion);
    glfw.windowHint(glfw.WindowHint.context_version_minor, info.minorversion);

    if (builtin.mode != .Debug and (builtin.mode != .Debug and info.flags.debug == 1)) {
        glfw.windowHint(glfw.WindowHint.opengl_debug_context, gl.TRUE);
    }

    if (info.flags.robust == 1) {
        glfw.windowHint(glfw.WindowHint.context_robustness, glfw.ContextRobustness.lose_context_on_reset);
    }

    glfw.windowHint(glfw.WindowHint.opengl_profile, glfw.OpenGLProfile.opengl_core_profile);
    glfw.windowHint(glfw.WindowHint.opengl_forward_compat, true);
    glfw.windowHint(glfw.WindowHint.samples, info.samples);

    // since stereo contains 1 or 0 which is same as how OpenGL present its true and false value
    // we can squarely use the numerical values.
    const stereo = info.flags.stereo == gl.TRUE; // used for rendering VR, thus false by default for normal screen
    glfw.windowHint(glfw.WindowHint.stereo, stereo);

    // full screen handling are ignored in the original sb7.h code, so I will skip that part of code
    const is_full_screen: ?*glfw.Monitor = if (info.flags.fullscreen == gl.TRUE) glfw.getPrimaryMonitor() else null;

    window = glfw.createWindow(
        info.windowWidth,
        info.windowHeight,
        info.title[0.. :0],
        is_full_screen,
    ) catch |err| {
        std.log.err("GLFW Window creation failed: {any}", .{err});
        std.log.err("info.windowWidth: {d}", .{info.windowWidth});
        std.log.err("info.windowHeight: {d}", .{info.windowHeight});
        std.log.err("info.title: {s}", .{info.title});
        return;
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    _ = glfw.setWindowSizeCallback(window, on_resize);
    _ = glfw.setKeyCallback(window, on_key);
    _ = glfw.setMouseButtonCallback(window, on_mouse_button);
    _ = glfw.setCursorPosCallback(window, on_mouse_move);
    _ = glfw.setScrollCallback(window, on_mouse_wheel);

    if (info.flags.cursor != 1) {
        glfw.setInputMode(window, glfw.InputMode.cursor, glfw.Cursor.Mode.hidden) catch {
            std.debug.print("setInputMode failed", .{});
            return;
        };
    }

    // Since I don't have gl3, but I have the zig version of the gl library, I will use the zig implementation;
    // thus, the following code will be different, but I have tested in other project before which behave the same.
    // Source: https://github.com/Logickin-Lambda/learn_opengl_first_triangle

    if (!procs.init(glfw.getProcAddress)) {
        std.log.err("GL  failed", .{});
    }

    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    // debug callback is not available because it involves some kind of windows callback.
    // will figure that out if I have time
    if (builtin.mode == .Debug) {
        std.debug.print("VENDOR: {s}\n", .{gl.GetString(gl.VENDOR).?});
        std.debug.print("VERSION: {s}\n", .{gl.GetString(gl.VERSION).?});
        std.debug.print("RENDERER: {s}\n", .{gl.GetString(gl.RENDERER).?});
    }

    start_up();

    while (running) {
        render(glfw.getTime());

        glfw.swapBuffers(window);
        glfw.pollEvents();

        running = running and (glfw.getKey(window, glfw.Key.escape) == .release);
        running = running and !glfw.windowShouldClose(window);
    }

    shutdown();
}
