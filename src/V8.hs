{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE LinearTypes       #-}
{-# LANGUAGE NoImplicitPrelude #-}

module V8 where

import           Foreign               (Ptr)
import qualified Foreign.Marshal.Pure  as Manual
import qualified Language.C.Inline.Cpp as C
import           Prelude.Linear
import qualified System.IO.Linear      as Linear

initialize :: IO ()
initialize = cInitialize

foreign import ccall unsafe "v8_hs_initialize" cInitialize :: IO ()

newtype Isolate = Ptr ()

main :: IO ()
main = do
  initialize
  putStrLn "hello"

go :: Manual.Pool %1 -> Ur ()
go pool = Manual.alloc (1 :: Int) pool & Manual.deconstruct & consume & move
