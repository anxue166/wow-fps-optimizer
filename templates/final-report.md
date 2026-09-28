# WoW 帧数优化 — 最终报告

生成日期：
目标：提升团本最低帧、1% Low 与帧时间稳定性（**非追求最高平均 FPS**）

---

## 1. 硬件报告

| 类别 | 规格 | 备注 |
|---|---|---|
| CPU | | |
| 内存 | GB / 条 / MHz | 单通道 / 双通道，XMP 状态 |
| 显卡 | | 显存 GB |
| 驱动 | | |
| 显示器 | @ Hz | |
| 系统 | | |
| 电源计划 | | |
| 游戏模式 / HAGS | / | |

**硬件层面结论**：

---

## 2. 当前 WoW 设置（优化后）

| 设置 | 优化前 | 优化后 | 是否生效 |
|---|---|---|---|
| Render Scale | | | |
| Shadow Quality | | | |
| Ray Traced Shadows | | | |
| Liquid Detail | | | |
| SSAO | | | |
| Compute Effects | | | |
| Outline Mode | | | |
| Particle Density | | | |
| Spell Density | | | |
| View Distance | | | |
| Environment Detail | | | |
| Ground Clutter | | | |
| Texture Resolution | | | **保持不变** |
| Texture Filtering | | | **保持不变** |
| Projected Textures | | | **保持不变** |
| Triple Buffering | | | |
| V-Sync | | | |
| Max Foreground FPS | | | |
| Max Background FPS | | | |

### Windows / NVIDIA 设置

| 项目 | 优化前 | 优化后 |
|---|---|---|
| 电源计划 | | |
| 游戏模式 | | |
| HAGS | | |
| 后台录制 / 叠加层 | | |
| NVIDIA 程序级配置 | 无 | 已建（仅作用于 Wow.exe） |

---

## 3. 建议修改项与执行情况

| # | 修改项 | 建议值 | 状态 | 说明 |
|---|---|---|---|---|
| 1 | | | ✅ 已执行 / ⏭ 用户跳过 | |
| 2 | | | | |

**未采纳的建议及原因**：

---

## 4. 修改前后对比

### 场景 1：主城

| 指标 | 修改前 | 修改后 | 变化 |
|---|---|---|---|
| Avg FPS | | | |
| Min FPS | | | |
| **1% Low** | | | |
| GPU% | | | |

### 场景 2：大秘境战斗

| 指标 | 修改前 | 修改后 | 变化 |
|---|---|---|---|
| Avg FPS | | | |
| Min FPS | | | |
| **1% Low** | | | |
| GPU% | | | |

### 场景 3：团本 / 世界 Boss ★

| 指标 | 修改前 | 修改后 | 变化 |
|---|---|---|---|
| Avg FPS | | | |
| **Min FPS** | | | |
| **1% Low** | | | |
| GPU% / Temp / VRAM | | | |
| CPU 主线程% | | | |

### 结论判定

- [ ] 团本 1% Low 提升 ≥ 15%
- [ ] 最低帧不再跌破 30
- [ ] 帧时间曲线明显平直
- [ ] 主观走位 / 打断无粘滞感

**最终结论**：

---

## 5. 三套 WoW 配置

### Profile A — 画质优先（任务 / 升级 / 野外）

| 设置 | 值 |
|---|---|
| Shadow Quality | High |
| Ray Traced Shadows | 关 |
| Liquid Detail | High |
| SSAO | High |
| Compute Effects | 开 |
| Outline Mode | 高 |
| Particle Density | High |
| Spell Density | All |
| View Distance / Env Detail | 10 / 10 |
| Ground Clutter | 8–10 |
| Texture Res / Filtering / Projected | High / 16x / 开 |
| Max FPS（前/后） | 刷新率−3 / 30 |

文件：`templates/profiles/profile-a.wtf`

### Profile B — 平衡（大秘境 / 日常）

| 设置 | 值 |
|---|---|
| Shadow Quality | Medium |
| Ray Traced Shadows | 关 |
| Liquid Detail | Medium |
| SSAO | Low |
| Compute Effects | 实测 |
| Outline Mode | 低/中 |
| Particle Density | Medium |
| Spell Density | Dynamic |
| View Distance / Env Detail | 7 / 7 |
| Ground Clutter | 5–6 |
| Texture Res / Filtering / Projected | High / 16x / 开 |
| Max FPS（前/后） | 刷新率−3 / 30 |

文件：`templates/profiles/profile-b.wtf`

### Profile C — Raid FPS（团本 / 世界 Boss / 主城）

| 设置 | 值 |
|---|---|
| Shadow Quality | **Low** |
| Ray Traced Shadows | 关 |
| Liquid Detail | Low |
| SSAO | **关** |
| Compute Effects | 关/低 |
| Outline Mode | 低/关 |
| Particle Density | **Low** |
| Spell Density | **Essential** |
| View Distance / Env Detail | **5 / 5** |
| Ground Clutter | **3–4** |
| Texture Res / Filtering / Projected | High / 8x–16x / **开** |
| Max FPS（前/后） | 刷新率−3 / 30 |

文件：`templates/profiles/profile-c.wtf`

### 切换命令

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/apply-profile.ps1" -WowPath "<WoW根目录>" -Profile C
```

> **切换前必须完全退出游戏。**

---

## 6. 一键恢复方案

### 备份位置

```
{backup-path}
├── MANIFEST.txt
├── system-state.json
├── Config.wtf
└── WTF\
```

### 恢复 WoW 配置

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/restore-wow.ps1" -BackupDir "{backup-path}"
```

只回滚 Config.wtf：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/restore-wow.ps1" -BackupDir "{backup-path}" -ConfigOnly
```

### 恢复 Windows 设置

| 项目 | 恢复方式 |
|---|---|
| 电源计划 | `powercfg /setactive {原 GUID}` |
| 游戏模式 | 设置 → 游戏 → 游戏模式 |
| HAGS | 设置 → 显示 → 图形 → 默认图形设置（需重启） |
| 后台录制 / 叠加 | 各自设置页改回 |

### 恢复 NVIDIA 设置

NVIDIA 控制面板 → 管理 3D 设置 → 程序设置 → **删除 WoW 条目**，即回到全局默认。

---

## 7. 后续建议

- 每次游戏版本大更新后重新跑一轮检测（CVar 名称与默认值可能变化）
- 插件大版本更新后重跑一次插件基线
- 驱动更新后对比一次 1% Low，出现回归就回退驱动
- 定期清理过期 WeakAuras 与不再使用的插件
