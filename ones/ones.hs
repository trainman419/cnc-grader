-- Many thanks to Erin Dahlgren for this haskell implementation of Ones.
-- ones.hs

import System.Environment
import Data.Digits


ones :: Int -> Int
ones n = foldr (\x y -> if x == 1 then x+y else y) 0 (digits 10 n)

countOnes :: Int -> Int
countOnes n = foldr (\x y -> (ones x) + y) 0 [0..n]

--  or less efficiently, but still correct
-- countOnes n = sum $ map ones [0..n]


main = do
  xs <- getLine
  let arg' = read xs :: Int
  print $ countOnes arg'
