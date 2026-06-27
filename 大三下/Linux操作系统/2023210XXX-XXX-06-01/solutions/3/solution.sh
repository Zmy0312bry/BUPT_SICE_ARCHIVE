#!/bin/bash
# 3: 将 domains.txt 中的重复 '.' 字符变换为只有一个
rm -f output.txt

tr -s '.' < domains.txt > output.txt

cat output.txt
