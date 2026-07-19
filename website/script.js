const weaponCopy = {
  m416: "自动步枪，负责中近距离持续压制，也是突击兵的核心武器。",
  barrett: "高伤害狙击枪，支持 2.5 倍和 5 倍开镜循环，适合远距离点杀。",
  knife: "战术匕首是纯近战武器，没有子弹、不会发射投射物，可以无限挥砍。",
  grenade: "手雷每局最多 10 个，2 秒冷却，抛物线投掷，近身爆炸可把玩家炸飞但不自伤。"
};

document.querySelectorAll(".tab").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach((tab) => tab.classList.remove("is-active"));
    button.classList.add("is-active");
    document.getElementById("weaponText").textContent = weaponCopy[button.dataset.weapon];
  });
});

document.querySelectorAll(".map-item").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".map-item").forEach((item) => item.classList.remove("is-selected"));
    button.classList.add("is-selected");
    document.getElementById("mapText").textContent = button.dataset.map;
  });
});
