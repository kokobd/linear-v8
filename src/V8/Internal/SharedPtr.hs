{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE LinearTypes         #-}
{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE NoFieldSelectors    #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE QualifiedDo         #-}

module V8.Internal.SharedPtr where

import           Control.Functor.Linear
import qualified Control.Functor.Linear as Linear
import           Data.IORef             (IORef, atomicModifyIORef)
import           Prelude.Linear         hiding (IO)
import           System.IO.Linear
import qualified Unsafe.Linear          as Unsafe

data SharedPtr a = SharedPtr
  { value      :: a
  , count      :: IORef Int
  , destructor :: a %1 -> IO ()
  }

new :: a %1 -> (a %1 -> IO ()) -> IO (SharedPtr a)
new value destructor = Linear.do
  Ur count <- newIORef 1
  pure $ SharedPtr { value, count, destructor }

clone :: SharedPtr a %1 -> IO (SharedPtr a, SharedPtr a)
clone = Unsafe.toLinear $ \(SharedPtr value count destructor) -> Linear.do
  fromSystemIO $ atomicModifyIORef count (\a -> (a+1, ()))
  let newPtr = SharedPtr { value, count, destructor }
  pure (newPtr, newPtr)
