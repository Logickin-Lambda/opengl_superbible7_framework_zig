// These are the libraries used in the examples,
// you may find the respostories from build.zig.zon
const std = @import("std");
const app = @import("application.zig");
const shader = @import("shaders_triangle.zig");

var program: app.gl.uint = undefined;
var vao: app.gl.uint = undefined;

pub fn main() !void {
    // "override" your program using function pointer,
    // and the run function will process them all
    app.start_up = startup;
    app.render = render;
    app.shutdown = shutdown;
    app.run();
}

fn startup() callconv(.c) void {
    program = app.gl.CreateProgram();

    // vertex shader
    const vs: app.gl.uint = app.gl.CreateShader(app.gl.VERTEX_SHADER);
    app.gl.ShaderSource(
        vs,
        1,
        &.{shader.vertexShaderImpl},
        &.{shader.vertexShaderImpl.len},
    );
    app.gl.CompileShader(vs);

    // fragment shader
    const fs: app.gl.uint = app.gl.CreateShader(app.gl.FRAGMENT_SHADER);
    app.gl.ShaderSource(
        fs,
        1,
        &.{shader.fragmentShaderImpl},
        &.{@as(c_int, @intCast(shader.fragmentShaderImpl.len))},
    );
    app.gl.CompileShader(fs);

    app.gl.AttachShader(program, vs);
    app.gl.AttachShader(program, fs);

    app.gl.LinkProgram(program);
    app.gl.GenVertexArrays(1, (&vao)[0..1]);

    app.gl.BindVertexArray(vao);
}

fn render(_: f64) callconv(.c) void {
    const green: [4]app.gl.float = .{ 0.0, 0.25, 0.0, 1.0 };
    app.gl.ClearBufferfv(app.gl.COLOR, 0, &green);

    app.gl.UseProgram(program);
    app.gl.DrawArrays(app.gl.TRIANGLES, 0, 3);
}

fn shutdown() callconv(.c) void {
    app.gl.BindVertexArray(0);
    app.gl.DeleteVertexArrays(1, (&vao)[0..1]);
    app.gl.DeleteProgram(program);
}
