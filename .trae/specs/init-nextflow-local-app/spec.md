# Nextflow 本地可视化应用 (nextflow.app) 规格说明

## Why
原有的 Nextflow 生信流程（如 `isoseq.nf`）依赖命令行交互，对非生物信息学背景的用户（如实验人员、临床医生）使用门槛较高。基于之前分析报告（`nextflow_app_plan.md`）的规划，我们需要构建一个开箱即用的本地桌面应用客户端，通过图形界面降低使用难度，并利用 `isoseq.nf` 中的 `testdata` 快速验证该客户端的可行性。

## What Changes
- 在项目根目录（`/Users/siyangming/nextflow_nf_core`）下新建 `nextflow.app` 目录。
- **架构建议与选型**：推荐使用 **Tauri (Rust) + Next.js (React 19)** 组合。相比 Electron，Tauri 内存占用极低且对底层文件系统/命令行子进程操作具有更好的性能，非常适合作为生信工具的本地客户端。
- **动态 UI 渲染**：解析 `isoseq.nf/nextflow_schema.json` 自动生成表单，替代手动修改 `nextflow.config`。
- **内置测试集快速启动**：深度集成 `isoseq.nf/testdata` 数据，提供“一键运行测试 (Run Test Profile)”的功能。
- **本地命令执行器**：在 Rust 后台（Tauri）封装 `nextflow run` 命令执行器，实时捕获标准输出和标准错误流（stdout/stderr），推送到前端展示。
- **结果可视化集成**：任务结束后自动扫描 `results` 目录并提供 MultiQC 等 HTML 报告的内置预览。

## Impact
- Affected code: 新增 `nextflow.app` 独立目录，对原有 Nextflow 流程（如 `isoseq.nf`）代码无任何破坏性修改。
- Affected specs: 增加了全新的本地客户端构建流程。

## ADDED Requirements
### Requirement: 基础环境检测与向导
系统必须能在启动时检测本地依赖环境，确保 Nextflow 可用。
#### Scenario: 环境依赖就绪
- **WHEN** 用户打开 `nextflow.app`
- **THEN** 系统自动检测 `java -version`、`nextflow -v` 及 `docker/conda`，并在界面显示状态绿灯。

### Requirement: 动态参数表单与测试数据挂载
系统必须能根据 schema 动态渲染输入项，并允许用户一键载入内置的 `testdata`。
#### Scenario: 运行 IsoSeq 测试流程
- **WHEN** 用户点击“加载 isoseq 测试用例”并点击“运行”
- **THEN** 前端自动填充 `testdata/samplesheet.csv` 等配置，后台触发 `nextflow run isoseq.nf -profile test,docker ...`，并展示实时运行日志和进度。

## MODIFIED Requirements
无

## REMOVED Requirements
无
