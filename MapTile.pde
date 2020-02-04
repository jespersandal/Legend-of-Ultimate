/*
This class are for the tiles that the map/level is made out of.

A MapTile needs a reference to a PImage with the image that should be displayed. It should also get a terrain type
that we use to determine whether the tile can be passed through, if it slows heroes and enemies down (like water), or if they
take damage if they pass through (like lava).

The terrain types are hardcoded and should be matched with the tiles in the tilesheet.

The values for how much a character is slowed down or how much damage they take should be kept in the map object.

For now, it is also possible to create a tile that is just a solid coloured square. This should be removed in the final version
after testing.
*/

class MapTile {
  
  int tileSize = 64*scale;
  color col;
  PImage tileImage;
  boolean blocked = false;
  boolean damage = false;
  boolean slowed = false;
  // These I might be able to do in a smarter way later (stairs up and down):
  boolean stairsUp = false;
  boolean stairsDown = false;
  
  // Constructors: (These overloaded constructors are for testing)
  MapTile(int greyScale) {
    col = color(greyScale);
  }
  MapTile(PImage p) {
    tileImage = p;
    col = color(0);
  }
  MapTile(PImage p, int terrain) {
    tileImage = p;
    col = color(0);
    setTerrain(terrain);
  }
  MapTile(PImage p, int terrain, boolean isLava, boolean isWater) {
    tileImage = p;
    col = color(0);
    damage = isLava;
    slowed = isWater;
    setTerrain(terrain);
  }
  MapTile(PImage p, int terrain, boolean isLava, boolean isWater, boolean isBlocked) {
    tileImage = p;
    col = color(0);
    damage = isLava;
    slowed = isWater;
    setTerrain(terrain);
    blocked = isBlocked;
  }
  
  void display(float x, float y) {
    if (tileImage == null) {
      fill(col);
      rect(x, y, tileSize, tileSize);
    }
    else {
      image(tileImage, x, y, tileSize, tileSize);
    }
  }
  
  void setTerrain(int terrainType) {
    switch(terrainType) {
      case 0: case 2: case 4:
        break;
      case 1: case 3: case 6: case 7:
        if (slowed || damage) { break; }
        blocked = true;
        break;
      case 5:
        if (!damage) {
          stairsDown = true;  // Bug fix for level 4.
        }
        break;
      case 8:
        if (!damage) {
          stairsUp = true;  // Bug fix for level 4.
        }
        break;
      case 9:
        slowed = true;
        break;
    }
  }
  
  // This is for simple collision detection where we just need to know if the tile is passable.
  boolean isBlocked() {
    return blocked;
  }
  // This is for collision detection where we need to also know if the tile is water or lava.
  int checkCollision() {
    if (blocked) { return 1; }
    else if (slowed) { return 2; }
    else if (damage) { return 3; }
    else { return 0; }
  }
  
  // This lets us set the size for displaying the image for the tile. We check if the size is useful or could cause problems.
  void setTileSize(int tsize) {
    if (tsize > 0 && tsize <= 1024) {
      tileSize = tsize;
    }
  }
}
