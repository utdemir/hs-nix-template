{-# LANGUAGE TemplateHaskell #-}

module Main where

import Hedgehog
import Hedgehog.Main
import {{cookiecutter.module}}

prop_test :: Property
prop_test = property $ do
  do{{cookiecutter.module}} === "{{cookiecutter.module}}"

main :: IO ()
main = defaultMain [checkParallel $$(discover)]
