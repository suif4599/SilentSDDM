# 在 NixOS 中集成 SilentSDDM（本 Fork）

本文档讲解如何把你 fork 出来的 SilentSDDM 集成到 NixOS 系统中。**从 GitHub 拉取，不拉取历史**。

> 阅读对象：使用 NixOS（开启 flakes）的用户。
> Fork 地址：`github:suif4599/SilentSDDM`
> 默认分支：`main`

---

## 0. TL;DR（最短路径）

如果你的 NixOS 配置已经是 flake 化的，只需要三步：

1. 在你的 `flake.nix` 的 `inputs` 中加入：
   ```nix
   silentSDDM = {
     url = "github:suif4599/SilentSDDM";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```
2. 在你的 NixOS 配置（通常是 `configuration.nix` 或某个 `host.nix`）中：
   ```nix
   { inputs, pkgs, lib, ... }: {
     imports = [ inputs.silentSDDM.nixosModules.default ];

     programs.silentSDDM.enable = true;
   }
   ```
3. 重建并切换：
   ```bash
   sudo nixos-rebuild switch --flake .#<你的hostname>
   ```

重启后即可看到 SilentSDDM 主题。

---

## 1. 关于「从 GitHub 拉取但不拉取历史」

Nix flakes 的 `github:owner/repo` 短链语法在拉取时会**自动从 GitHub API 请求 tarball**，而不是 `git clone`。这意味着：

- ✅ 不会拉取 git 历史（`--depth=1` 都不需要，因为根本不是 git 协议）
- ✅ 拉取的是某个 commit 的快照（由 `flake.lock` 锁定具体 commit）
- ✅ 比手动 `git clone --depth=1` 更快、更省空间

所以**只要用 `url = "github:suif4599/SilentSDDM"` 就天然满足了"不拉历史"的要求**。无需 `--depth=1`、无需 `submodules`、无需任何额外参数。

如果你坚持想要本地浅克隆一份再消费（不推荐，仅在没网/离线场景才考虑），见 [§7. 离线/浅克隆方案](#7-离线浅克隆方案可选)。

---

## 2. 前置条件

在你 NixOS 的 `configuration.nix`（或等价位置）里确认：

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

没开 flakes 的话，先用 channels 方式，但本文档主要围绕 flakes（推荐）。

---

## 3. 第一步：在你的 flake 里注册输入

打开你 NixOS 系统的 `flake.nix`（不是这个仓库内的，是你 `/etc/nixos/` 或自定义 dotfiles 仓库里的那个），在 `inputs` 块里加：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # 注册 SilentSDDM fork
    silentSDDM = {
      url = "github:suif4599/SilentSDDM";
      # 让本 flake 复用系统的 nixpkgs，避免重复下载一份
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, silentSDDM, ... }@inputs: {
    nixosConfigurations.<hostname> = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        # 这里也可以直接 import module，详见下一步
      ];
    };
  };
}
```

要点：
- `inputs.nixpkgs.follows = "nixpkgs"` 是关键，避免下载一份冗余的 nixpkgs。
- `flake.lock` 在你首次 `nixos-rebuild` 时会自动生成并锁定 SilentSDDM 的具体 commit。

---

## 4. 第二步：在系统配置里启用主题

在你 NixOS 的某个 `modules` 文件（例如 `configuration.nix` 或 `sddm.nix`）里：

```nix
{ inputs, pkgs, lib, config, ... }:

{
  # 引入 fork 提供的 NixOS module
  imports = [ inputs.silentSDDM.nixosModules.default ];

  programs.silentSDDM = {
    enable = true;

    # 选择内置预设（可选，默认是 "rei"）
    # 该 fork 中 rei/ken/silvia 的视频背景已被移除，
    # 因此建议使用：default / default-left / default-right
    theme = "default";

    # 自定义配置项（覆盖主题默认）
    # 完整选项列表见：docs/Options.md 或上游 Wiki
    settings = {
      "LoginScreen" = {
        background = "default.jpg";
      };
      "LockScreen" = {
        background = "default.jpg";
      };
    };
  };
}
```

应用并切换：

```bash
sudo nixos-rebuild switch --flake .#<你的hostname>
```

> **重要**：SDDM 主题变更需要**重启**（或重启 display-manager 服务）才能完全生效：
> ```bash
> sudo systemctl restart display-manager.service
> ```
> 不重启的话 greeter 缓存可能还显示旧主题。

---

## 5. 第三步：测试主题（无需重启）

本 fork 的 nix flake 提供了一个 `test-sddm-silent` 可执行文件，可以在当前会话里直接预览 greeter，不需要注销/重启：

```bash
# 在你的 NixOS 系统上，直接用 nix run 调用本 fork 的 test 包
nix run github:suif4599/SilentSDDM#test
```

或者，因为你已经把它作为 flake input，可以在系统包里直接调用：

```bash
test-sddm-silent
```

（这个 binary 已经通过 module 的 `environment.systemPackages = [silent' silent'.test];` 自动装到 PATH 里。）

---

## 6. 第四步（可选）：自定义壁纸

本 fork 的 `Main.qml` 已经被简化为**硬编码使用 `backgrounds/default.jpg`**，所以即使 module 提供了 `backgrounds` 选项，默认也不会被 `Main.qml` 读取。你有两个选择：

### 选项 A：替换 `default.jpg`（推荐，最简单）

直接把你的壁纸覆盖 `backgrounds/default.jpg`（通过 fork 仓库的 git 改），主题就会用它。

### 选项 B：使用 module 的 `backgrounds` 选项（需要还原 Main.qml）

如果你想让 module 的 `backgrounds` 选项生效，需要把 `Main.qml` 还原成上游版本（参考 `initial/Main.qml`），然后用：

```nix
programs.silentSDDM = {
  enable = true;
  backgrounds = {
    mywall = pkgs.fetchurl {
      name = "mywall.jpg";
      url = "https://example.com/wallpaper.jpg";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
  settings."LoginScreen".background = "mywall.jpg";
};
```

> 注意：上游依赖 `qt6-imageformats`（用于支持 webp/tiff 等格式）。**本 fork 为了精简依赖把它移除了**，所以 `backgrounds` 里只支持 jpg/png/svg/mp4 等 Qt 原生格式。如果你需要 webp/tiff，把 `nix/package.nix` 第 34 行改回：
> ```nix
> inherit (kdePackages) qtmultimedia qtsvg qtvirtualkeyboard qtimageformats;
> ```

---

## 7. 离线/浅克隆方案（可选）

如果你因为某些原因不能用 `github:` 短链（比如内网/无 GitHub API 访问），可以用本地浅克隆 + path input：

```bash
# 在你的 dotfiles 仓库旁边浅克隆（不带历史）
git clone --depth=1 https://github.com/suif4599/SilentSDDM
```

然后在你的 `flake.nix`：

```nix
inputs.silentSDDM.url = "path:/path/to/SilentSDDM";
```

`path:` 输入会被当作 git 仓库处理，但因为 `--depth=1`，本地这份也没有历史。每次 `nixos-rebuild` 都会用本地最新内容（注意：path input 默认是 dirty 的，会跟着 working tree 走；如果想要干净 commit，加 `flake=false` 或先 commit）。

---

## 8. 完整可运行示例

下面是一个最小化的 NixOS flake 配置，开箱即用：

```nix
# flake.nix
{
  description = "My NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    silentSDDM = {
      url = "github:suif4599/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, silentSDDM, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        ./sddm.nix
      ];
    };
  };
}
```

```nix
# sddm.nix
{ inputs, pkgs, lib, ... }:
{
  imports = [ inputs.silentSDDM.nixosModules.default ];

  programs.silentSDDM = {
    enable = true;
    theme = "default";
  };
}
```

应用：

```bash
sudo nixos-rebuild switch --flake .#myhost
sudo systemctl restart display-manager.service
```

---

## 9. 排错

### 主题没生效，还是原来的 SDDM
1. 确认 `programs.silentSDDM.enable = true;` 真的写在了被消费的 module 列表里。
2. `sudo systemctl restart display-manager.service` 重启 sddm。
3. `sudo sddm-greeter --test-mode --theme /run/current-system/sw/share/sddm/themes/silent` 直接预览看报错。

### 字体显示成方块
module 已经会自动把仓库自带的 Red Hat 字体安装到系统字体路径。如果你看到方块，确认 `fonts.packages` 没被你在别处覆盖掉。检查命令：
```bash
fc-list | grep -i "red hat"
```

### `nix run github:suif4599/SilentSDDM#test` 报 hash 不匹配
说明 GitHub 上 commit 变了但你的 `flake.lock` 锁着旧版本。先：
```bash
nix flake update silentSDDM
```
然后重新 rebuild。

### 想恢复 lock 文件
本 fork 仓库内 `flake.lock` 已被删除（按用户要求）。这没问题：当 SilentSDDM 被作为 input 消费时，**消费者的 `flake.lock` 会锁定具体 commit**，本仓库内部不需要 lock。

如果你想在 fork 仓库本地测试 `nix run .#test`，第一次运行会自动生成 `flake.lock`。可以放心加入 git。

---

## 10. 与上游的差异（针对本 Fork）

如果你之后想 cherry-pick 上游更新或者向 upstream 报 issue，需要知道本 fork 相对 upstream 的差异：

| 项 | Upstream | 本 Fork |
|---|---|---|
| `Main.qml` 背景逻辑 | 根据 `Config.loginScreenBackground` 动态切换，支持 jpg/png/mp4/webm 等 | **硬编码 `backgrounds/default.jpg`** |
| `Main.qml` 视频播放 | 支持（`Video {}` 元素） | **已移除** |
| `LockScreen.qml` | 上游版本 | **替换为 Clock.qml**（仿 sddm-anime-tactical 的大时钟屏） |
| 内置壁纸 | 包含 rei/ken/silvia 的 mp4+png、mountain、smoky 等 | **只保留 `default.jpg`** |
| `qtimageformats` | 列为依赖 | **已移除**（不影响默认使用，仅影响 webp/tiff 自定义壁纸） |
| 仓库根目录 README 截图 | 无 | 多了 `clock.png` / `login.png`（packaging 时已排除，不会装进系统） |
| `flake.lock` | 存在 | **已删除**，可重新生成 |

如果你将来想把 `qtimageformats` 加回来（恢复完整上游兼容性），改 [nix/package.nix](../nix/package.nix) 第 34 行即可。

---

## 11. 参考

- 上游仓库：<https://github.com/uiriansan/SilentSDDM>
- 本 Fork 仓库：<https://github.com/suif4599/SilentSDDM>
- 选项文档：[Options.md](./Options.md)
- Nix Flakes 官方手册：<https://nixos.wiki/wiki/Flakes>
- `nixos-rebuild` 文档：<https://nixos.org/manual/nixos/stable/#sec-changing-config>
