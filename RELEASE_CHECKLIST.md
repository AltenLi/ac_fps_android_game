# CS 5v5 Release Checklist

每次发布前必须完成本清单。未通过自动化预检或真机测试时不得发布。

## 1. 自动化

- [ ] 运行 `./scripts/release_preflight.sh` 并通过。
- [ ] 确认版本号已递增：Android `version/code`、`version/name`。
- [ ] 确认 `agent.md`、`README.md`、`PLAN.md` 与实际功能一致。

## 2. 手动 QA

- [ ] 首页：首次安装/重置存档会自动弹出分步骤教程，开始游戏、设置、手动教程、每日奖励、每日任务均可用。
- [ ] 地图：免费地图可进，锁定地图可解锁，星星不足提示正确。
- [ ] 战斗：移动、瞄准、射击、装弹、切枪、弹药箱、RPG 爆炸正常。
- [ ] AI：三档难度可选，AI 会巡逻、追击、射击、死亡。
- [ ] 结算：胜利、失败、平局、MVP 星星、每日任务进度、观战、下一局、返回首页正常。
- [ ] Android：触屏移动、滑动视角、开火、装弹、切枪按钮正常。
- [ ] 性能：低端机 5 分钟一局不崩溃，帧率基本稳定。

## 3. Android 发布

- [ ] 使用 `Android Release` 预设导出 `build/android/CS5v5.aab`。
- [ ] 使用正式 release keystore 签名；keystore 不提交仓库。
- [ ] `package/show_as_launcher_app=true`。
- [ ] `user_data_backup/allow=false`，避免本地软货币被系统备份造成权益不一致。
- [ ] 未接入广告/内购/统计 SDK 前保持 `permissions/internet=false`。
- [ ] 接入真实 SDK 后同步更新隐私政策、SDK 清单和数据安全声明。

## 4. 商店素材

- [ ] 应用图标。
- [ ] 至少 5 张横屏截图。
- [ ] 15-30 秒宣传视频。
- [ ] 短描述、长描述、关键词。
- [ ] 年龄分级材料。
- [ ] 隐私政策 URL 和用户协议 URL。

## 5. 商业化

- [ ] 广告位 ID / IAP 商品 ID 使用安全配置，不硬编码私钥。
- [ ] 激励广告失败不阻塞核心玩法。
- [ ] 奖励统一通过 `PlayerData.add_stars()` 或服务端权益发放。
- [ ] 付费权益上线前需要服务端校验或平台收据校验；当前本地星星不适合作为真实付费权益。
