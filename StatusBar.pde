/*
This class is for displaying a status bar. This could be a progress bar, but in this case it is for the health and mana bars. These could have been
  part of the UserInterface class, but these were the first part of the interface I made, and the class has some potential for reuse in later projects,
  unlike the more specialized UserInterface class.
*/

class StatusBar {
  float maxValue;
  float currentValue;
  float minValue = 0;
  color fillColor = color(9, 88, 82, 90);
  float posX;
  float posY;
  float barSize;
  float barHeight;
  float currentValSize;
  
  StatusBar(float maxVal, float x, float y, float s) {
    if (maxVal > 0) {
      maxValue = maxVal;
    }
    else {
      maxValue = 1;  // This is to avoid a potential division by zero if we make an error later on.
    }
    barSize = s;
    currentValSize = barSize;
    barHeight = (barSize/10);
    posX = x;
    posY = y;
  }
  
  void display() {
    // First we make the outline which is the full, maximum size:
    stroke(0, 0, 0, 80);
    strokeWeight(2);
    noFill();
    rect(posX, posY, barSize+1, barHeight+1);
    // Then we make another rectangle inside the first:
    noStroke();
    fill(fillColor);
    rect(posX+1, posY+1, currentValSize, barHeight); 
  }
  
  void updateValue(float change) {
    currentValue += change;
    if (currentValue > maxValue) {
      currentValue = maxValue;
    }
    if (currentValue < minValue) {
      currentValue = minValue;
    }
    currentValSize = (currentValue/maxValue) * barSize; 
  }
  
  void setCurrentValue(float newVal) {
    if (newVal >= minValue && newVal <= maxValue) {
      currentValue = newVal;
    }
    currentValSize = (currentValue/maxValue) * barSize; 
  }
  
  void setColor(String c) {
    colorMode(HSB, 360, 100, 100, 100);
    if (c == "red") {
      fillColor = color(9, 88, 82, 90);
    }
    if (c == "blue") {
      fillColor = color(233, 100, 70, 90);
    }
  }
}
