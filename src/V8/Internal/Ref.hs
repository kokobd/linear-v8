{-# LANGUAGE LinearTypes       #-}
{-# LANGUAGE NoImplicitPrelude #-}

module V8.Internal.Ref
  ( Ref,
    ref,
    deref,
    unsafeMapRef,
    unsafeDeref,
  )
where

import           Data.Unrestricted.Linear
import           Prelude.Linear           hiding (IO)
import qualified Unsafe.Linear            as Unsafe

newtype Ref a = Ref a

instance Consumable (Ref a) where
  consume = Unsafe.toLinear (const ())

instance Dupable (Ref a) where
  dup2 = Unsafe.toLinear (\x -> (x, x))

ref :: a %1 -> (Ref a %1 -> Ur b) %1 -> (a, Ur b)
ref = Unsafe.toLinear $ \x f -> (x, f (Ref x))

deref :: Movable a => Ref a %1 -> Ur a
deref (Ref x) = move x

unsafeMapRef :: (a -> b) %1 -> Ref a %1 -> Ref b
unsafeMapRef f (Ref x) = Ref (Unsafe.toLinear f x)

unsafeDeref :: Ref a %1 -> a
unsafeDeref (Ref x) = x
