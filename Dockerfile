# # 第一阶段：构建依赖
FROM python:3.13-rc-slim as builder

WORKDIR /app
COPY requirements.txt .

# 合并清理步骤到单个 RUN 指令
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc python3-dev \
 && pip3 install --user --no-cache-dir -r requirements.txt

# 第二阶段：运行环境
FROM python:3.13-rc-slim

# 合并运行时依赖安装步骤
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
  
WORKDIR /app

# 精确复制 Python 依赖
COPY --from=builder /root/.local/lib/python3.13/site-packages /home/captcha/.local/lib/python3.13/site-packages
COPY --from=builder /root/.local/bin /home/captcha/.local/bin
COPY . .

# 清理 Python 缓存和临时文件
RUN find /app -name "*.pyc" -delete \
 && find /app -name "__pycache__" -delete \
 && find /home/captcha/.local -name "*.pyc" -delete \
 && find /home/captcha/.local -type d -name "__pycache__" -exec rm -rf {} +

RUN useradd -u 6801 -m -s /bin/bash captcha && \
    chown -R captcha:captcha /home/captcha /app

USER captcha

# 环境变量与清理
ENV PATH=/home/captcha/.local/bin:$PATH \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PYTHONDONTWRITEBYTECODE=1

CMD ["python3", "main.py"]
