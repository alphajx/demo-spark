package demo

import org.apache.spark.rdd.RDD
import org.apache.spark.sql.types.{DataType, StructType}
import org.apache.spark.sql.{DataFrame, Row, SparkSession}

import java.text.SimpleDateFormat

object App {

  var spark: SparkSession = _


  /**
    * rdd 转 dataframe
    * @param rdd RDD[Row]
    * @param param param(ind) = ("f" + ind.toString, StringType, true)
    * @return
    */
  def rdd2df(rdd: RDD[Row], param: Array[(String, DataType, Boolean)]): DataFrame = {
    var schema = new StructType()
    for (item <- param) {
      schema = schema.add(item._1, item._2, item._3)
    }
    println(schema)

    val df = spark.createDataFrame(rdd, schema)
    print(df)

    df.show()

    df
  }


  /**
    * dataframe写入hive表
    * @param df: DataFrame
    * @param hive_table_name: ku.table_name
    * @param hive_table_partition: "year=\"2019\", month=\"05\", day=\"21\"", must have \"
    * @param overwrite: "overwrite" or ""
    * @param repartition: -1 or int such as 1000
    */
  def insert_to_hive(df: DataFrame, hive_table_name: String, hive_table_partition: String, overwrite: String, repartition: Int): Unit = {
    val df_cnt = df.count()
    println("df.count(): " + df_cnt)

    var repartition_num: Int = repartition
    if (repartition_num == -1) repartition_num = (df.schema.length * df_cnt / 10000000).toInt + 1
    println("repartition_num: " + repartition_num)

    val table_name_tmp = "table_tmp"

    df.repartition(repartition_num).createOrReplaceTempView(table_name_tmp)

    val sql = f"""
        insert $overwrite table $hive_table_name
        partition($hive_table_partition)
        select *
        from $table_name_tmp
    """
    print(sql)

    spark.sql(sql)
  }


  def main(args: Array[String]): Unit = {
    println("spark app begin")

    spark = SparkSession
      .builder()
      .enableHiveSupport()
      .getOrCreate()
//    spark.conf.set("spark.yarn.queue", "")
    spark.conf.set("hive.exec.orc.split.strategy", "BI")
    spark.conf.set("mapred.input.dir.recursive", true)
    spark.conf.set("mapreduce.input.fileinputformat.input.dir.recursive", true)
//    spark.conf.set("spark.sql.shuffle.partitions", 1000)
//    spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 100L * 1024 * 1024)

    val date = args.apply(0)
    val path = args.apply(1)

    val date_time = new SimpleDateFormat("yyyyMMdd").parse(date)
    val date_dash = new SimpleDateFormat("yyyy-MM-dd").format(date_time)

    println(date, date_time, date_dash)
    println(path)

    val sql =
      """
        |select
        |1
        |,'123xd' regexp '^[0-9]+$'
        |,'123' regexp '^[0-9]+$'
        |,'12.3' regexp '^[0-9]+$'
        |,'-123' regexp '^[0-9]+$'
        |
      """.stripMargin.format(date_dash, date_dash)
    println(sql)

    var df = spark.sql(sql)
    df.show()
    println(df.count())

    df.repartition(1)
      .write.format("com.databricks.spark.csv")
      .option("header", "true")
      .option("sep","\t")
      .save(path)

    println("spark app end")
  }
}
