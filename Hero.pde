/*
This is the hero. This class keeps track of all the informations related to the hero that isn't on the map. There are many conditions and abilities that
need to be tracked. It is built to be expanded with more abilities and advanced stuff.

TODO: We are not really using the inventory yet. But we have the possibility to add more types of potions or other items at a later point.
      
      We are also not using the option to add temporary effects to regeneration of hit points or mana.
      
      The hero can run through enemies. This is not ideal and should be fixed.
      
ISSUES: The fix for the weird result of the check for lava damage works, but it has not really solved the cause of the problem. I suspect it must be checking
      for collisions with all the maps, before the game is fully loaded. For now it should only check for lava damage if the level i greater than 0. This works,
      since there's no lava on level 0, but a true fix would be better than this workaround.
 */

class Hero {
  float heroSize = 16;
  float posX = (width/2) - (0.5*heroSize);
  float posY = (height/2) - heroSize;
  PImage heroImage;
  int currentFrame;
  int maxFrame = 4; // We only have 4 frames for the animation
  int frameDuration = 125;
  int ticksLast;
  float baseSpeed = 120.0;
  float effectSpeed = 0.0;
  boolean isBlocked = false;
  boolean inWater = false;
  boolean inLava = false;
  boolean isShielded = false;
  int mainAttackCool;
  int mainAttackCoolDownTime = 400;
  int secondaryAttackCool;
  int secondaryAttackCoolDownTime = 2000;
  int thirdAbilityCool = 0; // The third ability is the magic shield for this hero (the only type right now).
  int thirdAbilityCoolDownTime;
  int fourthAbilityCool;  
  int fourthAbilityCoolDownTime = 1800;
  float baseHitPoints;
  float currentHitPoints;
  boolean isDead = false;
  float baseHPRegen = 0.8; // Hit points per second.
  float effectHPRegen = 0; // Additional regeneration from effects, equipment or abilities.
  StatusBar hitPointBar;
  float baseManaPoints;
  float currentManaPoints;
  float baseMRegen = 5; // Mana points per second.
  float effectMRegen = 0; // Additional regeneration from effect.
  StatusBar manaBar;
  int goldLooted = 0;
  Treasure[] inventory;
  int inventoryIndex = 0;
  int healthPotions = 5;
  int manaPotions = 5;
  
  Hero() {
    heroImage = loadImage("sorcerer2.png");
    currentFrame = 1;  // we start at the middle frame, which displays the character at rest.
    ticksLast = millis();
    baseHitPoints = 100;
    currentHitPoints = baseHitPoints;
    hitPointBar = new StatusBar(baseHitPoints, (width/2)-140, 15, 120);
    hitPointBar.setColor("red");
    baseManaPoints = 100;
    currentManaPoints = baseManaPoints;
    manaBar = new StatusBar(baseManaPoints, (width/2)+20, 15, 120);
    manaBar.setColor("blue");
    inventory = new Treasure[1000];  // We're giving our hero a Bag of Holding. Gold it kept on the side.
    heroUI = new UserInterface();
  }
  void update(int ticks) {
    if (isDead || !finishedLoading) {
      return;  // No need to update anything if the hero is dead.< or the game isn't ready.
    }
    // Collision check:
    if (gameMap.isHeroColliding()) {
      if (isBlocked) {
        scrolling = false;
        upPressed = false;
        rightPressed = false;
        downPressed = false;
        leftPressed = false;
      }
    }
    if (scrolling) {
      float currentSpeed = 0.0;
      if (inWater) {
        currentSpeed = (0.5 * (baseSpeed + effectSpeed)) * float(millis() - ticks) * 0.001;
      }
      else {
        currentSpeed = (baseSpeed + effectSpeed) * float(millis() - ticks) * 0.001;
      }
      gameMap.update(direction, currentSpeed);
    }
    // Take damage from effects and terrain:
    if (!playerFirstAction && inLava && level > 0) {
      // The check for first action should prevent the hero from taking damage from terrain, before the game is ready.
      currentHitPoints -= lavaDamage * float(millis() - ticks) * 0.001;
    }
    float myHits = gameMap.checkEffectCollisions(posX, posY, heroSize*2, 2); // The 2 means we check against enemy effects.
    if (isShielded && currentManaPoints > 10) {
      currentManaPoints -= myHits * particleDPS * float(millis() - ticks) * 0.001;  // The magic shield effect lets the hero use mana instead of taking damage.
      if (currentManaPoints <= 0) {
        currentHitPoints += currentManaPoints;
        isShielded = false;
      }
    }
    else {
      currentHitPoints -= myHits * particleDPS * float(millis() - ticks) * 0.001;
    }
    // update hit points and mana:
    if (currentHitPoints < baseHitPoints) {
      currentHitPoints += (baseHPRegen + effectHPRegen) * float(millis() - ticks) * 0.001;
    }
    if (currentHitPoints > baseHitPoints) {
      currentHitPoints = baseHitPoints;
    }
    hitPointBar.setCurrentValue(currentHitPoints);
    if (currentManaPoints < baseManaPoints) {
      currentManaPoints += (baseMRegen + effectMRegen) * float(millis() - ticks) * 0.001;
    }
    if (currentManaPoints > baseManaPoints) {
      currentManaPoints = baseManaPoints;
    }
    manaBar.setCurrentValue(currentManaPoints);
    // Finally, we check if the hero is still alive. We'll let 0 hit points be ok, since it's he hero after all:
    if (currentHitPoints < 0) {
      isDead = true;
      scrolling = false;
      gameState = "gameover"; // you only have one life. Even as the hero.
    }
  }
  void display() {
    // from the main program, we get the direction as an integer which matches the row of frames we need.
    PImage frame = heroImage.get(currentFrame*16, direction*18, 16, 18);
    image(frame, posX, posY, 32, 36);
    int delta = millis() - ticksLast;
    if (delta >= frameDuration && scrolling) {
      currentFrame++;
      if (currentFrame >= maxFrame) {
        currentFrame = 0;
      }
      ticksLast += delta;
    }
    // Display the magic shield if activated:
    if (isShielded) {
      fill(191, 48, 92, 35);
      stroke(191, 48, 53, 50);
      ellipse(posX+heroSize, posY+heroSize, heroSize*4, heroSize*4);
    }
    // Display hit point bar:
    hitPointBar.display();
    manaBar.display();
    heroUI.display();
  }
  
  void addItem(Treasure item) {
    if (item.itemName == "Gold") {
      goldLooted += item.goldValue;  // Gold coins go straight in the pocket rather than inventory.
      score += item.goldValue;  // You get points for picking up gold.
    }
    else {
      inventory[inventoryIndex] = item;
      if (inventoryIndex == (inventory.length-1)) {
        inventoryIndex = 0;  // We've looted so much stuff that the bag of holding can't hold any more, so we're starting over.
      }
      else {
        inventoryIndex++;
      }
    }
    if (item.itemName == "Healing Potion") {
      healthPotions++;
    }
    else if (item.itemName == "Mana Potion") {
      manaPotions++;
    }
  }
      
  
  void mainAttack() {
    int cooldown = millis() - mainAttackCool;
    if (cooldown > 0) {
      castMagicMissile();
    }
  }
  void secondaryAttack() {
    int cooldown = millis() - secondaryAttackCool;
    if (cooldown > 0) {
      castColourCone();
    }
  }
  void fourthAbility() {
    int cooldown = millis() - fourthAbilityCool;
    if (cooldown > 0) {
      castFireBall();
    }
  }
  
  void castFireBall() {
    float manaCost = 30;
    if (currentManaPoints - manaCost < 0) {
      return; // No casting a spell without paying the mana cost.
    }
    float range = 120;
    float targetX = hero.getPosX() + heroSize;
    float targetY =  hero.getPosY() + heroSize;
    if (direction == 0) {
      targetY -= range;
    }
    else if (direction == 1) {
      targetX += range;
    }
    else if (direction == 2) {
      targetY += range;
    }
    else if (direction == 3) {
      targetX -= range;
    }
    Effect e = new Effect(targetX, targetY, "fireball", 6);
    gameMap.addEffect(e, 1);  // The 1 designates that this is a player effect.
    fourthAbilityCool = millis() + fourthAbilityCoolDownTime; // This is a hardcoded cooldown value. There should be a better way to change this if we change hero types later.
    currentManaPoints -= manaCost;
    manaBar.setCurrentValue(currentManaPoints);
  }
  
  void castMagicMissile() {
    float manaCost = 10;
    int coolTime = mainAttackCoolDownTime;
    if (currentManaPoints - manaCost < 0) {
      return; // No casting a spell without paying the mana cost.
    }
    float originX = hero.getPosX();
    float originY =  hero.getPosY();
    if (direction == 0) {
      originX += heroSize;
      originY -= heroSize;
    }
    else if (direction == 1) {
      originX += heroSize*2;
      originY += heroSize;
    }
    else if (direction == 2) {
      originY += heroSize*2;
      originX += heroSize;
    }
    else if (direction == 3) {
      originX -= heroSize;
      originY += heroSize;
    }
    Effect e = new Effect(originX, originY, "missiles", 6);
    gameMap.addEffect(e, 1);
    mainAttackCool = millis() + coolTime; 
    currentManaPoints -= manaCost;
    manaBar.setCurrentValue(currentManaPoints);
  }
  
  void castColourCone() {
    int coolTime = secondaryAttackCoolDownTime;
    float manaCost = 25;
    if (currentManaPoints - manaCost < 0) {
      return; // No casting a spell without paying the mana cost.
    }
    float originX = getPosX();
    float originY = getPosY();
    if (direction == 1 || direction == 2) {
      originX += heroSize*2;
      originY += heroSize*2;
    }
    Effect e = new Effect(originX, originY, "colour cone", 6);
    gameMap.addEffect(e, 1);
    secondaryAttackCool = millis() + coolTime;
    currentManaPoints -= manaCost;
    manaBar.setCurrentValue(currentManaPoints);
  }
  
  // The magic shield effect requires us to toggle it on while the key is pressed, and stop it when the key is released.
  void castShield() {
    isShielded = true;
  }
  void dropShield() {
    isShielded = false;
  }
  
  void drinkPotion(int potion) {
    if (potion == 1 && healthPotions > 0) {
      currentHitPoints += 25;
      if (currentHitPoints > baseHitPoints) {
        currentHitPoints = baseHitPoints;
      }
      healthPotions--;
    }
    else if (potion == 2 && manaPotions > 0) {
      currentManaPoints += 25;
      if (currentManaPoints > baseManaPoints) {
        currentManaPoints = baseManaPoints;
      }
      manaPotions--;
    }
  }
  
  float getPosX() {
    return posX;
  }
  float getPosY() {
    return posY;
  }
  float getHeroSpeed() {
    return baseSpeed + effectSpeed;
  }
  // We can use this method to add effects such as Haste spell or a Potion of Speed:
  void setHeroSpeed(float spd) {
    effectSpeed = spd;
  }
  float getHeroSize() {
    return heroSize;
  }
}
