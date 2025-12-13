#!/usr/bin/env python3

import sys
import os
import time
import re
from pathlib import Path

try:
    import paramiko
    import tomli
except ImportError:
    print("错误: 需要安装必要的库")
    print("请运行: pip install paramiko tomli")
    sys.exit(1)


def load_config():
    config_path = Path(__file__).parent / "config.toml"
    if not config_path.exists():
        print(f"错误: 配置文件不存在: {config_path}")
        sys.exit(1)

    with open(config_path, "rb") as f:
        config = tomli.load(f)

    return config


def calculate_f_center(poina):
    f_center = (poina - 600000) * 15000 + 3000000000 + 273 * 12 / 2 * 30000
    return int(f_center)


def ssh_connect(ssh_config):
    hostname = ssh_config.get("host")
    username = ssh_config.get("user")
    port = ssh_config.get("port", 22)
    password = ssh_config.get("password")
    key_filename = ssh_config.get("ssh_key")

    if not hostname or not username:
        print("错误: 配置文件中缺少 host 或 user")
        sys.exit(1)

    print(f"正在连接到 {username}@{hostname}:{port}...")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        connect_kwargs = {
            "hostname": hostname,
            "port": port,
            "username": username
        }

        if key_filename and os.path.exists(os.path.expanduser(key_filename)):
            connect_kwargs["key_filename"] = os.path.expanduser(key_filename)
        elif password:
            connect_kwargs["password"] = password

        ssh.connect(**connect_kwargs)
        print("SSH 连接成功!")
        return ssh
    except Exception as e:
        print(f"SSH 连接失败: {e}")
        sys.exit(1)


def modify_rx_file(channel, f_center):
    print(f"\n修改 rx.c 文件，设置 f_center = {f_center}...")

    rx_file_path = "~/ComCirsys/oxgrf_trx/rx.c"

    channel.send(f"sed -i 's/\\(double[[:space:]]\\+dl_carrier[[:space:]]*=[[:space:]]*\\)[0-9]\\+\\([[:space:]]*;\\)/\\1{f_center}\\2/' {rx_file_path}\n")
    time.sleep(0.5)

    while channel.recv_ready():
        channel.recv(65536)

    channel.send(f"sed -i 's/\\(double[[:space:]]\\+ul_carrier[[:space:]]*=[[:space:]]*\\)[0-9]\\+\\([[:space:]]*;\\)/\\1{f_center}\\2/' {rx_file_path}\n")
    time.sleep(0.5)

    while channel.recv_ready():
        channel.recv(65536)

    print("文件修改成功!")
    return True


def execute_interactive_session(ssh, poina):
    print("\n启动交互式会话...")

    channel = ssh.invoke_shell()
    channel.settimeout(0.5)

    time.sleep(1)
    while channel.recv_ready():
        print(channel.recv(65536).decode('utf-8'), end='')

    f_center = calculate_f_center(poina)

    if not modify_rx_file(channel, f_center):
        return False

    commands = [
        "cd ~/ComCirsys/oxgrf_trx/build",
        "cmake ..",
        "make",
    ]

    print("\n开始执行编译命令...")
    for cmd in commands:
        print(f"\n执行: {cmd}")
        channel.send(cmd + "\n")
        time.sleep(2)

        output = ""
        try:
            while True:
                chunk = channel.recv(65536).decode('utf-8')
                output += chunk
                print(chunk, end='')
        except:
            pass

    print("\n执行第一次 sudo ./rx (等待10秒)...")
    channel.send("cd ~/ComCirsys/oxgrf_trx/build/bin\n")
    time.sleep(0.5)

    try:
        while channel.recv_ready():
            print(channel.recv(65536).decode('utf-8'), end='')
    except:
        pass

    channel.send("timeout 10 sudo ./rx\n")
    time.sleep(0.5)

    try:
        while True:
            chunk = channel.recv(65536).decode('utf-8')
            print(chunk, end='')
            if "[sudo]" in chunk or "password" in chunk.lower():
                password = input()
                channel.send(password + "\n")
    except:
        pass

    time.sleep(6)

    try:
        while channel.recv_ready():
            print(channel.recv(65536).decode('utf-8'), end='')
    except:
        pass

    print("\n执行第二次 sudo ./rx (等待10秒)...")
    channel.send("timeout 10 sudo ./rx\n")
    time.sleep(0.5)

    try:
        while True:
            chunk = channel.recv(65536).decode('utf-8')
            print(chunk, end='')
            if "[sudo]" in chunk or "password" in chunk.lower():
                password = input()
                channel.send(password + "\n")
    except:
        pass

    time.sleep(6)

    try:
        while channel.recv_ready():
            print(channel.recv(65536).decode('utf-8'), end='')
    except:
        pass

    print("\n命令执行完成!")
    channel.close()
    return True


def download_file(ssh, poina, output_dir):
    remote_file = "~/ComCirsys/oxgrf_trx/build/bin/fp_iq.hex"
    local_file = os.path.join(output_dir, f"fp_iq_{poina}.hex")

    print(f"\n下载文件: {remote_file} -> {local_file}")

    try:
        sftp = ssh.open_sftp()

        stdin, stdout, stderr = ssh.exec_command(f"echo {remote_file}")
        expanded_path = stdout.read().decode('utf-8').strip()

        os.makedirs(output_dir, exist_ok=True)

        sftp.get(expanded_path, local_file)
        sftp.close()

        print(f"文件下载成功: {local_file}")
        return True
    except Exception as e:
        print(f"文件下载失败: {e}")
        return False


def main():
    config = load_config()

    poina = config.get("poina")
    if poina is None:
        print("错误: 配置文件中未设置 poina")
        sys.exit(1)

    print(f"POINA: {poina}")
    print(f"计算得到 f_center: {calculate_f_center(poina)} Hz")

    ssh_config = config.get("ssh", {})
    ssh = ssh_connect(ssh_config)

    try:
        if not execute_interactive_session(ssh, poina):
            print("执行失败，退出")
            sys.exit(1)

        output_dir = "./downloads"
        download_file(ssh, poina, output_dir)

        print("\n所有操作完成!")

    finally:
        ssh.close()
        print("\nSSH 连接已关闭")


if __name__ == "__main__":
    main()
