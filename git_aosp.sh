#!/bin/bash

# 默认配置
DEFAULT_HOST="https://aosp.tuna.tsinghua.edu.cn/"
DEFAULT_BRANCH="android12-platform-release"

# 初始化变量
GIT_HOST="$DEFAULT_HOST"
GIT_BRANCH="$DEFAULT_BRANCH"

# 显示帮助信息
show_help() {
    echo "用法: $0 [-h host] [-b branch] <path>"
    echo ""
    echo "参数:"
    echo "  -h <host>     指定Git主机地址 (默认: $DEFAULT_HOST)"
    echo "  -b <branch>   指定Git分支 (默认: $DEFAULT_BRANCH)"
    echo "  <path>        AOSP项目路径，必须以'platform/'开头"
    echo ""
    echo "示例:"
    echo "  $0 platform/frameworks/base"
    echo "  $0 -b android12-platform-release platform/frameworks/base"
    echo "  $0 -h https://android.googlesource.com/ platform/frameworks/base"
    echo "  $0 -h https://android.googlesource.com/ -b android12-platform-release platform/frameworks/base"
}

# 解析命令行参数
while getopts "h:b:" opt; do
    case $opt in
        h)
            GIT_HOST="$OPTARG"
            # 确保URL以/结尾
            if [[ ! "$GIT_HOST" =~ /$ ]]; then
                GIT_HOST="$GIT_HOST/"
            fi
            ;;
        b)
            GIT_BRANCH="$OPTARG"
            ;;
        \?)
            echo "错误: 无效参数 -$OPTARG" >&2
            show_help
            exit 1
            ;;
        :)
            echo "错误: 参数 -$OPTARG 需要一个值" >&2
            show_help
            exit 1
            ;;
    esac
done

# 移除已处理的参数
shift $((OPTIND-1))

# 检查path参数
if [ $# -eq 0 ]; then
    echo "错误: 请提供路径参数"
    show_help
    exit 1
fi

if [ $# -gt 1 ]; then
    echo "错误: 太多参数"
    show_help
    exit 1
fi

PATH_INPUT="$1"

# 检查路径是否以platform/开头
if [[ ! "$PATH_INPUT" =~ ^platform/ ]]; then
    echo "错误: 路径必须以 'platform/' 开头"
    exit 1
fi

# 去掉platform/前缀
RELATIVE_PATH="${PATH_INPUT#platform/}"

# 提取目录部分和仓库名
if [[ "$RELATIVE_PATH" == *"/"* ]]; then
    # 包含目录结构
    TARGET_DIR=$(dirname "$RELATIVE_PATH")
    REPO_NAME=$(basename "$RELATIVE_PATH")
else
    # 直接在根目录
    TARGET_DIR=""
    REPO_NAME="$RELATIVE_PATH"
fi

# 显示配置信息
echo "=== 下载配置 ==="
echo "主机地址: $GIT_HOST"
echo "分支: $GIT_BRANCH"
echo "项目路径: $PATH_INPUT"
echo "目标目录: ${TARGET_DIR:-'当前目录'}"
echo "仓库名: $REPO_NAME"

# 创建并进入目标目录
if [ -n "$TARGET_DIR" ]; then
    echo "创建目录: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR" || exit 1
    echo "进入目录: $(pwd)"
fi

# 构造完整的git URL
GIT_URL="${GIT_HOST}${PATH_INPUT}"

# 执行git clone
echo "开始下载: $GIT_URL"

git clone -b "$GIT_BRANCH" "$GIT_URL" "$REPO_NAME"

if [ $? -eq 0 ]; then
    echo "下载完成: $REPO_NAME"
    echo "位置: $(pwd)/$REPO_NAME"
else
    echo "下载失败"
    exit 1
fi
