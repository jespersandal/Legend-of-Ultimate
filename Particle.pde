/*
A simple particle for visual effects. Well, it started out as a simple particle, but as I added more types of effects, more and more variables were added.
Now, particles can pulsate, they can be harmless and they can have durations.

TODO: There are still a bit of functionality I'd like to add to create more visual effects.
*/

class Particle {
 
  // Class fields to control position, appearence and movement of the particle:
  float posX;
  float posY;
  int particleDirection;  // A value of 0-7, going from up=0 clockwise in 45 degree steps.
  float speedY = 0;  // pixels per second.
  float speedX = 0;  // pixels per second.
  boolean hasDuration = false;  // Set to true when the particle should disappear after a set amount of time.
  int duration;   // In milliseconds. 
  int particleTimer;
  int timerLimit = 500; // Milliseconds between switching pulsation.
  float pulseSize;
  boolean isPulsating; // We can use this to make particles grow and shrink over time.
  int pulseTimer;
  float pulseSpeed;
  boolean isFading;
  float fadeTimer;
  float fadeSpeed;
  boolean isShrinking;
  float shrinkSpeed;   // Note that negative value here can be used for making expanding particles.
  boolean oneHit = false;  // We use this to make a particle disappear after it hits a target.
  boolean isHarmless = false;  // For particle effects that are not used for damage.
  boolean isVisible = true;
  color parColor;
  int size;
  float transparency;
  
  // Constructor
  Particle(float x, float y, int s, int dir, String col) {
    posX = x;
    posY = y;
    size = s;
    particleDirection = dir; 
    setDirection(particleDirection);
    // The particle accepts some predefined types of colours - representing different effects. Maybe we can overload it to accept a color as well as an option.
    setColor(col);
  }
  
  // In some cases, we need to send a particle in a particular direction:
  Particle(float x, float y, int s, float dirX, float dirY, float baseSpeed, String col) {
    posX = x;
    posY = y;
    size = s;
    setSpeeds(dirX, dirY, baseSpeed);
    // The particle accepts some predefined types of colours - representing different effects. Maybe we can overload it to accept a color as well as an option.
    setColor(col);
  }
  
  // Overloaded constructor for setting a specific colour:
  Particle(int x, int y, int dir, int s, color c) {
    posX = x;
    posY = y;
    size = s;
    particleDirection = dir;
    setDirection(particleDirection);
    parColor = c;
  }
  
  void display() {
    if (!isVisible) { return; }  // exits display method early.
    noStroke();  // We don't want an outline of our particles.
    // do we need to set colorMode again? Or is that only when we change a color?
    fill(parColor);
    ellipse(posX, posY, size, size);
  }
  
  // We can use the update method to adjust position, size and other changes.
  void update(int ticks) {
    if (!isVisible) { return; }  // exits update method early.
    else {
      posX += speedX*float(millis() - ticks)*0.001;
      posY += speedY*float(millis() - ticks)*0.001;
    }
    if (hasDuration && particleTimer < ticks) {
      setSize(0);
      hasDuration = false;
      isVisible = false;
    }
    if (isPulsating) {
      int delta = ticks - pulseTimer;
      if (delta >= timerLimit || size <= pulseSize) {
        pulseSpeed = -pulseSpeed;
        pulseTimer += delta;
      }
      size += pulseSpeed;
    }
    if (isFading && hasDuration) {
      float delta = particleTimer - ticks;
      float newAlpha = 20 + (80 * (delta/float(duration)));
      setAlpha(newAlpha);
    }
    if (isShrinking && hasDuration) {
      float delta = particleTimer - ticks;
      size -= shrinkSpeed * (delta/float(duration));
    }
    // Finally, we check for collisions with walls and other obstacles. If the particle's center has entered a non-passable tile, we make the particle invisible.
    if (gameMap.checkParticleCollision(posX, posY)) {
      // We can fade the particle out quickly rather than just making it go away:
      if (hasDuration) {
        particleTimer = millis() - 60;
        isFading = true;
      }
      else {
        isVisible = false;
      }
    }
  }
  
  // This function is used for fixing the Particle object's position to the map as the player moves
  void mapUpdate(float moveX, float moveY) {
    posX += moveX;
    posY += moveY;
  }
  
  void setColor(String scheme) {
    
    // First we set the colorMode to HSB, since it is easier for gradients, such as the red-orange-yellow for fire:
    colorMode(HSB, 360, 100, 100, 100);
    
    // Then we use a switch to set the colour of this particle to one from one of the predefined colour schemes below:
    switch(scheme) {
      
      case("fire"):
        // We want colors from red to yellow, which is 0 to 60 "degrees" on the HSB colour wheel.
        parColor = color(int(random(0, 60)), 100, 100, 100);
        break;
      case("energy"):
        // For this, we want some whites and bright, light blues. So we set hue to 180 degrees and 100% brightness and just tweak the saturation.
        parColor = color(180, int(random(0, 15)), 100, 100);
        break;
      case("poison"):
        // For this, we want some fairly saturated green colors.
        parColor = color(108, int(random(80, 100)), int(random(60, 80)), 100);
        break;
      case("rainbow"):
        // Here we want the entire spectrum.
        parColor = color(int(random(0,360)), int(random(80, 100)), int(random(80, 100)), int(random(50,90)));
        break;
      case("necrotic"):
        // Black and dark purple colours:
        parColor = color(int(random(270, 281)), 90, int(random(20,40)), int(random(60,100)));
        break;
      case("blood"):
        // Crimsom red nuances:
        parColor = color(355, int(random(80, 100)), int(random(50, 90)), 90);
        break;
      case("water"):
        // Sea blue colors:
        parColor = color(211, int(random(65, 85)), int(random(60, 80)), int(random(30, 70)));
        break;
    }    
  }
  
  // We may want to change the opacity/tranparency of the particle.
  void setAlpha(float a) {
    transparency = a;
    // First we need to get the current values of the color:
    float fhue = hue(parColor);
    float fsat = saturation(parColor);
    float fbright = brightness(parColor);
    // Then we can make a new color with the added transparency value:
    parColor = color(fhue, fsat, fbright, transparency);
  }
  
  // If the particle should move, this allows the effect to specify the speeds.
  void setSpeeds(float spX, float spY) {
    speedX = spX;
    speedY = spY;
  }
  
  void setSpeeds(float spX, float spY, float baseSpeed) {
    speedX = spX * baseSpeed;
    //println(speedX);
    speedY = spY * baseSpeed;
    //println(speedY);
  }
  
  void setDirection(int dir) {
    // 0: Up. 1: Right. 2: Down. 3: Left. 4: NE. 5: SE. 6: SW. 7: NW.
    float variationX = random(-25, 25);
    float variationY = random(-25, 25);
    switch(dir) {
      case 0:
        speedX = 0 + variationX;
        speedY = -speedY;
        break;
      case 1:
        speedY = 0 + variationY;
        break;
      case 2:
        speedX = 0 + variationX;
        break;
      case 3:
        speedX = -speedX;
        speedY = 0 + variationY;
        break;
      case 4:
        speedY = -speedY;
        break;
      case 5:
        break;
      case 6:
        speedX = -speedX;
        break;
      case 7:
        speedX = -speedX;
        speedY = -speedY;
        break;
      default:
        speedX = 0;
        speedY = 0;
        break;
    }
  }
  
  // The effect may need to change the size of the particle.
  void setSize(int s) {
    size = s;
  }
  
  // We can set the duration of the particle. This can be used to time how long it is going to be visible:
  void setDuration(int dur) {
    hasDuration = true;
    duration = dur;
    particleTimer = millis() + duration; // Set the timer to the time after which the particle should no longer be visible.
  }
  
  void setPulsation(boolean variation) {
    isPulsating = true;
    pulseSize = size/2;  // This is the minimum size our particle should have. Big is fine for most effects.
    if (!variation) {
      pulseSpeed = 1.1;
    }
    else {
      pulseSpeed = 1 + random(-0.2,0.8);
      timerLimit = 500 + int(random(-100, 200));
    }
    pulseTimer = millis();
  }
  
  // A particle might need to fade out and become completely transparent.
  void setFadeOut(int dur, boolean shrink) {
    // setDuration will override this for the duration
    if (!hasDuration) {
      duration = dur;
      hasDuration = true;
    }
    isFading = true;
    isShrinking = shrink;
  }
}
