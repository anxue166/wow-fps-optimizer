# 硬件与系统检测手册

所有命令均为**只读**。首选直接运行 `scripts/detect-hardware.ps1`；下面列出手工命令，用于脚本失败或需要复核单项时兜底。

---

## 1. CPU 型号与规格

```powershell
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, BaseClockSpeed
```

关注点：
- WoW 是**重度单线程依赖**的游戏，单核性能 > 核心数量。
- 若 `NumberOfLogicalProcessors` ≥ 8 但主频偏低，团本场景仍可能主线程吃满。
- 记录是否开启 SMT / 超线程（BIOS 层，一般保持开启）。

补充：`Get-ComputerInfo | Select CsProcessors` 或任务管理器"性能→CPU→内核/逻辑处理器"。

---

## 2. 内存容量与频率（关键，常被忽略）

```powershell
# 容量与数量
Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity, Speed, Manufacturer, PartNumber, ConfiguredClockSpeed

# 总容量（GB）
[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)

# 是否双通道
Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
```

判定规则：
- `Speed`（标称 JEDEC 频率）与 `ConfiguredClockSpeed`（实际运行频率）不一致是**正常且常见**的——XMP/EXPO 超频后 `Speed` 仍显示基础值。
- **真正的判断方法**：进 BIOS 看是否启用 XMP/EXPO；或用 CPU-Z 的 Memory 选项卡看 **DRAM Frequency**（DDR 需 ×2 才是有效频率）。
- DDR4-3200 以下或 DDR5-4800 以下跑团本，会明显拖低 1% Low。
- **单通道内存是重大缺陷**：插 1 条 16GB 远差于 2 条 8GB。检测时若只有一根内存条，必须标 ⚠️。

---

## 3. GPU 型号与显存

```powershell
Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion, DriverDate, VideoModeDescription, CurrentRefreshRate
# 更准确的显存（GB）
$nv = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like '*NVIDIA*' }
[math]::Round($nv.AdapterRAM / 1GB, 0)
```

注意：`AdapterRAM` 在部分系统上溢出/不准（显示 4GB 但实际 8GB）。兜底：

```powershell
& "C:\Windows\System32\nvidia-smi.exe" --query-gpu=name,memory.total,driver_version --format=csv
```

（nvidia-smi 通常位于 `C:\Windows\System32\nvidia-smi.exe`，随驱动安装。）

---

## 4. 显示器刷新率与分辨率

```powershell
# 当前桌面分辨率
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::PrimaryScreen.Bounds

# 用 WMI 取刷新率（部分系统返回空，需兜底）
Get-CimInstance Win32_VideoController | Select-Object CurrentRefreshRate, VideoModeDescription

# 所有显示器（含刷新率）
Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams | Select-Object VideoInputType
```

**最可靠的刷新率确认方式**：Windows 设置 → 系统 → 屏幕 → 高级显示 → 选择刷新率。

> 很多机器出厂默认 60Hz，插了 144Hz 显示器却没改，这是"优化半天没效果"的头号原因。**检测报告必须重点标出。**

---

## 5. Windows 电源模式

```powershell
# 当前活动电源计划
powercfg /getactivescheme

# 全部计划
powercfg /list
```

判定：
- GUID `8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c` = 高性能
- GUID `e9a42b02-d5df-448d-aa00-03f14749eb61` = 卓越性能（Win10 1803+ 可用）
- GUID `381b4222-f694-41f0-9685-ff5bb260df2e` = 平衡（默认）

⚠️ 若活动计划是"平衡"或"节能"，CPU 会降频，团本 1% Low 直接打折。建议改为"高性能"或"卓越性能"（可逆）。

开启卓越性能（需用户确认）：
```powershell
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
```

---

## 6. 游戏模式与 HAGS

```powershell
# 游戏模式（Game Mode）
Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue
Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "GameMode" -ErrorAction SilentlyContinue

# 硬件加速 GPU 调度（HAGS）
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue
```

`HwSchMode` 取值：
- `2` = 开启（Win10 2004+ 默认）
- `1` = 关闭

说明：HAGS 对 WoW 影响**因机器而异**，没有普适结论。正确做法是开着测一轮、关着测一轮，看 1% Low 哪个更好。**不要预设"必须开"或"必须关"。**

界面路径：设置 → 系统 → 显示 → 图形 → 默认图形设置 / 硬件加速 GPU 调度。

---

## 7. NVIDIA 驱动版本

```powershell
& "C:\Windows\System32\nvidia-smi.exe" --query-gpu=driver_version --format=csv
Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like '*NVIDIA*' } | Select-Object DriverVersion, DriverDate
```

建议：
- 保持 **Game Ready Driver** 较新版本，但不要盲目追最新（新驱动偶有帧时间回归）。
- 若当前驱动超过 6 个月未更新，列为建议项。
- 若用户反馈"更新驱动后开始卡"，建议用 DDU 干净重装（**提前说明这是重操作，需用户确认**）。

---

## 8. World of Warcraft 安装路径

```powershell
# 方法 1：注册表（Battle.net 卸载项）
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
              "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
  Get-ItemProperty | Where-Object { $_.DisplayName -like '*World of Warcraft*' } |
  Select-Object DisplayName, InstallLocation

# 方法 2：Battle.net 配置文件
Get-Content "$env:APPDATA\Battle.net\Battle.net.config" -ErrorAction SilentlyContinue |
  Select-String -Pattern 'World of Warcraft'

# 方法 3：常见安装目录兜底
@("C:\Program Files\World of Warcraft", "C:\Program Files (x86)\World of Warcraft",
  "D:\World of Warcraft", "D:\Games\World of Warcraft", "E:\World of Warcraft",
  "D:\Battle.net\World of Warcraft") | Where-Object { Test-Path $_ }
```

**关键：区分版本目录**

| 版本 | 目录 | 配置位置 |
|---|---|---|
| 正式服 Retail | `...\_retail_\` | `<WoW>\_retail_\WTF\` |
| 经典怀旧服 | `...\_classic_\` 或 `_classic_era_` | `<WoW>\_classic_\WTF\` |
| 硬核 / 赛季服 | `_classic_era_` 等 | 对应子目录的 `WTF\` |

**必须确认用户玩的是哪个版本**，配置目录完全不同。

---

## 9. Config.wtf 读取

```powershell
$wtf = "<WoW根目录>\_retail_\WTF\Config.wtf"
Get-Content $wtf | Where-Object { $_ -match '^(SET )?(gx|graphics|maxFPS|renderScale|raidGraphics|shadow|particle|liquid|SSAO|compute|outline|spell|view|env|ground|texture|projected|ray)' }
```

典型位置：
- `<WoW>\_retail_\WTF\Config.wtf` — 显示与图形主配置
- `<WoW>\_retail_\WTF\Account\<账号名>\Config.wtf` — 账号级覆盖
- `<WoW>\_retail_\WTF\Account\<账号名>\<服务器>\<角色>\Config.wtf` — 角色级覆盖

**优先级：角色级 > 账号级 > 全局。** 脚本默认处理全局；若存在账号级覆盖，报告中必须提示，因为它会盖掉全局设置。

---

## 10. 后台高占用程序

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, CPU, WorkingSet64, Id
```

重点排查：浏览器（Chrome/Edge 开着硬件加速 + 几十个标签）、Steam、Discord、杀毒全盘扫描、OneDrive 同步、Windows Update 后台下载（会偷偷吃 CPU 和磁盘）。

---

## 11. 检测报告必标 ⚠️ 的异常项

| 异常 | 影响 |
|---|---|
| 显示器刷新率 ≤ 60Hz（但硬件支持更高） | 帧数上限被锁死 |
| 单通道内存 | 1% Low 大幅下降 |
| 内存未开 XMP/EXPO | CPU 侧吞吐不足 |
| 电源计划为"平衡/节能" | CPU 降频 |
| 驱动超过 6 个月未更新 | 兼容性与性能回归 |
| WoW 装在机械硬盘 | 加载卡顿与贴图弹出 |
| 分辨率远超显示器原生（如 4K 显示器跑 1080p 全屏拉伸） | 无谓 GPU 开销或画面糊 |
