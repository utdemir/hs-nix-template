{-# LANGUAGE StaticPointers #-}

module Main where

--------------------------------------------------------------------------------
import           Test.Tasty
import           Test.Tasty.Hedgehog
import           Hedgehog
import qualified Hedgehog.Gen                                     as Gen
import qualified Hedgehog.Range                                   as Range
import           Test.Tasty.HUnit       hiding (assert)
--------------------------------------------------------------------------------
import           Example
--------------------------------------------------------------------------------

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup
  "Tests"
  [ testCase "empty" $ 
      reverse' ([] :: [Char]) @=? []
  , testCase "single" $ 
      reverse' ['a'] @=? ['a']
  , testCase "reverse" $ 
      reverse' "abc" @=? "cba"
  , testProperty "reference" $ property $ do
      xs <- forAll $ Gen.list (Range.linear 0 1000) (Gen.enum 'a' 'z')
      reverse' xs === reverse xs
  , testProperty "roundtrip" $ property $ do
      xs <- forAll $ Gen.list (Range.linear 0 1000) (Gen.enum 'a' 'z')
      reverse' (reverse' xs) === xs
  ]
