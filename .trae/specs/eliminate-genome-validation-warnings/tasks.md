# Tasks

- [x] Task 1: 修改 `nextflow_schema.json` — 补充 `igenomes_base` 属性定义
  - [x] SubTask 1.1: 在 `reference_genome_options.properties` 中新增 `igenomes_base` 属性，设为 `type: "string"`、`hidden: true`、`default: "s3://ngi-igenomes/igenomes/"`，并添加 `description` 和 `fa_icon`
  - [x] SubTask 1.2: 确认 JSON 语法正确（逗号、缩进与现有属性一致）

- [x] Task 2: 修改 `nextflow.config` — 替换旧版 validationSchemaIgnoreParams
  - [x] SubTask 2.1: 从 `params {}` 块中移除 `validationSchemaIgnoreParams = 'genomes,igenomes_base'` 行
  - [x] SubTask 2.2: 在 `params {}` 块之后（`includeConfig 'conf/base.config'` 之前）添加 `validation { ignoreParams = ["genomes"] }` 配置作用域

- [x] Task 3: 运行测试验证无警告
  - [x] SubTask 3.1: 运行 `nextflow run main.nf -profile test_local,docker --outdir results/test_isoseq`
  - [x] SubTask 3.2: 确认控制台不再输出 `--genomes.*`、`--igenomes_base`、`--validationSchemaIgnoreParams`、`--monochromeLogs`、`--large_genome` 警告（grep 输出为空，管道 "Pipeline completed successfully"）

# Task Dependencies
- [Task 3] 依赖 [Task 1] 和 [Task 2] 完成
- [Task 1] 和 [Task 2] 可并行执行
