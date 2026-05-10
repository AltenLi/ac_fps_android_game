# CS 5v5 - 项目记录

## 项目目标

制作一款低模 3D 第一人称单人 5v5 枪战游戏，并逐步推进到可发布、可测试、可商业化接入的预发布版本。玩家加入蓝队，与 4 名队友 AI 对战 5 名橙队 AI；单局 5 分钟，到时间按剩余人数判胜，一方全灭可提前结算。

## 当前真实状态

- 项目名：`CS 5v5`。
- 引擎：Godot 4.6 / GDScript。
- 主场景：`scenes/main_menu.tscn`。
- 当前定位：可玩预发布原型；尚未接入真实广告、内购、统计或崩溃上报 SDK。
- Android 包名：`com.liacgames.cs5v5`。
- Android Release 目标输出：`build/android/CS5v5.aab`。

## 当前功能范围

- 首页：开始游戏、设置、星星总数、每日奖励、每日任务面板、首次进入自动弹出的分步骤新手教程与手动教程入口。
- 地图选择：11 张原创低模地图，前 3 张免费，其余使用星星解锁。
- 武器：RPG、M416、巴雷特。
- 角色：玩家第一人称；队友 AI 4 名；敌方 AI 5 名。
- 玩法：移动、视角、射击、切枪、生命值/护盾、死亡、观战、倒计时、剩余人数、胜负结算。
- 反馈：动态准星、命中标记、伤害数字、玩家击杀条幅、3D 击杀特效、胜利纸屑。
- 进度：星星、累计击杀/死亡、地图解锁、每日奖励、每日任务、教程完成状态（首局引导不重复弹出）。
- 设置：音量、灵敏度、画质模式、选中地图、AI 难度。
- 平台：桌面端、Android；移动端使用半透明触屏控件。

## 架构

- `scenes/main_menu.tscn`：首页。
- `scenes/settings_menu.tscn`：设置页。
- `scenes/map_select.tscn`：地图选择与星星解锁。
- `scenes/game.tscn`：比赛入口，挂载 `scripts/match_manager.gd`。
- `scenes/*_map.tscn`：11 张地图场景。
- `scenes/player.tscn`：玩家角色。
- `scenes/ai_bot.tscn`：AI 角色。
- `scenes/hud.tscn`：战斗 HUD 和结算。
- `scenes/mobile_controls.tscn`：安卓触屏控件。
- `scripts/map_registry.gd`：地图元数据唯一来源。
- `scripts/player_data.gd`：星星、地图解锁、战绩、每日奖励、每日任务、教程状态。
- `scripts/monetization_service.gd`：商业化抽象；当前为无 SDK/调试占位。
- `tests/`：Godot Headless 轻量单测。
- `scripts/release_preflight.sh`：发布前预检脚本。

## 核心规则

- 蓝队：玩家 + 4 名队友 AI。
- 橙队：5 名敌方 AI。
- 回合时长：300 秒。
- 胜负：任意一方全灭立即结束；时间到按双方存活人数比较，人数相同为平局。
- 玩家：100 HP + 30 护盾；AI：100 HP。
- 胜利 +1 星；玩家 MVP 胜利 +2 星；每日奖励 +2 星；每日任务最多 +4 星；激励广告占位 +3 星。
- 前三张地图免费；锁定地图采用温和递增成本：`factory=6`、`jungle=10`、`ruins=10`、`harbor=12`、`night_city=12`、`cave=15`、`space=15`、`volcano=18`。
- AI 交战距离按武器区分：M416 `45`、巴雷特 `85`、RPG `50`，未知武器回退 `32`。

## 武器设定

- RPG：`95` 伤害、`5.0` 爆炸半径、`2.6s` 装弹，发射慢速火箭弹，定位为高风险范围爆发。
- M416：`18` 伤害、`0.11s` 冷却，中等伤害、高射速、射线命中，暂不调整。
- 巴雷特：`105` 伤害、`1.45s` 冷却，高伤害、低射速、远距离射线命中，可一枪击杀 100 HP AI。

## 运行、测试与构建

- 电脑端：用 Godot 4.6 打开项目，按 `F5` 运行，或执行 `godot --path .`。
- 单测：`godot --headless --path . --script res://tests/test_runner.gd`。
- 发布前必须运行：`./scripts/release_preflight.sh`。
- Android Release：配置正式 keystore 后导出 `Android Release` 预设，目标 `build/android/CS5v5.aab`。
- 密钥、keystore、广告位 ID、支付私钥不得提交到仓库。

## 上线赚钱路线

1. 先完成发布护栏：文档一致、单测、发布预检、Release 配置、真机 QA。
2. 使用 `MonetizationService` 抽象承接商业化，不直接在 UI/玩法里硬编码 SDK。
3. 第一阶段变现建议：免费下载 + 激励广告得星星/翻倍奖励 + 可选去广告。
4. 接入真实 SDK 前必须补齐隐私政策、用户协议、第三方 SDK 清单和商店数据安全声明。
5. 商业化奖励必须有兜底：广告不可用时不阻塞核心玩法；奖励统一通过 `PlayerData.add_stars()` 发放。

## 发布前规则

每次发布前必须：

1. 运行 `./scripts/release_preflight.sh` 并通过。
2. 手动测试首页、教程、每日奖励、每日任务、设置、地图解锁、免费地图进入、胜利/失败/观战结算。
3. Android 真机安装并完整跑一局。
4. 检查 `RELEASE_CHECKLIST.md`。
5. 更新版本号和变更记录。

## 开源协议

- 项目采用 Apache License 2.0，协议正文维护在 `LICENSE`。

## Git 与大文件

- 仓库远程地址：`git@github.com:AltenLi/ac_fps_android_game.git`。
- 大型二进制产物与游戏媒体通过 `.gitattributes` 配置 Git LFS：`*.apk`、`*.aab`、`*.pck`、`*.zip`、常见图片/音频/模型格式等。
- `.codebuddy/`、`.godot/`、`android/` 与 `*.idsig` 为本地/生成目录或签名旁路文件，不提交到 Git。
- `godot.gdkey` 为导出加密密钥，不提交到 Git。

## Claude Code Game Studios 模板接入记录

- 模板本地路径：`/Users/altenli/Documents/works/my-game`，来源：`https://github.com/Donchitos/Claude-Code-Game-Studios`。
- 状态：已 clone 且结构完整；该模板不是 npm 项目，未发现 `package.json`，无需 `npm install`。实际“安装/启用”是使用其 `.claude/` agents、skills、hooks、rules、docs 工作流。
- 本机依赖已验证：Git `2.50.1`、Claude Code `2.1.77`、jq `1.7.1`、Python `3.12.10`、Godot `4.6.2.stable` 均可用。
- 模板内容：`49` 个 agents、`72` 个 skills、`12` 个 hooks、`11` 个 rules、`39` 个文档模板。
- Godot 相关 agents：`godot-specialist`、`godot-gdscript-specialist`、`godot-shader-specialist`、`godot-gdextension-specialist`、`godot-csharp-specialist`。当前项目使用 Godot 4.6 + GDScript，优先参考 `godot-specialist` 与 `godot-gdscript-specialist`。
- 当前项目推荐工作流：把模板作为开发方法论和检查清单使用；开发功能时参考 `/quick-design`、`/dev-story`、`/code-review`、`/smoke-check`、`/release-checklist`；做系统设计时参考 `/design-system`、`/create-architecture`、`/architecture-decision`；发布前参考 `/team-qa`、`/team-release`、`/launch-checklist`。
- 接入原则：暂不把模板 `.claude/settings.local.json` 或 hooks 直接复制进当前项目，避免路径和 Claude Code 专用 hook 与 CodeBuddy 当前工作流冲突；如后续明确要完整启用，再手动迁移 `.claude/` 并按本项目路径改写配置。
- 编码约定：GDScript 尽量使用类型标注、`class_name`、信号解耦、文件 `snake_case`、类名 `PascalCase`；玩法数值优先数据驱动，不把武器/平衡数值散落硬编码。

## 变更日志

- 2026-05-05：创建 Godot 项目计划和基础设计记录。
- 2026-05-05：实现首页、设置页、地图选择页、低模城市地图、玩家 FPS 控制、RPG/M416/巴雷特、5v5 AI、5 分钟计时、胜负结算、HUD、触屏控件和导出说明。
- 2026-05-05：新增 Apache License 2.0 开源协议文件，并在 `README.md` 中补充协议说明。
- 2026-05-05：新增 `.gitignore` 与 `.gitattributes`，准备将项目推送到 GitHub，并为大型导出/媒体文件启用 Git LFS。
- 2026-05-05：完成建模与操作优化：新增程序化士兵/枪械模型、弹匣/备弹/装弹逻辑、HUD 子弹显示和移动端右侧开火/切枪/装弹按钮。
- 2026-05-05：新增地图随机弹药掉落：每个弹药箱为每把武器补充 2 个弹匣量备弹，拾取后约 28 秒刷新；Godot Debug 下强制显示触摸控件，便于电脑端调试移动 UI。
- 2026-05-05：修复电脑 Debug 下虚拟摇杆只能前进/斜向的问题：`Control.gui_input` 的 `event.position` 已是局部坐标，不再减 `global_position`，并支持鼠标拖出摇杆底盘后继续更新。
- 2026-05-05：参考无畏契约手游等移动 FPS 控制习惯，触摸模式下非按钮区域全屏滑动移动视角，且普通触摸/鼠标左键不再直接开火，只有右侧“开火”按钮会开火。
- 2026-05-06：建立上线商业化计划、发布前单测/预检规则、商业化抽象、每日奖励和新手教程入口。
- 2026-05-07：完成首轮 CCGS 思路数值调优：巴雷特 `105/1.45s`、RPG `95/5.0/2.6s`、AI 武器化交战距离、锁定地图递增成本 `6/10/10/12/12/15/15/18`；本机已有正式 Android release keystore，密钥不入库。
- 2026-05-07：补齐首局自动弹出的分步骤新手教程，覆盖任务目标、移动瞄准、射击装弹切枪、武器定位、星星地图，并加入教程流程测试。
- 2026-05-08：新增每日任务系统，包含今日击杀 3 人、赢得 1 局、战斗获得 2 星，支持每日重置、首页展示、领奖、结算进度记录和持久化测试。
- 2026-05-09：修复 Android 战斗触控层被 HUD 全屏根节点遮挡的问题：非交互 HUD 节点统一忽略鼠标/触摸，移动端视角区只在玩家存活且比赛进行中拦截输入，恢复右屏滑动视角和右下角开火/装弹/切枪按钮。
- 2026-05-09：补充移动端触控回归测试，覆盖右屏滑动视角、开火/装弹/切枪按钮、HUD 输入穿透和结算面板拦截；修复脚本模式单测对 `MapRegistry` Autoload 编译依赖，并恢复 Android Release 预设为 AAB 发布配置。
- 2026-05-09：修复 Android 多指战斗操作：移动摇杆和开火改为独立触点追踪，右下角开火/装弹/切枪增加手动命中检测，松开摇杆不再停止开火，保证移动中可持续射击。
- 2026-05-09：根据真机 logcat 定位卡退为 Godot/OpenSL `AudioTrack` 原生崩溃；Android 默认关闭程序化循环 BGM，固定音效改为缓存复用，复用播放器前先 `stop()`，降低替换播放中音频流导致的崩溃风险，并补充音频稳定性测试。
- 2026-05-09：新增 AI 缺弹补给行为：电脑当前武器弹匣和备弹都耗尽时进入寻找弹药状态，自动前往最近弹药箱，玩家与 AI 共用弹药箱拾取/刷新逻辑。
- 2026-05-09：补齐移动端与观战体验修复：观战当前目标选择性隐藏本体/武器避免遮挡；默认关闭脚步音并限制空仓音效避免叠加蜂鸣；新增左侧居中开火键，右下角开火键左移约 1/3 直径，开火触点拖动可同时瞄准。
- 2026-05-09：修复 HUD 纸屑延迟清理空引用：`_spawn_confetti()` 不再在定时器 lambda 中直接调用循环变量 `queue_free()`，改为绑定当前粒子并通过 `_queue_free_if_valid()` 安全释放，避免首页/每日奖励滑动后报错。
- 2026-05-09：优化简单难度 AI 交战设计：区分“最大射程”和“有效交战距离”，简单 AI 看到敌人后会继续前压到更近距离，视线被遮挡时继续找角度，不再在远距离原地停住导致低命中率死局。
- 2026-05-09：重设计手机首页信息架构：首屏只保留标题、星星、开始游戏、教程/设置快捷入口和简短提示；每日奖励与每日任务收纳到右侧“每日”小按钮，点击后在弹层中领取奖励和查看任务，降低手机首页拥挤感。
- 2026-05-10：重做 AI 作战行为：比赛开始时 `MatchManager` 基于当前地图巡逻点、队伍方向和 bot 编号生成固定作战路线并注入 AI；AI 巡逻阶段按航点推进，不再随机偏航；只有近距离或有视线时才脱离路线接敌；增加卡住检测，撞障碍/原地转圈时自动推进到下一航点或回到路线。
- 2026-05-10：移动端新增跳跃键：在右下角开火键左侧增加 96px 跳跃按钮，点击调用 `PlayerController.mobile_jump()`，按 `MOBILE_JUMP_HEIGHT=0.9` 计算初速度，约跳半个角色高度。
- 2026-05-10：升级全地图表现：`BaseMap` 增加程序化纹理材质、发光材质、透明水面、圆柱、岩石/雪堆、局部灯光和主题装饰工具；11 张地图全部调用 `_add_theme_props()`，分别加入道路窗光、风沙棕榈、雪堆冰面、工厂管线、丛林树冠、遗迹断柱、海港水面、夜城霓虹、洞穴暖灯、太空能量线和火山熔岩光效。
- 2026-05-10：继续优化 AI 移动策略：AI 不再只直线冲目标，移动前会用前方/左右射线做局部避障；卡墙时进入短时左右脱困方向，连续卡住才推进航点；巡逻路线取消随机跳跃，降低撞墙、卡墙和原地转圈概率。
- 2026-05-10：按样板优先重做三张地图差异化：`BaseMap` 新增锥台/圆锥、球体、霓虹灯管等通用建模工具；夜城改成黑色道路、高楼、发光窗、全息广告牌和霓虹灯管；火山改成锥台火山体、熔岩池、烟雾、熔岩流和黑曜石岩块；丛林改成泥路、圆柱树干、球状树冠、藤蔓、茅草屋顶和自然灌木。
- 2026-05-10：修复移动端切枪按钮一次点击可能触发多次的问题：按钮与手动触点检测统一走 `_request_next_weapon()` 并加入 180ms 去抖；桌面 `Q/1/2/3/R` 忽略按键自动重复；第一人称武器切换新增旧枪下收、新枪抽出回弹的 Tween 动态动作。
- 2026-05-10：移除 Android/iOS 战斗页底部桌面 WASD 操作提示块，桌面端仍保留该提示，结算更新提示文字时增加判空保护。
- 2026-05-10：修复切枪去抖/动画实现的解析错误，补充 `_weapon_switch_tween` 与 `_last_weapon_switch_msec` 成员变量声明。
