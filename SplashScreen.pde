/*
This class is used as a standard way to display information on the screen, such as the Start Screen, the Game Over screen,
and it is also used for displaying the High Score. This way, we reuse some of the logic.

NOTE: This is based on the code I made for the Flappy Bird clone.

TODO: Proper set/get methods for the fields.
*/

class SplashScreen {
  
  String title;     // Can be used as a headline for the screen, displayed top and center in a big font.
  PImage graphics;  // We may need to display a logo or something.
  String[] textLines; // An array to hold the lines of text, we'll display such as high scores.
  String[] actionsInstructions; // For interactivity instructions to the player.
  PFont splashFont;  // holds the font, we'll use as standard.
  PImage selectionIcons;
  boolean showIcons = false;
  boolean showSelectedBox = false;
  boolean longlist = false;  // This allows us to re-adjust how the text is displayed if the list is longer than a couple of lines.
  int selection = 0;
  //PFont titleFont;   // Allows for a different font or size for the title.
  color splashTextColor = color(42, 92, 19, 100);
  
  // Constructor:
  SplashScreen() {
    splashFont = messageFont;
    textLines = new String[10];
    actionsInstructions = new String[10];
  }
  
  void display() {
    fill(42, 51, 87, 100);
    rectMode(CENTER);
    rect(width/2, height/2, width*0.8, height*0.8, 20);
    textAlign(CENTER);
    textFont(titleFont);
    fill(splashTextColor);
    if (title != null) {
      textLeading(28);
      text(title, width/2, height*0.2);
    }
    textFont(messageFont);
    if (textLines != null) {
      textSize(12);
      for (int i = 0; i < textLines.length; i++) {
        if (textLines[i] != null && !longlist) {    // We may have more places in than we have set String objects, so we need to check for null.
          text(textLines[i], width/2, height*(0.5 + (i*0.05)));
        }
        else if (textLines[i] != null && longlist) {
          textSize(10);
          text(textLines[i], width/2, height*(0.28 + (i*0.05)));
        }
      }
    }
    if (actionsInstructions != null) {
      for (int i = 0; i < actionsInstructions.length; i++) {
        if (actionsInstructions[i] != null) {
          text(actionsInstructions[i], width/2, (height*(0.8 + i*0.05)));
        }
      }
    }
    // There are some hardcoded values here that make parts of the class hard to reuse.
    if (showIcons) {
      image(selectionIcons,(width/2)-192, height/4, 384, 48);
    }
    if (showSelectedBox) {
      rectMode(CORNER);
      float boxX = ((width/2) - 192) + (selection * 64) + 2;
      float boxY = (height/4) - 8;
      stroke(228, 90, 94, 90);
      noFill();
      rect(boxX, boxY, 60, 60);
    }
    // Resetting the settings for rectMode and textAlign to avoid problems elsewhere:
    rectMode(CORNER);
    textAlign(LEFT);
  }
  // This method sets just one line of text as the textLines[]:
  void setTextLine(String textLine) {
    textLines[0] = textLine;
  }
  // and this method lets us set an array of strings for the textLines[].
  void setTextLines(String[] lines) {
    textLines = lines;
  }
  // The same way we can set the actionsInstructions - for now just for one line:
  void setActionInstruction(String instruction) {
    actionsInstructions[0] = instruction;
  }
  // If there's a selection using the mouse, we can get the mouse coordinates and figure out which box was selected
  void selectedIcon(float clickX, float clickY) {
    if (clickX >= ((width/2)-192) && clickX <= ((width/2)+192)) {
      if (clickY >= (height/4) && clickY <= ((height/4)+48)) {
        showSelectedBox = true;
        selection = int((clickX-((width/2)-192))/64);
      }
    }
  }
  // We also need to be able to add the icons, if we want to display them.
  void setIcons(PImage img) {
    selectionIcons = img;
    showIcons = true;
  }
  
}
