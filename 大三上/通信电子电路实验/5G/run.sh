#!/bin/bash

# 5G NR SSB解析实验自动运行脚本
# 功能：在命令行模式下运行MATLAB，执行main.m并保存所有图像

echo "================================================"
echo "  5G NR SSB 信号解析实验"
echo "  自动运行脚本"
echo "================================================"
echo ""

# 检查MATLAB是否安装
if ! command -v matlab &> /dev/null
then
    echo "错误: 未找到MATLAB命令"
    echo "请确保MATLAB已安装并添加到系统PATH中"
    exit 1
fi

# 创建assets目录（如果不存在）
if [ ! -d "assets" ]; then
    echo "创建assets目录..."
    mkdir -p assets
fi

# 清空之前的图像文件（可选）
read -p "是否清空assets文件夹中的旧图像? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "清空assets目录..."
    rm -f assets/*.png assets/*.jpg assets/*.fig
fi

echo ""
echo "开始运行MATLAB程序..."
echo "------------------------------------------------"
echo ""

# 使用MATLAB命令行模式运行
# -nodisplay: 不显示图形界面
# -nosplash: 不显示启动画面
# -nodesktop: 不启动桌面环境
# -r: 运行指定的MATLAB命令
# -logfile: 保存日志文件

matlab -nodisplay -nosplash -nodesktop -r "try; run('main.m'); catch ME; fprintf('错误: %s\n', ME.message); exit(1); end; exit(0);" -logfile matlab_output.log

# 检查MATLAB执行结果
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "  MATLAB程序执行成功！"
    echo "================================================"
    echo ""
    echo "生成的图像已保存到 assets/ 目录"
    echo "MATLAB运行日志已保存到 matlab_output.log"
    echo ""

    # 列出生成的图像文件
    if [ "$(ls -A assets/ 2>/dev/null)" ]; then
        echo "生成的图像文件："
        ls -lh assets/
    else
        echo "警告: assets目录中没有找到图像文件"
    fi
else
    echo ""
    echo "================================================"
    echo "  错误: MATLAB程序执行失败"
    echo "================================================"
    echo ""
    echo "请查看 matlab_output.log 了解详细错误信息"
    exit 1
fi

echo ""
echo "完成！"
