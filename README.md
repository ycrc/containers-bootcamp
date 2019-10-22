# containers-bootcamp

A talk about how to use Singularity. Also about how to build Docker images to be used as either Singularity or Docker containers.

Some examples are in the directory [dockerfile-examples](dockerfile-examples)

## Presenting

The default keyboard shortcuts are:

- <kbd>N</kbd>, <kbd>SPACE</kbd>:   Next slide
- <kbd>P</kbd>: Previous slide
- <kbd>←</kbd>, <kbd>H</kbd>: Navigate left
- <kbd>→</kbd>, <kbd>L</kbd>: Navigate right
- <kbd>↑</kbd>, <kbd>K</kbd>: Navigate up
- <kbd>↓</kbd>, <kbd>J</kbd>: Navigate down
- <kbd>Home</kbd>: First slide
- <kbd>End</kbd>: Last slide
- <kbd>B</kbd>, <kbd>.</kbd>: Pause (Blackout)
- <kbd>F</kbd>: Fullscreen
- <kbd>ESC</kbd>, <kbd>O</kbd>: Slide overview / Escape from full-screen
- <kbd>S</kbd>: Speaker notes view - broken right now
- <kbd>?</kbd>: Show keyboard shortcuts
- <kbd>alt</kbd> + click: Zoom in. Repeat to zoom back out.

## To Build

Need `pandoc`, my version is `2.7.3`. To build slides (index.html) just run `make`.

## Format

Slides are written in markdown, with intent to convert to [reveal.js](https://revealjs.com/). Make new slides with single `#` (h1). Make vertical runs of slides by wrapping them with `<section></section>`.