{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Json.Syntax where

import Data.Aeson
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Represents the type of syntax element.
data SyntaxType
  = STFunction
  | STConstant
  | STTypedef
  | STTypealias
  deriving (Show, Eq, Generic)

instance ToJSON SyntaxType where
  toJSON STFunction = String "function"
  toJSON STConstant = String "constant"
  toJSON STTypedef = String "typedef"
  toJSON STTypealias = String "typealias"

instance FromJSON SyntaxType where
  parseJSON = withText "SyntaxType" $ \t ->
    case t of
      "function" -> pure STFunction
      "constant" -> pure STConstant
      "typedef" -> pure STTypedef
      "typealias" -> pure STTypealias
      _ -> fail $ "Invalid SyntaxType: " ++ show t

-- | Represents a syntax element in the code.
data SyntaxEntry = SyntaxEntry
  { type :: SyntaxType,
    name :: Text,
    code :: Text,
    startLine :: Int,
    endLine :: Int,
    calls :: [Text],
    imports :: [Text]
  }
  deriving (Show, Eq, Generic)

instance ToJSON SyntaxEntry where
  toJSON (SyntaxEntry ty n c sl el cls imps) =
    object
      [ "type" .= ty,
        "name" .= n,
        "code" .= c,
        "startLine" .= sl,
        "endLine" .= el,
        "calls" .= cls,
        "imports" .= imps
      ]

instance FromJSON SyntaxEntry where
  parseJSON = withObject "SyntaxEntry" $ \v ->
    SyntaxEntry
      <$> v .: "type"
      <*> v .: "name"
      <*> v .: "code"
      <*> v .: "startLine"
      <*> v .: "endLine"
      <*> v .: "calls"
      <*> v .: "imports"
