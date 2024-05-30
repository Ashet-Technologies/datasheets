{
	type=DATASHEET,
	status = DRAFT,
	title = "BlockEngine",
	part = "ACT-DMA-I",
	date = Date(2023,04,19),
	revision = Version(0,1),
}

**DISCLAIMER: This document is very much work-in-progress and is only a rough working draft!**

# Brain Dump

- Split the DMA into a DMA (block transfers) and a draw engine (render primitives)
- There can be several DMA transfers active at once
- DMA transfers are clocked by a "input signal"
- DMA clocks can come from peripherials (serial fifo half-empty or something) or just "go as fast as possible"
- DMA transfers always perform block copies, but can have "advanced image manipulation" enabled
- Rectangle transfers need to have modes "tile, wrap, clamp"
- Keep linked list DMA transfers

# TODO

- blitter finished irq
- vector fill - How to solve "xor" with color values? - filler-line must "kill" previous lines for _Vector Fill_ to work

# Draw Lists

The OverkillDMA has a linked-list design to process a sequence of commands instead of accepting single commands.

The supported commands are:

- Copy Rectangle
- Paint Primitives (Point, Line, Circle, Triangle)
- Vector Fill

Each draw list entry starts with a shared configuration part that defines part of the linked list and some common flags:

| Offset | Size | Description                             |
| ------ | ---- | --------------------------------------- |
| 0      | 3    | Pointer to the next element in the list |
| 3      | 1    | Flags                                   |

The flags define one bit right now:

| Bit     | Description |
| ------- | ----------- |
| `[3:0]` | Operation   |
| `[7:4]` | _reserved_  |

_Operation_ is one of the following values and define the type of operation that will be performed when reading this node:

| Value  | Name            | Description                                                                                            |
| ------ | --------------- | ------------------------------------------------------------------------------------------------------ |
| `0000` | End of List     | If this operation is encountered, the chip will stop following the linked list and emit an IRQ signal. |
| `0001` | Copy Rect       | This node describes a _Copy Rect_ operation.                                                           |
| `0010` | Vector Fill     | This node describes a _Vector Fill_ operation                                                          |
| `0011` | _reserved_      |                                                                                                        |
| `0100` | _reserved_      |                                                                                                        |
| `0101` | _reserved_      |                                                                                                        |
| `0110` | _reserved_      |                                                                                                        |
| `0111` | _reserved_      |                                                                                                        |
| `1000` | Paint Primitive | This node describes a _Paint Point_ operation.                                                         |
| `1001` | Paint Primitive | This node describes a _Paint Line_ operation.                                                          |
| `1010` | Paint Primitive | This node describes a _Paint Triangle_ operation.                                                      |
| `1011` | Paint Primitive | This node describes a _Paint Circle_ operation.                                                        |
| `1100` | _reserved_      |                                                                                                        |
| `1101` | _reserved_      |                                                                                                        |
| `1110` | _reserved_      |                                                                                                        |
| `1111` | _reserved_      |                                                                                                        |

# Copy Rect

The _Copy Rect_ operation will read data from a source rectangle and will copy it to a destination rectangle.
While copying, both an alpha operation as well as a masking operation can be performed.

## Operation

**Inputs:**

- Alpha (byte)
- Source (rectangle)
- Destination (rectangle)
- Mask (rectangle)
- Alpha Function
- Pixel Function

This operation will copy bytes from a _source_ rectangle into _destination_ rectangle in memory. _Alpha_ together with the _Alpha Function_ determine which bytes are actually copied, while _mask_ determines which portion of the byte is copied. The _Pixel Function_ will be applied to each copied byte before applying the mask.

Rectangles are a pointers that will be incremented by 1 for each pixel in a row of the rectangle. After _width_ pixels, the start of the row will be incremented by _stride_ bytes. This will be repeated for the _height_ of the rectangle. While copying, when coordinates overflow in the _source_ or _mask_ rectangle, they will wrap around to the start of the row or rectangle, allowing smaller portions of ram to be copied repeatedly.

This allows a versatile set of operations to be performed with the RAM Blitter:

- Copy a linear portion of RAM
- Fill a linear portion of RAM
- Copy a rectangular portion of RAM
- Fill a rectangular portion of RAM with a pattern
- Copy a sprite with transparent pixels into a frame buffer
- Enable color cycling with the mask and pixel operations
- …

The operation that happens in detail is the following:

```
fetch alpha
foreach addr in dst:
	pixel ← fetch src
	if alpha-func(pixel, alpha):
		pixel ← pixel-func(pixel)
		if mask-enabled:
			fetch mask
			if mask != 0xFF:
				fetch dst
				pixel ← (pixel & mask) & (dst & ~mask)
				write pixel → dst
		else
			write pixel → dst
```

Each fetch follows the following logic:

```py
fetch-result ← memory(work-ptr)
work-ptr += 1
x += 1
if x == w:
	work-ptr += (stride - w)
	x = 0
	y += 1
	if y == h:
		work-ptr = rectangle-ptr
		y = 0
```

## Data Structures

The _Copy Rect_ list node has the following structure:

| Offset | Size | Description                             |
| ------ | ---- | --------------------------------------- |
| 0      | 3    | Pointer to the next element in the list |
| 3      | 1    | Flags                                   |
| 4      | 1    | Alpha                                   |
| 5      | 1    | Functions                               |
| 6      | 10   | Source Rectangle                        |
| 16     | 10   | Mask Rectangle                          |
| 26     | 10   | Destination Rectangle                   |

Each rectangle is encoded as this:

| Offset | Size | Description                       |
| ------ | ---- | --------------------------------- |
| 0      | 3    | Pointer to the pixel data         |
| 3      | 1    | _reserved_                        |
| 4      | 2    | Stride between scanlines          |
| 6      | 2    | Width of the rectangle in pixels  |
| 8      | 2    | Height of the rectangle in pixels |

The byte in the _Functions_ field is organized as a bit field:

| Range   | Description            |
| ------- | ---------------------- |
| `[2:0]` | Alpha Function         |
| `[3]`   | _reserved_             |
| `[6:4]` | Pixel Function         |
| `[7]`   | Enable _Mask_ when `1` |

The _Alpha Function_ has the following options:

| Value   |                                |
| ------- | ------------------------------ |
| `"000"` | Copy always                    |
| `"001"` | Copy when `alpha != src-pixel` |
| `"010"` | Copy when `alpha == src-pixel` |
| `"011"` | Copy when `alpha >= src-pixel` |
| `"100"` | Copy when `alpha <= src-pixel` |
| `"101"` | Copy when `alpha < src-pixel`  |
| `"110"` | Copy when `alpha > src-pixel`  |
| `"111"` | _reserved_                     |

The _Pixel Function_ has the following options:

| Value   |                             |
| ------- | --------------------------- |
| `"000"` | Copy pixel value            |
| `"001"` | Increment pixel value       |
| `"010"` | Decrement pixel value       |
| `"011"` | Bitwise invert pixel value  |
| `"100"` | Clear pixel value to `0x00` |
| `"101"` | Set pixel value to `0xFF`   |
| `"110"` | _reserved_                  |
| `"111"` | _reserved_                  |

# Paint Primitive

The _Paint Primitive_ operation draws a list of 2D primitives, namely points, lines, circles and triangles.

**Inputs:**

- Source (Pointer+Stride)
- Count (Word)
- Type (point/line/tris/circ)
- Mode (filled/outline/filler-line)

Each primitive is composed of a number of xy-coordinates and one or two colors and are separated by _stride_ bytes.

todo: - xy-commands relative to what? how to efficiently calculate memory offsets?

type=line
cnt = 4
src = stride=10, [
10, 0, 10, 0, 100, 0, 10, 0, C, ?,
100, 0, 10, 0, 100, 0, 100, 0, C, ?,
100, 0, 100, 0, 10, 0, 100, 0, C, ?,
10, 0, 100, 0, 10, 0, 10, 0, C, ?,
]

## Data Structures

The _Paint Primitive_ list node has the following structure:

| Offset | Size | Description                             |
| ------ | ---- | --------------------------------------- |
| 0      | 3    | Pointer to the next element in the list |
| 3      | 1    | Flags                                   |
| 4      | 3    | Pointer to the array of elements        |
| 7      | 1    | Element Type and Paint Mode             |
| 8      | 2    | Primitive Count                         |

Byte 7 is a bit field:

| Range   | Name           | Description                                |
| ------- | -------------- | ------------------------------------------ |
| `[2:0]` | Primitive Type | Defines the primitive that is drawn        |
| `[3]`   | _reserved_     |                                            |
| `[5:4]` | Paint Mode     | Defines how the primitives should be drawn |
| `[7:5]` | _reserved_     |                                            |

**Primitive Type:**

| Value   | Description |
| ------- | ----------- |
| `"000"` | Point       |
| `"001"` | Line        |
| `"010"` | Triangle    |
| `"011"` | Circle      |
| `"1**"` | _reserved_  |

**Paint Mode:**

| Value  | Description                                                             |
| ------ | ----------------------------------------------------------------------- |
| `"00"` | The primitives will be drawn as outlines.                               |
| `"01"` | _reserved_                                                              |
| `"10"` | The primitive will be filled with its color                             |
| `"11"` | The primitive outline will be drawn with another color than its content |

# Vector Fill

Similar to amiga filler: Toggle filling mode on and off when a certain color value is detected

Params:
src : rect[ptr,stride,w,h]
dst : rect[ptr,stride,w,h]
color : rect[ptr,stride,w,h]
on : color
off : color
mode : inclusive/exclusive

## Data Structures

The _Vector Fill_ list node has the following structure:

| Offset | Size | Description                             |
| ------ | ---- | --------------------------------------- |
| 0      | 3    | Pointer to the next element in the list |
| 3      | 1    | Flags                                   |
