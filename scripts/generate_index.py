#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动生成 BUPT_SICE_ARCHIVE 项目的目录索引
"""

import os
import json
from pathlib import Path
from urllib.parse import quote

def should_ignore(name):
    """判断是否应该忽略该文件或目录"""
    ignore_list = ['.git', '.github', 'scripts', 'docs', '__pycache__',
                   '.DS_Store', 'node_modules', '.gitignore', '.gitmodules',
                   'LICENSE', 'README.md']
    return name in ignore_list or name.startswith('.')

def get_github_url(repo_owner, repo_name, path):
    """生成 GitHub 文件/目录的 URL"""
    base_url = f"https://github.com/{repo_owner}/{repo_name}"
    encoded_path = '/'.join([quote(p, safe='') for p in path.split('/')])
    return f"{base_url}/tree/main/{encoded_path}"

def get_file_url(repo_owner, repo_name, path):
    """生成 GitHub 文件下载 URL"""
    base_url = f"https://github.com/{repo_owner}/{repo_name}"
    encoded_path = '/'.join([quote(p, safe='') for p in path.split('/')])
    return f"{base_url}/raw/refs/heads/main/{encoded_path}"

def scan_directory(root_path, repo_owner, repo_name):
    """扫描目录并生成结构"""
    structure = {}

    for item in sorted(os.listdir(root_path)):
        if should_ignore(item):
            continue

        full_path = os.path.join(root_path, item)
        rel_path = os.path.relpath(full_path, root_path)

        if os.path.isdir(full_path):
            # 扫描子目录
            sub_items = []
            for sub_item in sorted(os.listdir(full_path)):
                if should_ignore(sub_item):
                    continue
                sub_full_path = os.path.join(full_path, sub_item)
                sub_rel_path = os.path.relpath(sub_full_path, root_path)

                if os.path.isdir(sub_full_path):
                    sub_items.append({
                        'name': sub_item,
                        'type': 'dir',
                        'url': get_github_url(repo_owner, repo_name, sub_rel_path)
                    })
                else:
                    # 文件
                    sub_items.append({
                        'name': sub_item,
                        'type': 'file',
                        'url': get_file_url(repo_owner, repo_name, sub_rel_path)
                    })

            structure[item] = {
                'type': 'dir',
                'url': get_github_url(repo_owner, repo_name, rel_path),
                'items': sub_items
            }

    return structure

def generate_markdown_index(structure):
    """生成 Markdown 格式的目录"""
    lines = []
    lines.append("## 索引 Index")

    # 定义学期顺序
    semester_order = ['大一上', '大一下', '大二上', '大二下', '大三上', '大三下', '其他资源']

    for semester in semester_order:
        if semester not in structure:
            continue

        lines.append(f"{semester}：")
        items = structure[semester]['items']

        for item in items:
            if item['type'] == 'dir':
                lines.append(f"- [{item['name']}]({item['url']})")
            else:
                # 文件类型，添加下载标识
                if item['name'].endswith(('.docx', '.pdf', '.zip', '.rar', '.md')):
                    lines.append(f"- [{item['name']}(点击下载)]({item['url']})")
                else:
                    lines.append(f"- [{item['name']}]({item['url']})")

        lines.append("")  # 空行分隔

    return '\n'.join(lines)

def update_readme(readme_path, new_index):
    """更新 README.md 文件中的索引部分"""
    with open(readme_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 查找索引部分的起始和结束位置
    start_marker = "## 索引 Index"
    end_marker = "## 关于我们"

    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)

    if start_idx == -1 or end_idx == -1:
        print("警告：未找到索引标记，将在文件开头插入索引")
        new_content = new_index + "\n\n" + content
    else:
        # 替换索引部分
        new_content = content[:start_idx] + new_index + "\n" + content[end_idx:]

    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("README.md 已更新！")

def generate_json_index(structure, output_path):
    """生成 JSON 格式的索引（用于网页）"""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(structure, f, ensure_ascii=False, indent=2)
    print(f"JSON 索引已生成：{output_path}")

def main():
    # 配置
    repo_owner = "Zmy0312bry"
    repo_name = "BUPT_SICE_ARCHIVE"

    # 获取项目根目录
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent

    print(f"扫描目录：{root_dir}")

    # 扫描目录结构
    structure = scan_directory(root_dir, repo_owner, repo_name)

    # 生成 Markdown 索引
    markdown_index = generate_markdown_index(structure)

    # 更新 README.md
    readme_path = root_dir / "README.md"
    update_readme(readme_path, markdown_index)

    # 生成 JSON 索引（用于网页）
    json_output = root_dir / "docs" / "index.json"
    json_output.parent.mkdir(exist_ok=True)
    generate_json_index(structure, json_output)

    print("✨ 索引生成完成！")

if __name__ == "__main__":
    main()
