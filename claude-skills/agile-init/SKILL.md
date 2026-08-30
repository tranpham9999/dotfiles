---
name: agile-init
description: Khởi tạo cấu trúc Agile docs + .claude/rules/ cho dự án mới. Dùng khi bắt đầu bất kỳ project mới nào cần mô phỏng team Scrum.
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# Agile Init Skill

Khi user gọi `/agile-init`, hãy:

1. Hỏi user 4 câu bằng AskUserQuestion (TẤT CẢ label, description, question, options PHẢI bằng tiếng Việt):

**Câu 1 (header: "Tên dự án"):**
- question: "Tên dự án của bạn là gì?"
- options: ["Dự án mới", "Khác (bạn tự nhập)"]

**Câu 2 (header: "Mô tả"):**
- question: "Mô tả ngắn gọn về dự án (1-2 câu)?"
- options: ["Ứng dụng web", "Sản phẩm SaaS", "Khác (bạn tự nhập)"]

**Câu 3 (header: "Tech Stack"):**
- question: "Dự án dùng tech stack gì?"
- options: ["React + TypeScript", "Next.js + TypeScript", "Node.js + TypeScript", "Khác (bạn tự nhập)"]

**Câu 4 (header: "Quy tắc"):**
- question: "Có quy tắc đặc thù nào cho stack này không? (VD: 'không dùng CSS-in-JS', 'luôn dùng Server Components trước', 'cấm any trong TypeScript'...). Nếu không có, chọn 'Không có'."
- options: ["Không có", "Strict TypeScript (cấm any, strict mode, explicit return types)", "Khác (bạn tự nhập)"]

2. Tạo cấu trúc `.claude/` (agent rules — tối giản, chỉ load những gì cần):

**`.claude/rules/project.md`:**
```markdown
# [Tên dự án] — Project Context

[Mô tả dự án từ user]

**Tech Stack:** [stack từ user]. Mock data only (real backend later).

**Scripts:** `npm run dev` / `npm run build`
```

**`.claude/rules/agile.md`:**
```markdown
# Agile Team Workflow

User = **Product Owner**, Claude = **Scrum Master + Dev Team**.

**Sprint docs:** docs/agile/PRD.md (requirements), docs/agile/SPRINT-1.md (backlog), docs/agile/TEAM.md (charter + DoD), docs/design/DESIGN.md (design system).

**Definition of Done:** code builds without errors, features work with mock data, responsive design.

**Cadence:** short 1-2 day sprints in mock phase.
```

**`.claude/rules/model-strategy.md`** (luôn tạo — giúp agent chọn model tiết kiệm chi phí):
```markdown
# Model Selection Strategy

To minimize cost while maintaining quality, agents must select the right model per task.

## General Rules

- **Main thread (current conversation):** stays on the user's chosen model unless instructed otherwise.
- **Sub-agents spawned via Agent tool:** explicitly set `model` based on the table below.
- **Default sub-agent model:** `sonnet` (good balance of speed + cost). Override when needed.

## Model Assignment by Task

### Opus — Plan & Design (expensive, high reasoning)
Only use when deep reasoning is required:
- Architecture design and planning
- Complex bug analysis (before writing a fix)
- PRD review, Sprint planning
- Security review
- Code review of critical paths

### Sonnet — Write & Execute (balanced, moderate cost)
Default for most implementation work:
- Writing and editing code
- Implementing features from an approved plan
- Refactoring (non-trivial but scoped)
- Reviewing PRs
- Running builds and tests

### Haiku — Read & Explore (cheapest, fast)
Use for read-only, low-reasoning tasks:
- Exploring codebase structure
- Searching for files or symbols
- Reading and summarizing docs
- Simple type-checking or linting
- Finding all callers/usages of a function

## Parallel Agent Strategy

When spawning multiple sub-agents in parallel:
- **Plan first** with Opus → produce a plan → get user approval
- **Then execute** with multiple Sonnet agents writing code simultaneously
- **Review** with Opus again if the changes touch critical logic

## Example

```
Plan feature:    Agent(model="opus")   — design the approach
Explore code:    Agent(model="haiku")  — find relevant files (can run in parallel)
Implement:       Agent(model="sonnet") — write the code
Test & build:    Agent(model="sonnet") — verify
```
```

**Nếu user cung cấp quy tắc đặc thù ở câu 4**, tạo thêm `.claude/rules/conventions.md`:
```markdown
# [Tên dự án] — Conventions

[Chép các quy tắc từ câu trả lời của user vào đây, mỗi dòng 1 bullet]
```

**KHÔNG tạo `architecture.md` lúc này** — file đó chỉ có giá trị khi codebase đã hình thành. Sẽ được tạo sau Sprint 1.

3. Tạo `.claude/CLAUDE.md` (hub trung tâm):

```markdown
# [Tên dự án] — Agent Instructions

[các dòng @.claude/rules/... tương ứng với các file đã tạo ở bước 2]

@.claude/rules/model-strategy.md

Before any implementation task, read the relevant rule files from `.claude/rules/`:
- New features: `@.claude/rules/project.md` + `@.claude/rules/agile.md`
- Code changes: `@.claude/rules/architecture.md` (create this file after Sprint 1)
- Sprint planning: `docs/agile/`
- Task delegation: `@.claude/rules/model-strategy.md` (pick right model for sub-agents)
```

4. Ghi đè `CLAUDE.md` gốc với nội dung tối giản:
```
@.claude/CLAUDE.md
```

5. Tạo cấu trúc `docs/` (tài liệu cho cả người và agent):

**`docs/agile/TEAM.md`:**
```markdown
# [Tên dự án] - Agile Team Charter

## Scrum Team

| Role | Name | Responsibilities |
|------|------|-----------------|
| **Product Owner** | Client (User) | Define vision, prioritize backlog, accept/reject increments |
| **Scrum Master** | Claude | Facilitate process, remove blockers, ensure Agile principles |
| **Dev Team** | Claude | Design, development, testing, deployment |

## Definition of Done (DoD)

- Code passes build without errors
- Feature works with mock data (real backend later)
- Responsive on mobile + desktop
- Clean code with proper TypeScript types

## Sprint Cadence

- Sprint Length: 1-2 days (mock phase)
- Daily: Review progress, adjust priorities
- Retro: After each Sprint
```

**`docs/agile/PRD.md`:**
```markdown
# Product Requirements Document - [Tên dự án]

## Vision

[Mô tả dự án từ user]

## Target Users

| Persona | Needs |
|---------|-------|
| **User** | (điền sau khi phân tích) |

## Functional Requirements (Sprint 1)

- (điền sau khi thảo luận với PO)

## Non-functional Requirements

- Responsive design
- Build thành công
- UI chuyên nghiệp
```

**`docs/agile/SPRINT-1.md`:**
```markdown
# Sprint 1 - Backlog

**Goal**: (điền sau khi xác định scope)

## User Stories

| ID | Story | Priority | Points | Status |
|----|-------|----------|--------|--------|
| US-1 | (điền sau) | P0 | | Todo |
| US-2 | (điền sau) | P0 | | Todo |

**Total**: points
```

**`docs/design/DESIGN.md`:**
```markdown
# Design System - [Tên dự án]

## Brand Identity
- **Name**: 
- **Vibe**: 

## Colors

| Token | Value | Usage |
|-------|-------|-------|

## Typography

- **Font**: 

## Components
- 
```

6. Sau khi tạo xong, thông báo: "Đã tạo cấu trúc Agile docs + .claude/rules/. Tiếp theo bạn (PO) muốn định nghĩa Sprint 1 scope như thế nào?" và chờ user chỉ đạo.

7. **Sau khi kết thúc phiên làm việc (project hoàn thành hoặc user rời đi)**, hãy reflect và cập nhật chính skill này nếu phát hiện điểm cần cải thiện:

   - Skill hiện tại có bước nào thừa/thừa không?
   - Có rule nào nên được tự động tạo cho stack phổ biến khác không?
   - Có câu hỏi nào nên hỏi thêm khi init không?
   - Ngôn ngữ/template có cần điều chỉnh cho phù hợp với nhóm người dùng khác không?

   Nếu phát hiện cần sửa, **ghi đè file skill này** (`~/.claude/skills/agile-init/SKILL.md`) với bản cập nhật, và lưu lý do thay đổi vào memory (type: feedback, name: agile-init-skill-evolution).
