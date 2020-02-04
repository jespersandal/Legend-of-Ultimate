/*
The Map class handles each level and every objects in each level. That includes the tiles to be displayed, the enemies,
the treasure and everything else.

 NOTE: The constructor should find the starting location on the map based on the type of tile specified in the tile map.
        We assume that the hero starts at the top and moves down through the dungeon. Since each map is its own object,
       it should remember the last position it was displayed at, meaning that the hero should reappear at the same location
       at the stairs down if the hero uses the stairs up.
 
 TODO: The Map class manages a lot of objects and also handles collision detection. This is not bad, but it does mean that
       there's a lot of code here. Part of is because there are some helper methods that is used for guessing if a tile is
       lava or water - and there is also an attempt at avoiding drawing parts of the map that are off screen.
 
 TODO: Right now the collision detection only works if map positions (the upper left corner) are always negative values.
       So the map has been "padded" with inaccessible tiles to the left and top to prevent it from changing from negative
       to positive. A more elegant solution would be to check if the position is positive or negative before converting
       the map position to a position in the map tile array.
 
 */

class Map {

  // Class fields:
  float mapPosX;
  float mapPosY;
  MapTile[][] mapTiles;
  PImage tileSheet = loadImage("tilesheet00.png");
  PImage[] tiles;
  Enemy[] enemies;
  Treasure[] treasure;
  Treasure[] droppedLoot;
  int nextDrop = 0;
  Effect[] effects;
  Effect[] enemyEffects; // These are the effects of the enemies' attacks. Keeping them separate from the player's avoids "friendly fire";
  Effect[] playerEffects; // These are the effects of the player's attacks.
  int nextEffect = 0; // This let's us reuse the slots in our Effect array and limits the number of active effects on the map.
  int nextEnemyEffect = 0;
  int nextPlayerEffect = 0;
  // We hardcode the size of the tiles for now:
  int sheetTileSize = 32;
  int displayTileSize = 64;
  //String mapType = "forest";
  int mapLevel;

  // Constructor:
  Map(int levelID) {
    mapLevel = levelID;
    String[] lines = loadTextMap(levelID);
    // We can use the map info to figure out where the starting position is:
    boolean matchStairsUp = false;  // This allows us to only keep looking through the map, until we find the stairs.
    for (int i = 0; i < lines.length && !matchStairsUp; i++) {
      for (int j = 0; j < lines[i].length(); j++) {
        if (lines[i].charAt(j) == '8') {
          mapPosX = (-1*((j-2)*displayTileSize)) + (0.5*displayTileSize);
          mapPosY = (-1*((i-1)*displayTileSize)) + (0.5*displayTileSize);
          matchStairsUp = true;
        }
      }
    }
    //println(mapPosX + "," + mapPosY);
    loadMapTiles(lines, levelID);
    //loadEnemies();
    DungeonFairy fairy = new DungeonFairy(mapPosX, mapPosY, lines);
    enemies = fairy.spawnEnemies(50, levelID);
    treasure = fairy.sprinkleLoot(100);
    loadEffects();
    droppedLoot = new Treasure[100];
    if (levelID == maxLevel) {
      finishedLoading = true;
    }
  }


  void display() {
    // To improve performance, we only draw the tiles that are visible.
    // To do that we use the size of the tiles and the position of the upper left corner of the map.
    // There could be tiles on either side of the main window that we don't need to display.
    // So we need to calculate four indexes of the mapTiles array that determine the borders of what we need to display.
    int tileSize = mapTiles[0][0].tileSize;
    int leftBorder;
    if (mapPosX < 0) {
      leftBorder = int((abs(mapPosX)/tileSize));  // We use the absolute value, since mapPosX is negative, but we need a positive index.
    } else {
      leftBorder = 0;  // Since we use the absolute value above, we can get to a point where the index starts counting up again
    }                  // but should be 0 since we're at the edge of the map.
    int upperBorder;
    if (mapPosY < 0) {
      upperBorder = int((abs(mapPosY)/tileSize));
    } else {
      upperBorder = 0;
    }
    int rightBorder = int(((abs(mapPosX)+width)/tileSize)) + 1;
    int lowerBorder = int(((abs(mapPosY)+height)/tileSize)) + 1;
    for (int i = leftBorder; i < min(rightBorder, mapTiles.length); i++) {
      for (int j = upperBorder; j < min(lowerBorder, mapTiles[i].length); j++) {
        mapTiles[i][j].display(i*tileSize + mapPosX, j*tileSize + mapPosY);
      }
    }
    // Update and display all enemies on the map:
    for (int i = 0; i < enemies.length; i++) {
      enemies[i].display();
      enemies[i].update(ticksLastUpdate);
    }
    // Update and display all treasure on the map:
    for (int i = 0; i < treasure.length; i++) {
      treasure[i].display();
    }
    for (int i = 0; i < droppedLoot.length; i++) {
      if (droppedLoot[i] != null) {
        droppedLoot[i].display();
      }
    }
    // Display all effects on the map:
    for (int i = 0; i < effects.length; i++) {
      if (effects[i] != null) {
        effects[i].display();
      }
    }
    for (int i = 0; i < playerEffects.length; i++) {
      if (playerEffects[i] != null) {
        playerEffects[i].display();
      }
    }
    for (int i = 0; i < enemyEffects.length; i++) {
      if (enemyEffects[i] != null) {
        enemyEffects[i].display();
      }
    }
  }

  // There is probably a parsing function in the Java Integer class, but for now I write my own as an exercise:
  int parseInt(char c) {
    int charAsciiValue = int(c);
    return charAsciiValue - 48;
  }

  void update(int dir, float spd) {
    if (!finishedLoading || !playerFirstAction) {
      return;
    }
    // update the position of all tiles, creatures and items fixed to the map:
    // Ideally, we cycle through all objects on the map, when we move the map.
    if (dir == 0) {
      mapPosY = mapPosY + spd;
      enemiesUpdate(0, spd);
      treasureUpdate(0, spd);
      effectsUpdate(0, spd);
    } else if (dir == 2) {
      mapPosY = mapPosY - spd;
      enemiesUpdate(0, -spd);
      treasureUpdate(0, -spd);
      effectsUpdate(0, -spd);
    } else if (dir == 1) {
      mapPosX = mapPosX - spd;
      enemiesUpdate(-spd, 0);
      treasureUpdate(-spd, 0);
      effectsUpdate(-spd, 0);
    } else if (dir == 3) {
      mapPosX = mapPosX + spd;
      enemiesUpdate(spd, 0);
      treasureUpdate(spd, 0);
      effectsUpdate(spd, 0);
    }
  }

  void enemiesUpdate(float x, float y) {
    for (int i = 0; i < enemies.length; i++) {
      enemies[i].mapUpdate(x, y);
    }
  }
  
  void treasureUpdate(float x, float y) {
    for (int i = 0; i < treasure.length; i++) {
      treasure[i].update(x, y);
    }
    for (int i = 0; i < droppedLoot.length; i++) {
      if (droppedLoot[i] != null) {
        droppedLoot[i].update(x, y);
      }
    }
  }
  
  void effectsUpdate(float x, float y) {
    for (int i = 0; i < effects.length; i++) {
      if (effects[i] != null) {
        effects[i].mapUpdate(x, y);
      }
    }
    for (int i = 0; i < playerEffects.length; i++) {
      if (playerEffects[i] != null) {
        playerEffects[i].mapUpdate(x, y);
      }
    }
    for (int i = 0; i < effects.length; i++) {
      if (enemyEffects[i] != null) {
        enemyEffects[i].mapUpdate(x, y);
      }
    }
  }
  
  void effectsUpdate() {
    for (int i = 0; i < effects.length; i++) {
      if (effects[i] != null) {
        effects[i].update();
      }
    }
    for (int i = 0; i < playerEffects.length; i++) {
      if (playerEffects[i] != null) {
        playerEffects[i].update();
      }
    }
    for (int i = 0; i < enemyEffects.length; i++) {
      if (enemyEffects[i] != null) {
        enemyEffects[i].update();
      }
    }
  }

  boolean isHeroColliding() {
    int tileSize = mapTiles[0][0].tileSize;
    // THe hero can overlap two tiles, so we need to check with both those tiles:
    int currentTileRightX = int(((abs(mapPosX - hero.getHeroSize())+hero.getPosX())/tileSize));
    int currentTileLeftX = int(((abs(mapPosX + tileSize)+hero.getPosX())/tileSize)) +1;
    int currentTileUpperY = int(((abs(mapPosY - hero.getHeroSize())+hero.getPosY())/tileSize));
    int currentTileLowerY = int(((abs(mapPosY + tileSize)+hero.getPosY())/tileSize)) +1;
    if (direction == 0) {
      // We know we're moving up, so we check the two tiles left and right of the hero:
      int collisionLeft = mapTiles[currentTileLeftX][currentTileLowerY].checkCollision();
      int collisionRight = mapTiles[currentTileRightX][currentTileLowerY].checkCollision();
      if (collisionLeft == 1 || collisionRight == 1) {
        hero.isBlocked = true;
        hero.inWater = false;
        hero.inLava = false;
        return true;
      } else if (collisionLeft == 2 || collisionRight == 2) {
        hero.isBlocked = false;
        hero.inWater = true;
        hero.inLava = false;
        return false;
      } else if (collisionLeft == 3 || collisionRight == 3) {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = true;
        return false;
      } else {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = false;
        return false;
      }
    }
    if (direction == 1) {
      int collisionUpper = mapTiles[currentTileRightX][currentTileUpperY].checkCollision();
      int collisionLower = mapTiles[currentTileRightX][currentTileLowerY].checkCollision();
      if (collisionUpper == 1 || collisionLower == 1) {
        hero.isBlocked = true;
        hero.inWater = false;
        hero.inLava = false;
        return true;
      } else if (collisionUpper == 2 || collisionLower == 2) {
        hero.isBlocked = false;
        hero.inWater = true;
        hero.inLava = false;
        return false;
      } else if (collisionUpper == 3 || collisionLower == 3) {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = true;
        return false;
      } 
      // We also know that the stairs are facing in such a way that moving left would make sense to climb up the stairs. So we check if there are stairs:
      else if (mapTiles[currentTileLeftX][currentTileUpperY].stairsDown){
        changeMap(true);
        return true;
      } else {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = false;
        return false;
      }
    }
    if (direction == 2) {
      // We know we're moving down, so we check the two tiles left and right of the hero:
      int collisionLeft = mapTiles[currentTileLeftX][currentTileUpperY].checkCollision();
      int collisionRight = mapTiles[currentTileRightX][currentTileUpperY].checkCollision();
      if (collisionLeft == 1 || collisionRight == 1) {
        hero.isBlocked = true;
        hero.inWater = false;
        hero.inLava = false;
        return true;
      } else if (collisionLeft == 2 || collisionRight == 2) {
        hero.isBlocked = false;
        hero.inWater = true;
        hero.inLava = false;
        return false;
      } else if (collisionLeft == 3 || collisionRight == 3) {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = true;
        return false;
      } else {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = false;
        return false;
      }
    }
    if (direction == 3) {
      int collisionUpper = mapTiles[currentTileLeftX][currentTileUpperY].checkCollision();
      int collisionLower = mapTiles[currentTileLeftX][currentTileLowerY].checkCollision();
      if (collisionUpper == 1 || collisionLower == 1) {
        hero.isBlocked = true;
        hero.inWater = false;
        hero.inLava = false;
        return true;
      } else if (collisionUpper == 2 || collisionLower == 2) {
        hero.isBlocked = false;
        hero.inWater = true;
        hero.inLava = false;
        return false;
      } else if (collisionUpper == 3 || collisionLower == 3) {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = true;
        return false;
      }
      // We also know that the stairs are facing in such a way that moving left would make sense to climb up the stairs. So we check if there are stairs:
      else if (mapTiles[currentTileLeftX][currentTileUpperY].stairsUp){
        changeMap(false);
        return true;
      } else {
        hero.isBlocked = false;
        hero.inWater = false;
        hero.inLava = false;
        return false;
      }
    } else {
      return false;
    }
  }
  // This method checks if a particle has entered a blocked tile. It takes the position of the particle as a parameter and returns true if the tile is blocked.
  boolean checkParticleCollision(float x, float y) {
    // Here we just do a check to see if the center of the particle has entered a mapTile that isBlocked (not passable). We could use the size
    // of the particle to do a classic collision box, but this way creates a better looking visual for the particle effects. We are mostly interested
    // in preventing particles from passing all the way through walls.
    int particleAtTileX = int((abs(mapPosX)+x)/displayTileSize);
    int particleAtTileY = int((abs(mapPosY)+y)/displayTileSize);
    return mapTiles[particleAtTileX][particleAtTileY].isBlocked();
  }
  
  // This method is called by an enemy to check for collisions with the mapTiles.
  int isEnemyColliding(float x, float y) {
    // Right now this only checks one point of the enemy against one tile.
    // The advantage is that it is harder for an enemy to get stuck, since we don't
    // have real pathing but only decides whether our enemy is chasing the player or not.
    // First, we need to compensate for the position being top left corner of the enemy:
    // Enemies are displayed at 48x48 or 64x64, so we use the smaller of the two:
    x += 24;  // half of 48.
    y += 24;  // we add because we go from top left towards the center of the box around the sprite.
    int tileRow = int(abs(x - mapPosX)/mapTiles[0][0].tileSize);
    int tileColumn = int(abs(y - mapPosY)/mapTiles[0][0].tileSize);
    int tileCollision = mapTiles[tileRow][tileColumn].checkCollision();
    return tileCollision;
  }
  
  // This method is for an Enemy to check for collision with other enemies.
  int enemiesColliding(float movingToX, float movingToY, float mySize, int myIndex) {
    int col = 0;
    // To make it look more realistic, we "shrink" the collision box, since there's some empty space around the visible part of the sprite.
    float padding = mySize/4;
    mySize -= padding;
    movingToX += padding;
    movingToY += padding;
    for (int i = 0; i < enemies.length; i++) {
      if (movingToX+mySize >= enemies[i].posX && movingToX <= enemies[i].posX+mySize) {
        if (movingToY+mySize >= enemies[i].posY && movingToY <= enemies[i].posY+mySize) {
          if (i != myIndex) {
            return 1; // right now, we return a 1 at the first collision. The enemy should take an action before we check again in the next call to update().
          }
        }
      }
    }
    return col;
  }
  
  // We can check for enemy collisions with all player effects on the map:
  float checkEffectCollisions(float x, float y, float s, int effectOwner) {
    // Yes, we use single letter variable names, but they are only temporary. x is for the x-position, y is for y-position and s is for size.
    float collisions = 0;
    if (effectOwner == 0) {  // General effects on the map. Usually harmless, but would otherwise harm both enemies and the player.
      for (int i = 0; i < effects.length; i++) {
        if (effects[i] != null) {
          collisions += effects[i].checkEnemyCollisions(x, y, s);
        }
      }
    }
    else if (effectOwner == 1) {  // The effects from the player's attacks.
      for (int i = 0; i < playerEffects.length; i++) {
        if (playerEffects[i] != null) {
          collisions += playerEffects[i].checkEnemyCollisions(x, y, s);
        }
      }
    }
    else if (effectOwner == 2) {  // The effects from enemies' attacks.
      for (int i = 0; i < enemyEffects.length; i++) {
        if (enemyEffects[i] != null) {
          collisions += enemyEffects[i].checkEnemyCollisions(x, y, s);  // Even though it is called checkEnemyCollisions, we can also use it for the player.
        }
      }
    }
    
    return collisions;
  }
  
  // This method allow us to add treasure to the map. We have two Treasure arrays: One for the random treasure when the map is first created, and one
  // for the treasure dropped by dying enemies. This method is for the dropped loot.
  void addLoot(Treasure t) {
    droppedLoot[nextDrop] = t;
    nextDrop++;
    if (nextDrop >= droppedLoot.length) {
      nextDrop = 0;  // This way we recycle the array, when we've filled it up;
    }
  }
  
  String[] loadTextMap(int levelID) {
    if (levelID < 10) {
      return loadStrings("level0" + levelID + ".txt");
    } else {
      return loadStrings("level" + levelID + ".txt");
    }
  }

  void loadMapTiles(String[] lines, int levelID) {
    mapTiles = new MapTile[lines.length][lines[0].length()];
    // For now, it is hardcoded to exactly 10 different tiles per level.
    tiles = new PImage[10];
    boolean[] isLava = new boolean[tiles.length];
    boolean[] isWater = new boolean[tiles.length];
    boolean[] isBlocked = new boolean[tiles.length];
    // We use levelID * sheetTileSize (32) to get the y-coordinate for our image and the charAt from lines * sheetTileSize (32) to get the x-coordinate
    for (int i = 0; i < tiles.length; i++) {
      tiles[i] = tileSheet.get(i*sheetTileSize, levelID*sheetTileSize, sheetTileSize, sheetTileSize);
      isLava[i] = isLava(tiles[i]);
      isWater[i] = isWater(tiles[i]);
      isBlocked[i] = isBlocked(levelID, i);
    }
    for (int i = 0; i < lines.length; i++) {
      for (int j = 0; j < lines[i].length(); j++) {
        int terrain = parseInt(lines[i].charAt(j));
        mapTiles[j][i] = new MapTile(tiles[terrain], terrain, isLava[terrain], isWater[terrain], isBlocked[terrain]);
        if (isLava[terrain]) {
          mapTiles[j][i].stairsUp = false;  // Bug fix for level 4.
        }
      }
    }
  }

  // We can use the pixels in the image to guess if a tile is a water tile. Here, we just check to see if blue is the dominant colour of all the pixels.
  boolean isWater(PImage testTerrain) {
    // For this, we need to switch back to RGB colour mode:
    colorMode(RGB, 255, 255, 255, 100);
    int totalPixels = testTerrain.width * testTerrain.height;
    testTerrain.loadPixels();
    // We will add up the amount of each colour for every pixel in the image.
    float redTotal = 0;
    float greenTotal = 0;
    float blueTotal = 0;
    for (int i = 0; i < totalPixels; i++) {
      redTotal = redTotal + red(testTerrain.pixels[i]);
      greenTotal += green(testTerrain.pixels[i]);
      blueTotal += blue(testTerrain.pixels[i]);
    }
    redTotal = redTotal/totalPixels;
    greenTotal = greenTotal/totalPixels;
    blueTotal = blueTotal/totalPixels;
    // Setting the colour mode back to HSB before we return a value, since the rest of the program uses HSB, not RGB:
    colorMode(HSB, 360, 100, 100, 100);
    if (blueTotal > greenTotal && blueTotal > redTotal) {
      return true;
    } else {
      return false;
    }
  }

  // We can check for lava the same way. However since red is often the dominant colour, we add an extra check.
  boolean isLava(PImage testTerrain) {
    // For this, we need to switch back to RGB colour mode:
    colorMode(RGB, 255, 255, 255, 100);
    int totalPixels = testTerrain.width * testTerrain.height;
    testTerrain.loadPixels();
    float redTotal = 0;
    float greenTotal = 0;
    float blueTotal = 0;
    // The lava tiles have bright red and/or bright yellow pixels. So we check to see if the image has at least one bright red or yellow pixel.
    boolean brightRed = false;
    boolean brightYellow = false;
    for (int i = 0; i < totalPixels; i++) {
      float redVal = red(testTerrain.pixels[i]);
      float greenVal = green(testTerrain.pixels[i]);
      if (redVal > 250) { 
        brightRed = true;
      } else if (redVal > 250 && greenVal > 250) {
        brightYellow = true;
      }
      redTotal = redTotal + redVal;
      greenTotal += greenVal;
      blueTotal += blue(testTerrain.pixels[i]);
    }
    redTotal = redTotal/totalPixels;
    greenTotal = greenTotal/totalPixels;
    blueTotal = blueTotal/totalPixels;
    // Setting the colour mode back to HSB before we return a value, since the rest of the program uses HSB, not RGB:
    colorMode(HSB, 360, 100, 100, 100);
    if (redTotal > greenTotal && redTotal > blueTotal) {
      if (brightRed || brightYellow) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  // When it comes to figuring out which tiles are blocked (the character cannot move there), it is difficult to avoid a bit of crude, manual work:
  boolean isBlocked(int level, int terrainType) {
    switch(terrainType) {
    case 0: 
    case 2: 
    case 4: 
    case 5: 
    case 8: 
    case 9:
      return false;
    case 1: 
    case 3: 
      return true;
    case 6: 
    case 7:
      if (level >= 2) { 
        return false;
      }
      return true;
    default:
      return false;
    }
  }

  void loadEnemies() {
    int iEnemies = 15;
    enemies = new Enemy[iEnemies];
    for (int i = 0; i < iEnemies; i++) {
      enemies[i] = new Enemy(random(mapPosX, mapPosX + mapTiles[0][0].tileSize * mapTiles[0].length), random(mapPosY, mapPosY + mapTiles[0][0].tileSize * mapTiles[0].length));
    }
  }
  
  //void loadTreasure() {
  //  int loot = 25;
  //  String[] treasureTypes = { "healing potion", "mana potion", "potion of protection", "potion of haste", "potion of heroism" };
  //  treasure = new Treasure[loot];
  //  for (int i = 0; i < treasure.length; i++) {
  //    treasure[i] = new Treasure(random(-400, 400), random(-400, 400), treasureTypes[int(random(0, treasureTypes.length))]);
  //    treasure[i].placeOnGround();
  //  }
  //}
  
  // We only use this method to create the initial array. We could probably just create the array in the constructor when we create the map.
  void loadEffects() {
    effects = new Effect[20];
    playerEffects = new Effect[10]; // The player doesn't need as many simultaneous effects.
    enemyEffects = new Effect[20];
  }
  
  // This method lets us add an effect to the map. It will recycle the spots in the effects array, but it doesn't take into consideration if 
  // an effect is still being displayed. We could perhaps add some code to remove effects that have expired and are no longer visible, when this
  // method is called.
  void addEffect(Effect e, int owner) {
    // The owner parameter let's us place the effect in either the general effects array (0), the player' array (1) or the enemies' array (2).
    if (owner == 0) {
      effects[nextEffect] = e;
      effects[nextEffect].createEffect();
      if (nextEffect < effects.length -1) {
        nextEffect++;
      }
      else {
        nextEffect = 0;
      }
    }
    else if (owner == 1) {
      playerEffects[nextPlayerEffect] = e;
      playerEffects[nextPlayerEffect].createEffect();
      if (nextPlayerEffect < playerEffects.length -1) {
        nextPlayerEffect++;
      }
      else {
        nextPlayerEffect = 0;
      }
    }
    else if (owner == 2) {
      enemyEffects[nextEnemyEffect] = e;
      enemyEffects[nextEnemyEffect].createEffect();
      if (nextEnemyEffect < enemyEffects.length -1) {
        nextEnemyEffect++;
      }
      else {
        nextEnemyEffect = 0;
      }
    }
  }
  
  float getTilePosX(int tileX, int tileY) {
    float tilePosX = 0;
    tilePosX = mapPosX + tileX * mapTiles[tileX][tileY].tileSize;
    return tilePosX;
  }
  float getTilePosY(int tileX, int tileY) {
    float tilePosY = 0;
    tilePosY = mapPosY + tileY * mapTiles[tileX][tileY].tileSize;
    return tilePosY;
  }
}
