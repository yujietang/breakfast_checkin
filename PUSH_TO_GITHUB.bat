@echo off
chcp 65001 >nul
echo ==========================================
echo    推送代码到 GitHub
echo ==========================================
echo.

cd /d w:\work_dir\breakfast_checkin_app

echo [1/4] 检查 Git 状态...
git status --short
echo.

echo [2/4] 添加所有更改...
git add .
echo ✓ 已添加所有文件
echo.

echo [3/4] 提交更改...
git commit -m "feat: 升级v2版本 - 添加成就、商店、急救卡系统、单元测试"
echo ✓ 已提交
echo.

echo [4/4] 推送到远程仓库...
git push origin main
echo.

if %errorlevel% == 0 (
    echo ==========================================
    echo    ✓ 推送成功！
    echo ==========================================
    echo.
    echo 查看代码：
    echo https://github.com/yujietang/breakfast_checkin
) else (
    echo ==========================================
    echo    ✗ 推送失败
    echo ==========================================
    echo.
    echo 尝试使用：git push origin master
)

pause
