# OpenClaw Auto-Fix System

🤖 OpenClaw系统自动监控与自主修复机制

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/fbica2gh/openclaw-auto-fix?style=social)](https://github.com/fbica2gh/openclaw-auto-fix/stargazers)

---

## 📊 项目简介

这是一个为OpenClaw系统设计的自动化监控和自主修复解决方案，能够：

- ✅ **自动检测系统异常**（Gateway、数据源、磁盘空间等）
- ✅ **自主修复常见问题**（服务重启、清理缓存等）
- ✅ **发送告警通知**（飞书、日志）
- ✅ **记录详细的修复日志**

---

## 🚀 快速开始

### **安装**

```bash
# 克隆仓库
git clone https://github.com/fbica2gh/openclaw-auto-fix.git
cd openclaw-auto-fix

# 赋予执行权限
chmod +x auto_fix.sh

# 立即运行测试
./auto_fix.sh
```

### **配置Cron（可选）**

```bash
# 编辑crontab
crontab -e

# 添加以下行（每小时检查一次）
0 * * * * /path/to/auto_fix.sh >> ~/auto_fix.log 2>&1
```

---

## 📖 功能特性

### **1. 自动健康检查**

- Gateway服务状态
- 数据源连接（BaoStock、腾讯API）
- 磁盘空间使用
- Python依赖完整性
- 配置文件完整性

### **2. 自主修复机制**

- 自动重启Gateway
- 清理临时文件和缓存
- 安装缺失的Python依赖
- 创建缺失的配置文件

### **3. 告警通知**

- 记录详细日志
- 支持飞书消息通知（可选）
- 记录修复结果

---

## 🔧 修复能力

| 问题类型 | 能否修复 | 修复方式 |
|---------|---------|---------|
| Gateway停止 | ✅ | openclaw gateway restart |
| 磁盘空间不足 | ✅ | 清理临时文件、缓存 |
| Python依赖缺失 | ✅ | pip install |
| 配置文件缺失 | ✅ | 创建默认配置 |
| 日志文件过大 | ✅ | 清空或压缩 |
| 网络问题 | ❌ | 需人工检查 |
| 代码错误 | ❌ | 需人工修复 |

---

## 📊 监控指标

### **Gateway监控**
- 进程状态
- 端口监听
- 日志错误

### **数据源监控**
- BaoStock连接
- 腾讯API连接
- Qlib数据完整性

### **系统资源监控**
- CPU使用率（阈值：80%）
- 内存使用率（阈值：85%）
- 磁盘使用率（阈值：90%）

---

## 📝 使用示例

### **手动运行**

```bash
# 运行自动修复脚本
./auto_fix.sh

# 查看修复日志
cat ~/auto_fix.log
```

### **Python健康检查**

```bash
# 运行Python监控脚本
python3 health_monitor.py
```

### **自定义配置**

编辑`auto_fix.sh`中的变量：

```bash
LOG_FILE="$HOME/auto_fix.log"           # 日志文件路径
WORKSPACE="$HOME/.openclaw/workspace"    # OpenClaw工作目录
INVESTMENT="$WORKSPACE/investment-system"
```

---

## 📝 日志格式

```
========================================
[2026-05-07 20:27:20] 开始自动修复
========================================

[1/6] 检查Gateway状态...
  [正常] Gateway运行中

[2/6] 检查磁盘空间...
  [检测] 磁盘空间不足: 98%
  [修复] 清理临时文件...
  [成功] 磁盘使用率: 98% → 96%

========================================
[2026-05-07 20:27:35] 自动修复完成
========================================
修复: 1 个
失败: 0 个
跳过: 5 个
========================================
```

---

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

### **贡献方式**
1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

---

## 📄 开源协议

本项目采用 MIT License - 详见 [LICENSE](LICENSE) 文件

---

## ⭐ Star History

如果这个项目对您有帮助，请给个Star！⭐

---

## 📧 联系方式

- **Issues**: https://github.com/fbica2gh/openclaw-auto-fix/issues
- **仓库地址**: https://github.com/fbica2gh/openclaw-auto-fix

---

## 🎯 路线图

- [ ] 支持更多数据源监控
- [ ] 集成更多通知渠道（邮件、Slack等）
- [ ] 添加Web仪表板
- [ ] 支持分布式监控
- [ ] 添加预测性维护功能

---

## 🙏 致谢

感谢所有贡献者的支持！

---

**Made with ❤️ by OpenClaw Community**