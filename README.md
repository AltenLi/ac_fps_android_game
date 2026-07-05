# CS 5v5

Current design handoff: `design/CURRENT_DESIGN.md`

CS 5v5 是一款使用 Godot 4.6 开发、以手机易操控和精致真实观感为目标的 3D 第一人称单人枪战游戏。玩家加入蓝队，与 4 名队友 AI 对战 5 名橙队 AI；每局 5 分钟，一方全灭提前结算，时间到按存活人数判胜。

## 当前状态

当前项目是“可玩预发布原型”，已具备完整单局循环和局外星星解锁，但尚未接入真实广告、内购、统计或崩溃上报 SDK。

## 当前功能

- 首页：开始游戏、设置、星星总数、每日奖励、每日任务面板、首次自动弹出的分步骤新手教程和手动教程入口。
- 地图选择：11 张原创程序化真实风格地图，前 3 张免费，其余按 `6/10/10/12/12/15/15/18` 星递增解锁。
- 难度：简单、普通、困难三档 AI。
- 5v5：玩家 + 4 名队友 AI，对战 5 名敌方 AI。
- 武器：M416、巴雷特、RPG，支持弹匣、备弹、手动装弹、空弹自动装弹和地图弹药补给。
- 战斗反馈：动态准星、命中标记、伤害数字、玩家击杀条幅、3D 击杀特效、胜利纸屑。
- 结算：胜负原因、双方剩余人数、玩家击杀、本局战绩、胜利星星奖励、MVP 额外奖励。
- 进度：星星、累计击杀/死亡、地图解锁、每日奖励、每日任务、教程完成状态、本地持久化。
- 桌面控制：WASD 移动、鼠标瞄准、左键射击、`R` 装弹、`1/2/3` 或 `Q` 切枪、`ESC` 释放鼠标、`Tab` 重新锁定鼠标。
- 安卓触屏控件：左侧浮动摇杆，右侧开火、切枪、装弹按钮；非按钮区域滑动移动视角。

## 运行

```bash
godot --path .
```

也可以用 Godot 4.6 打开项目后按 `F5` 运行。

## 自动化测试与发布前预检

每次发布前必须先运行：

```bash
./scripts/release_preflight.sh
```

该脚本会运行 Godot Headless 单测，并检查关键发布配置。只想运行单测时：

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

测试覆盖：地图注册表、玩家星星/解锁/每日任务逻辑、武器资源、AI 平衡、教程流程、设置校验、Android Release 配置。

## Android Release 构建

1. 安装 Godot 4.6 对应 Android Export Templates。
2. 配置 Android SDK/JDK 和正式 release keystore。
3. 先运行 `./scripts/release_preflight.sh`。
4. 导出 `Android Release` 预设，默认输出：

```bash
build/android/DustCityFPS.apk
```

命令行示例：

```bash
godot --headless --path . --export-release "Android Release" build/android/DustCityFPS.apk
```

当前 Android 包名：`com.liacgames.cs5v5`。

## 商业化说明

当前只实现了商业化抽象和调试占位，不包含真实广告或内购 SDK。正式上线赚钱前需要：

- 接入激励广告 SDK 或平台内购 SDK。
- 打开并说明必要网络/广告权限。
- 更新隐私政策、用户协议、SDK 清单和商店数据安全声明。
- 完成 `RELEASE_CHECKLIST.md` 中的素材、签名、测试和合规项。

## 开源协议

本项目采用 Apache License 2.0，详见 `LICENSE`。
