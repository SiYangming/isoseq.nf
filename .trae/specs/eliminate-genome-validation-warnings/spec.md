# 消除 isoseq.nf 基因组参数验证警告 Spec

## Why

运行 `nextflow run main.nf -profile test_local,docker` 时，nf-schema 输出 300+ 条参数验证警告（完整记录于 `isoseq.nf/.trae/genome_error.md`）。警告分为三类：

| 警告类型 | 数量 | 来源 | 根因 |
|---------|------|------|------|
| `--genomes.*`（如 `genomes.GRCh38.fasta`） | ~300 | `conf/igenomes.config` 中 `params.genomes.*` 嵌套对象 | schema 未定义 `genomes` 对象，nf-schema 将每个嵌套键视为未识别参数 |
| `--igenomes_base` | 1 | `nextflow.config` 第 39 行 `igenomes_base = 's3://...'` | schema 的 `reference_genome_options` 缺少 `igenomes_base` 属性 |
| `--validationSchemaIgnoreParams` | 1 | `nextflow.config` 第 78 行（nf-validation 1.x 遗留参数） | nf-schema 2.x 不再实现此参数，但它本身被当作未识别参数触发警告 |

## What Changes

采用**组合方案**（schema + config），针对不同类型的警告使用不同机制：

### 变更 1：修改 `nextflow_schema.json` — 补充缺失的简单参数定义
- **新增** `igenomes_base` 属性到 `reference_genome_options.properties`：
  - `type: "string"`
  - `hidden: true`
  - `default: "s3://ngi-igenomes/igenomes/"`
  - 添加 `description` 和 `fa_icon`
- **说明**：`igenomes_base` 是简单字符串参数，可直接在 schema 中定义以消除其警告
- **不定义 `genomes` 对象**：`genomes` 是包含 30+ 物种、每个物种 8-10 个嵌套键的深层对象（300+ 参数），在 schema 中逐一定义不可维护；nf-schema 对 `additionalProperties: true` 的嵌套对象验证行为不可靠

### 变更 2：修改 `nextflow.config` — 迁移到 nf-schema 2.x 配置语法
- **移除** `params` 块中的 `validationSchemaIgnoreParams = 'genomes,igenomes_base'`（nf-validation 1.x 遗留，nf-schema 2.x 不识别）
- **新增** `params` 块外的 `validation { ignoreParams = ["genomes"] }` 配置作用域
  - 仅需忽略 `genomes`（前缀匹配 `genomes.GRCh38.fasta` 等所有嵌套键）
  - 不再需要忽略 `igenomes_base`（已通过 schema 定义消除）
- **保留** `validationFailUnrecognisedParams`、`validationLenientMode`、`validationShowHiddenParams`、`validate_params` 在 `params` 块中

## Impact

- Affected specs: 无
- Affected code:
  - `isoseq.nf/nextflow_schema.json`（新增 `igenomes_base` 属性）
  - `isoseq.nf/nextflow.config`（替换 `validationSchemaIgnoreParams`，新增 `validation` 作用域）

## ADDED Requirements

### Requirement: nf-schema 2.x 参数忽略配置

The system SHALL 使用 nf-schema 2.x 的 `validation` 配置作用域来忽略深层嵌套的动态参数（如 `genomes.*`），而非旧版 `params.validationSchemaIgnoreParams`。

`validation.ignoreParams` 接受字符串列表，支持前缀匹配：
- `"genomes"` 匹配 `genomes`、`genomes.GRCh38`、`genomes.GRCh38.fasta` 等所有嵌套子参数

#### Scenario: 运行时无 genomes 警告
- **WHEN** 用户运行 `nextflow run main.nf -profile test_local,docker --outdir results/test_isoseq`
- **THEN** 控制台不输出 `--genomes.*` 相关的 `invalid input values` 警告

### Requirement: schema 补充缺失参数定义

The system SHALL 在 `nextflow_schema.json` 的 `reference_genome_options` 中定义 `igenomes_base` 为隐藏字符串属性，使 nf-schema 将其识别为合法参数而非未识别参数。

#### Scenario: 运行时无 igenomes_base 警告
- **WHEN** 用户运行 `nextflow run main.nf -profile test_local,docker --outdir results/test_isoseq`
- **THEN** 控制台不输出 `--igenomes_base` 验证警告

## MODIFIED Requirements

无

## REMOVED Requirements

### Requirement: 旧版 validationSchemaIgnoreParams 参数
**Reason**: `params.validationSchemaIgnoreParams` 是 nf-validation 1.x 的遗留参数，nf-schema 2.x 源码中不再实现此功能，且其本身会触发未识别参数警告
**Migration**: 
- `igenomes_base` → 通过 `nextflow_schema.json` 定义为合法参数
- `genomes` → 通过 `validation { ignoreParams = ["genomes"] }` 前缀匹配忽略

## 设计决策

### 为何 `igenomes_base` 用 schema 而非 ignoreParams？
`igenomes_base` 是简单字符串参数，在 schema 中定义后：
1. nf-schema 可对其进行类型检查
2. `nf-core launch` 时可显示默认值
3. 消除警告的同时保留参数可见性

### 为何 `genomes` 用 ignoreParams 而非 schema？
`genomes` 是 `conf/igenomes.config` 动态注入的深层嵌套对象：
1. 30+ 物种 × 8-10 键 = 300+ 参数，逐一定义不可维护
2. 物种列表可能变化（自定义 genome），schema 无法预知所有键
3. nf-schema 对 `type: "object"` + `additionalProperties: true` 的嵌套验证行为不可靠
4. `validation.ignoreParams` 的前缀匹配机制（`"genomes"` 匹配 `genomes.*`）是 nf-schema 官方推荐的处理方式

## Reference

- nf-schema 2.x 源码：`ValidationConfig.groovy` 定义 `validation.ignoreParams`（`Set<CharSequence>` 类型）
- nf-schema 2.x 源码：`ParameterValidator.groovy` 实现前缀匹配逻辑 `dotParam.startsWith(ignoreParam + '.')`
- nf-schema v2.4.2 CHANGELOG：修复了 `validation.ignoreParams` 对嵌套参数的忽略
- 迁移指南：`docs/migration_guide.md` 映射 `params.validationSchemaIgnoreParams` → `validation.ignoreParams`
- 触发文件：`isoseq.nf/.trae/genome_error.md` 记录了完整的警告输出
