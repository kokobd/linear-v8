{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE LinearTypes         #-}
{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE NoFieldSelectors    #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE QualifiedDo         #-}

module V8
  ( initialize
  , Isolate
  , newIsolate
  , deleteIsolate
  ) where

import qualified Control.Applicative     as NonLinear
import           Control.Concurrent.Chan
import           Control.Functor.Linear
import qualified Control.Functor.Linear  as Linear
import           Control.Monad           (when)
import           Data.IORef              (IORef, atomicModifyIORef)
import           Foreign                 (Ptr)
import qualified Foreign.Marshal.Pure    as Manual
import           GHC.Records
import           Prelude.Linear          hiding (IO)
import qualified System.IO               as NonLinear
import           System.IO.Linear
import qualified Unsafe.Linear           as Unsafe
import           V8.Internal.OsThread
import           V8.Internal.Ref

initialize :: IO ()
initialize = fromSystemIO cInitialize

foreign import ccall unsafe "v8_hs_initialize" cInitialize :: NonLinear.IO ()

data Isolate = Isolate
  { raw      :: Ptr ()
  , osThread :: OsThread
  }

newIsolate :: IO Isolate
newIsolate = Linear.do
  osThread <- newOsThread
  raw <- fromSystemIO cNewIsolate
  pure (Isolate {raw, osThread})

foreign import ccall unsafe "v8_hs_new_isolate" cNewIsolate :: NonLinear.IO (Ptr ())

deleteIsolate :: Isolate %1 -> IO ()
deleteIsolate = Unsafe.toLinear $ \iso -> fromSystemIO $ do
  withLinearIO $ move <$> deleteOsThread iso.osThread
  cDeleteIsolate iso.raw

foreign import ccall unsafe "v8_hs_delete_isolate" cDeleteIsolate :: Ptr () -> NonLinear.IO ()

main :: NonLinear.IO ()
main = withLinearIO $ Linear.do
  initialize
  iso <- newIsolate

  deleteIsolate iso
  pure (Ur ())
