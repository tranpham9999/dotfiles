---
name: op-logtime
description: Log spent time vao OpenProject work package. Dung khi nguoi dung muon log thoi gian lam viec vao task. Hieu cac cau lenh tieng Viet nhu "logtime task X Y gio", "log Yh cho WP X ngay Z", "logtime 5h moi ngay cho tuan nay" (tuan nay = thu 2 den thu 6 cua tuan hien tai).
allowed-tools: [Bash]
---

# OP Logtime Skill

Log spent time vao OpenProject qua API v3 truc tiep (curl). Khong su dung script trung gian.

## Config

- Env file: `~/.config/opencode/.env`
- Base URL: `https://openproject.example.com`

## Cach su dung

### Buoc 1: Load env

```bash
source <(grep -E '^(OP_|TG_)' ~/.config/opencode/.env | sed 's/^/export /')
```

### Buoc 2: Lay user ID (lan dau tien)

```bash
curl -s -u "apikey:${OP_API_KEY}" "${OP_BASE_URL}/api/v3/users/me" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])"
```

### Buoc 3: Tao time entry

```bash
curl -s -X POST -u "apikey:${OP_API_KEY}" -H "Content-Type: application/json" \
  "${OP_BASE_URL}/api/v3/time_entries" \
  -d '{
    "hours": "PT0H30M",
    "spentOn": "YYYY-MM-DD",
    "comment": {"format":"plain","raw":"Noi dung","html":"<p>Noi dung</p>"},
    "_links": {
      "project": {"href": "/api/v3/projects/PROJECT_ID"},
      "entity": {"href": "/api/v3/work_packages/WP_ID"},
      "user": {"href": "/api/v3/users/USER_ID"},
      "activity": {"href": "/api/v3/time_entries/activities/ACTIVITY_ID"}
    }
  }'
```

### Helper: chuyen hours thanh ISO 8601

```python
def hours_to_iso8601(h):
    hh, mm = int(h), int(round((h - int(h)) * 60))
    return f"PT{hh}H{mm}M" if mm else f"PT{hh}H"
```

### Lenh nhanh — 1 step (env + curl + parse)

```bash
source <(grep -E '^(OP_|TG_)' ~/.config/opencode/.env | sed 's/^/export /') \
&& python3 -c "
import base64, json, sys, requests

env = dict(line.split('=',1) for line in open('/dev/stdin') if '=' in line)
" <<< "$(grep -E '^(OP_|TG_)' ~/.config/opencode/.env)" \
&& ...
```

**Cach thuc te — dung requests trong 1 dong python sau khi load env:**

```bash
source <(grep -E '^(OP_|TG_)' ~/.config/opencode/.env | sed 's/^/export /') \
&& python3 -c "
import base64, json, os, requests

token = base64.b64encode(f'apikey:{os.environ[\"OP_API_KEY\"]}'.encode()).decode()
headers = {'Authorization': f'Basic {token}', 'Content-Type': 'application/json'}
base = os.environ.get('OP_BASE_URL', 'https://openproject.example.com')

# Lay user ID
user = requests.get(f'{base}/api/v3/users/me', headers=headers).json()
user_id = user['id']

# Lay project_id tu work package
wp_id = WP_ID
wp = requests.get(f'{base}/api/v3/work_packages/{wp_id}', headers=headers).json()
proj_id = int(wp['_links']['project']['href'].rstrip('/').rsplit('/',1)[-1])

# Tao time entry
resp = requests.post(f'{base}/api/v3/time_entries', headers=headers, json={
    'hours': 'PT0H30M',
    'spentOn': 'YYYY-MM-DD',
    'comment': {'format':'plain', 'raw':'Comment', 'html':'<p>Comment</p>'},
    '_links': {
        'project': {'href': f'/api/v3/projects/{proj_id}'},
        'entity': {'href': f'/api/v3/work_packages/{wp_id}'},
        'user': {'href': f'/api/v3/users/{user_id}'},
        'activity': {'href': '/api/v3/time_entries/activities/25'},
    }
})
entry = resp.json()
print(f'Logged on {\"YYYY-MM-DD\"} for WP #{wp_id}. Entry ID: {entry[\"id\"]}')
"
```

## Cach hieu yeu cau nguoi dung

Nguoi dung co the noi nhieu cach khac nhau:
- "logtime task 18495 8h" → log 8h vao WP 18495
- "log 0.25h cho WP 23118 ngay 23/5" → log 0.25h vao WP 23118 date 2026-05-23
- "logtime 8 tieng task 18495 hom nay" → log 8h vao WP 18495 ngay hom nay
- "log time cho daily meeting 0.25h" → log 0.25h vao WP 18495 (Daily meeting)
- "logtime cho tôi task 24329 mỗi ngày 5h cho tuần này" → log 5h vao WP 24329 cho tung ngay thu 2 -> thu 6 cua tuan hien tai

### Trich xuat thong tin tu cau noi

1. **Task ID**: Tim so co 4-5 chu so (vi du: `18495`, `23118`). Hoac neu nguoi dung noi "Daily meeting" thi dung ID `18495`.
2. **Hours**: Tim so thap phan gan tu "gio", "tieng", "h", "hour". VD: "8h" → 8, "0.25 gio" → 0.25.
3. **Ngay (date)**:
   - "hom nay" → dung ngay hom nay
   - "ngay 23/5" → `2026-05-23`
   - "20/5" → `2026-05-20`
   - Neu khong co ngay → mac dinh hom nay

### Xu ly theo tuan (quan trong)

**"Tuần này" LUON LUON = thứ 2 → thứ 6 của tuần hiện tại, tính theo thời gian thực khi chạy lệnh** (không quan trọng hôm nay là thứ mấy, kể cả thứ 7/chủ nhật thì "tuần này" vẫn là thứ 2 → thứ 6 của tuần chứa hôm nay).

Cách tính trong python:

```python
from datetime import date, timedelta

today = date.today()
monday = today - timedelta(days=today.weekday())   # thu 2 cua tuan chua hom nay
week_days = [monday + timedelta(days=i) for i in range(5)]  # thu 2 -> thu 6 (5 ngay)
```

Vi du: hom nay Thu 26/08/2026 → "tuần này" = `[2026-08-24, 2026-08-25, 2026-08-26, 2026-08-27, 2026-08-28]` (log ca nhung ngay tuong lai).

Cac cum tu khac:
- "tuan truoc" → thu 2 -> thu 6 cua tuan truoc (`monday - timedelta(days=7)` lam moc)
- "tuần trước", "last week" → tương tự tuần này nhưng của tuần trước
- "moi ngay Xh cho tuan nay" / "5h mỗi ngày tuần này" → loop log Xh cho tung ngay thu 2 -> thu 6

### Trich xuat thong tin tu cau noi (phan log theo tuan)

1. **Hours moi ngay**: "mỗi ngày 5h" → 5h/ngay. Neu chi noi "15h cho tuan nay" → chia deu 15/5 = 3h/ngay.
2. **Log ca ngay tuong lai**: khi log theo tuan, log het ca thu 4, 5, 6 ke ca neu hom nay moi thu 3 — dung loai bo phan con lai.
3. **Comment mac dinh** khi nguoi dung khong ghi ro: dung subject cua WP, vd `"Lam viec tren task: <subject>"`.
4. **Comment**: Lay phan mo ta cong viec. VD: "log 8h task 18495 hop team" → `"Hop team"`

## Template lenh nhanh (copy-paste)

```bash
source <(grep -E '^(OP_|TG_)' ~/.config/opencode/.env | sed 's/^/export /') && python3 << 'PYEOF'
import base64, json, os, requests

token = base64.b64encode(f'apikey:{os.environ["OP_API_KEY"]}'.encode()).decode()
headers = {"Authorization": f"Basic {token}", "Content-Type": "application/json"}
base = os.environ.get("OP_BASE_URL", "https://openproject.example.com")

USER_ID = requests.get(f"{base}/api/v3/users/me", headers=headers).json()["id"]
ACTIVITY_ID = 25  # Default activity (N/A)

def log_time(wp_id, hours, spent_on, comment):
    h, m = int(hours), int(round((hours - int(hours)) * 60))
    hours_iso = f"PT{h}H{m}M" if m else f"PT{h}H"
    wp = requests.get(f"{base}/api/v3/work_packages/{wp_id}", headers=headers).json()
    proj_id = int(wp["_links"]["project"]["href"].rstrip("/").rsplit("/", 1)[-1])
    resp = requests.post(f"{base}/api/v3/time_entries", headers=headers, json={
        "hours": hours_iso,
        "spentOn": spent_on,
        "comment": {"format": "plain", "raw": comment, "html": f"<p>{comment}</p>"},
        "_links": {
            "project": {"href": f"/api/v3/projects/{proj_id}"},
            "entity": {"href": f"/api/v3/work_packages/{wp_id}"},
            "user": {"href": f"/api/v3/users/{USER_ID}"},
            "activity": {"href": f"/api/v3/time_entries/activities/{ACTIVITY_ID}"},
        }
    })
    resp.raise_for_status()
    entry = resp.json()
    print(f"Logged {hours_iso} on {spent_on} for WP #{wp_id} ({wp.get('subject','?')})")
    print(f"Entry ID: {entry['id']}")
    print(f"URL: {base.rstrip('/api/v3')}/work_packages/{wp_id}/time_entries")
    return entry["id"]

# === Thay doi tham so o day ===
log_time(wp_id=WP_ID, hours=HOURS, spent_on="YYYY-MM-DD", comment="COMMENT")
PYEOF
```

## Sau khi log

1. Doc output de lay Entry ID
2. Bao cho user: "Da log Xh cho WP #<id> vao ngay YYYY-MM-DD. Entry #<so>. Kiem tra: https://openproject.example.com/work_packages/<id>/time_entries"
3. Neu user ngay hom nay, nhac ho kiem tra UI

## Neu user muon log nhieu ngay

Goi `log_time()` nhieu lan trong cung 1 script python, moi lan 1 ngay.

### Template log theo tuần ("tuần này" = thứ 2 → thứ 6)

```bash
source <(grep -E '^(OP_|TG_)' ~/.config/opencode/.env | sed 's/^/export /') && python3 << 'PYEOF'
import base64, os, requests
from datetime import date, timedelta

token = base64.b64encode(f'apikey:{os.environ["OP_API_KEY"]}'.encode()).decode()
headers = {"Authorization": f"Basic {token}", "Content-Type": "application/json"}
base = os.environ.get("OP_BASE_URL", "https://openproject.example.com")

USER_ID = requests.get(f"{base}/api/v3/users/me", headers=headers).json()["id"]
ACTIVITY_ID = 25
WP_ID = WP_ID          # thay ID task
HOURS_PER_DAY = "PT5H" # thay so gio moi ngay

wp = requests.get(f"{base}/api/v3/work_packages/{WP_ID}", headers=headers).json()
proj_id = int(wp["_links"]["project"]["href"].rstrip("/").rsplit("/", 1)[-1])
comment = f"Lam viec tren task: {wp.get('subject', '?')}"

today = date.today()
monday = today - timedelta(days=today.weekday())
for i in range(5):
    spent_on = (monday + timedelta(days=i)).isoformat()
    resp = requests.post(f"{base}/api/v3/time_entries", headers=headers, json={
        "hours": HOURS_PER_DAY,
        "spentOn": spent_on,
        "comment": {"format": "plain", "raw": comment, "html": f"<p>{comment}</p>"},
        "_links": {
            "project": {"href": f"/api/v3/projects/{proj_id}"},
            "entity": {"href": f"/api/v3/work_packages/{WP_ID}"},
            "user": {"href": f"/api/v3/users/{USER_ID}"},
            "activity": {"href": f"/api/v3/time_entries/activities/{ACTIVITY_ID}"},
        }
    })
    status = "OK" if resp.status_code < 400 else f"FAIL {resp.status_code}"
    entry = resp.json().get("id", "?")
    print(f"{status} {spent_on}: {HOURS_PER_DAY} -> Entry #{entry}")
PYEOF
```

## Neu user khong ro task ID

Gop y user mo OpenProject tim task va lay ID tu URL:
`https://openproject.example.com/work_packages/<ID>`

## Cac task da biet

| ID | Ten | Project |
|----|-----|---------|
| 18495 | Daily meeting | HSI_SSD8_VMIS Trien khai CustomApp |
| 23118 | HPT_14175_DQM Ho tro Disable External Share | Trien khai (Microsoft HCM) |
| 24329 | AZ-104: Microsoft Azure Administrator | Chứng chỉ quan hệ đối tác (Microsoft HCM) |
