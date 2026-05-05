# Dust City FPS - 项目记录

## 项目目标
制作一款低模 3D 第一人称单人枪战游戏，先交付电脑可运行原型，再补安卓 APK 构建。玩家加入蓝队，和 4 名队友 AI 对战 5 名橙队敌方 AI；单局 5 分钟，到时间按剩余人数判胜，一方全灭可提前结算。

## 第一版范围
- 首页：开始游戏、设置。
- 地图选择：第一版一个原创低模城市巷战地图，风格参考经典沙色城市 FPS，不复制任何受版权保护地图布局或资源。
- 武器：RPG、M416、巴雷特。
- 角色：玩家第一人称；队友 AI 4 名；敌方 AI 5 名。
- 玩法：移动、视角、射击、切枪、生命值、死亡、倒计时、剩余人数、胜负结算。
- 设置：音量、灵敏度、画质模式。
- 平台：Godot 4.x；桌面端优先可玩；后续 Android APK。

## 架构
- `scenes/main_menu.tscn`：首页。
- `scenes/settings_menu.tscn`：设置页。
- `scenes/map_select.tscn`：地图选择。
- `scenes/game.tscn`：比赛入口，挂载 `scripts/match_manager.gd`。
- `scenes/city_map.tscn`：程序化低模城市地图。
- `scenes/player.tscn`：玩家角色。
- `scenes/ai_bot.tscn`：AI 角色。
- `scenes/hud.tscn`：战斗 HUD 和结算。
- `scenes/mobile_controls.tscn`：安卓触屏控件。

## 核心规则
- 蓝队：玩家 + 4 名队友 AI。
- 橙队：5 名敌方 AI。
- 回合时长：300 秒。
- 胜负：任意一方全灭立即结束；时间到按双方存活人数比较，人数相同为平局。
- 武器数值先以可玩性为主，后续可调。

## 武器设定
- RPG：发射慢速火箭弹，爆炸范围伤害，冷却长。
- M416：中等伤害、高射速、射线命中。
- 巴雷特：高伤害、低射速、远距离射线命中。

## 运行与构建
- 电脑端：用 Godot 4.2/4.3 打开项目，按 `F5` 运行，或执行 `godot --path .`。
- 安卓端：安装 Godot Android Export Templates，配置 Android SDK/JDK/debug keystore 后，使用 `Android Debug` 导出预设构建 `build/android/DustCityFPS.apk`。

## 开源协议
- 项目采用 Apache License 2.0，协议正文维护在 `LICENSE`。

## Git 与大文件
- 仓库远程地址：`git@github.com:AltenLi/ac_fps_android_game.git`。
- 大型二进制产物与游戏媒体通过 `.gitattributes` 配置 Git LFS：`*.apk`、`*.aab`、`*.pck`、`*.zip`、常见图片/音频/模型格式等。
- `.codebuddy/` 与 `.godot/` 为本地/生成目录，不提交到 Git。

## 变更日志
- 2026-05-05：创建 Godot 项目计划和基础设计记录。
- 2026-05-05：实现首页、设置页、地图选择页、低模城市地图、玩家 FPS 控制、RPG/M416/巴雷特、5v5 AI、5 分钟计时、胜负结算、HUD、触屏控件和导出说明。
- 2026-05-05：新增 Apache License 2.0 开源协议文件，并在 `README.md` 中补充协议说明。
- 2026-05-05：新增 `.gitignore` 与 `.gitattributes`，准备将项目推送到 GitHub，并为大型导出/媒体文件启用 Git LFS。
