const home = document.getElementById("gameHome");
const panel = document.getElementById("homePanel");
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");
const startButton = document.getElementById("startButton");
const restartButton = document.getElementById("restartButton");
const scoreHud = document.getElementById("scoreHud");
const scoreText = document.getElementById("scoreText");
const comboText = document.getElementById("comboText");
const timeText = document.getElementById("timeText");
const bottomTip = document.getElementById("bottomTip");
const cover = new Image();
cover.src = "assets/cover.png";

const state = {
  playing: false,
  score: 0,
  combo: 0,
  bestCombo: 0,
  timeLeft: 45,
  target: { x: 640, y: 360, radius: 54, age: 0, life: 1.8 },
  cursor: { x: 640, y: 360 },
  sparks: [],
  lastTime: performance.now()
};

function resizeCanvas() {
  const ratio = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = Math.max(1, Math.floor(rect.width * ratio));
  canvas.height = Math.max(1, Math.floor(rect.height * ratio));
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
  spawnTarget();
}

function requestFullscreen() {
  if (!document.fullscreenElement && home.requestFullscreen) {
    home.requestFullscreen().catch(() => {});
  }
}

function startGame() {
  requestFullscreen();
  state.playing = true;
  state.score = 0;
  state.combo = 0;
  state.bestCombo = 0;
  state.timeLeft = 45;
  state.target.radius = 54;
  state.sparks = [];
  state.lastTime = performance.now();
  panel.classList.add("is-hidden");
  home.classList.add("is-playing");
  scoreHud.hidden = false;
  restartButton.hidden = false;
  bottomTip.textContent = "鼠标瞄准 · 左键 / 空格射击 · R 重新开始";
  spawnTarget();
  updateHud();
}

function spawnTarget() {
  const rect = canvas.getBoundingClientRect();
  const margin = state.target.radius + 34;
  const topSafe = 118;
  state.target.x = random(margin, Math.max(margin, rect.width - margin));
  state.target.y = random(topSafe + margin, Math.max(topSafe + margin, rect.height - margin));
  state.target.age = 0;
}

function random(min, max) {
  return min + Math.random() * Math.max(0, max - min);
}

function updateHud() {
  scoreText.textContent = `得分 ${state.score}`;
  comboText.textContent = `连击 x${state.combo}`;
  timeText.textContent = `${Math.ceil(state.timeLeft)}`;
}

function shoot(x, y) {
  if (!state.playing) {
    return;
  }
  const distance = Math.hypot(x - state.target.x, y - state.target.y);
  if (distance <= state.target.radius + 14) {
    state.combo += 1;
    state.bestCombo = Math.max(state.bestCombo, state.combo);
    state.score += 10 + state.combo * 3;
    state.target.radius = Math.max(34, state.target.radius - 1.1);
    addSparks(state.target.x, state.target.y, "#25e0a4", 18);
    spawnTarget();
  } else {
    state.combo = 0;
    addSparks(x, y, "#ff5f52", 8);
  }
  updateHud();
}

function addSparks(x, y, color, count) {
  for (let i = 0; i < count; i += 1) {
    state.sparks.push({
      x,
      y,
      vx: random(-180, 180),
      vy: random(-180, 180),
      life: random(0.22, 0.48),
      age: 0,
      color
    });
  }
}

function pointerPosition(event) {
  const rect = canvas.getBoundingClientRect();
  return { x: event.clientX - rect.left, y: event.clientY - rect.top };
}

canvas.addEventListener("pointermove", (event) => {
  const pos = pointerPosition(event);
  state.cursor.x = pos.x;
  state.cursor.y = pos.y;
});

canvas.addEventListener("pointerdown", (event) => {
  const pos = pointerPosition(event);
  state.cursor.x = pos.x;
  state.cursor.y = pos.y;
  shoot(pos.x, pos.y);
});

window.addEventListener("keydown", (event) => {
  if (event.code === "Space") {
    event.preventDefault();
    shoot(state.cursor.x, state.cursor.y);
  }
  if (event.code === "KeyR") {
    startGame();
  }
});

startButton.addEventListener("click", startGame);
restartButton.addEventListener("click", startGame);
window.addEventListener("resize", resizeCanvas);

function drawCover(width, height) {
  if (cover.complete && cover.naturalWidth > 0) {
    const imgRatio = cover.naturalWidth / cover.naturalHeight;
    const canvasRatio = width / height;
    let drawWidth = width;
    let drawHeight = height;
    let x = 0;
    let y = 0;
    if (imgRatio > canvasRatio) {
      drawWidth = height * imgRatio;
      x = (width - drawWidth) * 0.5;
    } else {
      drawHeight = width / imgRatio;
      y = (height - drawHeight) * 0.5;
    }
    ctx.drawImage(cover, x, y, drawWidth, drawHeight);
  } else {
    const gradient = ctx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, "#0a1114");
    gradient.addColorStop(0.55, "#16201e");
    gradient.addColorStop(1, "#07090b");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
  }
  ctx.fillStyle = state.playing ? "rgba(3, 6, 7, 0.58)" : "rgba(3, 6, 7, 0.30)";
  ctx.fillRect(0, 0, width, height);
}

function drawTarget() {
  const t = state.target;
  const progress = Math.max(0, 1 - t.age / t.life);
  ctx.fillStyle = "rgba(255, 95, 82, 0.20)";
  ctx.beginPath();
  ctx.arc(t.x, t.y, t.radius + 16, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#ff5f52";
  ctx.beginPath();
  ctx.arc(t.x, t.y, t.radius, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#f3bc50";
  ctx.beginPath();
  ctx.arc(t.x, t.y, t.radius * 0.48, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#101515";
  ctx.beginPath();
  ctx.arc(t.x, t.y, 5, 0, Math.PI * 2);
  ctx.fill();
  ctx.strokeStyle = "rgba(238, 247, 244, 0.92)";
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.arc(t.x, t.y, t.radius + 7, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress);
  ctx.stroke();
}

function drawCrosshair() {
  const c = state.cursor;
  ctx.strokeStyle = "rgba(238, 247, 244, 0.82)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(c.x - 20, c.y);
  ctx.lineTo(c.x - 7, c.y);
  ctx.moveTo(c.x + 7, c.y);
  ctx.lineTo(c.x + 20, c.y);
  ctx.moveTo(c.x, c.y - 20);
  ctx.lineTo(c.x, c.y - 7);
  ctx.moveTo(c.x, c.y + 7);
  ctx.lineTo(c.x, c.y + 20);
  ctx.stroke();
}

function updateSparks(delta) {
  state.sparks = state.sparks.filter((spark) => {
    spark.age += delta;
    spark.x += spark.vx * delta;
    spark.y += spark.vy * delta;
    return spark.age < spark.life;
  });
}

function drawSparks() {
  for (const spark of state.sparks) {
    ctx.globalAlpha = 1 - spark.age / spark.life;
    ctx.fillStyle = spark.color;
    ctx.beginPath();
    ctx.arc(spark.x, spark.y, 3.5, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.globalAlpha = 1;
}

function loop(now) {
  const rect = canvas.getBoundingClientRect();
  const delta = Math.min(0.05, (now - state.lastTime) / 1000 || 0);
  state.lastTime = now;

  if (state.playing) {
    state.timeLeft = Math.max(0, state.timeLeft - delta);
    state.target.age += delta;
    if (state.target.age > state.target.life) {
      state.combo = 0;
      spawnTarget();
      updateHud();
    }
    if (state.timeLeft <= 0) {
      state.playing = false;
      panel.classList.remove("is-hidden");
      home.classList.remove("is-playing");
      bottomTip.textContent = `训练结束：得分 ${state.score}，最高连击 x${state.bestCombo}。点击开始游玩可重开。`;
    }
  }

  updateSparks(delta);
  drawCover(rect.width, rect.height);
  if (state.playing) {
    drawTarget();
  }
  drawSparks();
  if (state.playing) {
    drawCrosshair();
  }
  requestAnimationFrame(loop);
}

resizeCanvas();
cover.onload = resizeCanvas;
requestAnimationFrame(loop);
