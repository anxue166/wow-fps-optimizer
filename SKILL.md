---
name: wow-fps-optimizer
description: 用于优化《魔兽世界》(World of Warcraft) 在 Windows + NVIDIA 平台上的帧数、1% Low 与帧时间稳定性。严格遵循"先检测后修改、先备份后落盘、逐项确认"流程，覆盖硬件与系统检测、WoW 图形 CVar 调校、RTX 4060 Ti 专项取舍、三套场景配置（野外/大秘境/团本）、插件性能排查、Windows 安全优化、NVIDIA 程序级配置、基准测试与瓶颈判定。当用户提到 WoW 掉帧、卡顿、帧数低、1% Low、团本卡、显卡 4060 Ti、插件掉帧、Config.wtf、WeakAuras 性能时使用。
---

# WoW FPS Optimizer

优化《魔兽世界》帧率的可逆化工作流。核心目标排序：

**1% Low / 最低帧 / 帧时间稳定性 > 平均 FPS**

平均帧数好看但团本一开怪就掉到 30 帧，等于没优化。

---

## 铁律（任何情况下都不得违反）

1. **先检测，后修改。** Phase 1 只允许读取，产出报告后停住，等用户确认再进入下一步。
2. **先备份，后落盘。** 任何涉及 WTF / Config.wtf / 系统设置 / 驱动的修改前，必须先生成备份并记录原始值快照。
3. **逐项确认。** 每个修改批次都要给出"改什么 / 为什么 / 预期 FPS 收益 / 画质代价"，用户勾选后才执行。禁止批量静默修改。
4. **全程可逆。** 每次执行都写变更日志，配套一键恢复命令。
5. **禁止危险优化。** 见 `references/windows-tuning.md` 的黑名单——不删服务、不关 Defender、不改未知注册表、不碰 HPET/BCD。
6. **NVIDIA 只建程序级配置**，不动全局默认；不把每一项无脑拉到"最高性能"。
7. **不迷信平均 FPS。** 判定成败看 1% Low 与最低帧。

---

## 工作流总览

```
Phase 0 采集需求   → 版本 / 分辨率 / 刷新率 / 痛点场景
Phase 1 只读检测   → detect-hardware.ps1，输出报告，STOP
Phase 2 备份       → backup-wow.ps1 + 原始状态快照
Phase 3 变更计划   → 六列表格，等用户确认，STOP
Phase 4 执行       → 只执行勾选项，写变更日志
Phase 5 基准测试   → 主城 / 大秘境 / 团本 三场景
Phase 6 瓶颈判定   → 按 GPU 占用分流，最多迭代 3 轮
Phase 7 交付       → 报告 + 三套配置 + 一键恢复
```

---

## Phase 0 — 采集需求

开工前先问清（用户已提供则可跳过）：

| 项目 | 为什么需要 |
|---|---|
| 正式服 / 怀旧服 / 硬核 | CVar 集合与图形选项差异很大 |
| 显示器分辨率 + 刷新率 | 决定 Max FPS、Render Scale 与 G-SYNC 策略 |
| 是否支持 G-SYNC / FreeSync | 决定 V-Sync 与帧率上限的组合方式 |
| 主要痛点场景 | 野外 / 大秘境 / 团本 / 主城，直接决定先出哪套 Profile |
| 是否愿意改 Windows / NVIDIA | 决定建议范围 |

---

## Phase 1 — 只读检测（不改任何东西）

```powershell
powershell -ExecutionPolicy Bypass -File "<skill>/scripts/detect-hardware.ps1" -Json
```

不带 `-Json` 则输出人类可读报告。脚本采集：

**硬件**：CPU 型号 / 核心线程、内存容量与频率（含是否跑在 XMP/EXPO 标称频率）、GPU 型号与显存、显示器当前刷新率与分辨率、系统盘类型。
**Windows**：电源计划（GUID + 名称）、游戏模式、HAGS（硬件加速 GPU 调度）、Xbox Game Bar 后台录制、活动电源方案是否"卓越性能/高性能"。
**NVIDIA**：驱动版本、驱动日期、已启用的 G-SYNC 状态、是否存在 WoW 程序级配置。
**WoW**：安装路径（注册表 + 常见目录 + Battle.net 配置）、`Config.wtf` 位置、当前图形相关 CVar、插件目录规模。

按 `templates/detection-report.md` 输出，异常项标 ⚠️。

> 检测命令的手工版本与失败兜底方案见 `references/hardware-detection.md`。

---

## Phase 2 — 备份与状态快照

```powershell
powershell -ExecutionPolicy Bypass -File "<skill>/scripts/backup-wow.ps1" -WowPath "<WoW根目录>"
```

生成 `<WoW>/WTF/../_WoW-FPS-Backup/<时间戳>/`，包含：

- `WTF/` — 完整目录树（含 `Config.wtf`、账号配置、插件配置）
- `Config.wtf` — 单独再存一份便于快速回滚
- `system-state.json` — Windows / NVIDIA 原始值快照
- `MANIFEST.txt` — 备份清单与恢复命令

**修改 Windows 或 NVIDIA 前**，先把当前值写进 `system-state.json`（脚本自动完成），保证能精确还原而不是"凭记忆改回去"。

---

## Phase 3 — 变更计划（必须等确认）

用 `templates/change-plan.md` 输出六列表格：

| 修改项 | 当前值 | 建议值 | 为什么改 | 预期 FPS 收益 | 画质代价 |
|---|---|---|---|---|---|

每一项必须说清它吃掉的是 **GPU 算力** / **CPU 主线程** / **显存** 中的哪一项，以及在本机（RTX 4060 Ti）上是否值得动。

然后明确写：**以上 N 项，请勾选要执行的部分，确认后我再改。**

---

## Phase 4 — 执行

```powershell
powershell -ExecutionPolicy Bypass -File "<skill>/scripts/apply-profile.ps1" -WowPath "<WoW根目录>" -Profile C
```

`apply-profile.ps1` 会：
1. 再次校验备份存在（没有就拒绝执行）
2. 读取实际 `Config.wtf`
3. **只改文件中已存在的键**，未在文件中出现的键以追加块写入并标注
4. 输出变更 diff 并写 `change-log.txt`

> 支持的 Profile：`A` 画质优先 / `B` 平衡 / `C` Raid FPS。取值表见 `references/profiles-abc.md` 与 `templates/profiles/*.wtf`。

---

## Phase 5 — 基准测试

每次调整后必须测这三个场景，缺一不可：

| 场景 | 时长 | 关注点 |
|---|---|---|
| 主城（奥格/暴风或瓦德拉肯） | 2–3 分钟站桩 + 飞行一圈 | 玩家密度与加载压力 |
| 大秘境战斗 | 完整一波 AOE + Boss | 粒子与法术密度峰值 |
| 团本 / 世界 Boss | 一次完整开怪 | **最关键**：1% Low 与最低帧 |

记录字段：`Average FPS / Minimum FPS / 1% Low / GPU Usage% / GPU Temp / GPU VRAM used / CPU 主线程占用`。

推荐工具：MSI Afterburner + RivaTuner（记录 1% Low 与帧时间曲线）、WoW 内置 `/frametimes`、CapFrameX。记录表模板见 `templates/benchmark-log.md`。

---

## Phase 6 — 瓶颈判定

| 观测现象 | 判定 | 下一步 |
|---|---|---|
| GPU 长时间 95–100% | **GPU 瓶颈** | 降 Render Scale、阴影、SSAO、粒子、远景；或限制 Max FPS 换稳定 |
| GPU 只有 50–70% 但 FPS 很低 | **CPU / 主线程 / 插件瓶颈** | 查插件、Spell Density、WoW 主线程占用、内存频率、后台程序 |
| 野外高帧但团本暴跌 | **CPU 侧 + 插件** | 优先 Spell Density、Particle、插件与 WeakAuras，而非继续砍画质 |
| 帧数不低但明显卡顿 | **帧时间抖动** | 查加载、插件 OnUpdate 尖峰、显存溢出、后台录制 |
| GPU 显存接近上限 | **显存瓶颈** | 降 Texture Resolution、关闭多余后台程序与浏览器硬件加速 |

判定细节与阈值见 `references/benchmark-bottleneck.md`。每轮只改一组变量，最多迭代 3 轮。

---

## Phase 7 — 最终交付

按 `templates/final-report.md` 输出：

1. 当前硬件报告
2. 当前 WoW 设置（与检测时对比）
3. 建议修改项及执行情况
4. **修改前后对比**（三场景 Average / Min / 1% Low）
5. 三套 WoW 配置（Profile A / B / C 完整 CVar）
6. 一键恢复方案（备份路径 + 恢复命令）

---

## 参考文件

| 文件 | 用途 |
|---|---|
| `references/hardware-detection.md` | 检测命令手册与手工兜底 |
| `references/wow-cvars.md` | 全部图形 CVar：影响、推荐值、代价 |
| `references/rtx-4060ti-tuning.md` | RTX 4060 Ti 专项取舍 |
| `references/profiles-abc.md` | 三套配置完整取值与理由 |
| `references/addon-performance.md` | 插件掉帧排查流程（WeakAuras / Details / ElvUI / Plater / DBM） |
| `references/nvidia-profile.md` | NVIDIA 程序级配置逐项理由 |
| `references/windows-tuning.md` | Windows 安全优化白名单 + 危险黑名单 |
| `references/benchmark-bottleneck.md` | 测试方法与瓶颈判定阈值 |
| `references/backup-restore.md` | 备份结构与一键恢复 |
| `templates/detection-report.md` | 检测报告模板 |
| `templates/change-plan.md` | 变更确认表模板 |
| `templates/benchmark-log.md` | 基准测试记录表 |
| `templates/final-report.md` | 最终交付报告模板 |
| `templates/profiles/profile-a.wtf` | 画质优先片段 |
| `templates/profiles/profile-b.wtf` | 平衡模式片段 |
| `templates/profiles/profile-c.wtf` | Raid FPS 片段 |
| `scripts/detect-hardware.ps1` | 只读检测 |
| `scripts/backup-wow.ps1` | 备份 WTF / Config.wtf / 系统状态 |
| `scripts/apply-profile.ps1` | 应用配置（需备份存在） |
| `scripts/restore-wow.ps1` | 一键恢复 |
| `scripts/scan-addons.ps1` | 插件规模与风险扫描 |

---

## 已知限制与诚实声明

- WoW 的图形 CVar 名称在不同版本间会有微调。脚本采用"**已存在的键改值、不存在则追加**"策略，报告中标出未匹配项，由用户确认后手动处理。
- 图形设置可能同时存在于 `WTF/Config.wtf`、`WTF/Account/<账号>/Config.wtf` 与账号级 `layout` 缓存中。脚本优先处理全局 `WTF/Config.wtf`，账号级差异由用户确认。
- 本 skill 无法代替实测。任何建议都必须经 Phase 5 三个场景验证后再下结论。
