const homeCanvas = document.getElementById("homeCanvas");
const homeCtx = homeCanvas.getContext("2d");
const startButton = document.getElementById("startButton");
const introButton = document.getElementById("introButton");
const introStartButton = document.getElementById("introStartButton");
const introBox = document.getElementById("introBox");
const bottomTip = document.getElementById("bottomTip");
const demoModal = document.getElementById("demoModal");
const demoFrame = document.getElementById("demoFrame");
const closeButton = document.getElementById("closeButton");
const cover = new Image();
cover.src = "assets/cover.png";

function resizeHomeCanvas() {
  const ratio = window.devicePixelRatio || 1;
  const rect = homeCanvas.getBoundingClientRect();
  homeCanvas.width = Math.max(1, Math.floor(rect.width * ratio));
  homeCanvas.height = Math.max(1, Math.floor(rect.height * ratio));
  homeCtx.setTransform(ratio, 0, 0, ratio, 0, 0);
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
    homeCtx.drawImage(cover, x, y, drawWidth, drawHeight);
  } else {
    const gradient = homeCtx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, "#0a1114");
    gradient.addColorStop(1, "#111819");
    homeCtx.fillStyle = gradient;
    homeCtx.fillRect(0, 0, width, height);
  }
  homeCtx.fillStyle = "rgba(3, 6, 7, 0.34)";
  homeCtx.fillRect(0, 0, width, height);
}

function drawHome(now) {
  const rect = homeCanvas.getBoundingClientRect();
  drawCover(rect.width, rect.height);
  homeCtx.fillStyle = "rgba(37, 224, 164, 0.08)";
  for (let i = 0; i < 6; i += 1) {
    const x = ((now * 0.012 + i * 190) % (rect.width + 220)) - 110;
    const y = rect.height * (0.22 + i * 0.11);
    homeCtx.fillRect(x, y, 120, 2);
  }
  requestAnimationFrame(drawHome);
}

function requestFullscreen() {
  return;
}

function openDemo() {
  if (!demoFrame.src) {
    demoFrame.src = `${demoFrame.dataset.src}?v=${Date.now()}`;
  }
  demoModal.hidden = false;
  bottomTip.textContent = "试玩版已打开。点左上角“返回首页”可回到首页。";
  requestFullscreen();
}

function closeDemo() {
  demoModal.hidden = true;
  bottomTip.textContent = "当前是游戏首页。点“进入游戏”后弹出试玩版。";
  if (document.fullscreenElement) {
    document.exitFullscreen().catch(() => {});
  }
}

startButton.addEventListener("click", openDemo);
introStartButton.addEventListener("click", openDemo);
introButton.addEventListener("click", () => {
  introBox.hidden = !introBox.hidden;
  introButton.textContent = introBox.hidden ? "游戏介绍" : "收起介绍";
});
closeButton.addEventListener("click", closeDemo);
window.addEventListener("resize", resizeHomeCanvas);

resizeHomeCanvas();
cover.onload = resizeHomeCanvas;
requestAnimationFrame(drawHome);
