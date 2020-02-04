/*
This class helps you create various visual effects designed for a game with a top down view (no gravity).
We can later expand the class to include gravity, but have a default gravity of 0 for top down effects.

Note: I started working on this class as prototype before I had decided which game to make.
*/

class Effect {
  
  String effectType;
  String particleColors; // this lets us do different particles for fire, energy, poison etc.
  float posX;
  float posY;
  int size;
  int effectDirection;
  Particle[] particles;
  int ticksLast;
  // For the enemy attacks:
  float speedX = 0;
  float speedY = 0;
  float baseSpeed = 0;
  float effectDPS = 1; // We can use this value to adjust how much damage each particle does in our effect, after we have time fixed the damage.
  
  // Constructors
  Effect(float x, float y, String type, int s) {
    posX = x;
    posY = y;
    effectType = type;
    size = s;
    ticksLast = millis();
  }
  Effect(float x, float y, String type, int s, int dir) {
    posX = x;
    posY = y;
    effectType = type;
    size = s;
    effectDirection = dir;
    ticksLast = millis();
  }
  Effect(float x, float y, float spdX, float spdY, float baseSpd, String type, int s) {
    posX = x;
    posY = y;
    effectType = type;
    size = s;
    ticksLast = millis();
    speedX = spdX;
    speedY = spdY;
    baseSpeed = baseSpd;
  }
  
  void display() {
    // Display all the particles:
    for (int i = 0; i < particles.length; i++) {
      particles[i].display();
    }
  }
  
  // If an effect is fixed relative to the screen - or in this case mostly the hero, we can just call this method:
  void update() {
    // Update all the particles:
    for (int i = 0; i < particles.length; i++) {
      particles[i].update(ticksLast);
    }
    ticksLast = millis();
  }
  // For effects that are fixed to the map, we need to both move the particles with the map and then update the particles:
  void mapUpdate(float x, float y) {
    // Update all the particles:
    for (int i = 0; i < particles.length; i++) {
      posX += x;
      posY += y;
      particles[i].mapUpdate(x, y);
      particles[i].update(ticksLast);
    }
    ticksLast = millis();
  }
  
  // we check for collisions with all the particles in the effect and returns the number of hits. This can be used to calculate damage.
  float checkEnemyCollisions(float enemyX, float enemyY, float enemySize) {
    // While the variables are named "enemy", we should be able to use the same method to get collisions for the hero.
    float hits = 0;
    for (int i = 0; i < particles.length; i++) {
      float parRadius = particles[i].size * 0.5;
      if (enemyX+enemySize >= particles[i].posX - parRadius && enemyX <= particles[i].posX + parRadius) {
        if (enemyY + enemySize > particles[i].posY - parRadius && enemyY <= particles[i].posY + parRadius) { //<>//
          if (particles[i].isVisible) {
            if (!particles[i].isHarmless) {
              hits += effectDPS;
            }
            if (particles[i].oneHit) {
              particles[i].isVisible = false;
            }
          }
        }
      }
    } 
    return hits;
  }
  
  // This specifies the overall recipe for the different type of effect, we can create with this class.
  void createEffect() {
    if (effectType == "missiles") {
      setParticleColors("energy");
      effectDPS = 100;
      missiles(5);
    }
    else if (effectType == "fireball") {
      setParticleColors("fire");
      effectDPS = 2;
      explosion(50);
    }
    else if (effectType == "poison cloud") {
      setParticleColors("poison");
      cloud(10);
    }
    else if (effectType == "enemy missiles") {
      setParticleColors("energy");
      effectDPS = 200;
      missiles(1, speedX, speedY, baseSpeed);
    }
    else if (effectType == "colour cone") {
      setParticleColors("rainbow");
      effectDPS = 2;
      cone(direction);
    }
    else if (effectType == "necro blob") {
      setParticleColors("necrotic");
      effectDPS = 5;
      slowBall(5, speedX, speedY);
    }
    else if (effectType == "slam") {
      setParticleColors("energy");
      effectDPS = 60;
      slam(1);
    }
    else if (effectType == "mini fireball") {
      setParticleColors("fire");
      effectDPS = 140;
      impactBall(6, speedX, speedY);
    }
    else if (effectType == "fire breath") {
      setParticleColors("fire");
      effectDPS = 3;
      cone(effectDirection);
    }
    else if (effectType == "drowning sphere") {
      setParticleColors("water");
      effectDPS = 10;
      slowBall(1, speedX, speedY);
    }
    else if (effectType == "gore") {
      setParticleColors("blood");
      effectDPS = 0;
      explosion(50);
    }
  }
 
  void setParticleColors(String scheme) {
    particleColors = scheme;
  }
  
  // Explosion: Circle of particles moving out from the centre.
  void explosion(int iParticles) {
    particles = new Particle[iParticles];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size*int(random(1,4)), 0, particleColors);
      particles[i].setSpeeds(random(20,60), random(20,60));
      particles[i].setDirection(int(random(0,8)));
      particles[i].setDuration(int(random(180,600)));
      particles[i].setFadeOut(500,false);
      particles[i].setPulsation(true);
    }
  }
  
  // Cloud: Stationary, bubbling particles.
  void cloud(int iParticles) {
    particles = new Particle[iParticles];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(random(-4*size,4*size)+posX, random(-4*size,4*size)+posY, size*int(random(1,4)), 8, particleColors);
      particles[i].setDuration(1000+int(random(0,500)));
      particles[i].setPulsation(true);
      particles[i].setAlpha(30);
    }
  }
  
  // Cone: A 90 degree area of effect.
  void cone(int direction) {
    particles = new Particle[30];
    // to get the 90 degree effect, we need to find the two neighbouring directions:
    int[] directions = new int[3];
    directions[1] = direction;
    directions[2] = direction + 4;
    if (direction == 0) {
      directions[0] = 7;
    }
    else {
      directions[0] = direction + 3;
    }
    for (int i = 0; i < particles.length; i++) {
      int pDirection = int(random(0,3));
      particles[i] = new Particle(posX, posY, size, directions[pDirection], particleColors);
      particles[i].setSpeeds(random(40,80), random(40,80));
      particles[i].setDirection(directions[pDirection]);
      particles[i].setDuration(850);
      particles[i].isShrinking = true;
      particles[i].shrinkSpeed = -3.0;
      particles[i].isFading = true;
    }
  }
  
  // Ball: a cluster of pulsating particles moving in one direction
  void ball(int number, float speedX, float speedY) {
    particles = new Particle[number];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size, speedX*random(1, 1.5), speedY*random(1, 1.5), baseSpeed, particleColors);
      particles[i].setDuration(1000);
      particles[i].setPulsation(true);
    }
  }
  
  // ImpactBall: A special case of the ball, where the particles are destroyed upon impact:
  void impactBall(int number, float speedX, float speedY) {
    particles = new Particle[number];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size, speedX*random(1, 1.5), speedY*random(1, 1.5), baseSpeed, particleColors);
      particles[i].setDuration(1000);
      particles[i].isShrinking = true;
      particles[i].shrinkSpeed = -1.0;
      particles[i].oneHit = true;
      particles[i].isFading = true;
    }
  }
  // a ball more suited for slower speeds.
  void slowBall(int number, float speedX, float speedY) {
    particles = new Particle[number];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size, speedX*random(1, 1.5), speedY*random(1, 1.5), baseSpeed, particleColors);
      particles[i].setDuration(2200+int(random(0,300)));
      particles[i].setPulsation(true);
    }
  }
  
  // Flash: a (single) expanding, fading sphere in a fixed location
  void slam(int number) {
    particles = new Particle[number];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size, effectDirection, particleColors);
      particles[i].setDuration(120);
      particles[i].isShrinking = true;
      particles[i].shrinkSpeed = -20;
      particles[i].isFading = true;
      particles[i].setAlpha(80);
    }
  }
  // Sphere: a single, large particle moving in one direction
  
  // Line: A line of particles that blooms and fade in place.
  
  // Ray: A line of moving particles.
  
  // Missiles: 1-5 particles moving towards a point.
  void missiles(int iMissiles) {
    particles = new Particle[iMissiles];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size, direction, particleColors);
      particles[i].setSpeeds(random(140,200), random(140,200));
      particles[i].setDirection(direction);
      particles[i].setDuration(1200);
      particles[i].oneHit = true;
    }
  }
  void missiles(int iMissiles, float speedX, float speedY, float baseSpeed) {
    particles = new Particle[iMissiles];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(posX, posY, size, speedX, speedY, baseSpeed, particleColors);
      //particles[i].setSpeeds(speedX*baseSpeed, speedY*baseSpeed);
      //particles[i].setDirection(direction);
      particles[i].setDuration(1200);
      particles[i].oneHit = true;
      //particles[i].isHarmless = true;
    }
  }
}
