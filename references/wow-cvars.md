# WoW 图形设置与 CVar 调校手册

> ⚠️ **CVar 名称在不同版本间会有微调。** 写入时采用"文件中已存在的键 → 改值；不存在的键 → 追加并在报告中标注"的策略，不要硬编码假设全集。

每一项都标注它主要消耗的是 **GPU**（算力/填充率）、**CPU**（主线程/绘制调用）还是 **VRAM**（显存）。这是决定"该不该砍"的关键。

---

## 一、渲染与同步类

| 设置 / CVar | 主要消耗 | 建议 | 说明 |
|---|---|---|---|
| **Render Scale** | GPU（极重） | **保持 100%**，除非 GPU 明显瓶颈 | 渲染分辨率倍率。降到 90% 约省 19% 像素填充，是 GPU 瓶颈时收益最大的单项，但画面会整体发糊。<br>**在 RTX 4060 Ti 上，除非 GPU 占用长期 97%+，否则不动它**——宁可砍阴影和 SSAO。 |
| **分辨率 / 全屏模式** | GPU | 原生分辨率 + 全屏（非无边框） | 无边框窗口化会引入桌面合成器开销，通常比独占全屏低 3–8% 帧且帧时间更抖。 |
| **V-Sync** | 延迟 / 帧时间 | 见下方决策表 | 关闭 V-Sync 会让帧时间更自由但可能撕裂；开启会锁帧但增加延迟。 |
| **Triple Buffering** | VRAM | **默认关闭** | 只在开启 V-Sync 且出现卡顿时才考虑打开。它会多占一帧缓冲并增加 1 帧延迟。<br>**未开 V-Sync 时开三重缓冲毫无意义。** |
| **Max Foreground FPS** | GPU / 功耗 | 见下方决策表 | 限制上限可显著降低 GPU 负载与温度、稳定帧时间。**超过显示器刷新率很多没有实际意义。** |
| **Max Background FPS** | GPU / 功耗 | **30–60** | 切出游戏时限制帧数，避免后台满载导致切回来时掉帧和高温。 |
| **Reduce Input Lag / Low Latency** | 延迟 | 团本建议开启 | 减少渲染队列帧数，代价是极高的帧数会略降，但帧时间更跟手。 |

### V-Sync / G-SYNC 决策表

| 显示器 | 推荐组合 | 理由 |
|---|---|---|
| 支持 G-SYNC / FreeSync | **NVIDIA 面板开 G-SYNC + 游戏内 V-Sync 关 + Max FPS 设为 刷新率−3**（如 144Hz → 141） | 让 G-SYNC 在可变刷新区间内工作，避免撞到上限触发 V-Sync 介入产生延迟 |
| 不支持可变刷新，60Hz | V-Sync 开 或 Max FPS 锁 60 | 60Hz 下撕裂非常明显，锁帧比开 V-Sync 延迟更低 |
| 不支持可变刷新，144Hz+ | V-Sync 关 + Max FPS 锁刷新率 | 高刷下撕裂不易察觉，锁帧控温度 |
| 追求极限响应（竞技向） | V-Sync 关 + 不锁帧 | 帧时间最自由，但可能撕裂、温度高 |

---

## 二、GPU 算力重灾区（优先砍这些）

| 设置 / CVar | 主要消耗 | 建议 | 说明 |
|---|---|---|---|
| **Shadow Quality** | GPU（重）+ CPU | **优先降低** | 阴影是 WoW 里性价比最低的画质项：吃掉大量算力，但对战斗判断几乎没有帮助。<br>从 High → Low 通常能换来 10–20% 帧数。**团本 Profile 直接降到 Low。** |
| **Ray Traced Shadows** | GPU（极重） | **关闭** | 光追阴影在 WoW 里收益极小、代价极大。RTX 4060 Ti 的光追单元带不动有意义的画质，直接关。 |
| **SSAO / 环境光遮蔽** | GPU（中重） | **关闭或 Low** | SSAO 在快速移动的团本战斗中几乎看不出来，但每帧都要跑一遍深度采样。<br>关掉通常换 5–10% 帧数。 |
| **Liquid Detail** | GPU（中） | **中等** | 水体渲染在多数团本/大秘境场景占比不高，中等即可。只有纳沙塔尔、海底类场景才需要高。 |
| **Compute Effects** | GPU（中，视驱动） | 按实测调整 | 部分机器上开启会明显掉帧，部分机器无感。**必须实测**：开着测一轮、关着测一轮，看 1% Low。 |
| **Depth Effects / Sunshafts** | GPU（轻中） | 低或关 | 纯观感项，战斗中无信息价值。 |
| **View Distance** | GPU + CPU | **5–7** | 远景对 GPU 顶点/绘制调用和 CPU 剔除都有压力。从 10 降到 7 几乎不影响战斗，但帧数提升明显。 |
| **Environment Detail** | GPU + CPU | **5–7** | 环境几何密度。同上，战斗中看不出差别。 |
| **Ground Clutter** | GPU + CPU（绘制调用） | **4–6** | 地面草丛杂物会产生海量小物件绘制调用，**是 CPU 主线程负担的隐形大户**。团本强烈建议降到 4。 |
| **Particle Density** | GPU + CPU | 团本环境适当降低 | 粒子是团本 AOE 高峰期掉帧主因之一。降低后画面"烟花"变少，但技能判定圈依然清晰。 |

---

## 三、CPU 主线程相关（团本掉帧的真凶）

| 设置 / CVar | 主要消耗 | 建议 | 说明 |
|---|---|---|---|
| **Spell Density** | CPU（重） + GPU | **Dynamic 或 Essential** | 控制显示多少其他玩家的法术特效。<br>**这是团本 FPS 单项影响最大的设置之一。**<br>`All` → `Essential` 在 30 人团本中可能带来 20–40% 帧数提升。<br>代价：别人放的视觉效果变少，但你自己的技能和必要的预警仍然会显示。 |
| **Nameplates / 姓名板** | CPU（中） | 团本关闭友方姓名板 | 通过 Plater 等插件关闭非目标友方姓名板，减少每帧更新的 UI 元素。 |
| **Ground Clutter** | CPU | 见上 | 属于跨 GPU/CPU 双消耗，团本要压低。 |
| **Outline Mode** | GPU（轻中） | **低或关闭** | 轮廓描边。低或关闭对可读性影响很小。 |

---

## 四、显存相关（RTX 4060 Ti 上要"守"而不是"砍"）

| 设置 / CVar | 主要消耗 | 建议 | 说明 |
|---|---|---|---|
| **Texture Resolution** | VRAM（大） | **保持高** | 贴图分辨率主要吃显存而不是算力。**RTX 4060 Ti（8GB/16GB）通常可以全程保持高贴图**，不要为了提帧牺牲它——低贴图会让画面明显变糊、技能图标和地面警示圈辨识度下降。 |
| **Texture Filtering（各向异性）** | GPU（轻） | **8x 或 16x** | 现代 GPU 上各向异性过滤开销很低，收益（斜视角地面清晰）明显。16x 与 8x 在 4060 Ti 上差距几乎测不出来。 |
| **Projected Textures** | GPU（轻中） | **开启** | 地面法术圈（如奉献、暴风雪、各种 AOE 警示）依赖投影贴图。**关掉会让脚下圈变得非常淡，直接影响走位判断——强烈建议保留。** |
| **Texture Atlas / 材质缓存** | VRAM | 保持默认 | 一般无需调整。 |

> **RTX 4060 Ti 显存提醒**：8GB 版本在高分辨率 + 大量插件材质 + 浏览器后台时可能接近上限。若基准测试出现"帧数骤降 + 明显卡顿 + VRAM 接近满"，才考虑降一档贴图。**不要预防性降低。**

---

## 五、UI 与显示类

| 设置 / CVar | 说明 |
|---|---|
| `gxApi` | 图形 API。现代版本建议 D3D12（默认）。若出现兼容性问题可尝试切换，但需实测。 |
| `gxWindow` / `gxMaximize` | 窗口模式。独占全屏通常帧时间最稳。 |
| `gxResolution` / `gxRefresh` | 分辨率与刷新率。确认与实际显示器一致。 |
| UI Scale | 不影响帧数，但过高的 UI 缩放会增加 UI 渲染负担（轻微）。 |

---

## 六、设置优先级速查（按"性价比"排序）

要提帧时，**按这个顺序从上往下砍**，不要一上来就降贴图或降分辨率：

1. Ray Traced Shadows → 关（几乎无代价）
2. Spell Density → Essential（团本收益最大，代价可接受）
3. Shadow Quality → Low（收益大，观感代价小）
4. SSAO → 关（收益中等，几乎看不出）
5. Ground Clutter → 4（收益中等，野外略微变秃）
6. View Distance / Environment Detail → 6（收益中等）
7. Particle Density → 降一档（团本收益中等，观感略损）
8. Outline Mode → 低（收益小但免费）
9. Liquid Detail → 中（收益小）
10. Compute Effects → 实测决定
11. Render Scale → 90%（**GPU 严重瓶颈时才动**）
12. Texture Resolution → 降档（**最后手段，优先避免**）

---

## 七、写入 Config.wtf 的格式

```txt
SET gxApi "D3D12"
SET gxResolution "2560x1440"
SET gxRefresh "144"
SET gxWindow "0"
SET gxMaximize "1"
SET gxVSync "0"
SET gxTripleBuffer "0"
SET maxFPS "141"
SET maxFPSBk "30"
SET graphicsShadowQuality "2"
SET graphicsSpellDensity "1"
```

规则：
- 一行一个 `SET <name> "<value>"`
- **游戏必须在关闭状态修改**，否则退出时会被游戏内存中的值覆盖
- 修改前先备份（见 `backup-restore.md`）
- 图形设置可能存在于账号级/角色级 `Config.wtf` 并覆盖全局，修改后需确认生效
