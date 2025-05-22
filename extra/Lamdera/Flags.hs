module Lamdera.Flags
  ( syntaxJsonEnabledRef
  , setSyntaxJsonGeneration
  , isSyntaxJsonGenerationEnabled
  ) where

import System.IO.Unsafe (unsafePerformIO)
import Data.IORef

-- Global IORef to store the flag's state
{-# NOINLINE syntaxJsonEnabledRef #-}
syntaxJsonEnabledRef :: IORef Bool
syntaxJsonEnabledRef = unsafePerformIO (newIORef False) -- Default to False

-- Function to set the flag's state
setSyntaxJsonGeneration :: Bool -> IO ()
setSyntaxJsonGeneration = writeIORef syntaxJsonEnabledRef

-- Function to get the flag's state
isSyntaxJsonGenerationEnabled :: IO Bool
isSyntaxJsonGenerationEnabled = readIORef syntaxJsonEnabledRef
