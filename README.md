# Kiro Skills Installer

為 Kiro IDE 學員準備的一鍵安裝腳本，解決兩個熱門 Skill（UI/UX PRO MAX、Playwright CLI）在 Kiro 下安裝流程不順的問題。

## 這個 Repo 解決什麼？

- **UI/UX PRO MAX**：官方 CLI 支援 Kiro，但學員常遇到不知道要加 `--global` 旗標
- **Playwright CLI**：官方 `playwright-cli install --skills` 只會裝到 Claude Code、Copilot 的目錄，Kiro 的 `~/.kiro/skills/` 會被忽略

本 repo 的腳本會呼叫上游官方工具，再補上 Kiro 的那段，學員不需要手動處理。

## 支援平台

- Windows（PowerShell）
- macOS / Linux（Bash）

## 使用方式（給學員貼到 Kiro 的對話區）

### 安裝 UI/UX PRO MAX

````
請幫我執行下列指令，幫 Kiro IDE 安裝 UI/UX PRO MAX Skill：

Windows（PowerShell）：
iwr -useb https://raw.githubusercontent.com/MozHubYo/kiro-skills-installer/main/install-ui-ux-pro-max.ps1 | iex

macOS：
curl -fsSL https://raw.githubusercontent.com/MozHubYo/kiro-skills-installer/main/install-ui-ux-pro-max.sh | bash

請依我的作業系統選擇，執行完成後告訴我安裝是否成功。
````

### 安裝 Playwright CLI

````
請幫我執行下列指令，幫 Kiro IDE 安裝 Playwright CLI Skill：

Windows（PowerShell）：
iwr -useb https://raw.githubusercontent.com/MozHubYo/kiro-skills-installer/main/install-playwright-cli.ps1 | iex

macOS：
curl -fsSL https://raw.githubusercontent.com/MozHubYo/kiro-skills-installer/main/install-playwright-cli.sh | bash

請依我的作業系統選擇，執行完成後告訴我安裝是否成功。
````

## 安裝完確認

在 Kiro 左側面板 **AGENT STEERING & SKILLS** > **Global** 區域應該可以看到：

- `ui-ux-pro-max`
- `playwright-cli`

## 腳本做了什麼？

### `install-ui-ux-pro-max.*`

1. 確認 `node` 和 `npm` 存在
2. `npm install -g uipro-cli`
3. `uipro init --ai kiro --global`（裝到 `~/.kiro/skills/ui-ux-pro-max/`）

### `install-playwright-cli.*`

1. 確認 `node` 和 `npm` 存在
2. `npm install -g @playwright/cli@latest`
3. `playwright-cli install --skills`（上游會裝到 `~/.claude/skills/` 或 `~/.copilot/skills/`）
4. 從上游裝到的位置，把 `playwright-cli` skill 複製到 `~/.kiro/skills/playwright-cli`

## 授權與致謝

本 repo 不重新分發任何 Skill 內容，只呼叫上游官方工具並補 Kiro 目錄處理。

- UI/UX PRO MAX：[nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)（MIT）
- Playwright CLI：[microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)（Apache 2.0）

本 repo 採 MIT 授權。
