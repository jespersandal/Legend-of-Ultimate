/*
This class is for the loot and treasure that you might find in the game.

ISSUES: There's a lot of hints in this class of functionality that had to be tabled for this version of my game. Such as support for items
      giving a temporary bonus that would dissappear after some time. I ended up prioritizing finishing the core of the game, but as you can
      see, the structures for some expanded functionality is still here.

TODO: It might be an idea to use inheritance for this if the number of different items increases greatly.
*/

class Treasure {
  // class fields:
  boolean onGround = false; // We can use this variable to display items that are on the ground.
  boolean inInventory = false; // We can use this for displaying items in the hero's inventory.
  float itemPosX;
  float itemPosY;
  PImage icon;
  String itemName = "";
  int goldValue = 1;  // if the item is gold, this variable holds how much gold.
  boolean active = false; // This is for when an item is activated either while worn or after drinking a potion.
  boolean consumable = false; // This allows us to check if the item disappears after use.
  int duration = 0; // If the item is consumable, it has a duration.
  int durationCounter = 0;
  int expirationCount = 0;
  // These are different bonuses that an item can give:
  int healing = 0;
  int mana = 0;
  int armor = 0;
  int offense = 0;
  int speed = 0;
  
  Treasure(float x, float y, String treasureType) {
    itemPosX = x;
    itemPosY = y;
    setTreasureType(treasureType);
  }
  Treasure(float x, float y, char treasureType) {
    itemPosX = x;
    itemPosY = y;
    setTreasureType(getTreasureType(treasureType));
  }
  
  void display() {
    if (onGround) {
      image(icon, itemPosX, itemPosY, 32, 32);
    }
  }
  
  void update(float mapPosX, float mapPosY) {
    if (onGround) {
      itemPosX += mapPosX;
      itemPosY += mapPosY;
      if (isColliding()) {
        onGround = false;
        inInventory = true;
        hero.addItem(this);
      }
    }
    if (active && duration > 0) {
      durationCounter = ticksLastUpdate;
      if (durationCounter >= expirationCount) {
        active = false;
      }
    }
  }
  
  boolean isColliding() {
    float heroX = hero.getPosX();
    float heroY = hero.getPosY();
    // We set a box of 32 x 32.
    if (heroX-16 < itemPosX && heroX+16 > itemPosX) {
      if (heroY-16 < itemPosY && heroY+16 > itemPosY) {
        //println("picked up a " + itemName);
        return true;
      }
      else { return false; }
    }
    else { return false; }
  }
  
  void placeOnGround() {
    onGround = true;
  }
  
  void activate() {
    if (!active) {
      active = true;
    }
    if (consumable) {
      expirationCount = ticksLastUpdate + duration;
      consumable = false;
    }
  }
  
  boolean checkDuration() {
    if (duration > 0) { return true; }
    else { return false; }
  }
  
  void setTreasureType(String t) {
    PImage itemIcons = loadImage("items.png");
    if (t == "healing potion") {
      duration = 1;
      healing = 50;
      consumable = true;
      itemName = "Healing Potion";
      icon = itemIcons.get(0, 0, 32, 32);
    }
    else if (t == "mana potion") {
      duration = 1;
      mana = 25;
      consumable = true;
      itemName = "Mana Potion";
      icon = itemIcons.get(32, 0, 32, 32);
    }
    else if (t == "potion of protection") {
      duration = 20000;
      armor = 10;
      consumable = true;
      itemName = "Potion of Protection";
      icon = itemIcons.get(64, 0, 32, 32);
    }
    else if (t == "potion of haste") {
      duration = 15000;
      speed = 60;
      consumable = true;
      itemName = "Potion of Haste";
      icon = itemIcons.get(96, 0, 32, 32);
    }
    else if (t == "potion of heroism") {
      duration = 15000;
      offense = 20;
      consumable = true;
      itemName = "Potion of Heroism";
      icon = itemIcons.get(128, 0, 32, 32);
    }
    else if (t == "gold") {
      goldValue = setRandomGoldValue();
      itemName = "Gold";
      icon = itemIcons.get(0, 32, 32, 32);
    }
  }
  
  String getTreasureType(char t) {
    switch(t) {
      case 'G':
      return "gold";
      case 'H':
      return "healing potion";
      case 'M':
      return "mana potion";
      case 'P':
      return "potion of protection";
      case 'S':
      return "potion of haste";
      case 'Z':
      return "potion of heroism";
      default:
      return "";
    }
  }
  
  int setRandomGoldValue() {
    // let's roll a couple of dice and add them up to get a good probability distribution:
    int goldSum = 0;
    for (int i = 0; i < 5; i++) {
      goldSum += int(random(1, 6));
    }
    return goldSum;
  }
}
