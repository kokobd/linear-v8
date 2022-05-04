{-# LANGUAGE DataKinds                 #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE LinearTypes               #-}
{-# LANGUAGE NamedFieldPuns            #-}
{-# LANGUAGE NoFieldSelectors          #-}
{-# LANGUAGE NoImplicitPrelude         #-}
{-# LANGUAGE OverloadedRecordDot       #-}
{-# LANGUAGE QualifiedDo               #-}

module V8.Internal.OsThread
  ( OsThread
  , newOsThread
  , deleteOsThread
  , runInOsThread
  ) where
import qualified Control.Applicative    as NonLinear
import           Control.Concurrent
import           Control.Exception      (AsyncException (UserInterrupt),
                                         Exception (toException), SomeException,
                                         try)
import           Control.Functor.Linear
import qualified Control.Functor.Linear as Linear
import           Control.Monad          (forever, when)
import           Control.Monad.Loops    (whileM_)
import qualified Data.Functor           as NonLinear
import           Data.Maybe
import           GHC.Records
import           Prelude.Linear         hiding (IO)
import qualified System.IO              as NonLinear
import           System.IO.Linear
import qualified Unsafe.Linear          as Unsafe
import           V8.Internal.Ref

data OsThread = OsThread
  { chan     :: Chan (Maybe Task)
  , threadId :: ThreadId
  , closed   :: MVar ()
  }


chanRef :: Ref OsThread %1 -> Ref (Chan (Maybe Task))
chanRef = unsafeMapRef (\o -> o.chan)

threadIdRef :: Ref OsThread %1 -> Ref ThreadId
threadIdRef = unsafeMapRef (\o -> o.threadId)

closedRef :: Ref OsThread %1 -> Ref (MVar ())
closedRef = unsafeMapRef (\o -> o.closed)

data Task = forall a. Task
  { action     :: NonLinear.IO a
  , resultSlot :: MVar (Either SomeException a)
  }

newOsThread :: IO OsThread
newOsThread = fromSystemIO newOsThread'

newOsThread' :: NonLinear.IO OsThread
newOsThread' = do
  closed <- newEmptyMVar
  chan <- newChan
  threadId <- forkOS $ flip whileM_ (NonLinear.pure ()) $ do
    isClosed <- NonLinear.fmap isJust (tryReadMVar closed)
    maybeTask <- readChan chan
    case maybeTask of
      Nothing -> NonLinear.pure False
      Just (Task action resultSlot) -> do
        if isClosed
        then putMVar resultSlot (Left (toException UserInterrupt))
        else do
          result <- try action
          putMVar resultSlot result
        NonLinear.pure True
  NonLinear.pure $ OsThread { chan, threadId , closed }

deleteOsThread :: OsThread %1-> IO ()
deleteOsThread = Unsafe.toLinear $ \osThread -> fromSystemIO $ do
  ok <- tryPutMVar osThread.closed ()
  when ok $
    writeChan osThread.chan Nothing
  NonLinear.pure ()

runInOsThread :: Ref OsThread -> NonLinear.IO a -> NonLinear.IO (Either SomeException a)
runInOsThread osThread action = withLinearIO $ Linear.do
  (Ur resultSlot) <- fromSystemIOU newEmptyMVar
  putTask osThread resultSlot action
  fromSystemIOU $ takeMVar resultSlot
  where
    putTask :: Ref OsThread %1 -> MVar (Either SomeException a) -> NonLinear.IO a -> IO ()
    putTask osThread resultSlot action =
      fromSystemIO $ unsafeDeref $
        unsafeMapRef (\chan -> writeChan chan (Just $ Task action resultSlot)) (chanRef osThread)
