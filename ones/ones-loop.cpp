#include <stdio.h>

int main() {
   int num;
   int tmp;
   int cnt;
   int i;

   while(1);

   while( scanf("%d", &num) == 1 ) {
      cnt = 0;
      for( i=0; i<=num; i++ ) {
         tmp = i;
         while( tmp > 0 ) {
            if( tmp % 10 == 1 ) cnt++;
            tmp /= 10;
         }
      }
      printf("%d\n", cnt);
   }
}
