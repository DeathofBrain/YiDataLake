# YiDataLake 第一阶段：Apache Iceberg 数据湖

这是一个面向学习、开发和 YiGraph 接入验证的单机数据湖。它参考 Apache Iceberg 的 Spark Quickstart 组合，使用 Docker Compose 启动：

- **MinIO**：保存 Parquet 数据文件和 Iceberg 元数据文件，模拟 S3 对象存储。
- **Iceberg REST Catalog**：管理命名空间、表名和表当前元数据位置。
- **SQLite**：持久化 REST Catalog 的登记信息。
- **Spark + Jupyter**：写入、查询和维护 Iceberg 表。

JupyterLab 已安装 Project Jupyter 社区维护的简体中文语言包，并默认使用中文界面。镜像内置的英文示例已由本项目的中文 Notebook 替换。

> 这是本地基线，不是生产集群。`iceberg-rest-fixture` 是官方测试/演示服务，生产环境应替换为高可用 Catalog。

为了让 REST fixture 能写入新建的 SQLite Docker 卷，本地编排让该容器以 `root` 运行。这也是它不能原样进入生产环境的原因之一。

## 先回答：Iceberg 带元数据管理层吗？

答案是“**有元数据机制，但不等于自带完整的企业元数据平台**”。

Iceberg 每张表会自行维护：

- `metadata.json`：表结构、分区规则、属性和当前快照。
- Manifest List / Manifest：每次快照包含哪些数据文件及统计信息。
- Snapshot：每次提交形成一个不可变版本，可用于时间旅行和回滚。

这些文件和数据一起存放在对象存储中。除此之外，还需要一个 **Catalog** 保存“`yigraph.person_events` 这个名字当前指向哪个 `metadata.json`”以及命名空间信息。本项目用 Iceberg REST Catalog 完成这一层。

Catalog 不是数据血缘、业务术语、数据质量、审批权限等“数据治理平台”。如果团队后续需要这些能力，可以再接入 OpenMetadata、DataHub 或 Apache Atlas。

面向 YiGraph 意图 Agent 的更完整方案见 [异构数据源元数据控制层调研](docs/异构数据源元数据控制层调研.md)：建议把 Iceberg 保留为表事实/快照底座，在其上增加语义抽取、实体对齐、质量、权限、lineage 和 Agent typed contract 控制面。

```text
用户 / YiGraph / 作业
        |
        v
 Spark 计算引擎
        |
        +------> Iceberg REST Catalog ------> SQLite Catalog 数据
        |          表名、命名空间、当前指针
        |
        +------> MinIO (S3)
                   Parquet 数据 + metadata.json + manifests
```

## 1. 启动

前置条件：Docker Desktop 已启动，并建议至少分配 4 GB 内存。

Windows 下可以直接双击项目根目录的 `start-datalake.bat`。保持该窗口开启；服务会在后台运行，按一次 `Ctrl+C` 后，脚本会停止并删除本项目的全部容器和网络，但保留数据卷。脚本不会再询问 `Terminate batch job (Y/N)?`。

也可以在终端手动启动：

```powershell
docker compose up -d
docker compose ps
```

首次启动需要下载镜像，耗时取决于网络。服务入口：

| 服务 | 地址 | 用途 |
|---|---|---|
| Jupyter | http://localhost:8888 | 交互式 Spark 开发 |
| MinIO Console | http://localhost:9001 | 查看对象和 Iceberg 文件 |
| Iceberg REST | http://localhost:8181 | Catalog API |
| Spark UI | http://localhost:8080 | 查看 Spark 作业 |

Jupyter 首页包含两份中文教程：

- `01-Iceberg中文入门.ipynb`
- `02-YiGraph图数据建模.ipynb`

更多术语和资料来源见 [Iceberg 中文学习指南](docs/Iceberg中文学习指南.md)。

MinIO 本地默认账号为 `admin`，密码为 `password123`。只允许用于本机学习；共享环境请先复制 `.env.example` 为 `.env` 并修改密码。

## 2. 跑通第一张表

示例会建表、写入三行数据、演示增加字段，并查看快照和底层数据文件：

```powershell
docker compose exec -T spark-iceberg spark-sql -f /home/iceberg/examples/quickstart.sql
```

成功时会看到 `Alice`、`Bob` 三条事件、多个 snapshot，以及 MinIO 中的 Parquet 文件路径。示例使用 `CREATE OR REPLACE TABLE`，所以可以重复执行。

也可以进入交互式 SQL：

```powershell
docker compose exec spark-iceberg spark-sql
```

进入后可执行：

```sql
SHOW NAMESPACES IN lake;
SHOW TABLES IN lake.yigraph;
SELECT * FROM lake.yigraph.person_events;
SELECT * FROM lake.yigraph.person_events.snapshots;
```

## 3. 你刚刚建立了什么

普通数据湖只是在对象存储里放文件，容易出现目录混乱、并发写坏数据和无法可靠修改表结构的问题。Iceberg 在文件之上增加“表”的语义：

1. Spark 写出新的 Parquet 文件。
2. Iceberg 生成 manifest 和新的 `metadata.json`。
3. Catalog 原子地把表的当前指针切换到新版本。
4. 旧快照仍存在，因此可以时间旅行；清理旧快照前也能回滚。

Iceberg 不负责计算，也不等同于存储。它是位于 Spark/Trino/Flink 与 S3/HDFS 之间的**开放表格式**。

## 4. 停止、重启与清空

停止但保留数据：

```powershell
docker compose down
```

再次执行 `docker compose up -d` 后，MinIO 数据和 Catalog 登记仍保留在 Docker 卷中。

彻底清空教学环境（会删除表、对象和 Catalog）：

```powershell
docker compose down -v
```

## 5. 常见检查

```powershell
docker compose ps
docker compose logs --tail 100 iceberg-rest
docker compose logs --tail 100 spark-iceberg
docker compose logs --tail 100 minio
```

如果端口 `9000`、`9001`、`8181`、`8888` 或 `8080` 已被占用，请修改 `compose.yaml` 中冒号左边的主机端口。

## 6. YiGraph 下一步如何接入

建议先把图数据映射为两类 Iceberg 表：

- 顶点表：稳定的 `vertex_id`、类型、属性和更新时间。
- 边表：`edge_id`、`src_id`、`dst_id`、边类型、属性和更新时间。

YiGraph 的导入作业通过 Spark 读取这些表；增量同步可以依据快照或业务更新时间读取变化。不要让 YiGraph 直接解析 Iceberg 的 metadata/manifest 文件，应通过 Spark、Flink、Trino 或 Iceberg SDK 访问表。

## 7. 上生产前必须替换或补齐

- 将 `iceberg-rest-fixture + SQLite` 替换为 Polaris、Nessie、Hive Metastore、云厂商 Catalog，或自建高可用 REST Catalog + 外部数据库。
- 将单机 MinIO 替换为高可用对象存储，并配置版本控制、生命周期和备份。
- 固定所有镜像版本，建立升级和兼容性测试；本地 Spark 镜像暂用 `latest` 是为了跟随官方 Quickstart。
- 增加 TLS、身份认证、最小权限、密钥管理、审计和网络隔离。
- 增加压缩小文件、过期快照、删除孤儿文件和统计信息维护任务。
- 增加监控、告警、灾备演练，以及 Catalog 和对象存储的一致备份。

## 参考

- [Apache Iceberg 文档](https://iceberg.apache.org/docs/latest/)
- [Spark + Iceberg Quickstart](https://iceberg.apache.org/spark-quickstart/)
- [Iceberg REST Catalog 规范](https://iceberg.apache.org/rest-catalog-spec/)
