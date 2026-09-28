# WoW FPS Optimizer

用于优化《魔兽世界》(World of Warcraft) 在 Windows + NVIDIA 平台上的**帧数、1% Low 与帧时间稳定性**的 Skill。

针对 RTX 4060 Ti / 类似定位显卡做过专项取舍，但流程和脚本对任何 Windows + NVIDIA 组合都适用。

## 核心目标

**1% Low / 最低帧 / 帧时间稳定性 > 平均 FPS**

平均帧数好看但团本一开怪就掉到 30 帧，等于没优化。

## 铁律

1. **先检测，后修改** — 检测阶段只允许读取
2. **先备份，后落盘** — 无备份拒绝执行
3. **逐项确认** — 每次修改前说明"改什么 / 为什么 / 预期收益 / 画质代价"
4. **全程可逆** — 变更日志 + 一键恢复
5. **不碰危险优化** — 不删服务、不关 Defender、不改未知注册表、不禁用 Windows Update、不碰 HPET/BCD
6. **NVIDIA 只建程序级配置**，不动全局默认

## 工作流

```
Phase 0 采集需求   → 版本 / 分辨率 / 刷新率 / 痛点场景
Phase 1 只读检测   → detect-hardware.ps1，输出报告，STOP
Phase 2 备份       → backup-wow.ps1 + 状态快照
Phase 3 变更计划   → 六列表格，等用户确认，STOP
Phase 4 执行       → apply-profile.ps1
Phase 5 基准测试   → 主城 / 大秘境 / 团本
Phase 6 瓶颈判定   → 按 GPU 占用分流，最多 3 轮
Phase 7 交付       → 报告 + 三套配置 + 一键恢复
```

## 快速开始

```powershell
# 1) 只读检测（不修改任何内容）
powershell -ExecutionPolicy Bypass -File .\scripts\detect-hardware.ps1

# 2) 备份 WTF / Config.wtf / 系统状态
powershell -ExecutionPolicy Bypass -File .\scripts\backup-wow.ps1 -WowPath "D:\World of Warcraft"

# 3) 应用配置（A 画质 / B 平衡 / C 团本）— 需先备份且游戏已关闭
powershell -ExecutionPolicy Bypass -File .\scripts\apply-profile.ps1 -WowPath "D:\World of Warcraft\_retail_" -Profile C

# 4) 一键恢复
powershell -ExecutionPolicy Bypass -File .\scripts\restore-wow.ps1 -BackupDir "D:\World of Warcraft\_WoW-FPS-Backup\<时间戳>"

# 附：插件扫描
powershell -ExecutionPolicy Bypass -File .\scripts\scan-addons.ps1 -WowPath "D:\World of Warcraft\_retail_"
```

## 正式服 / 怀旧服

**两套 CVar 完全不同，不能混用。** 怀旧服另有一整套 `RAID*` 前缀的团本配置（进团本自动套用），优化团本必须同时改基础键和 `RAID*` 孪生键。

| Profile | 版本 | 场景 |
|---|---|---|
| `A` / `B` / `C` | 正式服 Retail | 画质优先 / 平衡 / Raid FPS |
| `CA` / `CB` / `CC` | 怀旧服 Classic | 画质优先 / 平衡 / Raid FPS |

```powershell
# 怀旧服团本配置
powershell -ExecutionPolicy Bypass -File .\scripts\apply-profile.ps1 -WowPath "E:\游戏\World of Warcraft\_classic_titan_" -Profile CC
```

怀旧服专属内容见 `references/wow-classic-cvars.md`（含 Questie 等怀旧服独有性能杀手）。

## 三套场景配置（正式服）

| | Profile A 画质优先 | Profile B 平衡 | Profile C Raid FPS |
|---|---|---|---|
| 场景 | 任务 / 升级 / 野外 | 大秘境 / 日常 | 团本 / 世界 Boss / 主城 |
| 优先级 | 观感 > 帧数 | 稳定 ≈ 可读性 | **最低帧 / 1% Low >> 观感** |
| Shadow Quality | High | Medium | **Low** |
| Ray Traced Shadows | 关 | 关 | 关 |
| SSAO | High | Low | **关** |
| Particle Density | High | Medium | **Low** |
| Spell Density | All | Dynamic | **Essential** |
| View Distance / Env Detail | 10 / 10 | 7 / 7 | **5 / 5** |
| Ground Clutter | 8–10 | 5–6 | **3–4** |
| Texture Resolution | High | High | **High（不动）** |
| Texture Filtering | 16x | 16x | **8x–16x（不动）** |
| Projected Textures | 开 | 开 | **开（绝不动）** |

模板：`templates/profiles/profile-{a,b,c}.wtf`

> 三套配置里**完全不变的三项**：贴图分辨率、各向异性过滤、投影贴图。
> 它们是"战斗可读性"的底线——投影贴图决定了脚下 AOE 圈能不能看清。

## RTX 4060 Ti 取舍原则

**优先砍**：阴影、光线追踪阴影、SSAO、粒子、远景、环境细节、地面杂物
**死守不动**：贴图分辨率 High、各向异性 8x/16x、投影贴图开启

> 这张卡跑 WoW，瓶颈经常在 **CPU 主线程和插件**，不在显卡本身。
> 团本掉帧十有八九要靠 Spell Density + 插件排查解决，继续砍画质没用。

## 目录结构

```
wow-fps-optimizer/
├── SKILL.md                     主工作流
├── references/
│   ├── hardware-detection.md    检测命令手册与兜底方案
│   ├── wow-cvars.md             全部图形 CVar：影响 / 推荐值 / 代价
│   ├── rtx-4060ti-tuning.md     RTX 4060 Ti 专项取舍
│   ├── profiles-abc.md          三套配置完整取值与理由
│   ├── addon-performance.md     插件二分排查（WA / Details / ElvUI / Plater / DBM）
│   ├── nvidia-profile.md        NVIDIA 程序级配置逐项理由
│   ├── windows-tuning.md        安全白名单 + 危险黑名单
│   ├── benchmark-bottleneck.md  测试方法与瓶颈判定阈值
│   └── backup-restore.md        备份结构与一键恢复
├── scripts/                     5 个 PowerShell 脚本（只读检测 / 备份 / 应用 / 恢复 / 插件扫描）
└── templates/
    ├── detection-report.md      检测报告
    ├── change-plan.md           变更确认表
    ├── benchmark-log.md         基准测试记录
    ├── final-report.md          最终交付报告
    └── profiles/                profile-a/b/c.wtf
```

## 安装到 WorkBuddy

放到用户级技能目录即可：

```
~/.workbuddy/skills/wow-fps-optimizer/
```

## 已知限制

- WoW 图形 CVar 名称在不同版本间会有微调。脚本采用"**已存在的键改值、不存在则追加**"策略，并在报告中标注未匹配项。
- 图形设置可能存在账号级 / 角色级 `Config.wtf` 覆盖，会盖掉全局设置，需人工确认。
- 本 skill 无法代替实测。任何建议都必须经三个场景验证后再下结论。
