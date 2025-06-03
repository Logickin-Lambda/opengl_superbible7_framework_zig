# OpenGL SuperBible 7th Edition Framework in zig
I have been learning OpenGL for a month, but I was stuck at the cube code example because I find it difficult to learn from the book without actually writing some code, while I am not a fan of having all code, libraries, and cmake build projects clump into a single folder, nor I want to work with cmake. Since I also want to learn about zig which I have planned for writing some gui application or even games, I decided to port the sb7.h into zig.

However, this library have a problem that the header file has a class defined which is not a pure C implementation that is not compatible with zig, so I have to take some time to find a way how to make it work with zig while it have a similar look and feel to the OpenGL superbible example. At the end, I seemed to find a working solution using function pointer as a substitute to the object classes to override any default functions.

Hope you find it useful if you want to get into OpenGL with zig.

# Dependencies
This sb7.h port applied with three dependencies:
[castholm - zigglen](https://github.com/castholm/zigglgen)
[zig-gamedev - zglfw](https://github.com/zig-gamedev/zglfw)
[griush - zm](https://github.com/griush/zm)
