# Tasks
- [x] Task 1: 初始化 nextflow.app 项目结构
  - [x] SubTask 1.1: 在当前目录下使用 `create-tauri-app` (配合 Next.js + TypeScript) 创建 `nextflow.app` 目录。
  - [x] SubTask 1.2: 在 Next.js 中集成 Tailwind CSS 和 Shadcn UI 组件库。
- [x] Task 2: 本地环境检测模块 (Rust/Tauri 侧)
  - [x] SubTask 2.1: 在 Tauri 中编写命令（Command），用于检测本地 `java`, `nextflow`, `docker` 是否已安装并返回版本号。
  - [x] SubTask 2.2: 在前端构建“环境状态面板”以展示检测结果。
- [x] Task 3: Schema 解析与动态表单生成 (Next.js 侧)
  - [x] SubTask 3.1: 读取 `isoseq.nf/nextflow_schema.json`，解析参数分组、类型和默认值。
  - [x] SubTask 3.2: 根据解析结果，使用 React Hook Form 动态渲染参数配置表单。
- [x] Task 4: Nextflow 执行引擎与日志监控 (Rust + React)
  - [x] SubTask 4.1: 开发“一键运行测试”功能，默认绑定 `isoseq.nf` 路径和 `testdata` 参数 (`-profile test,docker`)。
  - [x] SubTask 4.2: 在 Rust 侧启动子进程执行 `nextflow run`，通过 Tauri Events 实时将日志流推送到前端的“终端日志视图”中。
- [x] Task 5: 结果管理与报告预览
  - [x] SubTask 5.1: 任务完成后，自动读取工作目录的 `results` 文件夹。
  - [x] SubTask 5.2: 提供 MultiQC HTML 报告的内嵌预览或使用系统默认浏览器打开。

# Task Dependencies
- Task 2 依赖于 Task 1
- Task 3 依赖于 Task 1
- Task 4 依赖于 Task 2 和 Task 3
- Task 5 依赖于 Task 4
