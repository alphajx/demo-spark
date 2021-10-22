#!/bin/bash
set -euo pipefail

version=$(date "+%Y_%m_%d_%H%M%S")
scripts_dir=$(cd "$(dirname "$0")";pwd)
base_dir=$(pwd)

git_remote=""

lib_dir=${base_dir}/lib
code_dir=${base_dir}/code_${version}

# 程序开始
echo -e '>>>>>>>>>>>>>>>> shell start:' "$(date)"
BEGIN_TIME=$(date +%s)
# 保留入口
invoke_cmd="sh $0 $@"
printf "\033[32m[DEBUG] 任务开始: %s | %s \033[0m\n" "$(date +%Y-%m-%d_%H:%M:%S)" "${invoke_cmd}"

# 退出处理
exit_program() {
    ret=$?

    rm -rf ${code_dir}

    END_TIME=$(date +%s)
    echo '******Total cost '  $((END_TIME-BEGIN_TIME)) ' seconds'
    printf "\033[32m[TRACE] 任务结束: %s | %s \033[0m\n" "$(date +%Y-%m-%d_%H:%M:%S)" "${invoke_cmd}"
    echo '>>>>>>>>>>>>>>>> shell end:' "$(date)"

    if ((${ret} != 0)); then
        printf "\033[31m[ERROR] 任务失败 | ${invoke_cmd}\033[0m\n"
        exit ${ret}
    else
        printf "\033[32m[INFO] TASK SUCCESS | ${invoke_cmd}\033[0m\n"
    fi
}

trap "exit_program" 0

if [ -z ${git_remote} ]; then
    echo "编译当前文件夹代码：$(pwd)"
else
    echo "编译远程仓库代码：${git_remote}"
    rm -rf ${code_dir}
    mkdir -p ${code_dir}
    cd ${code_dir}
    git clone ${git_remote}
    cd *
    # git checkout -b zjx origin/zjx
    git branch -vv
fi

mvn clean package assembly:single -U -P online -Dmaven.test.skip=true

mkdir -p ${lib_dir}

cd target

for file in $(ls *.jar)
do
    jar_path=${lib_dir}/${file}

    if [ -f ${jar_path} ]; then
        echo "备份历史文件：${jar_path} to ${jar_path}.${version}.jar"
        mv ${jar_path} ${jar_path}.${version}.csv
    fi
done

echo "开始复制"
echo "$(ls *.jar) to ${lib_dir}"
cp *.jar ${lib_dir}
echo "复制结束"