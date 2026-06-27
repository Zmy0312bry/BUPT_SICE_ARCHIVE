#!/bin/bash
# 4: 求 test.txt 文件中所有数字之和
rm -f output.txt

# 区分包含 /8 和不包含 /8 的情况

(
echo "1. 包含 /8"

# 方法: 先将 /8 替换为 8，然后提取所有数字求和
sum_with_8=$(cat test.txt | sed 's|/8|8|g' | tr -s ' ' '\n' | grep -E '^[0-9]+$' | paste -sd+ | bc)

echo "数字之和: $sum_with_8"
echo ""
) > output.txt

(
echo "2. 不包含 /8"

# 方法: 先删除 /8，然后提取所有数字求和
# 注意: 这里 /8 被整体删除，不作为数字处理
content=$(cat test.txt | sed 's|/8||g')
sum_without_8=$(echo "$content" | tr -s ' ' '\n' | grep -E '^[0-9]+$' | paste -sd+ | bc)

echo "数字之和: $sum_without_8"
) >> output.txt

cat output.txt
