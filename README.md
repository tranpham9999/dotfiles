# dotfiles — opencode + agent skills, cài lại 1 lệnh

Repo chứa toàn bộ cấu hình opencode, skills tự viết và skills Microsoft/Azure,
kèm installer để khôi phục hoàn chỉnh trên **máy macOS mới** hoặc **Windows
(qua WSL)**.

## Cấu trúc

```
├── install.sh                 # installer cho macOS + Linux/WSL
├── install-windows.ps1        # bootstrap WSL trên Windows rồi gọi install.sh
├── opencode/
│   ├── opencode.json          # global config: provider + 7 MCP servers
│   └── package.json           # plugin deps (@opencode-ai/plugin)
├── opencode-skills/           # skills opencode tự viết
│   └── macos-return-ghostty/
├── claude-skills/             # skills claude code tự viết
│   ├── agile-init/  drawio/  op-logtime/
├── agents-skills/             # 20 skills Microsoft (azure-*, foundry, entra)
├── .env.example               # template secrets
└── .gitignore                 # .env, node_modules
```

**Không lưu trong repo** (installer tự tải từ nguồn gốc, giữ repo ~2MB):

| Thành phần | Nguồn |
|---|---|
| `archify` skill (7.3MB) | `github.com/tt-a1i/archify` |
| `claude-office-skills` (130MB + node_modules) | `github.com/tfriedel/claude-office-skills` |
| `node_modules` (opencode plugin, office-skills) | `npm install` |

## Cài trên máy macOS mới

```bash
xcode-select --install          # nếu chưa có git
git clone https://github.com/<you>/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Script tự cài thiếu gì (`brew install node`, uv qua installer chính chủ),
backup config cũ, rồi cài đủ mọi thứ. Chạy lại được nhiều lần (idempotent).

## Cài trên Windows mới (qua WSL — runtime khuyến nghị của opencode)

PowerShell (không cần admin nếu WSL đã có):

```powershell
git clone https://github.com/<you>/dotfiles.git
cd dotfiles
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-windows.ps1 -RepoUrl https://github.com/<you>/dotfiles.git
```

Script tự cài WSL/Ubuntu nếu thiếu (có thể yêu cầu reboot → chạy lại script),
rồi clone + chạy `install.sh` **bên trong WSL**.

## Secrets (không bao giờ commit)

`install.sh` tạo `~/.config/opencode/.env` từ `.env.example` nếu chưa có.
Điền:

```
OP_BASE_URL=https://your-openproject-host
OP_API_KEY=xxxxxxxx
```

MCP **openproject** sẽ không start nếu thiếu 2 biến này. **ms365** cần login
OAuth một lần: chạy `/ms365 login` trong opencode.

**GitHub MCP** đọc token từ file `~/.config/opencode/github-pat` (1 dòng,
raw token, không quote). Cách lấy: tạo PAT tại
`github.com/settings/tokens` (scopes `repo` + `read:org`) hoặc dùng
`gh auth login` rồi `gh auth token > ~/.config/opencode/github-pat`.
Nếu file chứa `replace-me` thì MCP github sẽ báo 401.

## MCP servers được cấu hình

| Server | Nền tảng | Ghi chú |
|---|---|---|
| `mslearn` | mọi nơi | remote, tài liệu Microsoft |
| `github` | mọi nơi | remote, cần `github-pat` (xem Secrets) |
| `drawio`, `drawio-edit` | mọi nơi | npx / uvx |
| `playwright` | mọi nơi | trình duyệt Chrome |
| `ms365` | mọi nơi | org-mode, read-only |
| `openproject` | mọi nơi | cần `.env` như trên |
| `macos-mcp` | **chỉ macOS** | installer tự tắt trên Linux/WSL |

## Cập nhật máy đang dùng

```bash
cd ~/dotfiles && git pull && ./install.sh
```

Config/skills hiện có được backup trước khi ghi đè; `.env` không bao giờ bị
đè. Sau khi cài xong nhớ **restart opencode**.

## Thêm nội dung mới vào repo

- Skill opencode tự viết mới → `opencode-skills/<tên>/SKILL.md`
- Skill claude mới → `claude-skills/<tên>/`
- Đổi MCP trong opencode → sửa `opencode/opencode.json` rồi commit
