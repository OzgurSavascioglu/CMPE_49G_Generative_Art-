// Don Quixote Against the Windmills
// Abstract generative painting using 2D Perlin noise
// + wind layer: velocity field (curl of Perlin ψ) + diffusion on particles
// Processing 4

final int SEED_FLOW = 20260416;
final float PSI_W = 0.0024f;
final float CURL_E = 4.0f;
final float CURL_K = 165.0f;
final float WIND_BIAS_X = 1.1f;
final float FLOW_DT = 0.11f;
final float FLOW_DAMP = 0.88f;
final float FLOW_DIFF = 0.42f;
final float FLOW_VMAX = 3.8f;
final int NUM_FLOW = 3200;
final int FLOW_STEPS = 140;
final int FLOW_RESEED = 35;

WQParticle[] flowParts;

void setup() {
  size(1200, 800);
  pixelDensity(1);
  randomSeed(SEED_FLOW);
  noiseSeed(SEED_FLOW);
  flowParts = new WQParticle[NUM_FLOW];
  for (int i = 0; i < NUM_FLOW; i++) {
    flowParts[i] = new WQParticle();
  }
  noLoop(); // Static painting — runs once
}

void draw() {
  background(20, 15, 25);
  
  // === LAYER 1: Abstract sky — warm turbulent Perlin field ===
  paintSky();
  
  // === LAYER 2: Distant horizon haze ===
  paintHorizon();
  
  // === LAYER 3: Abstract windmill silhouettes ===
  paintWindmills();
  
  // === LAYER 4: The La Mancha terrain — earthy Perlin noise ===
  paintTerrain();
  
  // === LAYER 5: Don Quixote — abstract silhouette emerging from noise ===
  paintQuixote();
  
  // === LAYER 6: Wind — Perlin velocity field + diffusion (particle trails) ===
  paintWindFlow();
  
  // === LAYER 7: Impasto texture overlay ===
  paintTexture();
  
  // === LAYER 8: Vignette & grain ===
  paintVignette();
  paintGrain();
  
  // === Signature ===
  paintSignature();
}

// ======= SKY — swirling warm Perlin noise field =======
void paintSky() {
  float scaleX = 0.004;
  float scaleY = 0.006;
  
  loadPixels();
  for (int y = 0; y < height * 0.55; y++) {
    for (int x = 0; x < width; x++) {
      float n1 = noise(x * scaleX, y * scaleY);
      float n2 = noise(x * scaleX * 2.5 + 100, y * scaleY * 2.5 + 100);
      float n = (n1 * 0.6 + n2 * 0.4);
      
      // Sunset palette: deep purple → burnt orange → golden
      float t = map(y, 0, height * 0.55, 0, 1);
      float r, g, b;
      
      if (t < 0.3) {
        // Deep sky — indigo/purple
        r = lerp(30, 80, n) + t * 60;
        g = lerp(15, 35, n) + t * 30;
        b = lerp(60, 120, n) - t * 20;
      } else if (t < 0.7) {
        // Mid sky — crimson/amber
        float tt = map(t, 0.3, 0.7, 0, 1);
        r = lerp(140, 230, n * tt);
        g = lerp(40, 130, n * tt * 0.8);
        b = lerp(50, 60, n);
      } else {
        // Horizon glow — golden/white-hot
        float tt = map(t, 0.7, 1.0, 0, 1);
        r = lerp(200, 255, n * tt);
        g = lerp(100, 200, n * tt);
        b = lerp(40, 100, n * tt * 0.5);
      }
      
      // Turbulent swirl distortion
      float swirl = noise(x * 0.002 + 500, y * 0.003 + 500) * 40 - 20;
      r = constrain(r + swirl * 0.3, 0, 255);
      g = constrain(g + swirl * 0.2, 0, 255);
      b = constrain(b + swirl * 0.15, 0, 255);
      
      pixels[y * width + x] = color(r, g, b);
    }
  }
  updatePixels();
}

// ======= HORIZON HAZE =======
void paintHorizon() {
  noStroke();
  for (int y = (int)(height * 0.45); y < (int)(height * 0.6); y++) {
    for (int x = 0; x < width; x += 2) {
      float n = noise(x * 0.003, y * 0.01 + 300);
      float alpha = map(y, height * 0.45, height * 0.6, 0, 120) * n;
      fill(220, 160, 80, alpha);
      rect(x, y, 2, 1);
    }
  }
}

// ======= ABSTRACT WINDMILL SILHOUETTES =======
void paintWindmills() {
  // Three windmills at different positions, built from Perlin noise brush strokes
  float[][] mills = {
    {width * 0.58, height * 0.38, 1.1},
    {width * 0.74, height * 0.40, 0.85},
    {width * 0.90, height * 0.42, 0.65}
  };
  
  for (float[] m : mills) {
    paintOneWindmill(m[0], m[1], m[2]);
  }
}

void paintOneWindmill(float cx, float cy, float s) {
  pushMatrix();
  translate(cx, cy);
  scale(s);
  
  // Tower — thick vertical brush strokes with noise
  for (int i = 0; i < 200; i++) {
    float bx = noise(i * 0.1, 0) * 40 - 20;
    float by = noise(i * 0.1, 1) * 140;
    float bw = noise(i * 0.15, 2) * 8 + 2;
    float bh = noise(i * 0.1, 3) * 12 + 4;
    float n = noise(bx * 0.05 + 50, by * 0.02 + 50);
    
    // Dark stone colors
    float r = 40 + n * 50;
    float g = 30 + n * 35;
    float b = 35 + n * 25;
    float alpha = 160 + n * 80;
    
    noStroke();
    fill(r, g, b, alpha);
    ellipse(bx, -by, bw, bh);
  }
  
  // Blades — abstract sweeping arcs using Perlin flow
  float bladeAngle = noise(cx * 0.01) * TWO_PI;
  for (int blade = 0; blade < 4; blade++) {
    float angle = bladeAngle + blade * HALF_PI;
    
    for (int j = 0; j < 120; j++) {
      float t = j / 120.0;
      float dist = t * 110;
      float noiseOff = noise(j * 0.08, blade * 10.0) * 15 - 7;
      
      float bx = cos(angle) * dist + noiseOff * cos(angle + HALF_PI);
      float by = -140 + sin(angle) * dist * (-1) + noiseOff * sin(angle + HALF_PI);
      
      float sz = (1 - t) * 6 + 1;
      float alpha = (1 - t * 0.7) * 180;
      
      noStroke();
      fill(55, 40, 35, alpha);
      ellipse(bx, by, sz, sz * 1.5);
    }
  }
  
  popMatrix();
}

// ======= TERRAIN — earthy 2D Perlin noise =======
void paintTerrain() {
  float scaleX = 0.005;
  float scaleY = 0.008;
  
  loadPixels();
  for (int y = (int)(height * 0.55); y < height; y++) {
    for (int x = 0; x < width; x++) {
      float n1 = noise(x * scaleX + 1000, y * scaleY + 1000);
      float n2 = noise(x * scaleX * 3 + 2000, y * scaleY * 3 + 2000);
      float n = n1 * 0.65 + n2 * 0.35;
      
      // Earth tones: ochre, sienna, umber
      float depth = map(y, height * 0.55, height, 0, 1);
      float r = lerp(120, 70, depth) + n * 60;
      float g = lerp(90, 45, depth) + n * 40;
      float b = lerp(40, 20, depth) + n * 20;
      
      // Patches of dry grass
      if (n1 > 0.55 && n2 > 0.45) {
        r += 30;
        g += 25;
      }
      
      // Dark furrows
      if (n2 < 0.35) {
        r -= 20;
        g -= 15;
        b -= 10;
      }
      
      r = constrain(r, 0, 255);
      g = constrain(g, 0, 255);
      b = constrain(b, 0, 255);
      
      pixels[y * width + x] = color(r, g, b);
    }
  }
  updatePixels();
}

// ======= DON QUIXOTE — abstract figure from Perlin brush strokes =======
void paintQuixote() {
  float cx = width * 0.22;
  float cy = height * 0.58;
  
  // === Horse silhouette — gestural strokes ===
  noStroke();
  
  // Horse body — flowing dark mass
  for (int i = 0; i < 500; i++) {
    float t = i / 500.0;
    float angle = noise(i * 0.02, 0) * PI - HALF_PI;
    float spread = noise(i * 0.03, 1) * 30;
    
    // Horse shape envelope
    float hx = cx + lerp(-35, 45, t) + noise(i * 0.05, 2) * spread - spread/2;
    float hy = cy + noise(i * 0.04, 3) * 20 - 5;
    
    float sz = noise(i * 0.06, 4) * 10 + 3;
    float n = noise(hx * 0.01, hy * 0.01);
    
    fill(35 + n * 25, 22 + n * 15, 18 + n * 10, 180);
    ellipse(hx, hy, sz, sz * 0.7);
  }
  
  // Horse legs — thin dripping strokes
  for (int leg = 0; leg < 4; leg++) {
    float lx = cx - 20 + leg * 18;
    for (int j = 0; j < 60; j++) {
      float ly = cy + 5 + j * 0.7;
      float wobble = noise(j * 0.1, leg * 5.0) * 6 - 3;
      float sz = map(j, 0, 60, 5, 1.5);
      float n = noise(lx * 0.02, ly * 0.02);
      fill(30 + n * 20, 20 + n * 12, 15 + n * 8, 200 - j * 2);
      noStroke();
      ellipse(lx + wobble, ly, sz, sz * 1.3);
    }
  }
  
  // Horse neck — upward curve
  for (int i = 0; i < 150; i++) {
    float t = i / 150.0;
    float nx = cx + 40 + t * 15 + noise(i * 0.05, 10) * 8;
    float ny = cy - t * 50 + noise(i * 0.06, 11) * 10;
    float sz = (1 - t * 0.5) * 10;
    float n = noise(nx * 0.01, ny * 0.01);
    fill(38 + n * 20, 25 + n * 12, 20 + n * 8, 190);
    noStroke();
    ellipse(nx, ny, sz, sz);
  }
  
  // Horse head
  for (int i = 0; i < 80; i++) {
    float hx = cx + 55 + noise(i * 0.08, 20) * 18;
    float hy = cy - 52 + noise(i * 0.08, 21) * 14 - 7;
    float sz = noise(i * 0.1, 22) * 6 + 2;
    fill(32, 20, 16, 200);
    noStroke();
    ellipse(hx, hy, sz, sz);
  }
  
  // === Rider (Don Quixote) — tall thin dark figure ===
  float riderX = cx + 10;
  float riderBaseY = cy - 10;
  
  // Torso — vertical strokes
  for (int i = 0; i < 200; i++) {
    float t = i / 200.0;
    float rx = riderX + noise(i * 0.04, 30) * 14 - 7;
    float ry = riderBaseY - t * 55 + noise(i * 0.05, 31) * 6;
    float sz = noise(i * 0.07, 32) * 6 + 2;
    float n = noise(rx * 0.02, ry * 0.02);
    
    // Dark armor/clothing
    fill(25 + n * 20, 20 + n * 12, 30 + n * 15, 200);
    noStroke();
    ellipse(rx, ry, sz, sz * 1.4);
  }
  
  // Head — small cluster
  for (int i = 0; i < 60; i++) {
    float hx = riderX + 2 + noise(i * 0.1, 40) * 10 - 5;
    float hy = riderBaseY - 60 + noise(i * 0.1, 41) * 10 - 5;
    float sz = noise(i * 0.15, 42) * 4 + 1;
    fill(190 + noise(i * 0.2, 43) * 40, 150, 120, 180);
    noStroke();
    ellipse(hx, hy, sz, sz);
  }
  
  // Helmet (barber's basin) — metallic gleam
  for (int i = 0; i < 40; i++) {
    float hx = riderX + 2 + noise(i * 0.12, 50) * 14 - 7;
    float hy = riderBaseY - 68 + noise(i * 0.12, 51) * 8 - 4;
    float sz = noise(i * 0.1, 52) * 5 + 2;
    float n = noise(hx * 0.03, hy * 0.03);
    fill(170 + n * 60, 165 + n * 50, 140 + n * 40, 200);
    noStroke();
    ellipse(hx, hy, sz, sz * 0.6);
  }
  
  // === CAPE — flowing red, the dramatic focal point ===
  // Perlin noise driven flowing shape
  beginShape();
  noStroke();
  fill(160, 25, 20, 0); // will use vertex colors via brush
  endShape();
  
  for (int i = 0; i < 600; i++) {
    float t = i / 600.0;
    // Cape flows backward and down from shoulders
    float capeX = riderX - 5 - t * 80 + noise(i * 0.015, 60) * 50;
    float capeY = riderBaseY - 40 + t * 60 + noise(i * 0.02, 61) * 35;
    float sz = noise(i * 0.025, 62) * 10 + 2;
    
    float n = noise(capeX * 0.008, capeY * 0.008);
    // Rich reds — crimson, vermillion, carmine
    float r = 140 + n * 80;
    float g = 15 + n * 30;
    float b = 10 + n * 25;
    float alpha = 160 - t * 80;
    
    fill(r, g, b, alpha);
    noStroke();
    ellipse(capeX, capeY, sz, sz * 1.2);
  }
  
  // === LANCE — diagonal line of strokes reaching toward windmills ===
  float lanceStartX = riderX + 15;
  float lanceStartY = riderBaseY - 45;
  float lanceEndX = width * 0.50;
  float lanceEndY = height * 0.35;
  
  for (int i = 0; i < 150; i++) {
    float t = i / 150.0;
    float lx = lerp(lanceStartX, lanceEndX, t) + noise(i * 0.08, 70) * 4 - 2;
    float ly = lerp(lanceStartY, lanceEndY, t) + noise(i * 0.08, 71) * 4 - 2;
    float sz = lerp(4, 1.5, t);
    
    // Wooden lance
    float n = noise(lx * 0.02, ly * 0.02);
    fill(100 + n * 40, 70 + n * 25, 35 + n * 15, 210);
    noStroke();
    ellipse(lx, ly, sz, sz);
  }
  
  // Lance tip — bright metallic point
  for (int i = 0; i < 20; i++) {
    float tx = lanceEndX + noise(i * 0.2, 80) * 8 - 4;
    float ty = lanceEndY + noise(i * 0.2, 81) * 8 - 4;
    fill(210, 210, 220, 200);
    noStroke();
    ellipse(tx, ty, 3, 3);
  }
}

// ======= WIND — curl(ψ) velocity + Langevin diffusion, sky band =======
float windPsi(float x, float y) {
  float a = noise(x * PSI_W + 3f, y * PSI_W + 7f);
  float b = noise(x * PSI_W * 2.1f + 40f, y * PSI_W * 2.1f + 11f);
  return a + 0.45f * b;
}

PVector windVelocity(float x, float y) {
  float dpsidy = (windPsi(x, y + CURL_E) - windPsi(x, y - CURL_E)) / (2f * CURL_E);
  float dpsidx = (windPsi(x + CURL_E, y) - windPsi(x - CURL_E, y)) / (2f * CURL_E);
  PVector v = new PVector(dpsidy, -dpsidx);
  v.mult(CURL_K);
  float g = noise(x * 0.002f + 90f, y * 0.002f + 20f);
  v.x += WIND_BIAS_X * (0.55f + 0.45f * g);
  v.y += 0.15f * (g - 0.5f);
  return v;
}

class WQParticle {
  PVector pos;
  PVector vel;

  WQParticle() {
    pos = new PVector();
    vel = new PVector();
    respawn();
  }

  void respawn() {
    pos.set(random(width), random(height * 0.14f, height * 0.68f));
    vel.mult(0);
  }

  void step() {
    PVector prev = pos.copy();
    PVector u = windVelocity(pos.x, pos.y);
    vel.mult(FLOW_DAMP);
    vel.add(PVector.mult(u, FLOW_DT));

    float nv = noise(pos.x * 0.0045f + 200f, pos.y * 0.0045f + 50f);
    float sigma = FLOW_DIFF * (0.35f + nv);
    vel.x += (random(1f) + random(1f) + random(1f) + random(1f) - 2f) * sigma;
    vel.y += (random(1f) + random(1f) + random(1f) + random(1f) - 2f) * sigma;

    vel.limit(FLOW_VMAX);
    pos.add(vel);
    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, height * 0.08f, height * 0.72f);

    float a = noise(pos.x * 0.003f, pos.y * 0.003f);
    stroke(255, 225 + (int)(a * 25), 165 + (int)(a * 40), 10 + (int)(18 * a));
    strokeWeight(0.6f + 0.9f * noise(pos.x * 0.02f, pos.y * 0.02f));
    line(prev.x, prev.y, pos.x, pos.y);
  }
}

void paintWindFlow() {
  for (WQParticle p : flowParts) {
    p.respawn();
  }
  for (int t = 0; t < FLOW_STEPS; t++) {
    if (t > 0 && t % FLOW_RESEED == 0) {
      for (WQParticle p : flowParts) {
        p.respawn();
      }
    }
    for (WQParticle p : flowParts) {
      p.step();
    }
  }
}

// ======= IMPASTO TEXTURE — thick paint feel =======
void paintTexture() {
  for (int i = 0; i < 3000; i++) {
    float x = random(width);
    float y = random(height);
    float n = noise(x * 0.01, y * 0.01);
    
    if (n > 0.5) {
      // Bright highlight dabs
      float sz = (n - 0.5) * 8;
      float alpha = (n - 0.5) * 40;
      fill(255, 240, 200, alpha);
      noStroke();
      ellipse(x, y, sz, sz * 0.6);
    } else if (n < 0.4) {
      // Dark shadow dabs
      float sz = (0.4 - n) * 6;
      float alpha = (0.4 - n) * 30;
      fill(10, 5, 15, alpha);
      noStroke();
      ellipse(x, y, sz, sz * 0.8);
    }
  }
}

// ======= VIGNETTE =======
void paintVignette() {
  noStroke();
  for (int i = 0; i < 120; i++) {
    float alpha = map(i, 0, 120, 80, 0);
    fill(15, 8, 20, alpha);
    // Top
    rect(0, i, width, 1);
    // Bottom
    rect(0, height - i, width, 1);
    // Left
    rect(i * 2, 0, 2, height);
    // Right
    rect(width - i * 2, 0, 2, height);
  }
}

// ======= FILM GRAIN =======
void paintGrain() {
  loadPixels();
  for (int i = 0; i < pixels.length; i++) {
    float grain = random(-12, 12);
    float r = constrain(red(pixels[i]) + grain, 0, 255);
    float g = constrain(green(pixels[i]) + grain, 0, 255);
    float b = constrain(blue(pixels[i]) + grain, 0, 255);
    pixels[i] = color(r, g, b);
  }
  updatePixels();
}

// ======= SIGNATURE =======
void paintSignature() {
  fill(200, 180, 140, 80);
  noStroke();
  textSize(11);
  textAlign(RIGHT);
  text("Don Quixote de la Mancha — Tilting at Giants", width - 30, height - 20);
  
  textAlign(LEFT);
  textSize(9);
  fill(180, 160, 120, 60);
  text("\"Take care, your worship; those are windmills.\" — Sancho Panza", 30, height - 20);
}

// Press 'S' to save, 'R' to regenerate with new seed
void keyPressed() {
  if (key == 's' || key == 'S') {
    save("DonQuixote_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".png");
    println("Saved!");
  }
  if (key == 'r' || key == 'R') {
    randomSeed((int)random(99999));
    noiseSeed((int)random(99999));
    redraw();
  }
}
