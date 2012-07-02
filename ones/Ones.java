import java.util.Scanner;

public class Ones {
   /* return the number of ones required to write i in base 10 */
   public static int ones(int i) {
      int r = 0;
      while( i > 0 ) {
         if( i % 10 == 1 ) ++r;
         i /= 10;
      }
      return r;
   }

   public static void main(String argv[]) {
      Scanner in = new Scanner(System.in);
      while( in.hasNextInt() ) {
         int i = in.nextInt();
         int r = 0;
         while( i > 0 ) {
            r += ones(i);
            --i;
         }
         System.out.println(r);
      }
   }
};
