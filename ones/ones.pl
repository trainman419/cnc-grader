#!/usr/bin/perl



while(<>) {
   $i = $_;
   $r = 0;
   while( $i > 0 ) {
      for( $j = $i; $j > 0; $j /= 10 ) {
         ++$r if($j % 10 == 1 );
      }
      --$i;
   }
   print "$r\n"
}
