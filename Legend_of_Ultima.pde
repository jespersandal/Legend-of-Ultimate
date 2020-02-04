/*
Title: The Legend of Ultima-te Trademark Violations

By Jesper Stein Sandal

December 2019

This is top down-ish fantasy action game, where you play as a spell casting hero, defeating the various monsters and enemies of The Lands of Untitled.
You get points for defeating enemies and collecting gold - although you sadly don't have anything to spend all this gold on at this point. But it's shiny.
To navigate, you use the arrow keys, and you can use your various abilities using a,s,d,f,1,2. Be sure to drink your potions(press 1 and 2), 
and watch out for the necromancers!

If you do well enough, you might make it to the highscore list!

KNOWN ISSUES:
      Sometimes the game will start with a game over screen. This happens when an enemy has spawned near the hero, and the combination of the time fix
      and damage being damage per second against particle collisions. 
      
      Enemies can get stuck on the terrain. This is a pathing problem, when the enemy's vector towards the hero goes through a blocked tile.
      
      Enemy to enemy collisions are a bit aggressive. The collision box for enemies colliding with each other needs to be tweaked.
      
      Hero doesn't collide with enemies. This created frustrating navigation, because the player would feel too "stuck" close to multiple enemies.
      This may be partly because of the problem with the size of the collision boxes for the enemies, which places them at a distance that also
      block the hero.
      
      It doesn't matter which avatar you pick for your hero. It is only cosmetic at this point. The priority was to give the hero several different
      abilities. Adding more abilities would definitely be a priority for further development.

NOTE: We create all the levels/maps right away. This may not be the most efficient way, since it uses up more memory, but it adds
      benefits such as giving us an easy way to preserve the states of each map (enemies, treasure etc.) since each Map object can
      track this individually. Another way to do this would be to link the maps together (like nextMap, previousMap), but for now
      we keep it as a slightly manual procedure in the main program.

TODO: Sound effects. Heroes with different ability combinations. Hero experience and level up. Offensive and defensive boosts. Resistances. Respawn
      faster, tougher enemies when the player has defeated all enemies on the last map.

Graphics from Opengameart.org:
Tiles by Dungeon Crawl Stone Soup, https://opengameart.org/content/dungeon-crawl-32x32-tiles-supplemental
Hero sprites by Charles Gabriel (Antifarea), https://opengameart.org/content/twelve-16x18-rpg-sprites-plus-base
Enemy sprites by Stephen Challener (Redshrike), https://opengameart.org/content/16x16-16x24-32x32-rpg-enemies-updated

Fonts from Google Fonts:
Press Start 2 Play by CodeMan38
Slackey by Font Diner Inc.
*/


// Time fixes:
int ticksLastUpdate = 0;

// Events:
boolean scrolling = false;
boolean leftPressed = false;
boolean rightPressed = false;
boolean upPressed = false;
boolean downPressed = false;
boolean shieldActivated = false;

// Movement
int direction;
float speed;
int scale = 1;

// Global settings:
float lavaDamage = 45;

// Objects
Map[] mapLevels;
Hero hero;
Enemy[] enemies;

// Game state:
String gameState;  // can be "start", "selecthero", "running", "gameover", "entername", "highscore"
Map gameMap = null;
int level = 0;
int minLevel = 0;
int maxLevel = 4;
int score = 0;
boolean finishedLoading = false;  // fixes that the hero can be dead before everything is loaded.
boolean playerFirstAction = false;

// User interface:
PFont messageFont;
PFont titleFont;
PFont alertFont;
UserInterface heroUI;
SplashScreen welcomeScreen;
SplashScreen selectHero;
HighScore hiScore;
MessageBox yourName;

// Gameplay:
float particleDPS = 1.0; // The damage system is based on collisions with particles. This helps us time fix it.

void setup() {
  size(480, 320);
  //size(480, 320, P2D);
  colorMode(HSB, 360, 100, 100, 100);
  surface.setTitle("The Legend of Ultima-te Trademark Violations");
  gameState = "start";
  welcomeScreen = new SplashScreen();
  welcome();
  selectHero = new SplashScreen();
  selectHero();
  messageFont = createFont("PressStart2P-Regular.ttf", 14);
  alertFont = createFont("PressStart2P-Regular.ttf", 30);
  titleFont = createFont("Slackey-Regular.ttf", 24);
}

void draw() {
  background(0);
  if (gameState == "running" || gameState == "gameover") {
    gameMap.display();
    if (gameState == "running") {
      // Update and display the player character:
      hero.update(ticksLastUpdate);
      gameMap.effectsUpdate();
      ticksLastUpdate = millis();
      hero.display();
    }
    else if (gameState == "gameover") {
      fill(180, 100, 0, 40);
      rect(0, 0, width, height);
      fill(180, 100, 100, 100);
      textFont(alertFont);
      textAlign(CENTER);
      text("GAME OVER", width/2, height/3);
      textFont(messageFont);
      text("press space to continue", width/2, 2*(height/3));
      textAlign(LEFT);
    }
  }
  else if (gameState == "start") {
    welcomeScreen.display();
  }
  else if (gameState == "selecthero") {
    selectHero.display();
  }
  else if (gameState == "entername") {
    hiScore.display();
    yourName.displayArcadeInput();
  }
  else if (gameState == "highscore") {
    hiScore.display();
  }
}

// We need some of the keys to behave differently, depending on the state of the game, so this contains checks for the game state:
void keyPressed() {
  if (!playerFirstAction && gameState == "running") {
    playerFirstAction = true;
  }
  if (gameState == "running") {
    switch(keyCode) {
    case UP:
      direction = 0;
      upPressed = true;
      scrolling = true;
      break;
    case RIGHT:
      direction = 1;
      rightPressed = true;
      scrolling = true;
      break;
    case DOWN:
      direction = 2;
      downPressed = true;
      scrolling = true;
      break;
    case LEFT:
      direction = 3;
      leftPressed = true;
      scrolling = true;
      break;
    }
    if (key == '1') {
      hero.drinkPotion(1);
    }
    else if (key == '2') {
      hero.drinkPotion(2);
    }
    else if (key == 'd' || key == 'D') {
      if (!shieldActivated) {
        hero.castShield();
        shieldActivated = true;
      }
    }
  }
  // For entering the player's name:
  if (gameState == "entername") {
    if (key == ENTER || key == RETURN) {
      // The player has entered their name. We add it to the list and change the state of the game.
      hiScore.addName(score, yourName.playerName);
      gameState = "highscore";
    }
    if (key == BACKSPACE && yourName.cursorAtChar > 0) {
      // Deleting text is a bit tricky. We also need to check if we are at index 0 in the array.
      yourName.cursorAtChar--;
      yourName.playerName = yourName.playerName.substring(0, (yourName.cursorAtChar));
    } 
    else if (yourName.cursorAtChar > 0 && yourName.cursorAtChar < 6) {
      yourName.playerName = yourName.playerName.substring(0, (yourName.cursorAtChar)) + key;
      yourName.cursorAtChar++;
    }  
    else if (yourName.cursorAtChar == 0 && key != BACKSPACE) {
      yourName.playerName = key + yourName.playerName.substring(1);
      yourName.cursorAtChar++;
    } 
    else if (yourName.cursorAtChar == 0 && key == BACKSPACE) {
      yourName.playerName = "------";                           // This is not the most elegant fix, but it prevents the off-by-one error.
      yourName.cursorAtChar = 0;
    }
  }
}

void keyReleased() {
  if (scrolling) {
    switch(keyCode) {
    case UP:
      upPressed = false;
      break;
    case RIGHT:
      rightPressed = false;
      break;
    case DOWN:
      downPressed = false;
      break;
    case LEFT:
      leftPressed = false;
      break;
    }
    if (!upPressed && !rightPressed && !downPressed && !leftPressed) {
      scrolling = false;
    }
    if (upPressed) { 
      direction = 0;
    }
    if (rightPressed) { 
      direction = 1;
    }
    if (downPressed) { 
      direction = 2;
    }
    if (leftPressed) { 
      direction = 3;
    }
  }
  if (gameState == "running") {
    if (key == 'a' || key == 'A') {
      hero.mainAttack();
    }
    if (key == 's' || key == 'S') {
      hero.secondaryAttack();
    }
    if (key == 'd' || key == 'D') {
      hero.dropShield();
      shieldActivated = false;
    }
    if (key == 'f' || key == 'F') {
      hero.fourthAbility();
    }
  }
  if (gameState == "start" && key == ' ') {
    gameState = "selecthero";
  }
  else if (gameState == "selecthero" && key == ' ') {
    gameState = "running";
    startGame(selectHero.selection);
  }
  else if (gameState == "gameover" && key == ' ') {
    showHighScore();
    //gameState = "entername";
  }
  else if (gameState == "highscore" && key == 'q') {
    exit();
  }
  else if (gameState == "highscore" && key == 'p') {
    resetGame();
  }
  // Cheat codes for demo:
  if (key == '.') {
    changeMap(true);
  }
  if (key == '-') {
    changeMap(false);
  }
}
void mouseReleased() {
  if (gameState == "selecthero") {
    selectHero.selectedIcon(mouseX, mouseY);
  }
}

// When the hero moves to the stairs, we can switch maps. True means down, false means up.
void changeMap(boolean upDown) {
  if (upDown && level < maxLevel) {
    gameMap = mapLevels[++level];
  }
  else if (level > 0) {
    gameMap = mapLevels[--level];
  }
}

// At the last level, we need a way for the player to "win". For now, we just check if all enemies on level 4 has been defeated.
// We check this every time an enemy is killed.
void beatTheGame() {
  if (level == 4) {
    // We'll count the number of isDead enemies and compare to the total number (enemies.length).
    int deadCount = 0;
    for (int i = 0; i < gameMap.enemies.length; i++) {
      if (gameMap.enemies[i].isDead) {
        deadCount++;
      }
    }
    if (deadCount == gameMap.enemies.length) {
      gameState = "gameover";
    }
  }
}

void welcome() {
  welcomeScreen.title = "The Legend of Ultima\n-te Trademark Violations";
  String byline = "by Jesper S. Sandal";
  welcomeScreen.setTextLine(byline);
  welcomeScreen.setActionInstruction("press space to start");
}

void selectHero() {
  selectHero.setTextLine("Use the mouse\n to select your hero");
  PImage heroes = loadImage("heroes.png");
  selectHero.setIcons(heroes);
  selectHero.setActionInstruction("press space\n to start the game");
}

void startGame(int heroImage) {
  direction = 2;  // By initializing it with a value of 2, the hero will first be displayed facing the player.
  mapLevels = new Map[5];
  for (int i = 0; i <= maxLevel; i++) {
    mapLevels[i] = new Map(i);
  }
  gameMap = mapLevels[level];
  hero = new Hero();
  if (heroImage == 0) { // this is the default image.
  }
  else if (heroImage == 1) { hero.heroImage = loadImage("sorcerer1.png"); }
  else if (heroImage == 2) { hero.heroImage = loadImage("ranger2.png"); }
  else if (heroImage == 3) { hero.heroImage = loadImage("ranger1.png"); }
  else if (heroImage == 4) { hero.heroImage = loadImage("warrior2.png"); }
  else if (heroImage == 5) { hero.heroImage = loadImage("warrior1.png"); }
}

void showHighScore() {
  hiScore = new HighScore();
  int place = hiScore.checkScore(score);
  if (place < 10) {
    place = place + 1; // The computer counts from 0, but the human probably expects 1 to be first place, not 0.
    yourName = new MessageBox("You placed number " + place);
    gameState = "entername";
  }
  else {
    gameState = "highscore";
  }
}

void resetGame() {
  // Resetting all global variables:
  level = 0;
  score = 0;
  finishedLoading = false;  
  playerFirstAction = false;
  scrolling = false;
  leftPressed = false;
  rightPressed = false;
  upPressed = false;
  downPressed = false;
  shieldActivated = false;
  // Setting gameState to hero selection:
  gameState = "selecthero";
}
