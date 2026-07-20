const home = document.getElementById("gameHome");
const panel = document.getElementById("homePanel");
const homeCanvas = document.getElementById("homeCanvas");
const homeCtx = homeCanvas.getContext("2d");
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");
const startButton = document.getElementById("startButton");
const introButton = document.getElementById("introButton");
const introStartButton = document.getElementById("introStartButton");
const introBox = document.getElementById("introBox");
const restartButton = document.getElementById("restartButton");
const closeButton = document.getElementById("closeButton");
const demoModal = document.getElementById("demoModal");
const scoreHud = document.getElementById("scoreHud");
const scoreText = document.getElementById("scoreText");
const comboText = document.getElementById("comboText");
const timeText = document.getElementById("timeText");
const bottomTip = document.getElementById("bottomTip");
const cover = new Image();
cover.src = "assets/cover.png";

const keys = new Set();
const state = {
  playing: false,
  player: { x: 0, z: 46, angle: -Math.PI / 2, hp: 100, ammo: 30 },
  allies: [],
  enemies: [],
  bullets: [],
  sparks: [],
  cursor: { x: 640, y: 360 },
  lastTime: performance.now()
};

function makeSquads() {
  state.allies = [
    { x: -18, z: 56, hp: 100, fire: 0.3 },
    { x: -8, z: 62, hp: 100, fire: 0.7 },
    { x: 10, z: 62, hp: 100, fire: 1.1 },
    { x: 20, z: 56, hp: 100, fire: 1.5 }
  ];
  state.enemies = [
    { x: -32, z: -54, hp: 100, fire: 0.2 },
    { x: -12, z: -66, hp: 100, fire: 0.8 },
    { x: 10, z: -68, hp: 100, fire: 1.4 },
    { x: 30, z: -54, hp: 100, fire: 1.0 },
    { x: 0, z: -82, hp: 100, fire: 0.5 }
  ];
}

function resizeCanvas() {
  const ratio = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = Math.max(1, Math.floor(rect.width * ratio));
  canvas.height = Math.max(1, Math.floor(rect.height * ratio));
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
  state.cursor.x = rect.width * 0.5;
  state.cursor.y = rect.height * 0.5;
}

function resizeHomeCanvas() {
  const ratio = window.devicePixelRatio || 1;
  const rect = homeCanvas.getBoundingClientRect();
  homeCanvas.width = Math.max(1, Math.floor(rect.width * ratio));
  homeCanvas.height = Math.max(1, Math.floor(rect.height * ratio));
  homeCtx.setTransform(ratio, 0, 0, ratio, 0, 0);
}

function requestFullscreen() {
  if (!document.fullscreenElement && demoModal.requestFullscreen) {
    demoModal.requestFullscreen().catch(() => {});
  }
}

function startGame() {
  demoModal.hidden = false;
  resizeCanvas();
  requestFullscreen();
  state.playing = true;
  state.player = { x: 0, z: 46, angle: -Math.PI / 2, hp: 100, ammo: 30 };
  state.bullets = [];
  state.sparks = [];
  state.lastTime = performance.now();
  makeSquads();
  bottomTip.textContent = "WASD 移动 / 鼠标瞄准 / 左键或空格开火 / R 重开";
  updateHud();
}

function closeDemo() {
  state.playing = false;
  demoModal.hidden = true;
  bottomTip.textContent = "当前是游戏首页。点“进入游戏”后弹出试玩版。";
  if (document.fullscreenElement) {
    document.exitFullscreen().catch(() => {});
  }
}

function updateHud() {
  const alliesAlive = 1 + state.allies.filter((unit) => unit.hp > 0).length;
  const enemiesAlive = state.enemies.filter((unit) => unit.hp > 0).length;
  scoreText.textContent = `蓝队 ${alliesAlive}`;
  comboText.textContent = `橙队 ${enemiesAlive}`;
  timeText.textContent = `M416 ${state.player.ammo}/30`;
}

function pointerPosition(event) {
  const rect = canvas.getBoundingClientRect();
  return { x: event.clientX - rect.left, y: event.clientY - rect.top };
}

function shoot() {
  if (!state.playing || state.player.ammo <= 0) {
    return;
  }
  state.player.ammo -= 1;
  const aim = screenToWorld(state.cursor.x, state.cursor.y);
  fireBullet(state.player.x, state.player.z, aim.x, aim.z, "blue", 34);
  addSparks(state.cursor.x, state.cursor.y, "#25e0a4", 5);
  updateHud();
}

function fireBullet(fromX, fromZ, toX, toZ, team, damage) {
  const dx = toX - fromX;
  const dz = toZ - fromZ;
  const length = Math.hypot(dx, dz) || 1;
  state.bullets.push({
    x: fromX,
    z: fromZ,
    vx: (dx / length) * 140,
    vz: (dz / length) * 140,
    team,
    damage,
    age: 0
  });
}

function random(min, max) {
  return min + Math.random() * Math.max(0, max - min);
}

function worldToScreen(x, z) {
  const rect = canvas.getBoundingClientRect();
  const scale = Math.min(rect.width / 150, rect.height / 120);
  return {
    x: rect.width * 0.5 + (x - state.player.x) * scale,
    y: rect.height * 0.62 + (z - state.player.z) * scale
  };
}

function screenToWorld(x, y) {
  const rect = canvas.getBoundingClientRect();
  const scale = Math.min(rect.width / 150, rect.height / 120);
  return {
    x: state.player.x + (x - rect.width * 0.5) / scale,
    z: state.player.z + (y - rect.height * 0.62) / scale
  };
}

function nearestLiving(units, from) {
  let best = null;
  let bestDistance = Infinity;
  for (const unit of units) {
    if (unit.hp <= 0) {
      continue;
    }
    const distance = Math.hypot(unit.x - from.x, unit.z - from.z);
    if (distance < bestDistance) {
      best = unit;
      bestDistance = distance;
    }
  }
  return best;
}

function updateUnits(delta) {
  for (const ally of state.allies) {
    if (ally.hp <= 0) {
      continue;
    }
    const target = nearestLiving(state.enemies, ally);
    ally.z = Math.max(-34, ally.z - 18 * delta);
    ally.x += Math.sin(performance.now() * 0.001 + ally.z) * 4 * delta;
    ally.fire -= delta;
    if (target && ally.fire <= 0) {
      ally.fire = random(0.45, 0.85);
      fireBullet(ally.x, ally.z, target.x, target.z, "blue", 24);
    }
  }
  for (const enemy of state.enemies) {
    if (enemy.hp <= 0) {
      continue;
    }
    enemy.z = Math.min(-18, enemy.z + 10 * delta);
    enemy.x += Math.sin(performance.now() * 0.0014 + enemy.x) * 5 * delta;
    enemy.fire -= delta;
    if (enemy.fire <= 0) {
      enemy.fire = random(0.65, 1.15);
      const targets = [state.player, ...state.allies.filter((unit) => unit.hp > 0)];
      const target = targets[Math.floor(Math.random() * targets.length)];
      fireBullet(enemy.x, enemy.z, target.x, target.z, "orange", 12);
    }
  }
}

function updatePlayer(delta) {
  const speed = keys.has("ShiftLeft") ? 48 : 34;
  let dx = 0;
  let dz = 0;
  if (keys.has("KeyA")) dx -= 1;
  if (keys.has("KeyD")) dx += 1;
  if (keys.has("KeyW")) dz -= 1;
  if (keys.has("KeyS")) dz += 1;
  const length = Math.hypot(dx, dz) || 1;
  state.player.x = Math.max(-62, Math.min(62, state.player.x + (dx / length) * speed * delta));
  state.player.z = Math.max(-4, Math.min(64, state.player.z + (dz / length) * speed * delta));
}

function updateBullets(delta) {
  for (const bullet of state.bullets) {
    bullet.x += bullet.vx * delta;
    bullet.z += bullet.vz * delta;
    bullet.age += delta;
    const targets = bullet.team === "blue" ? state.enemies : [state.player, ...state.allies];
    for (const target of targets) {
      if (target.hp <= 0) {
        continue;
      }
      if (Math.hypot(target.x - bullet.x, target.z - bullet.z) < 4.2) {
        target.hp = Math.max(0, target.hp - bullet.damage);
        const hit = worldToScreen(target.x, target.z);
        addSparks(hit.x, hit.y, bullet.team === "blue" ? "#25e0a4" : "#ff5f52", 12);
        bullet.age = 9;
        break;
      }
    }
  }
  state.bullets = state.bullets.filter((bullet) => bullet.age < 1.4);
}

function updateSparks(delta) {
  state.sparks = state.sparks.filter((spark) => {
    spark.age += delta;
    spark.x += spark.vx * delta;
    spark.y += spark.vy * delta;
    return spark.age < spark.life;
  });
}

function addSparks(x, y, color, count) {
  for (let i = 0; i < count; i += 1) {
    state.sparks.push({
      x,
      y,
      vx: random(-70, 70),
      vy: random(-70, 70),
      life: random(0.18, 0.42),
      age: 0,
      color
    });
  }
}

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
    gradient.addColorStop(1, "#111819");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
  }
  ctx.fillStyle = state.playing ? "rgba(3, 6, 7, 0.22)" : "rgba(3, 6, 7, 0.34)";
  ctx.fillRect(0, 0, width, height);
}

function drawArena(width, height) {
  const horizon = height * 0.28;
  const floor = ctx.createLinearGradient(0, horizon, 0, height);
  floor.addColorStop(0, "#27362f");
  floor.addColorStop(1, "#111715");
  ctx.fillStyle = floor;
  ctx.fillRect(0, horizon, width, height - horizon);

  ctx.strokeStyle = "rgba(238, 247, 244, 0.12)";
  ctx.lineWidth = 2;
  for (let i = -5; i <= 5; i += 1) {
    const x = width * 0.5 + i * width * 0.09;
    ctx.beginPath();
    ctx.moveTo(width * 0.5, horizon);
    ctx.lineTo(x, height);
    ctx.stroke();
  }
  for (let j = 0; j < 8; j += 1) {
    const y = horizon + j * j * 11;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
    ctx.stroke();
  }
}

function drawUnit(unit, team, label) {
  if (unit.hp <= 0) {
    return;
  }
  const p = worldToScreen(unit.x, unit.z);
  const distanceFade = Math.max(0.45, 1 - Math.abs(unit.z - state.player.z) / 150);
  const size = team === "player" ? 26 : 20 * distanceFade;
  ctx.fillStyle = team === "orange" ? "#ff7a52" : "#25e0a4";
  ctx.beginPath();
  ctx.arc(p.x, p.y, size, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "rgba(5, 9, 10, 0.82)";
  ctx.fillRect(p.x - size * 0.8, p.y - size * 0.2, size * 1.6, size * 1.6);
  ctx.fillStyle = "#eef7f4";
  ctx.font = "700 12px Microsoft YaHei, Arial";
  ctx.textAlign = "center";
  ctx.fillText(label, p.x, p.y - size - 9);
  ctx.fillStyle = "rgba(0,0,0,0.5)";
  ctx.fillRect(p.x - 18, p.y + size + 8, 36, 5);
  ctx.fillStyle = team === "orange" ? "#ff5f52" : "#25e0a4";
  ctx.fillRect(p.x - 18, p.y + size + 8, 36 * (unit.hp / 100), 5);
}

function drawBullet(bullet) {
  const p = worldToScreen(bullet.x, bullet.z);
  ctx.fillStyle = bullet.team === "blue" ? "#eafff8" : "#ffd7c9";
  ctx.beginPath();
  ctx.arc(p.x, p.y, 3, 0, Math.PI * 2);
  ctx.fill();
}

function drawCrosshair(width, height) {
  const x = state.cursor.x || width * 0.5;
  const y = state.cursor.y || height * 0.5;
  ctx.strokeStyle = "rgba(238, 247, 244, 0.9)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(x - 24, y);
  ctx.lineTo(x - 8, y);
  ctx.moveTo(x + 8, y);
  ctx.lineTo(x + 24, y);
  ctx.moveTo(x, y - 24);
  ctx.lineTo(x, y - 8);
  ctx.moveTo(x, y + 8);
  ctx.lineTo(x, y + 24);
  ctx.stroke();
  ctx.strokeStyle = "rgba(37, 224, 164, 0.72)";
  ctx.beginPath();
  ctx.arc(x, y, 34, 0, Math.PI * 2);
  ctx.stroke();
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

function endMatch(message) {
  state.playing = false;
  bottomTip.textContent = message;
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
  shoot();
});

window.addEventListener("keydown", (event) => {
  keys.add(event.code);
  if (event.code === "Space") {
    event.preventDefault();
    shoot();
  }
  if (event.code === "KeyR" && state.playing) {
    startGame();
  }
});

window.addEventListener("keyup", (event) => {
  keys.delete(event.code);
});

startButton.addEventListener("click", startGame);
introStartButton.addEventListener("click", startGame);
introButton.addEventListener("click", () => {
  introBox.hidden = !introBox.hidden;
  introButton.textContent = introBox.hidden ? "游戏介绍" : "收起介绍";
});
restartButton.addEventListener("click", startGame);
closeButton.addEventListener("click", closeDemo);
window.addEventListener("resize", () => {
  resizeHomeCanvas();
  resizeCanvas();
});

function drawHome(now) {
  const rect = homeCanvas.getBoundingClientRect();
  drawCoverOn(homeCtx, rect.width, rect.height, false);
  homeCtx.fillStyle = "rgba(37, 224, 164, 0.08)";
  for (let i = 0; i < 6; i += 1) {
    const x = ((now * 0.012 + i * 190) % (rect.width + 220)) - 110;
    const y = rect.height * (0.22 + i * 0.11);
    homeCtx.fillRect(x, y, 120, 2);
  }
}

function drawCoverOn(targetCtx, width, height, playing) {
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
    targetCtx.drawImage(cover, x, y, drawWidth, drawHeight);
  } else {
    const gradient = targetCtx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, "#0a1114");
    gradient.addColorStop(1, "#111819");
    targetCtx.fillStyle = gradient;
    targetCtx.fillRect(0, 0, width, height);
  }
  targetCtx.fillStyle = playing ? "rgba(3, 6, 7, 0.22)" : "rgba(3, 6, 7, 0.34)";
  targetCtx.fillRect(0, 0, width, height);
}

function loop(now) {
  const rect = canvas.getBoundingClientRect();
  const delta = Math.min(0.05, (now - state.lastTime) / 1000 || 0);
  state.lastTime = now;

  if (state.playing) {
    updatePlayer(delta);
    updateUnits(delta);
    updateBullets(delta);
    updateSparks(delta);
    if (state.player.ammo <= 0) {
      state.player.ammo = 30;
    }
    if (state.enemies.every((enemy) => enemy.hp <= 0)) {
      endMatch("蓝队胜利：敌人已清空。点击进入游戏可以再开一局。");
    }
    if (state.player.hp <= 0) {
      endMatch("蓝队阵亡：点击进入游戏重新挑战。");
    }
    updateHud();
  } else {
    updateSparks(delta);
  }

  drawHome(now);
  if (demoModal.hidden) {
    requestAnimationFrame(loop);
    return;
  }

  drawCover(rect.width, rect.height);
  if (state.playing) {
    drawArena(rect.width, rect.height);
    for (const bullet of state.bullets) drawBullet(bullet);
    for (const ally of state.allies) drawUnit(ally, "blue", "队友");
    for (const enemy of state.enemies) drawUnit(enemy, "orange", "敌人");
    drawUnit(state.player, "player", "我");
    drawCrosshair(rect.width, rect.height);
  }
  drawSparks();
  requestAnimationFrame(loop);
}

resizeHomeCanvas();
resizeCanvas();
cover.onload = () => {
  resizeHomeCanvas();
  resizeCanvas();
};
requestAnimationFrame(loop);
