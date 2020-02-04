/*
This class is for handling most of the user interface. It displays the items in the hero's inventory and the hero's abilities. This should help the player
remembering which buttons activate which ability.

NOTE: The hero keeps track of its hit point and mana status bars, and the main program keeps track of the score. Later on, it might clean up the hero class
      and the main program, if we move some of that to here.

ISSUES: There's not really room to displlay both the number of remaining potions and the shortcut to activate them. But we're also displaying the shortcuts
      for the skills, so it could create some misunderstanding. Instructions should be made clear on the welcome screen.

TODO: Simplify the visualisation of the cooldown using a redesign of the Hero class' use of cooldown timers so they are more easily accessible, and by making
      the coordinates for displaying the skill bar easier to access.
*/

class UserInterface {
  PImage items;
  PImage skills;
  float displaySize = 32;
  float padding = 2;
  UserInterface() {
    items = loadImage("items.png");
    skills = loadImage("skills.png");
  }
  void display() {
    displayScore();
    displaySkills();
    displayItems();
    displayCooldown();
  }
  void displayScore() {
    textFont(messageFont);
    fill(255);
    textAlign(LEFT);
    text("score:\n"+score, 10, 20);
    textAlign(RIGHT);
    text("level:\n"+level, 470, 20);
  }
  void displaySkills() {
    fill(180, 0, 0, 70);
    stroke(180, 0, 20, 50);
    strokeWeight(3);
    float skillBarX = (4*displaySize)+(5*padding);
    float topX = (width/2)-(skillBarX/2);
    float topY = height-((2*displaySize)+(6*padding));
    float skillBarHeight = displaySize+(2*padding);
    rect(topX, topY, skillBarX, skillBarHeight);
    String[] buttons = { "a", "s", "d", "f" };
    fill(282, 2, 98, 80);
    textAlign(LEFT);
    for (int i = 0; i < 4; i++) {
      PImage skill = skills.get(i*32, 0, 32, 32);
      image(skill, topX+padding+(i*displaySize)+(i*padding), topY+padding);
      text(buttons[i], topX-(2*padding)+displaySize+(i*displaySize), topY+padding+displaySize);
    }
  }
  void displayItems() {
    fill(180, 0, 0, 70);
    stroke(180, 0, 20, 50);
    strokeWeight(3);
    float itemBarX = (6*displaySize)+(7*padding);
    float topX = (width/2)-(itemBarX/2);
    float topY = height-(displaySize+(2*padding));
    float itemBarHeight = displaySize+(2*padding);
    rect(topX, topY, itemBarX, itemBarHeight);
    String[] buttons = { str(hero.healthPotions), str(hero.manaPotions) }; // We only have two items at the moment that can be activated: health potions and mana potions.
    fill(282, 2, 98, 80);
    textAlign(LEFT);
    for (int i = 0; i < 2; i++) {
      PImage item = items.get(i*32, 0, 32, 32);
      image(item, topX+padding+(i*displaySize)+(i*padding), topY+padding);
      text(buttons[i], topX-(2*padding)+displaySize+(i*displaySize), topY+padding+displaySize);
    }
  }
  // This is used for showing a shrinking, translucent box over the ability to indicate the remaining cooldown time.
  void displayCooldown() {
    // Since the hero's abilities and cooldown timers are not in a nice array, we need to do it one by one:
    // mainAttack:
    float tMax = hero.mainAttackCoolDownTime;
    float tCurrent = hero.mainAttackCool;
    float deltaT = millis() - tCurrent;
    float coolX = (width/2)-((2*displaySize)+(2*padding)/2);
    float coolY = height-((2*displaySize)+(5*padding));
    if (deltaT > 0) {
      float coolSize = displaySize;  
      float coolHeight = (deltaT/tMax) * coolSize;
      if (coolHeight < coolSize) {
        coolY += coolHeight;
        fill(180, 25, 78, 50);
        noStroke();
        rect(coolX, coolY, coolSize, (coolSize - coolHeight));
      }
    }
    // secondaryAttack:
    tMax = hero.secondaryAttackCoolDownTime;
    tCurrent = hero.secondaryAttackCool;
    deltaT = millis() - tCurrent;
    coolX = (width/2)-((displaySize)+(padding)/2);
    if (deltaT > 0) {
      float coolSize = displaySize;  
      float coolHeight = (deltaT/tMax) * coolSize;
      if (coolHeight < coolSize) {
        coolY += coolHeight;
        fill(180, 25, 78, 50);
        noStroke();
        rect(coolX, coolY, coolSize, (coolSize - coolHeight));
      }
    }
    // fourthAbility:
    tMax = hero.fourthAbilityCoolDownTime;
    tCurrent = hero.fourthAbilityCool;
    deltaT = millis() - tCurrent;
    coolX = (width/2)+((displaySize)+(2*padding));
    if (deltaT > 0) {
      float coolSize = displaySize;  
      float coolHeight = (deltaT/tMax) * coolSize;
      if (coolHeight < coolSize) {
        coolY += coolHeight;
        fill(180, 25, 78, 50);
        noStroke();
        rect(coolX, coolY, coolSize, (coolSize - coolHeight));
      }
    }
  }
}
