FROM tabulario/spark-iceberg:latest

RUN python -m pip install --no-cache-dir \
    jupyterlab-language-pack-zh-CN==4.3.post3

COPY overrides.json /usr/local/share/jupyter/lab/settings/overrides.json
