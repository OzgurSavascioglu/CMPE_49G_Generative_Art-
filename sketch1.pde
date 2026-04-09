/**
 * Static image: Diffusion + Velocity field + 2D Perlin noise
 *
 * Color bands (top → bottom): feminist purple (women's movement),
 * labor red/rust (worker movement), gold/amber (student/youth mobilization),
 * pale pink–lavender (solidarity / shared horizon).
 */

final int SEED = 20260413;

final int W = 1300;
final int H = 900;

final float NOISE_SCALE = 0.0024f;
final float FLOW_STRENGTH = 2.35f;

final float BIAS_CENTER = 0.038f;
final float BIAS_WARP   = 0.016f;

final int NUM_PARTICLES = 9000;
final int STEPS = 520;
final int RESEED_EVERY = 80;

final float MAX_SPEED = 2.35f;
final float DT = 0.085f;

Particle[] parts;

void setup() {
  size(1300, 900, P2D);
  smooth(8);
  pixelDensity(displayDensity());
  randomSeed(SEED);
  noiseSeed(SEED);

  // Deep plum–ink ground so purple, red, and gold strokes read clearly
  background(18, 12, 22);

  parts = new Particle[NUM_PARTICLES];
  for (int i = 0; i < NUM_PARTICLES; i++) {
    parts[i] = new Particle();
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

  saveFrame("prj3_static_diffusion_flow_####.png");
  noLoop();
}

void draw() {
}

PVector velocityField(float x, float y) {
  float n = noise(x * NOISE_SCALE, y * NOISE_SCALE);
  float ang = n * TWO_PI * 2.0f;
  PVector v = PVector.fromAngle(ang).mult(FLOW_STRENGTH);

  PVector c = new PVector(width * 0.5f, height * 0.48f);
  PVector toCenter = PVector.sub(c, new PVector(x, y));
  float dm = max(1.0f, toCenter.mag());
  toCenter.div(dm);
  toCenter.mult(BIAS_CENTER * (0.7f + 0.6f * noise(x * 0.0014f + 5, y * 0.0014f + 7)));
  v.add(toCenter);

  PVector warp = new PVector(0, -1);
  warp.mult(BIAS_WARP * (0.5f + noise(x * 0.0035f + 20, y * 0.0035f + 30)));
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
    vel.add(PVector.mult(acc, DT));
    vel.limit(MAX_SPEED);
    pos.add(vel);

    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);

    strokeForSegment(prev, pos);
    line(prev.x, prev.y, pos.x, pos.y);
  }
}

void strokeForSegment(PVector a, PVector b) {
  float mx = (a.x + b.x) * 0.5f;
  float my = (a.y + b.y) * 0.5f;
  float yN = my / height;

  color c;
  if (yN < 0.25f) {
    // Women's movement: suffrage / feminist purples and violet
    c = lerpColor(color(72, 28, 68), color(168, 98, 188), noise(mx * 0.002f, my * 0.002f));
  } else if (yN < 0.5f) {
    // Worker / labor: international red, rust, near-black
    c = lerpColor(color(198, 42, 38), color(42, 18, 22), noise(mx * 0.002f + 2, my * 0.002f + 2));
  } else if (yN < 0.75f) {
    // Student / youth: gold and amber into militant red (solidarity with labor)
    c = lerpColor(color(232, 186, 52), color(188, 52, 42), noise(mx * 0.002f + 4, my * 0.002f + 4));
  } else {
    // Shared horizon: pale rose and lavender (unity across movements)
    c = lerpColor(color(252, 232, 238), color(210, 198, 228), noise(mx * 0.002f + 6, my * 0.002f + 6));
  }

  float al = 22 + 38 * noise(mx * 0.003f, my * 0.003f);
  stroke(red(c), green(c), blue(c), al);
  strokeWeight(0.75f + 0.9f * noise(mx * 0.01f, my * 0.01f));
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveFrame("prj3_static_diffusion_flow_manual_####.png");
  }
}