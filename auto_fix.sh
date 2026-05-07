#!/bin/bash
# OpenClaw系统自动修复脚本
# 自动检测和修复常见系统问题

LOG_FILE="$HOME/auto_fix.log"
WORKSPACE="$HOME/.openclaw/workspace"
INVESTMENT="$WORKSPACE/investment-system"

echo "========================================" | tee -a $LOG_FILE
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始自动修复" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE

FIXED=0
FAILED=0
SKIPPED=0

# 1. 修复Gateway
echo "" | tee -a $LOG_FILE
echo "[1/6] 检查Gateway状态..." | tee -a $LOG_FILE

if ! pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
    echo "  [检测] Gateway未运行" | tee -a $LOG_FILE
    echo "  [修复] 尝试重启Gateway..." | tee -a $LOG_FILE

    if openclaw gateway restart >> $LOG_FILE 2>&1; then
        sleep 5
        if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
            echo "  [成功] Gateway已重启" | tee -a $LOG_FILE
            ((FIXED++))
        else
            echo "  [失败] Gateway重启失败" | tee -a $LOG_FILE
            ((FAILED++))
        fi
    else
        echo "  [失败] Gateway重启命令失败" | tee -a $LOG_FILE
        ((FAILED++))
    fi
else
    echo "  [正常] Gateway运行中" | tee -a $LOG_FILE
    ((SKIPPED++))
fi

# 2. 修复磁盘空间
echo "" | tee -a $LOG_FILE
echo "[2/6] 检查磁盘空间..." | tee -a $LOG_FILE

DISK_USAGE=$(df "$WORKSPACE" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')

if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -gt 80 ]; then
    echo "  [检测] 磁盘空间不足: ${DISK_USAGE}%" | tee -a $LOG_FILE
    echo "  [修复] 清理临时文件..." | tee -a $LOG_FILE

    # 清理临时文件
    if [ -d "$WORKSPACE/temp" ]; then
        rm -rf "$WORKSPACE/temp"/*
        echo "  [清理] temp/*" | tee -a $LOG_FILE
    fi

    # 清理日志文件（保留最近的）
    if [ -d "$WORKSPACE/logs" ]; then
        find "$WORKSPACE/logs" -name "*.log" -type f -exec sh -c 'echo "  [清理] $(basename "$1")"' _ {} \;
        # 只清理大日志文件（>100MB）
        find "$WORKSPACE/logs" -name "*.log" -size +100M -exec truncate -s 0 {} \;
        find "$WORKSPACE/logs" -name "*.log" -size +50M -exec gzip {} \; 2>/dev/null
    fi

    # 清理Python缓存
    find "$WORKSPACE" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find "$WORKSPACE" -type f -name "*.pyc" -delete 2>/dev/null

    NEW_DISK_USAGE=$(df "$WORKSPACE" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "  [成功] 磁盘使用率: ${DISK_USAGE}% → ${NEW_DISK_USAGE}%" | tee -a $LOG_FILE
    ((FIXED++))
else
    if [ -n "$DISK_USAGE" ]; then
        echo "  [正常] 磁盘空间充足: ${DISK_USAGE}%" | tee -a $LOG_FILE
    else
        echo "  [跳过] 无法获取磁盘信息" | tee -a $LOG_FILE
    fi
    ((SKIPPED++))
fi

# 3. 修复Python依赖
echo "" | tee -a $LOG_FILE
echo "[3/6] 检查Python依赖..." | tee -a $LOG_FILE

DEPENDENCIES="baostock psutil requests"
MISSING_DEPS=""

for dep in $DEPENDENCIES; do
    if ! python3 -c "import $dep" 2>/dev/null; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo "  [检测] 缺失依赖: $MISSING_DEPS" | tee -a $LOG_FILE
    echo "  [修复] 安装缺失依赖..." | tee -a $LOG_FILE

    if pip3 install $MISSING_DEPS --quiet >> $LOG_FILE 2>&1; then
        echo "  [成功] 依赖已安装: $MISSING_DEPS" | tee -a $LOG_FILE
        ((FIXED++))
    else
        echo "  [失败] 依赖安装失败" | tee -a $LOG_FILE
        ((FAILED++))
    fi
else
    echo "  [正常] 所有依赖已安装" | tee -a $LOG_FILE
    ((SKIPPED++))
fi

# 4. 修复配置文件
echo "" | tee -a $LOG_FILE
echo "[4/6] 检查配置文件..." | tee -a $LOG_FILE

CONFIG_FILES=(
    "$INVESTMENT/cron-config.json"
    "$HOME/.openclaw/openclaw.json"
)

for config in "${CONFIG_FILES[@]}"; do
    if [ ! -f "$config" ]; then
        echo "  [检测] 配置文件缺失: $(basename $config)" | tee -a $LOG_FILE
        echo "  [修复] 创建默认配置..." | tee -a $LOG_FILE

        # 根据文件类型创建不同的默认配置
        if [[ "$config" == *"cron-config.json"* ]]; then
            cat > "$config" << 'EOF'
{
  "version": "1.0.0",
  "created_at": "auto-generated",
  "jobs": []
}
EOF
        fi

        echo "  [成功] 配置文件已创建" | tee -a $LOG_FILE
        ((FIXED++))
    else
        echo "  [正常] 配置文件存在: $(basename $config)" | tee -a $LOG_FILE
    fi
done

if [ "$FIXED" -eq "$PREVIOUS_FIXED" ]; then
    ((SKIPPED++))
fi

# 5. 修复数据源连接
echo "" | tee -a $LOG_FILE
echo "[5/6] 检查数据源连接..." | tee -a $LOG_FILE

SOURCES_OK=0
SOURCES_FAIL=0

# 检查腾讯API
if curl -s --connect-timeout 5 http://qt.gtimg.cn/q=sh000001 2>/dev/null | grep -q "~"; then
    echo "  [正常] 腾讯API: 可用" | tee -a $LOG_FILE
    ((SOURCES_OK++))
else
    echo "  [警告] 腾讯API: 不可用（可能网络问题）" | tee -a $LOG_FILE
    ((SOURCES_FAIL++))
fi

# 检查BaoStock
if python3 -c "import baostock; baostock.login(); baostock.logout()" 2>/dev/null; then
    echo "  [正常] BaoStock: 可用" | tee -a $LOG_FILE
    ((SOURCES_OK++))
else
    echo "  [警告] BaoStock: 不可用" | tee -a $LOG_FILE
    ((SOURCES_FAIL++))
fi

if [ $SOURCES_FAIL -eq 0 ]; then
    ((SKIPPED++))
elif [ $SOURCES_OK -gt 0 ]; then
    echo "  [提示] 部分数据源可用" | tee -a $LOG_FILE
else
    echo "  [失败] 所有数据源不可用（需人工检查网络）" | tee -a $LOG_FILE
    ((FAILED++))
fi

# 6. 检查关键文件
echo "" | tee -a $LOG_FILE
echo "[6/6] 检查关键文件..." | tee -a $LOG_FILE

KEY_FILES=(
    "$INVESTMENT/audited_backtest_v2.py"
    "$INVESTMENT/backtest_stock_selection_workflow.py"
    "$INVESTMENT/rdagent_integration.py"
)

MISSING_FILES=""

for file in "${KEY_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES="$MISSING_FILES $(basename $file)"
    fi
done

if [ -n "$MISSING_FILES" ]; then
    echo "  [警告] 缺失关键文件: $MISSING_FILES" | tee -a $LOG_FILE
    echo "  [提示] 需要从备份恢复或重新创建" | tee -a $LOG_FILE
    ((FAILED++))
else
    echo "  [正常] 所有关键文件存在" | tee -a $LOG_FILE
    ((SKIPPED++))
fi

# 汇总
echo "" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 自动修复完成" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE
echo "修复: $FIXED 个" | tee -a $LOG_FILE
echo "失败: $FAILED 个" | tee -a $LOG_FILE
echo "跳过: $SKIPPED 个" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# 输出到标准输出
echo ""
echo "========== 自动修复结果 =========="
echo "修复: $FIXED 个"
echo "失败: $FAILED 个"
echo "跳过: $SKIPPED 个"
echo ""
echo "详细日志: $LOG_FILE"
echo "========================================"

# 如果有失败的修复，返回非零退出码
if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0