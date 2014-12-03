-- > ghc -DTESTING --make -O2 -fforce-recomp -i.. Sequence.hs
module Main where

import Control.DeepSeq
import Criterion.Main
import Data.List (foldl')
import qualified Data.Sequence as S
import qualified Data.Foldable
import System.Random

main = do
    let s10 = S.fromList [1..10] :: S.Seq Int
        s100 = S.fromList [1..100] :: S.Seq Int
        s1000 = S.fromList [1..1000] :: S.Seq Int
    rnf [s10, s100, s1000] `seq` return ()
    let g = mkStdGen 1
    let rlist n = map (`mod` (n+1)) (take 10000 (randoms g)) :: [Int]
        r10 = rlist 10
        r100 = rlist 100
        r1000 = rlist 1000
    rnf [r10, r100, r1000] `seq` return ()
    defaultMain
      [ bgroup "splitAt/append"
         [ bench "10" $ nf (shuffle r10) s10
         , bench "100" $ nf (shuffle r100) s100
         , bench "1000" $ nf (shuffle r1000) s1000
         ]
      , bgroup "zip"
         [ bench "ix10000/5000" $ nf (\(xs,ys) -> S.zip xs ys `S.index` 5000) (S.replicate 10000 (), S.fromList [1..10000::Int])
         , bench "nf150" $ nf (uncurry S.zip) (S.fromList [1..150::Int], S.replicate 150 ())
         , bench "nf10000" $ nf (uncurry S.zip) (S.fromList [1..10000::Int], S.replicate 10000 ())
         ] ]

-- splitAt+append: repeatedly cut the sequence at a random point
-- and rejoin the pieces in the opposite order.
-- Finally getting the middle element forces the whole spine.
shuffle :: [Int] -> S.Seq Int -> Int
shuffle ps s = case S.viewl (S.drop (S.length s `div` 2) (foldl' cut s ps)) of
    x S.:< _ -> x
  where cut xs p = let (front, back) = S.splitAt p xs in back S.>< front
