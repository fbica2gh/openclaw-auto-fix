#!/usr/bin/env python3
"""
OpenClaw系统健康监控脚本

监控范围：
1. Gateway服务状态
2. 数据源连接状态
3. 磁盘空间使用
4. Python依赖完整性
5. 配置文件完整性
"""

import subprocess
import json
import os
import psutil
from datetime import datetime
from typing import Dict, List, Optional

class SystemHealthMonitor:
    """系统健康监控器"""

    def __init__(self):
        self.openclaw_path = os.path.expanduser('~/.openclaw')
        self.workspace_path = os.path.join(self.openclaw_path, 'workspace')
        self.investment_path = os.path.join(self.workspace_path, 'investment-system')
        self.issues = []

    def check_all(self) -> Dict:
        """执行所有健康检查"""
        results = {
            'timestamp': datetime.now().isoformat(),
            'checks': {},
            'issues': []
        }

        # Gateway检查
        results['checks']['gateway'] = self.check_gateway()

        # 数据源检查
        results['checks']['data_sources'] = self.check_data_sources()

        # 磁盘空间检查
        results['checks']['disk'] = self.check_disk()

        # Python依赖检查
        results['checks']['dependencies'] = self.check_dependencies()

        # 配置文件检查
        results['checks']['config_files'] = self.check_config_files()

        results['issues'] = self.issues

        return results

    def check_gateway(self) -> Dict:
        """检查Gateway状态"""
        result = {'status': 'unknown', 'details': {}}

        try:
            # 检查进程
            gateway_process = subprocess.run(
                ['pgrep', '-f', 'openclaw.*gateway'],
                capture_output=True
            )

            if gateway_process.returncode == 0:
                pids = gateway_process.stdout.decode().strip().split('\n')
                result['status'] = 'running'
                result['details']['pids'] = pids
            else:
                result['status'] = 'stopped'
                result['details']['error'] = 'Gateway进程未运行'
                self.add_issue('Gateway未运行', 'critical')

        except Exception as e:
            result['status'] = 'error'
            result['details']['error'] = str(e)

        return result

    def check_data_sources(self) -> Dict:
        """检查数据源状态"""
        result = {'status': 'unknown', 'sources': {}}

        # 检查BaoStock
        result['sources']['baostock'] = self.check_baostock()

        # 检查腾讯API
        result['sources']['tencent'] = self.check_tencent_api()

        return result

    def check_baostock(self) -> Dict:
        """检查BaoStock"""
        result = {'status': 'unknown', 'details': {}}

        try:
            import baostock as bs
            lg = bs.login()

            if lg.error_code == '0':
                result['status'] = 'available'
            else:
                result['status'] = 'unavailable'
                result['details']['error'] = lg.error_msg

            bs.logout()

        except ImportError:
            result['status'] = 'not_installed'
            result['details']['error'] = 'BaoStock未安装'

        except Exception as e:
            result['status'] = 'error'
            result['details']['error'] = str(e)

        return result

    def check_tencent_api(self) -> Dict:
        """检查腾讯API"""
        result = {'status': 'unknown', 'details': {}}

        try:
            response = subprocess.run(
                ['curl', '-s', '--connect-timeout', '5', 'http://qt.gtimg.cn/q=sh000001'],
                capture_output=True,
                timeout=10
            )

            if response.returncode == 0 and b'~' in response.stdout:
                result['status'] = 'available'
            else:
                result['status'] = 'unavailable'

        except Exception as e:
            result['status'] = 'error'
            result['details']['error'] = str(e)

        return result

    def check_disk(self) -> Dict:
        """检查磁盘空间"""
        result = {'status': 'unknown', 'details': {}}

        try:
            disk = psutil.disk_usage(self.workspace_path)

            result['details']['percent'] = disk.percent
            result['details']['used_gb'] = disk.used / (1024**3)
            result['details']['free_gb'] = disk.free / (1024**3)

            if disk.percent > 90:
                result['status'] = 'critical'
                self.add_issue('磁盘空间严重不足', 'critical')
            elif disk.percent > 80:
                result['status'] = 'warning'
                self.add_issue('磁盘空间不足', 'warning')
            else:
                result['status'] = 'ok'

        except Exception as e:
            result['status'] = 'error'
            result['details']['error'] = str(e)

        return result

    def check_dependencies(self) -> Dict:
        """检查Python依赖"""
        result = {'status': 'unknown', 'details': {}}

        dependencies = ['baostock', 'psutil', 'requests']
        missing = []

        for dep in dependencies:
            try:
                __import__(dep)
            except ImportError:
                missing.append(dep)

        if missing:
            result['status'] = 'missing'
            result['details']['missing'] = missing
            self.add_issue(f'缺少Python依赖: {", ".join(missing)}', 'warning')
        else:
            result['status'] = 'installed'

        return result

    def check_config_files(self) -> Dict:
        """检查配置文件"""
        result = {'status': 'unknown', 'details': {}}

        config_files = [
            os.path.join(self.openclaw_path, 'openclaw.json'),
            os.path.join(self.investment_path, 'cron-config.json')
        ]

        missing = []

        for config_file in config_files:
            if not os.path.exists(config_file):
                missing.append(os.path.basename(config_file))

        if missing:
            result['status'] = 'incomplete'
            result['details']['missing'] = missing
            self.add_issue(f'缺少配置文件: {", ".join(missing)}', 'warning')
        else:
            result['status'] = 'complete'

        return result

    def add_issue(self, message: str, severity: str = 'warning'):
        """添加问题记录"""
        self.issues.append({
            'message': message,
            'severity': severity,
            'timestamp': datetime.now().isoformat()
        })


def main():
    """主函数"""
    monitor = SystemHealthMonitor()
    results = monitor.check_all()

    # 输出结果
    print(json.dumps(results, indent=2, ensure_ascii=False))

    # 返回退出码
    if any(issue['severity'] == 'critical' for issue in results['issues']):
        return 2
    elif results['issues']:
        return 1
    return 0


if __name__ == '__main__':
    exit(main())