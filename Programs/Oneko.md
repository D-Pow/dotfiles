# Oneko

Oneko is a cat that stays on your desktop and chases your mouse.
It's available for Unix-based systems, possibly Windows but uncertain.
Requires X11 library.

## Installation

* Install X11
* `clang -Wno-parentheses -std=c11 -pedantic -D_DEFAULT_SOURCE oneko.c -o oneko -lc -lm -lX11 -lXext`
* Can use `clang` or `gcc`.
* For mac: Add `-I/opt/X11/include -L/opt/X11/lib` because Mac installs X11 in a different location than expected by C compilers.

## References
* GitHub with instructions: https://github.com/tie/oneko
* Standard website (linked in GitHub): http://www.daidouji.com/oneko/
