/* This class is for a box that can pop up and ask for user input or display a message

NOTE: This is based on the code I used for the Flappy Bird clone.

We can reuse this for entering your name if you make it to the highscore list or display a message while pausing the game.
*/

class MessageBox {
  
  // Fields
  String messageText;
  String userInput;
  //PFont messageFont;
  PFont inputFont;
  color boxColor;
  color textColor;
  
  // Constructor
  MessageBox(String m) {
    messageText = m;
    boxColor = color(42, 51, 87, 100);
    textColor = color(180, 0, 0, 100);
    inputFont = messageFont;
  }
  
  void display() {
    fill(boxColor);
    rectMode(CENTER);
    rect(width/2, height/2, width*0.8, height*0.8, 5);
    textAlign(CENTER);
    textFont(messageFont);
    fill(textColor);
    text(messageText, width/2, (height/2) - 24);
  }
  
  // We need to be able to input text, when the player enter their name.
  
  // It might be more elegant to extend the class by inheritance to a new class InputBox.
  
  int cursorAtChar = 0;  // Keeps track of how many characters has been entered out of the maximum 6 for your high score name.
  String playerName = "------";  // Using dashes to show how many characters you can enter. We should remember to remove extra dashes when we're done.
  
  void displayArcadeInput() {
    // We need to display the MessageBox:
    display();
    // And then add the playerName:
    textFont(inputFont);
    text(playerName, width/2, (height/2) + 24);
    // Resetting textAlign and rectMode:
    textAlign(LEFT);
    rectMode(CORNER);
  }
  
}
