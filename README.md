# Farfadet

A simple tool to describe sprites, tilesets, animations, etc within an image.
It generate a single json file associated with the image.

## Json file

Here's what a generated json file looks like :

```json
{
    "elements": [
        {
            "clip": {
                "h": 18,
                "w": 18,
                "x": 0,
                "y": 0
            },
            "flip": "none",
            "name": "myKey1",
            "type": "sprite"
        },
        {
            "clip": {
                "h": 18,
                "w": 18,
                "x": 0,
                "y": 18
            },
            "flip": "none",
            "name": "myKey2",
            "type": "sprite"
        }
    ],
    "texture": "..\/..\/media\/my_image.png",
    "type": "spritesheet"
}
```

`type` is always "spritesheet".
`texture` is the relative path to access the image from the json directory.
`elements` is an array of all the keys defined inside the image.

Each element is defined by a name (a key), its the one set in the list on the left.
So you get :
`name` the user defined name of the key.
`type` can either be "sprite", "animation", "tileset", "bordered_brush", "borderless_brush" or "ninepatch".
`flip` is the mirroring property, it can either be "none" (default), "horizontal", "vertical" or "both".
`clip` is a node that contains the region inside the image with {x, y} being the top-left corner and {w, h} its size.

`duration` (Animation only) is the time taken to complete the animation in seconds. (Default: 1.0)
`loop` (Animation only) is the looping mode. It can either be "once" (Default), "loop" or "bounce".
`reverse` (Animation only) If the animation is being done in reverse, either true or false (Default).

`margin` (Animation & tileset only) is a node that contains the spacing between each tile with {x, y} (Both 0 by default).

`columns` (Animation & tileset only) is the number of tiles used horizontally. (Default: 1)
`lines` (Animation & tileset only) is the number of tiles used vertically. (Default: 1)
`maxtiles` (Animation & tileset only) is the maximum number of tiles used. If 0 (Default), its the product of columns and lines. (Can be between 0 and columns * lines).

`top` (Ninepatch only) is the size of the top border inside the tile. (Default: 0)
`bottom` (Ninepatch only) is the size of the top border inside the tile. (Default: 0)
`left` (Ninepatch only) is the size of the top border inside the tile. (Default: 0)
`right` (Ninepatch only) is the size of the top border inside the tile. (Default: 0)

## Shortcuts

`1` -> Toggle the selection tool.
`2` -> Toggle the move tool.
`3` -> Toggle the resize corner tool.
`4` -> Toggle the resize border tool.

`Ctrl + Left` -> Select the previous tab (project).
`Ctrl + Right` -> Select the next tab (project).

`Ctrl + A` -> Select all the image.
`Ctrl + S` -> Save the current project.
`Ctrl + Shift + S` -> Save as a new project.
`Ctrl + O or Ctrl + I` -> Open a project or image. (You can also drop the file on the screen).
`Ctrl + P` -> Close the current project.
`Ctrl + R` -> Reload the current project. (Discard all changes)
`Ctrl + G` -> Reload the image. (Update the image without discarding changes).

`Ctrl + N or Ctrl + Q` -> Create a new key.
`Ctrl + D` -> Duplicate the current key.
`Ctrl + R` -> Rename the current key.
`Ctrl + Delete` -> Delete the current key.

`Up` -> Select the key above.
`Down` -> Select the key below.
`Ctrl + Up` -> Move the current key above. (Swap positions)
`Ctrl + Down` -> Move the current key below. (Swap positions)


