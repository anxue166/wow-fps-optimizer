# NVIDIA 控制面板：WoW 程序级配置

> **铁律：只为 World of Warcraft 建立程序级配置，绝不修改全局默认配置。**
> 全局配置会影响所有程序，出问题难以定位。程序级配置随时可删，风险可控。

---

## 一、如何建立程序级配置

1. 打开 **NVIDIA 控制面板** → 左侧 **管理 3D 设置**
2. 切到 **程序设置** 选项卡
3. 点 **添加** → 选择 WoW 可执行文件：
   - 正式服：`<WoW>\_retail_\Wow.exe`
   - 经典怀旧服：`<WoW>\_classic_\Wow.exe`
   - 若列表里没有，点 **浏览** 手动定位
4. 按下表逐项设置 → **应用**

> 如果 WoW 重装或换版本目录，需要重新添加一次。

---

## 二、逐项推荐与理由

**不要把所有项无脑拉到"最高性能"。** 下面每一项都给出了为什么这么设、代价是什么。

### Power Management Mode（电源管理模式）

| | |
|---|---|
| **推荐** | **Prefer maximum performance（优先最大性能）** |
| **为什么** | WoW 的负载波动极大——野外几乎空闲、团本开怪瞬间满载。默认的 "Optimal power" 会根据负载动态降频，**在负载突变时来不及升频，直接表现为团本开怪那一下的帧数断崖和卡顿**。锁定最高性能可以让 GPU 时钟保持稳定。 |
| **代价** | 待机/低负载时 GPU 不降频，功耗和温度略高、风扇可能更响。 |
| **为什么不是"最高性能"就行** | 对 WoW 这种负载突变型游戏，稳定性比峰值功耗重要。若机器散热差、噪音敏感，可退到 "Normal" 并配合 Max Frame Rate 锁帧。 |

### Preferred Refresh Rate（首选刷新率）

| | |
|---|---|
| **推荐** | **Highest available（可用最高）** |
| **为什么** | 确保游戏能拿到显示器标称刷新率。设为 "Application-controlled" 时，某些程序会取 60Hz 默认值，直接浪费高刷显示器。 |
| **代价** | 基本无。唯一副作用是桌面/游戏中刷新率切换时的短暂黑屏。 |

### Low Latency Mode（低延迟模式）

| | |
|---|---|
| **推荐** | **On（开启）**（团本/大秘境）；追求极限帧数可设 Off 或 Ultra 实测对比 |
| **为什么** | 限制渲染队列深度，让 CPU 提交帧更贴近 GPU 渲染，减少输入延迟。对团本走位和打断反应有实际帮助。<br>**Ultra** 会进一步限制并动态降频，可能损失少量帧数——**不要直接上 Ultra，先 On 测一轮**。 |
| **代价** | 极高帧数下峰值 FPS 可能略降，但帧时间更稳。 |
| **注意** | 与游戏内 Reduce Input Lag 功能作用类似，**不要两个都开到极致**，可能相互干扰。 |

### Max Frame Rate（最大帧率）

| | |
|---|---|
| **推荐** | **设为 显示器刷新率 − 3**（如 144Hz → 141，165Hz → 162，60Hz → 57 或不设） |
| **为什么** | 这是**稳定性最优解**：<br>1. 配合 G-SYNC 时，帧率必须低于刷新率上限才能留在可变刷新区间内，一旦撞到上限就会触发 V-Sync 介入，延迟骤增。<br>2. 锁帧能显著降低 GPU 负载、温度与功耗，帧时间曲线更平直，1% Low 更好看。<br>3. 超过刷新率的帧数根本没有画面收益，只是白烧电。 |
| **代价** | 峰值 FPS 数字变小（但你不看平均 FPS，你看 1% Low）。 |
| **例外** | 竞技向玩家追求极限响应可不锁或锁更高，需自行权衡。 |

### V-Sync（垂直同步）

| | |
|---|---|
| **推荐** | **G-SYNC 显示器：关（由 G-SYNC 接管）**；非 G-SYNC：见 `wow-cvars.md` 决策表 |
| **为什么** | 开启 G-SYNC 时，面板里的 V-Sync 通常设为 **On** 配合 G-SYNC 工作（NVIDIA 官方组合是 G-SYNC + V-Sync On + 帧率上限低于刷新率）。<br>但 WoW 这类 CPU 密集型游戏，很多玩家反馈 V-Sync Off + Max Frame Rate 锁帧的手感更好。**正确做法是两种都测一轮 1% Low 与帧时间曲线，再定。** |
| **代价** | 开：延迟增加但无撕裂；关：可能撕裂但延迟低。 |

### G-SYNC

| | |
|---|---|
| **推荐** | **若显示器支持：Enable（全屏 + 窗口模式都勾上）** |
| **为什么** | 消除撕裂的同时不引入传统 V-Sync 的延迟惩罚，是改善"流畅感"最有效的单项设置。对帧数波动大的团本场景尤其明显。 |
| **代价** | 需要显示器硬件支持（NVIDIA 认证 G-SYNC 或兼容 G-SYNC Compatible 的 FreeSync 显示器）。部分低价 FreeSync 显示器在低帧时可能出现闪烁（LFC 覆盖不足）。 |
| **注意** | 启用 G-SYNC 后**务必同时设置 Max Frame Rate = 刷新率−3**，否则帧率撞顶会失效。 |

### Texture filtering - Quality（纹理过滤质量）

| | |
|---|---|
| **推荐** | **High Performance（高性能）** 或 **Quality** |
| **为什么** | 现代 NVIDIA 卡上各向异性过滤的开销很低。"High Performance" 会做轻微优化，肉眼几乎不可辨，但能省一点带宽。<br>**不要设成 "High Quality"** ——它加了额外的三线性优化，WoW 里看不出差别。 |
| **代价** | High Performance 下极高斜视角的地面可能略糊，实际几乎看不出。 |

### Texture filtering - Anisotropic sample optimization / Trilinear optimization

| | |
|---|---|
| **推荐** | **Anisotropic sample optimization: On**；**Trilinear optimization: On** |
| **为什么** | 只对真正需要的像素做各向异性/三线性采样，省带宽且画质几乎无损。对 128-bit 显存的 4060 Ti 尤其友好。 |
| **代价** | 理论上极轻微画质损失，实测不可辨。 |

### Threaded optimization（线程优化）

| | |
|---|---|
| **推荐** | **Auto（自动）** |
| **为什么** | 让驱动根据程序的多线程特征自行决定。WoW 主要是单线程瓶颈，强制 On 有时反而增加调度开销。 |
| **代价** | 无。 |

### Triple buffering（三重缓冲）

| | |
|---|---|
| **推荐** | **Off（关闭）** |
| **为什么** | 只在开启 V-Sync 时才有意义。未开 V-Sync 时开启只是白白增加一帧缓冲和延迟。 |
| **代价** | 无（关闭状态）。 |

### Vertical sync / Preferred refresh rate 以外的项

其余项（Antialiasing、DSR、MFAA、CUDA 等）**保持默认**，不要在 WoW 上强行开启抗锯齿。

> WoW 有自己的后处理抗锯齿（游戏内设置）。在 NVIDIA 面板强行开启 MSAA/SSAA 会叠加巨大开销且可能与 DX12 冲突。

---

## 三、完整推荐表（RTX 4060 Ti + WoW）

| 项目 | 推荐值 | 理由摘要 |
|---|---|---|
| Power Management Mode | Prefer maximum performance | 防止负载突变时降频导致开怪断崖 |
| Preferred Refresh Rate | Highest available | 确保拿到标称刷新率 |
| Low Latency Mode | On（先不要 Ultra） | 减少渲染队列，帧时间更跟手 |
| Max Frame Rate | 刷新率 − 3 | 配合 G-SYNC，稳定 1% Low |
| V-Sync | G-SYNC 下实测决定（通常 Off + 锁帧） | 见决策表 |
| G-SYNC | 支持则 Enable（全屏+窗口） | 改善流畅感最有效单项 |
| Texture filtering - Quality | High Performance | 省带宽，画质无损感 |
| Anisotropic sample optimization | On | 省带宽 |
| Trilinear optimization | On | 省带宽 |
| Threaded optimization | Auto | 让驱动决定 |
| Triple buffering | Off | 未开 V-Sync 时无意义 |
| Antialiasing 相关 | 全部默认 / 由游戏控制 | 不要叠加驱动级抗锯齿 |

---

## 四、不推荐的做法

- ❌ **修改全局默认配置** — 影响所有程序，出问题难回滚。
- ❌ **把所有项都拉到"最高性能"** — 例如 Texture filtering Quality 设成 High Performance 已经足够，强行关掉过滤只会让画面变糊却换不来几帧。
- ❌ **开 DSR / 超采样** — 在 4060 Ti 上跑 WoW 是自找瓶颈。
- ❌ **驱动级强制 MSAA** — 与 DX12 冲突风险高，开销巨大。
- ❌ **超频后不测稳定性** — 显存超频导致的错误会以"随机卡顿"形式出现，极难排查。若要超频，先锁默认状态跑通整个流程再说。

---

## 五、状态记录（用于恢复）

修改前用 `backup-wow.ps1` 把当前 NVIDIA 相关状态写进 `system-state.json`。NVIDIA 面板设置本身无法用脚本读取/写入，因此：

1. 修改前**截图保存**每个选项卡的当前值
2. 在 `system-state.json` 中记录：`是否已有 WoW 程序级配置`、`G-SYNC 状态`、`驱动版本`
3. 恢复时：删除 WoW 程序级配置即可回到全局默认，或按截图逐项还原
