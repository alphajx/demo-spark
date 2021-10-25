#!/bin/sh
set -xueo pipefail

# 预定义参数
base_dir=$(pwd)
scripts_dir=$(cd "$(dirname "$0")";pwd)
version=$(date "+%Y_%m_%d_%H%M%S")

# 项目参数
spark_submit_queue=""
output_hdfs="tmp/${version}/001"
error_msg=demo-spark
mail_list=demo@demo.com
jar_dir=${base_dir}/target/demo-spark-1.0-SNAPSHOT-jar-with-dependencies.jar
class=demo.App
spark_conf_path=${scripts_dir}/spark-env.sh

# 是否覆盖已有结果，默认覆盖
is_overwrite=1

# 程序开始
echo -e '>>>>>>>>>>>>>>>> shell start:' "$(date)"
BEGIN_TIME=$(date +%s)
# 保留入口
invoke_cmd="sh $0 $@"
printf "\033[32m[DEBUG] 任务开始: %s | %s \033[0m\n" "$(date +%Y-%m-%d_%H:%M:%S)" "${invoke_cmd}"

python -c "print('\n\n\n' + '='*40 + '\n' + '='*40 + '\n' + '='*9 + ' 代码改动记得重新编译 ' + '='*9 + '\n' + '='*40 + '\n' + '='*40 + '\n\n\n')"

# 退出处理
exit_program() {
    ret=$?

    END_TIME=$(date +%s)
    echo '******Total cost '  $((END_TIME-BEGIN_TIME)) ' seconds'
    printf "\033[32m[TRACE] 任务结束: %s | %s \033[0m\n" "$(date +%Y-%m-%d_%H:%M:%S)" "${invoke_cmd}"
    echo '>>>>>>>>>>>>>>>> shell end:' "$(date)"

    if ((${ret} != 0)); then
        printf "\033[31m[ERROR] 任务失败 | ${invoke_cmd}\033[0m\n"
        python ./scripts/send_warn_email.py ${mail_list} ${error_msg}_$(date "+%Y-%m-%d_%H:%M:%S") 详情: 服务器: $(hostname -i) 目录: $(pwd) 程序: "$invoke_cmd" 返回码: $ret
        exit ${ret}
    else
        printf "\033[32m[INFO] TASK SUCCESS | ${invoke_cmd}\033[0m\n"
    fi
}

trap "exit_program" 0


sh scripts/get_jar.sh


if [ ! -f ${spark_conf_path} ];
then
    hdfs dfs -get online/env/spark_conf/spark-env.sh ${spark_conf_path}
fi
source ${spark_conf_path}


# 获取日期参数
if [[ $# -lt 1 ]]; then
    echo "sh $0 <date>"
    exit 3
else
    date=${1}
    shift 1
    param=$@
fi

# 日期相关参数
output_hdfs=$(printf "${output_hdfs}" ${date})

# 是否跳过任务
set +e
if ((${is_overwrite} == 0)); then
    hdfs dfs -test -e ${output_hdfs}/_SUCCESS
    if [[ $? == 0 ]]; then
        echo '路径存在，不提交spark任务，正常退出'
        exit 0
    fi
fi
set -e

# 检查依赖，待添加
set +e
set -e

# 执行任务
hdfs dfs -rm -r -f ${output_hdfs}

spark-submit \
    --queue ${spark_submit_queue} \
    --conf spark.dynamicAllocation.minExecutors=10 \
    --conf spark.dynamicAllocation.maxExecutors=200 \
    --conf spark.executor.cores=4 \
    --conf spark.default.parallism=1024 \
    --executor-memory 12g \
    --driver-memory 15g \
    --conf "spark.executor.memoryOverhead=3g" \
    --class ${class} \
    ${jar_dir} ${date} ${output_hdfs} ${param}

# 检查输出路径
hdfs dfs -test -e ${output_hdfs}/_SUCCESS
