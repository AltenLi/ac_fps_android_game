# Dust City FPS

低模 3D 第一人称单人枪战原型。玩家加入蓝队，和 4 名队友 AI 对战 5 名橙队敌方 AI；每局 5 分钟，时间到按剩余人数判胜，一方全灭提前结算。

## 当前功能

- 首页：开始游戏、设置。
- 地图选择：第一版一个原创低模城市巷战地图。
- 5v5：玩家 + 4 名队友 AI，对战 5 名敌方 AI。
- 武器：M416、巴雷特、RPG，支持弹匣、备弹、手动装弹和空弹自动装弹。
- 美术：程序化低模士兵、M416、巴雷特、RPG 模型，替换早期方块/胶囊占位。
- 桌面控制：WASD 移动、鼠标瞄准、左键射击、`R` 装弹、`1/2/3` 或 `Q` 切枪、`ESC` 释放鼠标、`Tab` 重新锁定鼠标。
- HUD：倒计时、双方剩余人数、生命值、当前武器、当前子弹/备弹、胜负结算。
- 安卓触屏控件：左下虚拟摇杆，右侧开火、切枪、装弹按钮，右侧拖动视角。

## 电脑端运行

1. 安装 Godot 4.6（当前项目已按 Godot 4.6.2 验证）。
2. 打开 Godot，选择 `Import`，导入本目录：
   ```bash
   /Users/altenli/Documents/李羽瑄/game
   ```
3. 打开项目后按 `F5` 运行。

如果已安装 Godot 命令行，也可以在本目录运行：

```bash
godot --path .
```

## 安卓 APK 构建

1. 在 Godot 中打开项目。
2. 进入 `Editor > Manage Export Templates`，安装与你的 Godot 版本一致的导出模板。
3. 进入 `Editor Settings > Export > Android`，配置 Android SDK、JDK、debug keystore。
4. 进入 `Project > Export`。
5. 选择 `Android Debug` 预设。
6. 点击 `Export Project`，输出路径默认是：
   ```bash
   build/android/DustCityFPS.apk
   ```
7. 把 APK 传到安卓手机安装，或拖入 Android Studio Emulator/其他安卓模拟器安装。

命令行导出示例：

```bash
godot --headless --path . --export-debug "Android Debug" build/android/DustCityFPS.apk
```

## 说明

第一版使用 Godot 内置几何体和程序化场景，不依赖外部美术资源。地图为原创低模城市巷战布局，仅参考沙色城市 FPS 氛围，不复制任何受版权保护地图资源。

## 开源协议

本项目采用 Apache License 2.0 开源协议，详见 `LICENSE`。
