// Boğaziçi University Resistance
// Abstract generative painting in El Lissitzky's Constructivist style
// Diffusion + velocity field (2D Perlin) + particle trails — Processing 4
//
// Palette: Lissitzky red, black, white, grey, ochre
// Style: Suprematist geometry + Constructivist dynamism
// Theme: Resistance, defiance, academic freedom

final int SEED = 20260409;

final float FLOW_NOISE_SCALE = 0.0025f;
final float FLOW_STRENGTH = 2.35f;
final float FLOW_BIAS_CENTER = 0.036f;
final float FLOW_BIAS_WARP = 0.015f;

final int NUM_PARTICLES = 8200;
final int FLOW_STEPS = 500;
final int FLOW_RESEED_EVERY = 78;

final float FLOW_MAX_SPEED = 2.35f;
final float FLOW_DT = 0.085f;

Particle[] flowParts;

void setup() {
  size(1200, 800, P2D);
  smooth(8);
  pixelDensity(1);
  randomSeed(SEED);
  noiseSeed(SEED);

  flowParts = new Particle[NUM_PARTICLES];
  for (int i = 0; i < NUM_PARTICLES; i++) {
    flowParts[i] = new Particle();
  }

  noLoop();
}

void draw() {
  // === BASE — off-white aged paper ===
  paintBackground();

  // === LAYER 1: Diffusion + Perlin velocity field — collective motion, static trails ===
  paintDiffusionVelocityField();

  // === LAYER 2: Diagonal axis — Lissitzky's signature dynamic diagonal ===
  paintDiagonal();
  
  // === LAYER 3: Oppressive geometry — the state, heavy and dark ===
  paintOppression();
  
  // === LAYER 4: The red wedge — resistance breaking through ===
  paintRedWedge();
  
  // === LAYER 5: Boğaziçi — the circle of knowledge, light against dark ===
  paintBogazici();
  
  // === LAYER 6: Scattered figures — people, solidarity ===
  paintFigures();
  
  // === LAYER 7: Geometric accents — Suprematist floating shapes ===
  paintAccents();
  
  // === LAYER 8: Texture & grain ===
  paintTexture();
  paintGrain();
}

// ======= Lissitzky Color Palette =======
color lRed()   { return color(204, 36, 29); }       // Constructivist red
color lBlack() { return color(25, 20, 20); }         // Deep black
color lWhite() { return color(235, 230, 220); }      // Aged white
color lGrey()  { return color(140, 135, 128); }      // Warm grey
color lOchre() { return color(180, 150, 90); }       // Ochre accent
color lDark()  { return color(55, 45, 40); }         // Dark brown-black

// ======= Perlin velocity field + diffusion (particle integration) =======

PVector velocityField(float x, float y) {
  float n = noise(x * FLOW_NOISE_SCALE, y * FLOW_NOISE_SCALE);
  float ang = n * TWO_PI * 2.0f;
  PVector v = PVector.fromAngle(ang).mult(FLOW_STRENGTH);

  PVector c = new PVector(width * 0.5f, height * 0.48f);
  PVector toCenter = PVector.sub(c, new PVector(x, y));
  float dm = max(1.0f, toCenter.mag());
  toCenter.div(dm);
  toCenter.mult(FLOW_BIAS_CENTER * (0.7f + 0.6f * noise(x * 0.0014f + 5, y * 0.0014f + 7)));
  v.add(toCenter);

  PVector warp = new PVector(0, -1);
  warp.mult(FLOW_BIAS_WARP * (0.5f + noise(x * 0.0035f + 20, y * 0.0035f + 30)));
  v.add(warp);

  return v;
}

class Particle {
  PVector pos;
  PVector vel;

  Particle() {
    pos = new PVector(random(width), random(height));
    vel = new PVector();
  }

  void respawn() {
    pos.set(random(width), random(height));
    vel.mult(0);
  }

  void step() {
    PVector prev = pos.copy();

    PVector acc = velocityField(pos.x, pos.y);
    vel.add(PVector.mult(acc, FLOW_DT));
    vel.limit(FLOW_MAX_SPEED);
    pos.add(vel);

    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);

    strokeForFlowSegment(prev, pos);
    line(prev.x, prev.y, pos.x, pos.y);
  }
}

void strokeForFlowSegment(PVector a, PVector b) {
  float mx = (a.x + b.x) * 0.5f;
  float my = (a.y + b.y) * 0.5f;
  float yN = my / height;

  color c;
  if (yN < 0.33f) {
    c = lerpColor(lDark(), lGrey(), noise(mx * 0.002f, my * 0.002f));
  } else if (yN < 0.66f) {
    c = lerpColor(lRed(), lBlack(), noise(mx * 0.002f + 2, my * 0.002f + 2));
  } else {
    c = lerpColor(lOchre(), lRed(), noise(mx * 0.002f + 4, my * 0.002f + 4));
  }

  float al = 18 + 32 * noise(mx * 0.003f, my * 0.003f);
  stroke(red(c), green(c), blue(c), al);
  strokeWeight(0.7f + 0.85f * noise(mx * 0.01f, my * 0.01f));
}

void paintDiffusionVelocityField() {
  for (Particle p : flowParts) {
    p.respawn();
  }

  for (int t = 0; t < FLOW_STEPS; t++) {
    if (t % FLOW_RESEED_EVERY == 0 && t > 0) {
      for (Particle p : flowParts) {
        p.respawn();
      }
    }
    for (Particle p : flowParts) {
      p.step();
    }
  }
}

// ======= BACKGROUND — aged constructivist paper =======
void paintBackground() {
  loadPixels();
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float n = noise(x * 0.008, y * 0.008);
      float r = lerp(225, 240, n);
      float g = lerp(218, 232, n);
      float b = lerp(200, 215, n);
      pixels[y * width + x] = color(r, g, b);
    }
  }
  updatePixels();
}

// ======= DIAGONAL AXIS — Lissitzky's dynamic composition line =======
void paintDiagonal() {
  // Main diagonal — from bottom-left to top-right
  // This is the axis of conflict / resistance
  stroke(lBlack());
  strokeWeight(3);
  
  for (int i = 0; i < 200; i++) {
    float t = i / 200.0;
    float x1 = lerp(width * 0.1, width * 0.85, t);
    float y1 = lerp(height * 0.85, height * 0.15, t);
    float n = noise(i * 0.05, 100);
    float offset = (n - 0.5) * 20;
    
    stroke(25, 20, 20, 100 + n * 100);
    strokeWeight(1 + n * 3);
    point(x1 + offset, y1 + offset * 0.5);
  }
  
  // Secondary diagonal — thinner, parallel
  for (int i = 0; i < 150; i++) {
    float t = i / 150.0;
    float x1 = lerp(width * 0.15, width * 0.90, t);
    float y1 = lerp(height * 0.80, height * 0.10, t);
    float n = noise(i * 0.06, 200);
    
    stroke(204, 36, 29, 40 + n * 60);
    strokeWeight(1);
    point(x1 + (n - 0.5) * 10, y1 + (n - 0.5) * 8);
  }
}

// ======= OPPRESSION — heavy dark geometric mass (top-right) =======
void paintOppression() {
  // Large dark angular mass — the state / authoritarian power
  // Built from overlapping dark rectangles with Perlin distortion
  
  pushMatrix();
  translate(width * 0.72, height * 0.18);
  rotate(radians(-12));
  
  // Main oppressive block
  for (int i = 0; i < 800; i++) {
    float bx = noise(i * 0.02, 300) * 260 - 130;
    float by = noise(i * 0.02, 301) * 200 - 100;
    float bw = noise(i * 0.03, 302) * 30 + 5;
    float bh = noise(i * 0.03, 303) * 20 + 5;
    
    float n = noise(bx * 0.01 + 5, by * 0.01 + 5);
    float r = lerp(20, 60, n);
    float g = lerp(15, 48, n);
    float b = lerp(18, 45, n);
    float alpha = 140 + n * 80;
    
    noStroke();
    fill(r, g, b, alpha);
    rect(bx, by, bw, bh);
  }
  
  // Hard geometric edges — rectangles overlapping
  noStroke();
  fill(lBlack());
  rect(-100, -60, 200, 120);
  fill(35, 28, 25, 200);
  rect(-80, -80, 160, 30);
  rect(-120, -40, 50, 100);
  
  // Cracks in the authority — white fissures
  stroke(lWhite());
  strokeWeight(1.5);
  for (int i = 0; i < 15; i++) {
    float cx = noise(i * 0.3, 310) * 180 - 90;
    float cy = noise(i * 0.3, 311) * 100 - 50;
    float len = noise(i * 0.4, 312) * 40;
    float angle = noise(i * 0.2, 313) * PI;
    line(cx, cy, cx + cos(angle) * len, cy + sin(angle) * len);
  }
  
  popMatrix();
}

// ======= RED WEDGE — "Beat the Whites with the Red Wedge" homage =======
// The central symbol of resistance piercing through oppression
void paintRedWedge() {
  // Large red triangle driving into the dark mass
  // Perlin-noise brush-stroke built
  
  float tipX = width * 0.62;
  float tipY = height * 0.30;
  float baseLeftX = width * 0.18;
  float baseLeftY = height * 0.55;
  float baseRightX = width * 0.25;
  float baseRightY = height * 0.35;
  
  // Fill the wedge with Perlin-noise red strokes
  for (int i = 0; i < 2000; i++) {
    float t1 = random(1);
    float t2 = random(1);
    
    // Barycentric coordinates for triangle fill
    if (t1 + t2 > 1) { t1 = 1 - t1; t2 = 1 - t2; }
    float t3 = 1 - t1 - t2;
    
    float px = tipX * t1 + baseLeftX * t2 + baseRightX * t3;
    float py = tipY * t1 + baseLeftY * t2 + baseRightY * t3;
    
    // Perlin distortion
    float n = noise(px * 0.006, py * 0.006);
    px += (n - 0.5) * 12;
    py += (n - 0.5) * 8;
    
    float sz = noise(i * 0.01, 400) * 12 + 3;
    
    // Red variations
    float rv = 180 + n * 60;
    float gv = 20 + n * 25;
    float bv = 15 + n * 20;
    float alpha = 180 + n * 60;
    
    noStroke();
    fill(rv, gv, bv, alpha);
    
    // Mix of rectangles and ellipses for texture
    if (noise(i * 0.05) > 0.5) {
      pushMatrix();
      translate(px, py);
      rotate(noise(i * 0.03, 401) * HALF_PI - QUARTER_PI);
      rect(-sz/2, -sz/4, sz, sz/2);
      popMatrix();
    } else {
      ellipse(px, py, sz, sz * 0.7);
    }
  }
  
  // Hard red edge lines of the wedge
  stroke(lRed());
  strokeWeight(3);
  noFill();
  line(tipX, tipY, baseLeftX, baseLeftY);
  line(tipX, tipY, baseRightX, baseRightY);
  strokeWeight(2);
  line(baseLeftX, baseLeftY, baseRightX, baseRightY);
}

// ======= BOĞAZİÇİ — circle of knowledge and light =======
void paintBogazici() {
  float cx = width * 0.35;
  float cy = height * 0.42;
  float radius = 95;
  
  // White/light circle — enlightenment, university, knowledge
  for (int i = 0; i < 1200; i++) {
    float angle = noise(i * 0.02, 500) * TWO_PI;
    float r = noise(i * 0.02, 501) * radius;
    float px = cx + cos(angle) * r;
    float py = cy + sin(angle) * r;
    
    float n = noise(px * 0.008, py * 0.008);
    float sz = noise(i * 0.03, 502) * 8 + 2;
    
    // White/cream tones — light of knowledge
    float rv = 220 + n * 30;
    float gv = 215 + n * 25;
    float bv = 200 + n * 20;
    float alpha = 160 + n * 80;
    
    noStroke();
    fill(rv, gv, bv, alpha);
    ellipse(px, py, sz, sz);
  }
  
  // Circle outline — strong, unbroken
  noFill();
  stroke(lBlack());
  strokeWeight(2.5);
  ellipse(cx, cy, radius * 2, radius * 2);
  
  // Inner geometric mark — abstracted castle tower (Rumelihisarı reference)
  stroke(lBlack());
  strokeWeight(2);
  // Three vertical lines — fortress towers
  for (int i = -1; i <= 1; i++) {
    float tx = cx + i * 18;
    line(tx, cy - 25, tx, cy + 30);
    // Crenellation
    line(tx - 6, cy - 25, tx + 6, cy - 25);
  }
  // Connecting wall
  line(cx - 18, cy + 10, cx + 18, cy + 10);
  
  // Radiating lines — knowledge spreading outward
  for (int i = 0; i < 24; i++) {
    float angle = i * TWO_PI / 24.0;
    float n = noise(i * 0.5, 510);
    float innerR = radius + 5;
    float outerR = radius + 15 + n * 25;
    
    stroke(lGrey());
    strokeWeight(0.8);
    float x1 = cx + cos(angle) * innerR;
    float y1 = cy + sin(angle) * innerR;
    float x2 = cx + cos(angle) * outerR;
    float y2 = cy + sin(angle) * outerR;
    line(x1, y1, x2, y2);
  }
}

// ======= FIGURES — abstract human forms, solidarity =======
void paintFigures() {
  // Row of abstract figures along the bottom — the people
  float baseY = height * 0.72;
  
  for (int f = 0; f < 18; f++) {
    float fx = width * 0.08 + f * (width * 0.05);
    float fy = baseY + noise(f * 0.5, 600) * 30;
    float fScale = 0.6 + noise(f * 0.3, 601) * 0.5;
    
    paintOneFigure(fx, fy, fScale, f);
  }
}

void paintOneFigure(float x, float y, float s, int seed) {
  pushMatrix();
  translate(x, y);
  scale(s);
  
  // Constructivist abstract figure — geometric shapes
  noStroke();
  
  // Body — vertical rectangle
  float n = noise(seed * 0.7, 610);
  if (n > 0.6) {
    fill(lRed()); // Some figures in red — the active resistors
  } else if (n > 0.3) {
    fill(lBlack()); // Others in black — solidarity
  } else {
    fill(lGrey()); // Others in grey — the masses
  }
  
  // Torso
  rect(-6, -30, 12, 35);
  
  // Head — circle
  ellipse(0, -38, 14, 14);
  
  // Arms raised — defiance
  float armAngle = noise(seed * 0.4, 620) * 0.8 - 0.1;
  strokeWeight(2.5);
  stroke(n > 0.6 ? lRed() : (n > 0.3 ? lBlack() : lGrey()));
  // Left arm up
  pushMatrix();
  rotate(-HALF_PI + armAngle);
  line(0, -25, 0, -50);
  popMatrix();
  // Right arm up
  pushMatrix();
  rotate(-HALF_PI - armAngle - 0.3);
  line(0, -25, 0, -48);
  popMatrix();
  
  // Fist (for red figures — raised fist)
  if (n > 0.6) {
    noStroke();
    fill(lRed());
    float fistX = sin(-HALF_PI + armAngle) * -25;
    float fistY = -25 + cos(-HALF_PI + armAngle) * -25;
    ellipse(fistX, fistY, 8, 8);
  }
  
  // Legs
  stroke(n > 0.6 ? lRed() : lBlack());
  strokeWeight(2);
  line(-3, 5, -6, 30);
  line(3, 5, 6, 30);
  
  popMatrix();
}

// ======= SUPREMATIST ACCENTS — floating geometric shapes =======
void paintAccents() {
  // Small floating rectangles, circles, lines — Lissitzky flourishes
  
  // Black rectangles
  noStroke();
  fill(lBlack());
  pushMatrix();
  translate(width * 0.82, height * 0.85);
  rotate(radians(25));
  rect(-40, -6, 80, 12);
  popMatrix();
  
  pushMatrix();
  translate(width * 0.10, height * 0.45);
  rotate(radians(-35));
  rect(-25, -4, 50, 8);
  popMatrix();
  
  // Red circles
  fill(lRed());
  ellipse(width * 0.92, height * 0.15, 30, 30);
  ellipse(width * 0.05, height * 0.12, 18, 18);
  
  // Grey squares
  fill(lGrey());
  pushMatrix();
  translate(width * 0.88, height * 0.42);
  rotate(radians(15));
  rect(-10, -10, 20, 20);
  popMatrix();
  
  // Ochre accent
  fill(lOchre());
  pushMatrix();
  translate(width * 0.15, height * 0.82);
  rotate(radians(-20));
  rect(-15, -5, 30, 10);
  popMatrix();
  
  // Thin black lines — structural
  stroke(lBlack());
  strokeWeight(1.5);
  line(width * 0.50, height * 0.05, width * 0.50, height * 0.15);
  line(width * 0.48, height * 0.05, width * 0.52, height * 0.05);
  
  // Cross mark — near figures
  stroke(lRed());
  strokeWeight(2);
  float crossX = width * 0.45;
  float crossY = height * 0.70;
  line(crossX - 10, crossY, crossX + 10, crossY);
  line(crossX, crossY - 10, crossX, crossY + 10);
  
  // Dotted line — Perlin spaced
  stroke(lGrey());
  strokeWeight(2);
  for (int i = 0; i < 30; i++) {
    float dx = width * 0.60 + i * 12;
    float dy = height * 0.78 + noise(i * 0.3, 700) * 8;
    point(dx, dy);
  }
}

// ======= TEXTURE — paper/lithograph feel =======
void paintTexture() {
  // Subtle crosshatch texture
  stroke(lBlack());
  strokeWeight(0.3);
  
  for (int i = 0; i < 2000; i++) {
    float x = random(width);
    float y = random(height);
    float n = noise(x * 0.01, y * 0.01);
    
    if (n > 0.52) {
      float len = (n - 0.5) * 10;
      float angle = noise(x * 0.005, y * 0.005) * PI;
      stroke(25, 20, 20, 15);
      line(x, y, x + cos(angle) * len, y + sin(angle) * len);
    }
  }
}

// ======= GRAIN =======
void paintGrain() {
  loadPixels();
  for (int i = 0; i < pixels.length; i++) {
    float grain = random(-8, 8);
    float r = constrain(red(pixels[i]) + grain, 0, 255);
    float g = constrain(green(pixels[i]) + grain, 0, 255);
    float b = constrain(blue(pixels[i]) + grain, 0, 255);
    pixels[i] = color(r, g, b);
  }
  updatePixels();
}

// Press S to save, R to regenerate
void keyPressed() {
  if (key == 's' || key == 'S') {
    save("BogaziciResistance_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".png");
    println("Saved!");
  }
  if (key == 'r' || key == 'R') {
    randomSeed((int)random(99999));
    noiseSeed((int)random(99999));
    redraw();
  }
}
