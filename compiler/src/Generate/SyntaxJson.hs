{-# LANGUAGE OverloadedStrings #-}
module Generate.SyntaxJson (generateSyntaxJson) where

import qualified AST.Canonical as Can
import qualified AST.Source as Src
import qualified Reporting.Annotation as A
import qualified Data.Name as Name
import qualified Elm.ModuleName as ModuleName
import qualified Json.Syntax as Json
import qualified CanSer.CanSer as CanSer
import qualified Ast.Dependencies as AstDeps

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Map as Map
import Data.Word (Word16)
import Data.List (reverse) -- Added for reversing the accumulator

-- Main function to generate SyntaxEntry list
generateSyntaxJson :: Src.Module -> Can.Module -> [Json.SyntaxEntry]
generateSyntaxJson srcModule canModule =
  let
    commonImports = extractImports (Src._imports srcModule)
    
    declEntries = processDecls srcModule canModule commonImports (Can._decls canModule)
    unionEntries = processUnions srcModule canModule commonImports
    aliasEntries = processAliases srcModule canModule commonImports
  in
    declEntries ++ unionEntries ++ aliasEntries

-- Helper to convert Word16 line numbers to Int
lineToInt :: Word16 -> Int
lineToInt = fromIntegral

-- Step 3: Import Handling
extractImports :: [A.Located Src.Import] -> [Text]
extractImports srcImports =
  map formatImport srcImports
  where
    formatImport :: A.Located Src.Import -> Text
    formatImport (A.At _ imp) =
      let moduleNameText = ModuleName.toText (A.toValue (Src._name imp))
      in case Src._alias imp of
           Nothing -> moduleNameText
           Just (A.At _ aliasName) -> moduleNameText <> " as " <> Name.toText aliasName

-- Step 4: Processing Definitions (Can.Decls)
processDecls :: Src.Module -> Can.Module -> [Text] -> Can.Decls -> [Json.SyntaxEntry]
processDecls srcModule canModule commonImportsListOuter decls =
  reverse (go decls []) -- Reverse the final list as it's accumulated in reverse
  where
    go :: Can.Decls -> [Json.SyntaxEntry] -> [Json.SyntaxEntry]
    go currentDecls acc =
      case currentDecls of
        Can.Declare def remainingDecls ->
          let entry = defToSyntaxEntry def commonImportsListOuter
          in go remainingDecls (entry : acc)
        
        Can.DeclareRec def defs remainingDecls ->
          let currentEntries = map (\d -> defToSyntaxEntry d commonImportsListOuter) (def:defs)
          in go remainingDecls (currentEntries ++ acc) -- Add multiple entries
          
        Can.SaveTheEnvironment -> acc -- End of declarations, return accumulated

    defToSyntaxEntry :: Can.Def -> [Text] -> Json.SyntaxEntry
    defToSyntaxEntry def commonImportsList =
      let (defNameLocated, patterns, expr) = case def of
            Can.Def n ps e -> (n, ps, e)
            -- For TypedDef, patTypes is [(Pattern, Type)], we need only Patterns for arg check
            Can.TypedDef n _ patTypes typedExpr _ -> (n, map fst patTypes, typedExpr)
          
          defName = Name.toText (A.toValue defNameLocated)
          defRegion = A.toRegion defNameLocated
          
          syntaxType = if null patterns then Json.STConstant else Json.STFunction
          
          code = CanSer.convert def
          
          startLine = lineToInt (A._line (A._start defRegion))
          endLine = lineToInt (A._line (A._end defRegion))
          
          calls = map T.pack (AstDeps.extractCallDependencies expr)

      in Json.SyntaxEntry
           { Json.type = syntaxType
           , Json.name = defName
           , Json.code = code
           , Json.startLine = startLine
           , Json.endLine = endLine
           , Json.calls = calls
           , Json.imports = commonImportsList
           }

-- Step 5: Processing Union Types (Can.Union)
processUnions :: Src.Module -> Can.Module -> [Text] -> [Json.SyntaxEntry]
processUnions srcModule canModule commonImportsList =
  Map.foldrWithKey (addUnionEntry) [] (Can._unions canModule)
  where
    addUnionEntry :: Name.Name -> Can.Union -> [Json.SyntaxEntry] -> [Json.SyntaxEntry]
    addUnionEntry unionName canUnion acc =
      let entryName = Name.toText unionName
          code = CanSer.convert canUnion
          
          (startLine, endLine) = findSrcUnionRegion unionName srcModule

      in Json.SyntaxEntry
           { Json.type = Json.STTypedef
           , Json.name = entryName
           , Json.code = code
           , Json.startLine = startLine
           , Json.endLine = endLine
           , Json.calls = [] 
           , Json.imports = commonImportsList
           } : acc

findSrcUnionRegion :: Name.Name -> Src.Module -> (Int, Int)
findSrcUnionRegion targetCanName srcMod =
  let targetText = Name.toText targetCanName
  in case filter (\(A.At _ su) -> Name.toText (A.toValue (Src._union_name su)) == targetText) (Src._unions srcMod) of
    (A.At region _):_ ->
        (lineToInt (A._line (A._start region)), lineToInt (A._line (A._end region)))
    [] -> (0, 0) 

-- Step 6: Processing Type Aliases (Can.Alias)
processAliases :: Src.Module -> Can.Module -> [Text] -> [Json.SyntaxEntry]
processAliases srcModule canModule commonImportsList =
  Map.foldrWithKey (addAliasEntry) [] (Can._aliases canModule)
  where
    addAliasEntry :: Name.Name -> Can.Alias -> [Json.SyntaxEntry] -> [Json.SyntaxEntry]
    addAliasEntry aliasName canAlias acc =
      let entryName = Name.toText aliasName
          code = CanSer.convert canAlias

          (startLine, endLine) = findSrcAliasRegion aliasName srcModule
          
      in Json.SyntaxEntry
           { Json.type = Json.STTypealias
           , Json.name = entryName
           , Json.code = code
           , Json.startLine = startLine
           , Json.endLine = endLine
           , Json.calls = []
           , Json.imports = commonImportsList
           } : acc

findSrcAliasRegion :: Name.Name -> Src.Module -> (Int, Int)
findSrcAliasRegion targetCanName srcMod =
  let targetText = Name.toText targetCanName
  in case filter (\(A.At _ sa) -> Name.toText (A.toValue (Src._alias_name sa)) == targetText) (Src._aliases srcMod) of
    (A.At region _):_ ->
        (lineToInt (A._line (A._start region)), lineToInt (A._line (A._end region)))
    [] -> (0, 0)
