# Geometry

Geometry is owned by Nagi Surface. TUI facades MAY re-export the canonical
types but MUST NOT define a second representation

- `Point` represents terminal cell coordinates with signed 32-bit `x` and `y`
- `Size` width and height are unsigned 32-bit values
- `Rect` is the half-open region `[x, x + width) x [y, y + height)`
- Empty rectangles are valid values
- Intersection, containment, translation, and clipping MUST use arithmetic that
  cannot overflow
- Rectangle endpoints are evaluated in a signed 64-bit intermediate domain
- Rectangle intersection always returns a rectangle. A disjoint intersection
  has zero width or height and uses the component-wise maximum origins
- Point and rectangle translation report failure when either translated origin
  is outside the signed 32-bit domain
- Drawing outside a surface MUST be clipped and MUST NOT panic
- Conversion to a platform-sized index occurs only at a checked indexing
  boundary
