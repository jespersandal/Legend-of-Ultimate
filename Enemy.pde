/*
This is the main class for all enemies. It is used for keeping track of the enemies' positions and movement. It also contains the main
chase algorithm for attacking the hero.

The specific enemies are created by the DungeonFairy class.

ISSUES: The enemies can collide with each other, but the collision box is a little big, causing the enemies to sometimes get stuck, when they group up.
      However, since the game right now is fairly difficult for the player, giving the player a bit of an advantage of using the map is not terrible.
*/

class Enemy {
  
  // Class fields:
  int myIndex; // This value should be set to the enemy's index in the Enemy array - that way we can avoid it colliding with itself.
  float posX;
  float posY;
  float enemySpeed = 80;
  boolean inLava = false;
  boolean inWater = false;
  boolean ignoresWater = false;
  boolean isFlying = false;
  boolean resistFire = false;
  boolean resistPoison = false;
  boolean isSlowed = false;
  PImage creatureSprite;
  int spriteWidth = 32;
  int spriteHeight = 32;
  float enemySize = 48;
  int ticksLastUpdate;
  int currentFrame = 1; // We initialize at frame 1, since this is at rest.
  int maxFrame = 4;     // We only have 4 frames for the animation.
  int frameDuration = 125;  // Time in milliseconds between frames.
  int facing = 2;       // We use this value to display the sprite from front, behind, left or right.
  boolean isChasing = false;
  boolean isDying = false;
  float fadeAway = 255;
  boolean isDead = false;
  int ticksLastVectorUpdate;
  float aggroDistance = 60000.0;
  float rangedDistance = 20000.0;
  float closeDistance = 1024.0;
  int rangedCool; // Cooldown for the ranged attack. The enemy can only use the attack, after the cooldown.
  int rangedCoolLimit = 600;  // This is the cooldown time in milliseconds between attacks.
  float hitPoints = 20;
  int scoreValue = 100;
  
  // Constructor:
  Enemy(float x, float y) {
    ticksLastUpdate = millis();
    posX = x;
    posY = y;
    // Here we should select the type of enemy this is:
    creatureSprite = loadImage("skull.png");
  }
  
  void display() {
    //if (isDying) {
    //  PImage frame = creatureSprite.get(currentFrame*32, facing*32, 32, 32);
    //  tint(360, 100, 100, fadeAway);
    //  image(frame, posX, posY, enemySize, enemySize);
    //  noTint();
    //}
    if (isDead) { return; }  // exits display method early.
    // The size of the frame that we grab needs to be adjusted to the type of enemy this is.
    PImage frame = creatureSprite.get(currentFrame*spriteWidth, facing*spriteHeight, spriteWidth, spriteHeight);
    // The size we display the sprite at should also depend on the type of enemy.
    image(frame, posX, posY, enemySize, enemySize);
    int delta = millis() - ticksLastUpdate;
    if (delta >= frameDuration && scrolling) {
      currentFrame++;
      if (currentFrame >= maxFrame) {
        currentFrame = 0;
      }
      ticksLastUpdate += delta;
    }
  }
  
  // This function is used for fixing the Enemy object's position to the map as the player moves
  void mapUpdate(float moveX, float moveY) {
    posX += moveX;
    posY += moveY;
  }
  
  void update(int ticks) {
    if (isDead) { return; }  // exits update method early.
    // First we check for "aggro". Enemies will chase the hero, if the hero is within a set distance:
    float deltaX = posX - hero.getPosX(); 
    float deltaY = posY - hero.getPosY();
    float distanceSquared = ((deltaX*deltaX) + (deltaY*deltaY));
    if (distanceSquared < aggroDistance) {
      isChasing = true;
    }
    else {
      isChasing = false;
    }
    // Now we check if the enemy is within range to attack, and if the attack has cooled down.
    if (distanceSquared <= rangedDistance) {  // Debug: We used to check for isChasing, but this would stop the enemy from attacking if it had collided with another enemy.
      int cooldown = millis() - rangedCool;
      if (cooldown > 0) {
        isChasing = false;
        rangedAttack(distanceSquared, deltaX, deltaY);
      }
      if (distanceSquared <= closeDistance) {
        isChasing = false;
      }
    }
    if (isChasing) {
      // We can use Pythagoras to get the hypotenuse of the triangle:
      float hypotenuse = sqrt(distanceSquared);
      // Now we need to normalize the x and y vectors before we apply the speed:
      deltaX = deltaX/hypotenuse;
      deltaY = deltaY/hypotenuse;
      // Now we can move the enemy towards the player, but first we must check if the move would cause a collision:
      float moveToX = posX - deltaX * enemySpeed * (float(millis() - ticks) * 0.001);
      float moveToY = posY - deltaY * enemySpeed * (float(millis() - ticks) * 0.001);
      // Before we check for collision and move the enemy, we can also use these values to figure out which way it is facing.
      // We already have the vectors, but we need to use the absolute values to compare their lengths.
      if (deltaX < 0 && abs(deltaX) > abs(deltaY)) {
        facing = 1;
      }
      else if (deltaX > 0 && abs(deltaX) > abs(deltaY)) {
        facing = 3;
      }
      else if (deltaY > 0 && abs(deltaY) > abs(deltaX)) {
        facing = 0;
      }
      else {
        facing = 2;
      }
      int colCheck = gameMap.isEnemyColliding(moveToX, moveToY);
      if (colCheck == 1) {
        isChasing = false;
      }
      else if (colCheck == 2 && !isFlying && !ignoresWater) {
        posX = moveToX*0.5;
        posY = moveToY*0.5;
        isChasing = true;
        inWater = true;
        inLava = false;
      }
      else if (colCheck == 3 && !resistFire && !isFlying) {
        posX = moveToX;
        posY = moveToY;
        isChasing = true;
        inWater = false;
        inLava = true;
        hitPoints -= (lavaDamage/2) * float(millis() - ticks) * 0.001;  // Yes, enemies takes half as much damage from lava as the hero. They don't know where they're going.
      }
      int colEnemiesChk = gameMap.enemiesColliding(moveToX, moveToY, enemySize, myIndex);
      if (colEnemiesChk == 1 && isChasing) {
        // Right now, we just let the enemy skip it's move, if it collides with another enemy. This could be improved.
        isChasing = true;
      }
      else if (isChasing) {
        posX = moveToX;
        posY = moveToY;
        isChasing = true;
      }
    }
    // Right now, all collisions just do a fixed amount of damage.
    hitPoints -= gameMap.checkEffectCollisions(posX, posY, enemySize, 1) * particleDPS * float(millis() - ticks) * 0.001;  // The 1 means we check against the player effects.
    if (hitPoints <= 0) {
      //isDying = true;
      isDead = true;
      isChasing = false;
      Effect e = new Effect(posX, posY, "gore", 1);
      gameMap.addEffect(e, 0);
      score += scoreValue;
      dropLoot();
    }
  }
  
  void rangedAttack(float distance, float speedX, float speedY) {
    // Enemies don't worry about mana cost unlike the hero. Enemies are evil, so they cheat!
    distance = sqrt(distance);
    speedX = speedX/distance;
    speedY = speedY/distance;
    float baseSpeed = 300;
    Effect e = new Effect(posX-(speedX*(enemySize/2))+(enemySize/2), posY-(speedY*(enemySize/2))+(enemySize/2), -speedX, -speedY, baseSpeed, "enemy missiles", 6);
    // Why "-speedX"? I wondered about this, but the Enemy object moves towards the hero by substracting the speed. The particles move by adding the speed.
    gameMap.addEffect(e, 2);
    rangedCool = millis() + rangedCoolLimit; 
  }
  
  // This method let's us deal damage to the enemy. We can specify which type to allow enemies to resist certain types and be vulnerable to others.
  void updateHitPoints(float dam, String damType) {
    if (damType == null || damType == "") {
      hitPoints -= dam;  // If there's no damage type, it is just damage.
    }
    else if (damType == "fire" && resistFire) {
      hitPoints -= 0.1*dam;
    }
    else if (damType == "poison" && resistPoison) {
      hitPoints -= 0.1*dam;
    }
    else {
      hitPoints -= dam;
    }
  }
  // When an enemy dies, it drops either gold or a potion. So when the enemy is dead, we call this method:
  void dropLoot() {
    Treasure enemyLoot;
    float roll = random(0, 100);
    if (roll >= 75) {
      float secondRoll = random(0, 100);
    if (secondRoll > 50) {
      enemyLoot = new Treasure(posX, posY, "healing potion");
    }
    else {
      enemyLoot = new Treasure(posX, posY, "mana potion");
    }
    }
    else {
      enemyLoot = new Treasure(posX, posY, "gold");
    }
    enemyLoot.placeOnGround();
    gameMap.addLoot(enemyLoot);
  }
}
