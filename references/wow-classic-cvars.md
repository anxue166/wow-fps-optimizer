# 怀旧服（Classic）CVar 差异与调校

> **正式服的 profile 不能直接套用到怀旧服。** 怀旧服（Classic Era / 探索赛季 `_classic_titan_` / TBC / WLK）使用不同的图形引擎与不同的 CVar 集合。
> 本文件基于一台真实 `_classic_titan_` 机器的 `Config.wtf` 整理。

---

## 一、和正式服的关键差异

| 差异 | 说明 |
|---|---|
| **独立的团本配置集** | 怀旧服有一整套 `RAID*` 前缀的 CVar（如 `RAIDgraphicsShadowQuality`），**进入团本/战场时自动套用**。这意味着"野外流畅但团本卡"在怀旧服里是**配置层面就能解释的**，不只是性能问题 |
| **没有光追、没有 Compute Effects、没有 Outline Mode** | 这些是正式服才有的选项，怀旧服里不存在 |
| **抗锯齿是 MSAAQuality + ffxAntiAliasingMode 两套** | 两者可能叠加开销，1440p 下 MSAA 很贵 |
| **法术密度用 `spellClutterRangeConstant`** | 正式服叫 `graphicsSpellDensity`，怀旧服是距离常量（数值越小显示越少） |
| **贴图/阴影/SSAO 的取值范围不同** | 例如贴图 `graphicsTextureResolution` 0–3，阴影 0–5 |

---

## 二、怀旧服 CVar 对照表

### 渲染 / 同步

| CVar | 说明 | 建议 |
|---|---|---|
| `maxFPS` / `useMaxFPS` | 前台帧率上限 | **设为 显示器刷新率−3**（60Hz → 57）。远高于刷新率是纯浪费：GPU 渲染 200 帧只显示 60 帧，白烧电、白发热、帧时间还更抖 |
| `vsync` | 垂直同步 | 有自适应同步则 0，无则按决策表 |
| `GxApi` | 图形 API | `D3D12` |
| `GxMaximize` / `GxWindowedResolution` | 窗口模式 | 建议独占全屏（`GxMaximize "1"`）。窗口/无边框会引入桌面合成器开销 |
| `RenderScale` | 渲染缩放 | 保持 1 |

### 抗锯齿

| CVar | 说明 | 建议 |
|---|---|---|
| `MSAAQuality` | MSAA 倍率（0–3） | **1440p 下很贵**。团本设 0，日常 1，野外 2 |
| `ffxAntiAliasingMode` | FidelityFX 后处理 AA | 保留 1（轻量）作为 MSAA 关闭后的替代，避免画面锯齿刺眼 |

### GPU 重负载

| CVar | 说明 | 团本建议 |
|---|---|---|
| `graphicsShadowQuality` / `RAIDgraphicsShadowQuality` | 阴影质量 | 0（团本）/ 2（日常）/ 4（野外） |
| `RAIDshadowMode` / `RAIDshadowNumCascades` | 阴影模式与级联数 | 1 / 1（团本） |
| `graphicsSSAO` / `RAIDgraphicsSSAO` / `RAIDSSAO` | 环境光遮蔽 | **0**（战斗中完全看不出） |
| `graphicsLiquidDetail` / `RAIDWaterDetail` | 水体细节 | 0（团本）/ 1–2（野外） |
| `graphicsParticleDensity` / `RAIDparticleDensity` / `RAIDparticleMTDensity` | 粒子密度 | 团本 1 / 30 / 30 |
| `reflectionMode` / `RAIDreflectionMode` | 反射 | 0 |
| `rippleDetail` / `RAIDrippleDetail` | 水面涟漪 | 0 |
| `graphicsSunshafts` / `RAIDsunShafts` / `sunShafts` | 光束 | 0（团本）/ 1–2（野外） |
| `ffxGlow` / `ffxNether` / `ffxDeath` | FidelityFX 特效 | 0（免费性能） |

### CPU / 绘制调用

| CVar | 说明 | 团本建议 |
|---|---|---|
| `graphicsGroundClutter` / `RAIDgraphicsGroundClutter` | 地面杂物 | 2（团本）/ 4（日常）/ 7（野外）——**绘制调用大户** |
| `graphicsEnvironmentDetail` / `RAIDgraphicsEnvironmentDetail` | 环境细节 | 2 / 5 / 8 |
| `RAIDlodObjectFadeScale` / `RAIDlodObjectCullSize` / `RAIDlodObjectMinSize` | LOD 淡出与剔除 | 70 / 30 / 0（团本更激进剔除） |
| `groundEffectDensity` / `RAIDgroundEffectDensity` | 地面特效密度 | 32 / 64 |
| `groundEffectDist` / `RAIDgroundEffectDist` | 地面特效距离 | 80 / 160 |
| `weatherDensity` / `RAIDweatherDensity` | 天气粒子 | 1 |
| `spellClutterRangeConstant` / `spellClutterRangeConstantRaid` | 法术显示距离 | **团本 5，日常 8–10**。这是怀旧服版的 Spell Density，团本收益很大 |

### 显存 / 可读性（**不要砍**）

| CVar | 说明 | 建议 |
|---|---|---|
| `graphicsTextureResolution` / `RAIDgraphicsTextureResolution` | 贴图分辨率 0–3 | **2（High）**。RTX 4060 Ti 8GB 在 1440p 完全够。<br>默认值被低画质预设拖到 1 是常见情况，属于"白白糊画面" |
| `worldBaseMip` / `RAIDworldBaseMip` | 世界贴图 mip 偏移 | 0（不额外降档） |
| `graphicsProjectedTextures` / `RAIDprojectedTextures` / `projectedTextures` | 投影贴图 | **1，绝不动**。脚下 AOE 圈靠它 |
| `graphicsQuality` / `RAIDgraphicsQuality` | 画质预设总档 | 调低预设以免它覆盖上面的单选项 |

---

## 三、怀旧服三套配置

| | CA 画质优先 | CB 平衡 | CC Raid FPS |
|---|---|---|---|
| maxFPS | 刷新率−3 | 刷新率−3 | 刷新率−3 |
| MSAAQuality | 2 | 1 | **0** |
| Shadow (普通 / RAID) | 4 / 2 | 2 / 1 | **0 / 0** |
| SSAO | 2 | 0 | **0** |
| Ground Clutter | 7 / 4 | 4 / 3 | **2 / 2** |
| Environment Detail | 8 / 5 | 5 / 4 | **2 / 2** |
| Particle (RAID) | 80 | 60 | **30** |
| spellClutterRange Raid | 10 | 7 | **5** |
| Liquid / Sunshafts | 2 / 2 | 1 / 1 | **0 / 0** |
| Texture Resolution | 3 / 2 | 2 / 2 | **2 / 2** |
| Projected Textures | 1 | 1 | **1** |
| graphicsQuality | 8 | 5 | **2** |

### 应用命令

```powershell
# 团本
powershell -ExecutionPolicy Bypass -File "scripts/apply-profile.ps1" -WowPath "E:\游戏\World of Warcraft\_classic_titan_" -Profile CC

# 日常
powershell -ExecutionPolicy Bypass -File "scripts/apply-profile.ps1" -WowPath "E:\游戏\World of Warcraft\_classic_titan_" -Profile CB

# 野外
powershell -ExecutionPolicy Bypass -File "scripts/apply-profile.ps1" -WowPath "E:\游戏\World of Warcraft\_classic_titan_" -Profile CA
```

---

## 四、怀旧服特有的性能杀手：Questie

正式服没有对应的东西。**Questie 是怀旧服独有的大头**：

- 体积通常 200MB+（任务数据库）
- 持续在地图上渲染成百上千个任务图标
- 每次区域切换、任务状态变化都要重算

**典型症状**：野外跑图卡、进主城卡、但打木桩不卡。

**排查**：
1. 先全关插件跑基线
2. 只开 Questie 再跑一遍
3. 若确认，优化手段：
   - 关闭"显示已完成任务的图标"
   - 缩小图标显示距离
   - 关闭多余的地图图标层
   - 团本中完全禁用（用 Addon Control Panel 类插件按场景禁用）

**其他的怀旧服高开销插件**：Details、WeakAuras、DBM、NDui/ElvUI 系、HandyNotes 系列、Atlas 地图包、MeetingHorn（组队频道持续查询）、背包类插件。

---

## 五、怀旧服特有的"人多就卡"

怀旧服的 40 人团本（MC / BWL / NAXX）比正式服 20–30 人团压力大得多：

1. **`spellClutterRangeConstantRaid` 是关键** —— 40 人同时施法，法术特效是 CPU 与 GPU 的双重灾难
2. **`RAIDparticleDensity` / `RAIDparticleMTDensity`** —— 群体 AOE 时的加载峰值
3. **插件** —— 122 个插件在 40 人团本里每个都在处理 COMBAT_LOG_EVENT
4. **`RAIDlodObjectCullSize`** —— 提高剔除阈值减少远景物件

按这个顺序改，实测每一项的 1% Low 变化。
