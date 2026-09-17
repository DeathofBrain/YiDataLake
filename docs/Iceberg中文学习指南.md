# Apache Iceberg 中文学习指南

## 资料选择说明

截至 2026-09-17，Apache Iceberg 官方网站没有维护完整的中文站点；GitHub 上也没有找到由 Apache 或活跃社区持续维护、版本可与当前 Iceberg 对齐的完整中文翻译仓库。因此本项目没有复制来源和版本不明的博客内容，而是采用以下方式：

- JupyterLab 界面使用 Project Jupyter 官方组织维护的简体中文语言包。
- 本地 Notebook 依据 Apache Iceberg 官方文档和官方 Spark Quickstart 独立编写，并针对本项目实际环境验证。
- 关键术语同时保留英文，便于继续阅读官方资料和排查错误。

## 核心术语

| 英文 | 常用中文 | 在本项目中的含义 |
|---|---|---|
| Table format | 表格式 | 规定数据文件、元数据和提交如何组织 |
| Catalog | 目录服务 | 管理命名空间、表名和当前元数据指针 |
| Snapshot | 快照 | 一次原子提交形成的表版本 |
| Manifest | 清单文件 | 记录数据文件及统计信息 |
| Schema evolution | 模式演进 | 安全增加、删除或重命名字段 |
| Hidden partitioning | 隐藏分区 | 查询者过滤业务列，无需处理物理分区目录 |
| Time travel | 时间旅行 | 按快照 ID 或时间读取历史表版本 |
| Compaction | 文件合并 | 将大量小文件重写为较少的大文件 |

## 推荐学习顺序

1. 打开 `01-Iceberg中文入门.ipynb`，理解表、快照和元数据表。
2. 打开 `02-YiGraph图数据建模.ipynb`，建立顶点表和边表。
3. 阅读官方 Spark DDL、写入和查询文档。
4. 学习表维护，包括小文件合并、快照过期和孤儿文件清理。
5. 再设计 YiGraph 的全量导入与增量同步协议。

## 元数据分层

```text
REST Catalog / SQLite
  保存：命名空间、表名、当前 metadata.json 的位置

MinIO / warehouse
  保存：metadata.json、manifest list、manifest、Parquet 数据文件
```

Catalog 丢失时，数据文件可能仍在，但正常按表名访问会失败。对象存储丢失时，Catalog 中只剩无效指针。因此生产备份必须同时覆盖 Catalog 数据库和对象存储，并保证恢复点一致。

## Jupyter 中文界面来源

- 项目：[JupyterLab Language Packs](https://github.com/jupyterlab/language-packs)
- 中文包：[jupyterlab-language-pack-zh-CN](https://pypi.org/project/jupyterlab-language-pack-zh-CN/)
- 本项目固定版本：`4.3.post3`，对应镜像中的 JupyterLab `4.3.5`
- 许可证：BSD License

## 英文官方资料

- [Apache Iceberg 文档](https://iceberg.apache.org/docs/latest/)
- [Spark 快速入门](https://iceberg.apache.org/spark-quickstart/)
- [Spark DDL](https://iceberg.apache.org/docs/latest/spark-ddl/)
- [Spark 查询](https://iceberg.apache.org/docs/latest/spark-queries/)
- [Spark Procedures](https://iceberg.apache.org/docs/latest/spark-procedures/)
- [REST Catalog 规范](https://iceberg.apache.org/rest-catalog-spec/)
