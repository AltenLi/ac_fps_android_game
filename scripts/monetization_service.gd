extends Node

signal reward_granted(reason: String, stars: int)
signal reward_failed(reason: String)

## 商业化抽象层：当前不接入真实 SDK。
## Debug/编辑器下允许占位奖励，Release 未接 SDK 时返回不可用。
var debug_rewards_enabled := false
var sdk_rewarded_available := false

func _ready() -> void:
	debug_rewards_enabled = OS.is_debug_build()

func is_rewarded_ad_available() -> bool:
	return debug_rewards_enabled or sdk_rewarded_available

func request_rewarded_stars(reason: String, amount: int) -> bool:
	if amount <= 0:
		reward_failed.emit("invalid_amount")
		return false
	if not is_rewarded_ad_available():
		reward_failed.emit("rewarded_ad_unavailable")
		return false
	PlayerData.add_stars(amount)
	reward_granted.emit(reason, amount)
	return true

func has_removed_ads() -> bool:
	return PlayerData.has_removed_ads()

func set_ads_removed(value: bool) -> void:
	PlayerData.set_ads_removed(value)
