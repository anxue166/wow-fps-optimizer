# 三套场景配置 Profile A / B / C

三套配置解决的是不同战斗密度下的不同矛盾。**不存在一套"全能最优"配置**——野外开 Profile C 是浪费画质，团本开 Profile A 必然掉帧。

---

## Profile A — 画质优先

**适用场景**：任务、升级、野外世界任务、单人场景、截图
**目标**：尽可能保持高画质，人物与场景密度低，GPU 与 CPU 都很空闲
**优先级**：观感 > 帧数（但仍应稳定在显示器刷新率附近）

| 设置 | 取值 | 理由 |
|---|---|---|
| Render Scale | 100% | 无瓶颈，不需要牺牲清晰度 |
| Shadow Quality | High | 野外场景阴影观感收益最高 |
| Ray Traced Shadows | 关 | 即使画质优先也不开，代价收益比太差 |
| Liquid Detail | High | 野外水域场景少，可以开高 |
| SSAO | High / Ultra | 静态场景观感提升明显 |
| Compute Effects | 开 | 低负载场景无压力 |
| Outline Mode | 高 | 无压力 |
| Particle Density | High | 单人战斗粒子量小 |
| Spell Density | All | 野外没有大量玩家施法 |
| View Distance | 10 | 野外远景是主要观感来源 |
| Environment Detail | 10 | 同上 |
| Ground Clutter | 8–10 | 野外草地茂密更好看 |
| Texture Resolution | High | 恒定 |
| Texture Filtering | 16x | 恒定 |
| Projected Textures | 开 | 恒定 |
| Triple Buffering | 关 | 无需要 |
| V-Sync | 按 G-SYNC 决策表 | 见 `wow-cvars.md` |
| Max Foreground FPS | 刷新率−3（G-SYNC）或刷新率 | 见决策表 |
| Max Background FPS | 30 | 省电降温 |

片段：`templates/profiles/profile-a.wtf`

---

## Profile B — 平衡模式

**适用场景**：大秘境、日常战斗、5 人本、战场小队
**目标**：在 5–10 人规模下保持稳定 FPS，画面仍保持较高水准
**优先级**：稳定帧数 ≈ 画面可读性

| 设置 | 取值 | 理由 |
|---|---|---|
| Render Scale | 100% | 5 人本 GPU 通常不是瓶颈 |
| Shadow Quality | Medium | 兼顾观感与性能 |
| Ray Traced Shadows | 关 | 恒定 |
| Liquid Detail | Medium | 中等即可 |
| SSAO | Low | 战斗中几乎看不出，省算力 |
| Compute Effects | 按实测 | 开着测一轮对比 1% Low |
| Outline Mode | 低 / 中 | 影响很小 |
| Particle Density | Medium | AOE 波次有压力，降一档 |
| Spell Density | Dynamic | 队友技能可见，但不全渲染 |
| View Distance | 7 | 副本内远景价值低 |
| Environment Detail | 7 | 同上 |
| Ground Clutter | 5–6 | 副本地面杂物无信息价值 |
| Texture Resolution | High | **不动** |
| Texture Filtering | 16x | **不动** |
| Projected Textures | 开 | **不动** |
| Triple Buffering | 关 | 默认 |
| V-Sync | 按 G-SYNC 决策表 | |
| Max Foreground FPS | 刷新率−3（G-SYNC） | |
| Max Background FPS | 30 | |

片段：`templates/profiles/profile-b.wtf`

---

## Profile C — Raid FPS

**适用场景**：20–30 人团本、世界 Boss、主城
**目标**：**最大化最低帧与 1% Low**，牺牲一切不影响战斗判断的观感
**优先级**：1% Low / 最低帧 >> 观感

| 设置 | 取值 | 理由 |
|---|---|---|
| Render Scale | 100%（GPU 严重瓶颈时 95%） | 先不动，先看砍完下面几项够不够 |
| Shadow Quality | **Low** | 团本阴影收益为零，开销巨大 |
| Ray Traced Shadows | **关** | 恒定 |
| Liquid Detail | Low / Medium | 团本水域少 |
| SSAO | **关** | 团本战斗中完全看不出 |
| Compute Effects | **关或低** | 团本高负载下优先省掉 |
| Outline Mode | **低或关** | 免费的性能 |
| Particle Density | **Low / Medium** | AOE 高峰期掉帧主因之一 |
| Spell Density | **Essential** | **团本单项收益最大的设置**。其他玩家的法术特效是 CPU 与 GPU 的双重灾难。降到 Essential 后自身技能与关键预警仍然显示 |
| View Distance | **5** | 团本内远景无意义 |
| Environment Detail | **5** | 同上 |
| Ground Clutter | **3–4** | 地面杂物是绘制调用大户，直接压到最低可用 |
| Texture Resolution | High | **不动**——除非实测 VRAM 见顶 |
| Texture Filtering | 8x–16x | **不动** |
| Projected Textures | **开** | **绝不动**——脚下 AOE 圈是走位命根子 |
| Triple Buffering | 关 | 默认 |
| V-Sync | 关（配合 G-SYNC） | 团本优先帧时间自由 |
| Max Foreground FPS | 刷新率−3（G-SYNC） | 锁帧换稳定，避免撞上限 |
| Max Background FPS | 30 | |

片段：`templates/profiles/profile-c.wtf`

---

## 三套配置横向对比

| 设置 | A 画质优先 | B 平衡 | C Raid FPS |
|---|---|---|---|
| Render Scale | 100% | 100% | 100%（必要时 95%） |
| Shadow Quality | High | Medium | **Low** |
| Ray Traced Shadows | 关 | 关 | 关 |
| Liquid Detail | High | Medium | Low–Medium |
| SSAO | High | Low | **关** |
| Compute Effects | 开 | 实测 | **关/低** |
| Outline Mode | 高 | 低/中 | **低/关** |
| Particle Density | High | Medium | **Low–Medium** |
| Spell Density | All | Dynamic | **Essential** |
| View Distance | 10 | 7 | **5** |
| Environment Detail | 10 | 7 | **5** |
| Ground Clutter | 8–10 | 5–6 | **3–4** |
| Texture Resolution | High | High | **High** |
| Texture Filtering | 16x | 16x | **8x–16x** |
| Projected Textures | 开 | 开 | **开** |
| Max Foreground FPS | 刷新率−3 | 刷新率−3 | 刷新率−3 |
| Max Background FPS | 30 | 30 | 30 |

**注意三套配置里完全不变的三项**：Texture Resolution、Texture Filtering、Projected Textures。这是刻意设计——它们是"战斗可读性"的底线，任何场景都不该动。

---

## 切换方式

推荐做法：把三套片段分别保存成文件，切换时用 `apply-profile.ps1` 载入，而不是每次手动改。

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/apply-profile.ps1" -WowPath "<WoW根目录>" -Profile C
```

**切换前必须完全退出游戏**，否则游戏退出时会用内存中的值覆盖文件。

---

## 团本专用补充建议（Profile C 之外）

1. **关闭友方姓名板**：通过 Plater 或系统姓名板设置，团本中关闭非目标友方姓名板，减少每帧 UI 更新。
2. **Details! 降到轻量模式**：团本中把 Details 的窗口数减到 1，关闭不必要的插件皮肤与动画。见 `addon-performance.md`。
3. **WeakAuras 分组禁用**：把只在特定 Boss 用的 WA 分组设置"仅战斗中加载"或按专精/场景禁用。
4. **战前清理后台**：浏览器、视频、直播软件全部关掉。
