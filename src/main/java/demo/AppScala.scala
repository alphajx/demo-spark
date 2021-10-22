package demo

object AppScala {
  def main(args: Array[String]): Unit = {
    val date_dash = "2019-10-10"

    val sql2 =
      """
      """.stripMargin.format(date_dash, date_dash)
    println(sql2)

    println("end")
  }
}
