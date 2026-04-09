/**
 * Carpet lattice — classic rug rhythm in abstract motion (no copied motif).
 *
 * Inspired by repeating field + central medallion + border framing of oriental carpets.
 *
 * • Velocity: curl of a PERIODIC stream function ψ (tile-wise Perlin in each cell)
 *   so swirls repeat like knot spacing; plus a weak radial “medallion” tangential term.
 * • Diffusion: Langevin noise on velocity, amplitude modulated by 2D Perlin.
 * • Color: sector hues (lapis / gold / crimson / cream) from angle + noise — pile-like variation.
 */

final int SEED = 20260414;

final float CELL = 78.0f;
final float PSI_SCALE = 0.11f;
final float CURL_EPS = 4.0f;
final float CURL_GAIN = 320.0f;
final float MEDALLION_GAIN = 1.15f;
final float BORDER_PULL = 0.38f;

final float DT = 0.1f;
final float VEL_DAMP = 0.9f;
final float DIFF = 0.42f;
final float MAX_SPEED = 3.6f;

final int NUM_PARTICLES = 10200;
final int STEPS = 520;
final int RESEED_EVERY = 74;

Particle[] parts;


void setup() {
  size(1100, 780, P2D);

  smooth(8);
  pixelDensity(1);
  randomSeed(SEED);
  noiseSeed(SEED);

  parts = new Particle[NUM_PARTICLES];
  for (int i = 0; i < NUM_PARTICLES; i++) {
    parts[i] = new Particle();
  }

  noLoop();
}

void draw() {
  paintRugGround();
  runCarpetFlow();
  paintBorderFrame();

  saveFrame("carpet_flow_####.png");
}

void paintRugGround() {
  loadPixels();
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float px = tileMod(x, CELL);
      float py = tileMod(y, CELL);
      float n = noise(px * 0.06f, py * 0.06f);
      float m = noise(x * 0.004f + 50f, y * 0.004f);
      float r = lerp(32, 58, n) + m * 8f;
      float g = lerp(28, 52, n * 0.9f);
      float b = lerp(72, 108, n);
      pixels[x + y * width] = color(constrain(r, 0, 255), constrain(g, 0, 255), constrain(b, 0, 255));
    }
  }
  updatePixels();
}

float tileMod(float v, float period) {
  float t = v % period;
  if (t < 0) {
    t += period;
  }
  return t;
}

float streamPsi(float x, float y) {
  float px = tileMod(x, CELL);
  float py = tileMod(y, CELL);
  float a = noise(px * PSI_SCALE + 1.7f, py * PSI_SCALE + 4.2f);
  float b = noise(px * PSI_SCALE * 2.05f + 20f, py * PSI_SCALE * 2.05f + 9f);
  return a + 0.46f * b;
}

PVector velocityField(float x, float y) {
  float dpsidy = (streamPsi(x, y + CURL_EPS) - streamPsi(x, y - CURL_EPS)) / (2f * CURL_EPS);
  float dpsidx = (streamPsi(x + CURL_EPS, y) - streamPsi(x - CURL_EPS, y)) / (2f * CURL_EPS);
  PVector v = new PVector(dpsidy, -dpsidx);
  v.mult(CURL_GAIN);

  float cx = width * 0.5f;
  float cy = height * 0.48f;
  float dx = x - cx;
  float dy = y - cy;
  float rr = sqrt(dx * dx + dy * dy) + 55f;
  PVector tan = new PVector(-dy / rr, dx / rr);
  tan.mult(MEDALLION_GAIN * (0.35f + 0.65f * noise(x * 0.0025f + 11f, y * 0.0025f + 3f)));
  v.add(tan);

  float edge = min(min(x, width - x), min(y, height - y));
  if (edge < width * 0.08f) {
    PVector inward = new PVector(cx - x, cy - y);
    inward.normalize();
    inward.mult(BORDER_PULL * (1f - edge / (width * 0.08f)));
    v.add(inward);
  }

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

    PVector u = velocityField(pos.x, pos.y);
    vel.mult(VEL_DAMP);
    vel.add(PVector.mult(u, DT));

    float nv = noise(pos.x * 0.004f + 200f, pos.y * 0.004f + 50f);
    float sigma = DIFF * (0.3f + nv);
    vel.x += (random(1f) + random(1f) + random(1f) + random(1f) - 2f) * sigma;
    vel.y += (random(1f) + random(1f) + random(1f) + random(1f) - 2f) * sigma;

    vel.limit(MAX_SPEED);
    pos.add(vel);

    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);

    strokePile(prev, pos);
    line(prev.x, prev.y, pos.x, pos.y);
  }
}

void strokePile(PVector a, PVector b) {
  float mx = (a.x + b.x) * 0.5f;
  float my = (a.y + b.y) * 0.5f;
  float cx = width * 0.5f;
  float cy = height * 0.48f;
  float ang = atan2(my - cy, mx - cx);
  float rad = mag(mx - cx, my - cy) / (0.52f * width);
  float t = noise(mx * 0.003f, my * 0.003f);
  float sp = PVector.dist(a, b);

  color navy = color(28, 38, 88);
  color lapis = color(52, 92, 168);
  color gold = color(210, 165, 58);
  color cream = color(232, 216, 188);
  color crimson = color(142, 28, 48);
  color teal = color(36, 118, 112);

  float sector = 0.5f + 0.5f * sin(ang * 5f + t * 3f);
  color c = lerpColor(navy, lapis, t);
  c = lerpColor(c, crimson, constrain(sector * rad * 1.4f, 0, 0.75f));
  c = lerpColor(c, gold, constrain((t - 0.4f) * 0.9f + rad * 0.25f, 0, 0.55f));
  c = lerpColor(c, teal, 0.15f * (1f - rad) * noise(mx * 0.002f + 1f, my * 0.002f));
  c = lerpColor(c, cream, 0.2f * noise(mx * 0.005f, my * 0.005f + 7f) * (0.4f + 0.6f * (1f - rad)));

  float al = 12 + 34 * noise(mx * 0.0035f, my * 0.0035f + 2f) + min(26f, sp * 5f);
  stroke(red(c), green(c), blue(c), al);
  strokeWeight(0.45f + 0.95f * noise(mx * 0.014f, my * 0.014f));
}

void runCarpetFlow() {
  for (Particle p : parts) {
    p.respawn();
  }
  for (int t = 0; t < STEPS; t++) {
    if (t % RESEED_EVERY == 0 && t > 0) {
      for (Particle p : parts) {
        p.respawn();
      }
    }
    for (Particle p : parts) {
      p.step();
    }
  }
}

void paintBorderFrame() {
  noFill();
  stroke(180, 145, 60, 70);
  strokeWeight(10);
  rect(18, 18, width - 36, height - 36);
  stroke(28, 38, 78, 120);
  strokeWeight(4);
  rect(32, 32, width - 64, height - 64);
  stroke(210, 175, 85, 45);
  strokeWeight(2);
  rect(44, 44, width - 88, height - 88);
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveFrame("carpet_flow_manual_####.png");
  }
  if (key == 'r' || key == 'R') {
    randomSeed((int)random(99999));
    noiseSeed((int)random(99999));
    redraw();
  }
}
