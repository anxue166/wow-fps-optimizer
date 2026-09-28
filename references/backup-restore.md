# 备份结构与一键恢复

---

## 一、备份目录结构

```
<WoW根目录>/
└── _WoW-FPS-Backup/
    └── 2026-09-28_19-50-12/
        ├── MANIFEST.txt          # 备份清单 + 恢复命令
        ├── system-state.json     # Windows / NVIDIA 原始状态快照
        ├── Config.wtf            # 单独备份，便于快速回滚
        └── WTF/                  # 完整 WTF 目录树
            ├── Config.wtf
            └── Account/
                └── <账号>/
                    ├── Config.wtf
                    └── <服务器>/<角色>/
```

备份放在 `_WoW-FPS-Backup/` 而不是 WTF 内部，避免"备份自己"和游戏扫描干扰。

---

## 二、system-state.json 内容

```json
{
  "timestamp": "2026-09-28T19:50:12",
  "windows": {
    "powerPlanGuid": "381b4222-f694-41f0-9685-ff5bb260df2e",
    "powerPlanName": "平衡",
    "gameMode": 1,
    "hwSchMode": 2,
    "xboxBackgroundCapture": 1
  },
  "nvidia": {
    "driverVersion": "560.94",
    "driverDate": "2026-08-12",
    "hasWowAppProfile": false,
    "gSyncEnabled": null
  },
  "wow": {
    "version": "retail",
    "installPath": "D:\\World of Warcraft\\_retail_",
    "configPath": "D:\\World of Warcraft\\_retail_\\WTF\\Config.wtf"
  }
}
```

作用：恢复时能精确还原到原始值，而不是"凭记忆改回去"。

---

## 三、备份命令

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/backup-wow.ps1" -WowPath "<WoW根目录>"
```

- 不带 `-WowPath` 时自动探测安装路径
- 每次执行生成独立时间戳目录，**永不覆盖旧备份**
- 输出 `MANIFEST.txt`，内含本次备份的路径与对应恢复命令

---

## 四、一键恢复

### 恢复 WoW 配置

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/restore-wow.ps1" -BackupDir "<WoW根目录>\_WoW-FPS-Backup\2026-09-28_19-50-12"
```

行为：
1. 校验备份目录完整性（必须有 `WTF/`）
2. **先把当前状态再备份一次**（防止"恢复错了还想反悔"）
3. 用备份覆盖 `WTF/`
4. 输出恢复报告

**恢复前必须完全退出游戏。**

### 手动恢复（脚本不可用时）

1. 关闭 WoW
2. 把备份目录里的 `WTF/` 整个复制，覆盖 `<WoW>\_retail_\WTF\`
3. 若只改了 `Config.wtf`，直接用备份里的 `Config.wtf` 覆盖即可

---

## 五、Windows / NVIDIA 恢复

| 项目 | 恢复方法 |
|---|---|
| 电源计划 | `powercfg /setactive <备份中的 GUID>` |
| 游戏模式 | 设置 → 游戏 → 游戏模式，改回原值 |
| HAGS | 设置 → 显示 → 图形 → 默认图形设置，改回原值（需重启） |
| Xbox 后台录制 | 设置 → 游戏 → 捕获，改回原值 |
| Discord 叠加 | Discord → 设置 → 游戏叠加，改回原值 |
| NVIDIA 覆盖 | GeForce Experience → 设置 → 常规，改回原值 |
| **NVIDIA WoW 程序配置** | NVIDIA 控制面板 → 管理 3D 设置 → 程序设置 → **删除 WoW 条目**即回到全局默认 |
| 显示器刷新率 | 设置 → 系统 → 屏幕 → 高级显示，改回原值 |

> NVIDIA 面板设置无法用脚本读写，因此修改前**必须截图保存**各选项卡原值。

---

## 六、变更日志（change-log.txt）

每次 `apply-profile.ps1` 执行后追加记录：

```
[2026-09-28 19:52:03] Profile C applied
  graphicsShadowQuality: 5 -> 2
  graphicsSpellDensity: 3 -> 1
  graphicsViewDistance: 10 -> 5
  (appended) graphicsGroundClutter: 4
  backup: D:\World of Warcraft\_WoW-FPS-Backup\2026-09-28_19-50-12
```

作用：出问题时能精确知道改了什么、改之前是什么，逐项回退而不是整个回滚。

---

## 七、备份纪律（铁律）

1. **任何修改前先备份**，没有备份就拒绝执行（脚本会强制校验）。
2. **备份永不覆盖**，每次独立时间戳。
3. **保留最近 3 次备份**即可，再老的可以手动清理（清理前先确认已达标）。
4. 恢复操作本身也会先做一次备份，保证"恢复错了能再反悔"。
5. **游戏必须在关闭状态**做备份与恢复，否则文件状态不一致。
