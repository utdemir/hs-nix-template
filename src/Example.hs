module Example where

reverse' :: [a] -> [a]
reverse' = go []
 where
  go acc [] = acc
  go acc (x:xs) = go (x:acc) xs
