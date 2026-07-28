# Tasks

- [x] Task 1: 修复 `conf/test_local.config` 资源限制和文件覆盖
  - [x] SubTask 1.1: 添加 `process { withLabel:process_low { cpus=2; memory=4.GB } }`
  - [x] SubTask 1.2: 添加 `process { withLabel:process_medium { cpus=4; memory=8.GB } }`
  - [x] SubTask 1.3: 添加 `process { withLabel:process_high { cpus=4; memory=8.GB } }`
  - [x] SubTask 1.4: 添加 `trace.overwrite = true`、`report.overwrite = true`、`timeline.overwrite = true`

- [x] Task 2: 检查并修复其他 `_local.config` 文件
  - [x] SubTask 2.1: 检查 `test_lima_entrypoint_local.config`
  - [x] SubTask 2.2: 检查 `test_isoseq3_refine_entrypoint_local.config`
  - [x] SubTask 2.3: 检查 `test_bamtools_convert_entrypoint_local.config`
  - [x] SubTask 2.4: 检查 `test_minimap2_local.config`
  - [x] SubTask 2.5: 检查 `test_minimap2_map_entrypoint_local.config`
  - [x] SubTask 2.6: 检查 4 个 `test_ultra_*_local.config`
  - [x] SubTask 2.7: 如有需要，为上述文件添加同样的资源覆盖和 overwrite 设置

- [x] Task 3: 运行测试验证
  - [x] SubTask 3.1: 运行 `nextflow run main.nf -profile test_local,docker --outdir results/test_isoseq`
  [x] SubTask 3.2: 确认 pipeline 不因资源超限而失败
  - [x] SubTask 3.3: 确认重复运行不抛出文件已存在错误

# Task Dependencies
- [Task 2] 依赖 [Task 1] 完成（确定具体修改内容）
- [Task 3] 依赖 [Task 1、2] 完成
