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
const versionUrl = "version.txt";
let currentVersion = "";

function resizeHomeCanvas() {
  const ratio = window.devicePixelRatio || 1;
  const rect = homeCanvas.getBoundingClientRect();
  homeCanvas.width = Math.max(1, Math.floor(rect.width * ratio));
  homeCanvas.height = Math.max(1, Math.floor(rect.height * ratio));
  homeCtx.setTransform(ratio, 0, 0, ratio, 0, 0);
}

function drawCover(width, height) {
  const backdrop = homeCtx.createLinearGradient(0, 0, width, height);
  backdrop.addColorStop(0, "#050a0c");
  backdrop.addColorStop(0.56, "#0a171b");
  backdrop.addColorStop(1, "#111326");
  homeCtx.fillStyle = backdrop;
  homeCtx.fillRect(0, 0, width, height);
  if (cover.complete && cover.naturalWidth > 0) {
    const imgRatio = cover.naturalWidth / cover.naturalHeight;
    const drawHeight = height * 1.08;
    const drawWidth = drawHeight * imgRatio;
    const x = width - drawWidth - Math.max(18, width * 0.055);
    const y = (height - drawHeight) * 0.5;
    homeCtx.save();
    homeCtx.shadowColor = "rgba(30, 220, 255, 0.28)";
    homeCtx.shadowBlur = 42;
    homeCtx.drawImage(cover, x, y, drawWidth, drawHeight);
    homeCtx.restore();
  }
  const shade = homeCtx.createLinearGradient(0, 0, width, 0);
  shade.addColorStop(0, "rgba(2, 5, 6, 0.10)");
  shade.addColorStop(0.55, "rgba(2, 5, 6, 0.18)");
  shade.addColorStop(1, "rgba(2, 5, 6, 0.02)");
  homeCtx.fillStyle = shade;
  homeCtx.fillRect(0, 0, width, height);
}

function drawHome(now) {
  const rect = homeCanvas.getBoundingClientRect();
  drawCover(rect.width, rect.height);
  homeCtx.fillStyle = "rgba(37, 224, 164, 0.10)";
  for (let i = 0; i < 6; i += 1) {
    const x = ((now * 0.012 + i * 190) % (rect.width + 220)) - 110;
    const y = rect.height * (0.22 + i * 0.11);
    homeCtx.fillRect(x, y, 120, 2);
  }
  requestAnimationFrame(drawHome);
}

function openDemo() {
  if (!demoFrame.src) {
    demoFrame.src = `${demoFrame.dataset.src}?v=${currentVersion || Date.now()}`;
  }
  demoModal.hidden = false;
  bottomTip.textContent = "试玩版已打开，点击左上角“返回首页”可回到首页。";
}

function closeDemo() {
  demoModal.hidden = true;
  bottomTip.textContent = "当前是游戏首页，点击“进入游戏”打开全屏试玩版。";
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

async function checkHotVersion() {
  try {
    const response = await fetch(`${versionUrl}?t=${Date.now()}`, { cache: "no-store" });
    if (!response.ok) return;
    const nextVersion = (await response.text()).trim();
    if (!nextVersion) return;
    if (!currentVersion) {
      currentVersion = nextVersion;
      return;
    }
    if (nextVersion !== currentVersion) {
      currentVersion = nextVersion;
      if (!demoModal.hidden) {
        demoFrame.src = `${demoFrame.dataset.src}?v=${currentVersion}`;
      } else {
        location.reload();
      }
    }
  } catch (_error) {
  }
}

resizeHomeCanvas();
cover.onload = resizeHomeCanvas;
requestAnimationFrame(drawHome);
checkHotVersion();
setInterval(checkHotVersion, 2000);
