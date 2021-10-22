package demo;

import java.text.ParseException;
import java.text.SimpleDateFormat;

/**
 * Hello world!
 *
 */
public class AppJava
{
    public static void main( String[] args ) throws ParseException {
        System.out.println( "Hello World!" );
        System.out.println(new SimpleDateFormat("yyyyMMdd").parse("20191010"));
    }
}
