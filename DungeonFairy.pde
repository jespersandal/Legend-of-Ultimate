/*
The DungeonFairy sprinkles enemies and treasure over the maps.

The class is really only used for holding some of the methods to generate each level. Since they are only necessary, when the Map object is
instantiated, I have put them in this helper class to avoid cluttering in the already very full Map class.

It also holds the subclasses for generating the various types of enemies that allows us to define specific speeds, attacks and other behaviour.
  These could also have been placed in the Enemy class file or in their own, separate files. But given the limited number of tabs in Proccessing's IDE,
  I decided it was best to put them close to where I needed the special behaviour (DungeonFairy handles the different enemies for the different
  levels.

ISSUES: There's a little bit too many hardcoded values spread throughout. Mainly related to scaling, but also what goes on for the different levels.
  If I ever wanted to expand the game with an engine for procedurally generated levels, something a bit more robust would be preferable.

*/

class DungeonFairy {
  // class fields
  MapTile[][] mapTiles;
  float mapPosX;
  float mapPosY;
  String[] textMap;
  float tileDisplaySize = 64;
  // constructor:
  DungeonFairy(float topLeftX, float topLeftY, MapTile[][] tiles) {
    mapTiles = tiles;
    mapPosX = topLeftX;
    mapPosY = topLeftY;
  }
  DungeonFairy(float topLeftX, float topLeftY, String[] lines) {
    textMap = lines;
    mapPosX = topLeftX;
    mapPosY = topLeftY;
  }
  // methods:
  
  // This method is only in case we later decide to scale up our graphics.
  void setTileDisplaySize(float size) {
    if (size >= 0 && size <= 4096) {  // Just checking for any ridiculous value.
      tileDisplaySize = size;
    }
  }
  
  
  // We will first make a list of enemies and then try to place them. If we can't find a valid random location on the map
  // in a limited number of tries, we discard the enemy and move on. This has the side effect of putting more enemies on a
  // big open map, and fewer on a small, closed map.
  
  Enemy[] spawnEnemies(int number, int mapLevel) {
    // We want to spawn random enemies, but the level of the dungeon determines the likelihood of certain types.
    Enemy[] randomEnemies = new Enemy[number];
    // Now, we fill this array with random enemies.
    for (int i = 0; i < randomEnemies.length; i++) {
      String nextEnemyType;
      int roll = int(random(0, 100));
      if (mapLevel == 0) {
        if (roll < 22) {
          nextEnemyType = "troll";
        }
        else {
          nextEnemyType = "goblin";
        }
      }
      else if (mapLevel == 1) {
        if (roll < 16) {
          nextEnemyType = "cultist";
        }
        else if (roll >= 16 && roll < 68) {
          nextEnemyType = "troll";
        }
        else {
          nextEnemyType = "goblin";
        }
      }
      else if (mapLevel == 2) {
        if (roll <= 8) {
          nextEnemyType = "necromancer";
        }
        else if (roll > 8 && roll < 44) {
          nextEnemyType = "troll";
        }
        else {
          nextEnemyType = "earth";
        }
      }
      else if (mapLevel == 3) {
        nextEnemyType = "water";
      }
      else if (mapLevel == 4) {
        if (roll < 16) {
          nextEnemyType = "skull";
        }
        else if (roll >= 16 && roll < 68) {
          nextEnemyType = "earth";
        }
        else {
          nextEnemyType = "cultist";
        }
      }
      else {
        nextEnemyType = "goblin";
      }
      randomEnemies[i] = makeEnemy(nextEnemyType);
    }
    randomEnemies = cleanUpNulls(randomEnemies);
    return randomEnemies;
  }
  
  // This method generates a new enemy of the specified type, unless we're unable to find a place to put the enemy.
  // If we can't place the enemy, we get a null value. We'll have to remove those, before we return the final Enemy[] to the Map object.
  
  Enemy makeEnemy(String enemyType) {
    float[] position = new float[2];
    position = randomValidPosition();
    if (position == null) {
      return null;    // This lets us just give it a limited number of tries to get a valid random position.
    }
    Enemy e;
    switch(enemyType) {
      case "goblin":
        e = new Goblin(position[0], position[1]);
        return e;
      case "troll":
        e = new Troll(position[0], position[1]);
        return e;
      case "cultist":
        e = new Cultist(position[0], position[1]);
        return e;
      case "necromancer":
        e = new Necromancer(position[0], position[1]);
        return e;
      case "water":
        e = new WaterElemental(position[0], position[1]);
        return e;
      case "skull":
        e = new FlameSkull(position[0], position[1]);
        return e;
      case "earth":
        e = new EarthElemental(position[0], position[1]);
        return e;
    }
    return null;
  }
  
  // First we pick a tile on the map at random. We're only looking at the characters in the original String[] that we read from the file.
  // We'll check to see if it is a tile that has no obstacles or special terrain. The tile types '0', '2' adn '4' are always open, so we'll only place enemies on 
  // those tiles for now. This may cause problems in our water level, but then we'll come back and add an extra check.
  
  float[] randomValidPosition() {
    int maxTries = 5;
    int mapWidth = textMap[0].length();
    int mapHeight = textMap.length;
    float[] mapPos = new float[2];
    for (int i = 0; i <= maxTries; i++) {
      int x = int(random(4, mapWidth));
      int y = int(random(4, mapHeight));
      if (textMap[y].charAt(x) == '0' || textMap[y].charAt(x) == '2' || textMap[y].charAt(x) == '4') {
        mapPos[0] = mapPosX + (x * tileDisplaySize) + 8;  // The 8 is a magic number for now to avoid spawning the enemy right at a wall.
        mapPos[1] = mapPosY + (y * tileDisplaySize) + 8;
        return mapPos;
      }
      else if (i == maxTries) {
        mapPos = null;
      }
    }
    return mapPos;
  }
  
  // Before we can return an Enemy[] to the Map object, we need to remove the null references that we may have gotten from the process above.
  
  Enemy[] cleanUpNulls(Enemy[] enemiesAndNull) {
    // First we count the number of nulls in our Enemy array:
    int nulls = 0;
    for (int i = 0; i < enemiesAndNull.length; i++) {
      if (enemiesAndNull[i] == null) {
        nulls++;
      }
    }
    // Then we create a new array for the actual enemies:
    Enemy[] enemies = new Enemy[(enemiesAndNull.length - nulls)];
    // And then we put all of our enemies into the new array.
    int enemiesIndex = 0;
    for (int i = 0; i < enemiesAndNull.length; i++) {
      if (enemiesAndNull[i] != null) {
        enemies[enemiesIndex] = enemiesAndNull[i];
        enemiesIndex++;
      }
    }
    // We should set the myIndex variable in each enemy for the self-collision check:
    for (int i = 0; i < enemies.length; i++) {
      enemies[i].myIndex = i;
    }
    return enemies;
  }
  
  // We can do the same for random treasure as we did for random enemies:
  Treasure[] sprinkleLoot(int number) {
    Treasure[] rolledTreasure = new Treasure[number];
    for (int i = 0; i < number; i++) {
      // First, we need to get a position. Note that this can return null.
      float[] treasureXY = randomValidPosition();
      // Now, we need to roll for the type of treasure. Since only gold, healing potions and mana potions are implemented for now, that's what we roll for:
      float roll = random(0,100);
      if (roll <= 25 && treasureXY != null) {
        rolledTreasure[i] = new Treasure(treasureXY[0], treasureXY[1], "mana potion");
      }
      else if (roll > 25 && roll <= 50 && treasureXY != null) {
        rolledTreasure[i] = new Treasure(treasureXY[0], treasureXY[1], "healing potion");
      }
      else if (treasureXY != null) {
        rolledTreasure[i] = new Treasure(treasureXY[0], treasureXY[1], "gold");
      }
    }
    // now we remove any null references that we may have ended up with in the process:
    rolledTreasure = cleanUpNulls(rolledTreasure);
    // now we need to let the Treasure objects know that they are on the ground:
    for (int i = 0; i < rolledTreasure.length; i ++) {
      rolledTreasure[i].placeOnGround();
    }
    return rolledTreasure;
  }
  
  // We also need to clean up nulls. 
  Treasure[] cleanUpNulls(Treasure[] treasureAndNull) {
    // First we count the number of nulls in our Treasure array:
    int nulls = 0;
    for (int i = 0; i < treasureAndNull.length; i++) {
      if (treasureAndNull[i] == null) {
        nulls++;
      }
    }
    // Then we create a new array for the actual Treasure objects:
    Treasure[] treasure = new Treasure[(treasureAndNull.length - nulls)];
    // And then we put all of our enemies into the new array.
    int treasureIndex = 0;
    for (int i = 0; i < treasureAndNull.length; i++) {
      if (treasureAndNull[i] != null) {
        treasure[treasureIndex] = treasureAndNull[i];
        treasureIndex++;
      }
    }
    return treasure;
  }
  
}

// Helper subclasses. Instead of epanding the Enemy class itself, let's try to use inheritance to create different types of enemies.

class Goblin extends Enemy {
  // class fields
  
  // constructor:
  Goblin(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("goblin.png");
  }
}

class Troll extends Enemy {
  // class fields
  
  // constructor:
  Troll(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("troll.png");
    aggroDistance = 90000.0;
    rangedDistance = 2000.0;
    rangedCoolLimit = 1000;
    hitPoints = 50;
    scoreValue = 150;
  }
  void rangedAttack(float dir, float targetX, float targetY) {
    float originX = posX;
    float originY = posY;
    // We want to adjust where the effect is centered depending on which way the enemy is facing:
    if (facing == 1) {
      originX += enemySize;
      originY += 0.5*enemySize;
    }
    else if (facing == 2) {
      originX += 0.5*enemySize;
      originY += enemySize;
    }
    else if (facing == 3) {
      originY += 0.5*enemySize;
    }
    else {
      originX += 0.5*enemySize;
    } 
    Effect e = new Effect(originX, originY, "slam", 40, facing);
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit;
  }
}

class Cultist extends Enemy {
  // class fields
  
  // constructor:
  Cultist(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("cultist.png");
    spriteHeight = 36;
    rangedCoolLimit = 1500;
    rangedDistance = 60000.0;
    hitPoints = 40;
    enemySpeed = 70;
    scoreValue = 300;
  }
  void rangedAttack(float distance, float speedX, float speedY) {
    // Enemies don't worry about mana cost unlike the hero. Enemies are evil, so they cheat!
    distance = sqrt(distance);
    speedX = speedX/distance;
    speedY = speedY/distance;
    float baseSpeed = 250;
    Effect e = new Effect(posX-(speedX*(enemySize/2))+(enemySize/2), posY-(speedY*(enemySize/2))+(enemySize/2), -speedX, -speedY, baseSpeed, "mini fireball", 10);
    // Why "-speedX"? I wondered about this, but the Enemy object moves towards the hero by substracting the speed. The particles move by adding the speed.
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit; 
  }
}

class Necromancer extends Enemy {
  // class fields
  
  // constructor:
  Necromancer(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("necromancer.png");
    resistPoison = true;
    aggroDistance = 90000.0;
    rangedDistance = 45000.0;
    rangedCoolLimit = 2000;
    hitPoints = 25;
    scoreValue = 450;
    enemySpeed = 60;
  }
  
  void rangedAttack(float distance, float speedX, float speedY) {
    // We dont't really need the arguments here, since necromancers are super evil and always hit the enemy!
    Effect e = new Effect(hero.getPosX()+hero.heroSize, hero.getPosY()+hero.heroSize, "poison cloud", 4);
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit;
  }
}

class WaterElemental extends Enemy {
  // class fields
  
  // constructor:
  WaterElemental(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("water.png");
    ignoresWater = true;
    spriteHeight = 36;
    spriteWidth = 36;
    hitPoints = 60;
    enemySpeed = 50;
    aggroDistance = 60000;
    rangedCoolLimit = 3000;
    rangedDistance = 60000.0;
    scoreValue = 300;
  }
  // Water elementals attack by hurling a big sphere of water against their enemies.
  void rangedAttack(float distance, float speedX, float speedY) {
    // Enemies don't worry about mana cost unlike the hero. Enemies are evil, so they cheat!
    distance = sqrt(distance);
    speedX = speedX/distance;
    speedY = speedY/distance;
    float baseSpeed = 100;
    Effect e = new Effect(posX-(speedX*(enemySize/2))+(enemySize/2), posY-(speedY*(enemySize/2))+(enemySize/2), -speedX, -speedY, baseSpeed, "drowning sphere", 40);
    // Why "-speedX"? I wondered about this, but the Enemy object moves towards the hero by substracting the speed. The particles move by adding the speed.
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit; 
  }
}

class EarthElemental extends Enemy {
  // class fields
  
  // constructor:
  EarthElemental(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("earth.png");
    resistFire = true;
    hitPoints = 80;
    enemySpeed = 20;
    aggroDistance = 90000;
    rangedCoolLimit = 3000;
    rangedDistance = 90000.0;
    enemySize = 64;
    spriteHeight = 36;
    spriteWidth = 36;
  }
  void rangedAttack(float distance, float speedX, float speedY) {
    // Enemies don't worry about mana cost unlike the hero. Enemies are evil, so they cheat!
    distance = sqrt(distance);
    speedX = speedX/distance;
    speedY = speedY/distance;
    float baseSpeed = 150;
    Effect e = new Effect(posX-(speedX*(enemySize/2))+(enemySize/2), posY-(speedY*(enemySize/2))+(enemySize/2), -speedX, -speedY, baseSpeed, "necro blob", 40);
    // Why "-speedX"? I wondered about this, but the Enemy object moves towards the hero by substracting the speed. The particles move by adding the speed.
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit; 
  }
}

class FlameSkull extends Enemy {
  // class fields
  
  
  // constructor:
  FlameSkull(float x, float y) {
    super(x, y);
    creatureSprite = loadImage("skull.png");
    resistFire = true;
    isFlying = true;
    enemySpeed = 95;
    rangedCoolLimit = 3000;
    rangedDistance = 10000.0;
    hitPoints = 40;
    scoreValue = 500;
  }
  
  // Fire breath attack:
  void rangedAttack(float dir, float targetX, float targetY) {
    float originX = posX;
    float originY = posY;
    // We want to adjust where the effect is centered depending on which way the enemy is facing:
    if (facing == 1) {
      originX += enemySize;
      originY += 0.5*enemySize;
    }
    else if (facing == 2) {
      originX += 0.5*enemySize;
      originY += enemySize;
    }
    else if (facing == 3) {
      originY += 0.5*enemySize;
    }
    else {
      originX += 0.5*enemySize;
    } 
    Effect e = new Effect(originX, originY, "fire breath", 20, facing);
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit;
  }
}
