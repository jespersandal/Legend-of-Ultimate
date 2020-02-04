/*
The HighScore class loads the current highscores from a text file, displays them, allows us to check if and where a score would place on the
  list, and lets us add a name and score to the list.
  
NOTE: Much of this has been repurposed from the highscore list I made for Flappy Bird. I had to tweak the display method to accomodate for the
      smaller screen size of this game.

*/

class HighScore {
  
  SplashScreen screen;
  String[] highScoreNames;
  int[] highScores;
  int place = 10;  // This means it starts outside of top 10 - since 0 is the best place.
  
  // Constructor
  HighScore() {
    screen = new SplashScreen();
    screen.longlist = true;
    highScoreNames = new String[10];
    highScores = new int[10];
    // We get the high scores from a file:
    String[] lines = loadStrings("scores.txt");
    // We need to split the names from the scores and turn the scores into integers:
    for (int i = 0; i < lines.length; i++) {
      String[] s = split(lines[i], ',');
      highScoreNames[i] = s[0];
      highScores[i] = int(s[1]);
    }
    // We prepare the SplashScreen object:
    screen.title = "High Scores";
    screen.textLines = new String[10];    
    screen.actionsInstructions = new String[2];
    screen.actionsInstructions[0] = "Press 'p' to play again";
    screen.actionsInstructions[1] = "Press 'q' to quit";
    //screen.titleFont = gillSans48;
    //screen.splashFont = gillSans36;
    update();
  }
  
  void save() {
    // Saves the high score list to a file.
    // First we need to recreate an array of strings, where each string is composed of the name, the delimiter "," and the score.
    String[] strOut = new String[10];
    for (int i = 0; i < strOut.length; i++) {
      strOut[i] = highScoreNames[i] + "," + highScores[i];
    }
    saveStrings("data/scores.txt", strOut);
  }
  
  void display() {
    screen.display();
  }
  
  void update() {
    // We add the values to our SplashScreen object:
    for (int i = 0; i < highScoreNames.length; i++) {
      screen.textLines[i] = highScoreNames[i] + "   " + highScores[i];
    }
  }
  
  void addName(int sco, String name) {
    // We remove any extra dashes from the name:
    name = name.replaceAll("-", "");
    // To make it arcade style, we convert the name to uppercase letters:
    name = name.toUpperCase();
    if (place >= 0 && place <= 9) {
      // This is a new highscore, so we need to rearrange our list:
      for (int j = (highScores.length - 1); j > place; j--) {
        highScores[j] = highScores[j-1];
        highScoreNames[j] = highScoreNames[j-1];
      }
      highScores[place] = sco;
      highScoreNames[place] = name;
    } 
    // We need to update the SplashScreen object so the new list is displayed:
    update();
    // we reset the value of place for the next game:
    place = 10;
    // We should save the high scores now.
    save();
  }
  
  int checkScore(int score) {
    boolean placed = false;
    for (int i = 0; i < highScores.length && !placed; i++) {   // We compare from the highest to the lowest score.
      // compare scores
      if (score >= highScores[i]) {
        placed = true;
        place = i;
      }
    }
    if (place >= 0 && place < highScores.length) {
      return place;
    }
    else {
      return 10;
    }
  }
}
