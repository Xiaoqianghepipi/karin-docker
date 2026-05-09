#!/bin/sh
set -e

# 通过 Karin 暴露的 7777 端口判断服务健康状态。
node - <<'NODE'
const ac = new AbortController()
const timer = setTimeout(() => ac.abort(), 4000)

# 只要接口返回可解析的 JSON 且 code 为 200，就认为容器健康。
fetch('http://127.0.0.1:7777', { signal: ac.signal })
  .then((res) => res.text())
  .then((text) => {
    clearTimeout(timer)
    let data
    try {
      data = JSON.parse(text)
    } catch {
      process.exit(1)
    }

    if (data && data.code === 200) {
      process.exit(0)
    }

    process.exit(1)
  })
  .catch(() => process.exit(1))
NODE
