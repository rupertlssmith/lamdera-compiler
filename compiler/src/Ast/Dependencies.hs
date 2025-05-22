{-# LANGUAGE OverloadedStrings #-}
module Ast.Dependencies (extractCallDependencies) where

import qualified AST.Canonical as Can
import qualified Data.Name as Name
import qualified Elm.ModuleName as ModuleName
import qualified Reporting.Annotation as A

import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Map as Map -- Added import for Data.Map

extractCallDependencies :: Can.Expr -> [String]
extractCallDependencies (A.At _ expr) =
  map T.unpack (Set.toList (collectDependencies expr)) -- Convert Text to String at the end

collectDependencies :: Can.Expr_ -> Set Text
collectDependencies expr =
  case expr of
    Can.VarLocal name ->
      Set.singleton (Name.toText name)

    Can.VarTopLevel modu name ->
      Set.singleton (ModuleName.toText modu <> "." <> Name.toText name)

    Can.VarForeign modu name _ ->
      Set.singleton (ModuleName.toText modu <> "." <> Name.toText name)

    Can.VarCtor _ modu name _ _ ->
      Set.singleton (ModuleName.toText modu <> "." <> Name.toText name)

    Can.VarOperator _ modu name _ -> -- Real name of operator, from a specific module
      Set.singleton (ModuleName.toText modu <> "." <> Name.toText name)

    Can.List exprs ->
      Set.unions (map (collectDependencies . A.toValue) exprs)

    Can.Negate subExpr ->
      collectDependencies (A.toValue subExpr)

    Can.Binop opName opMod opRealName _ leftExpr rightExpr ->
      -- The Binop itself (opName) is a reference to an operator definition
      let opDep = Set.singleton (ModuleName.toText opMod <> "." <> Name.toText opRealName)
      in Set.unions [opDep, collectDependencies (A.toValue leftExpr), collectDependencies (A.toValue rightExpr)]

    Can.Lambda _ bodyExpr ->
      -- Dependencies in patterns are bindings, not calls from the lambda's perspective for external dependencies
      collectDependencies (A.toValue bodyExpr)

    Can.Call funcExpr argExprs ->
      Set.union (collectDependencies (A.toValue funcExpr)) (Set.unions (map (collectDependencies . A.toValue) argExprs))

    Can.If conditions elseExpr ->
      let condExprs = Set.unions (map (\(p, e) -> Set.union (collectDependencies (A.toValue p)) (collectDependencies (A.toValue e))) conditions)
      in Set.union condExprs (collectDependencies (A.toValue elseExpr))

    Can.Let def bodyExpr ->
      let defDeps = collectDefDependencies def
          -- For `let x = y in z`, `y` is a dependency of the let binding, not `x` itself from outside.
          -- Dependencies *within* the definition `def` are captured by `collectDefDependencies`.
          -- `x` becomes a local binding, not a "call dependency" in the sense of this function.
      in Set.union defDeps (collectDependencies (A.toValue bodyExpr))

    Can.LetRec defs bodyExpr ->
      let defsDeps = Set.unions (map collectDefDependencies defs)
          -- Similar to Let, names defined in defs are local bindings.
      in Set.union defsDeps (collectDependencies (A.toValue bodyExpr))

    Can.LetDestruct pattern destructExpr bodyExpr ->
      -- Names in `pattern` are local bindings.
      -- Dependencies can be in the expression being destructured and the body.
      Set.union (collectDependencies (A.toValue destructExpr)) (collectDependencies (A.toValue bodyExpr))

    Can.Case caseExpr branches ->
      -- Names in patterns of branches are local bindings.
      let branchDeps = Set.unions (map collectBranchDependencies branches)
      in Set.union (collectDependencies (A.toValue caseExpr)) branchDeps

    Can.Access recordExpr _ ->
      collectDependencies (A.toValue recordExpr) -- The field name is not a "call"

    Can.Update _ recordExpr fieldUpdates ->
      let updateExprDeps = Set.unions (map (\(Can.FieldUpdate _ e) -> collectDependencies (A.toValue e)) (Map.elems fieldUpdates))
      in Set.union (collectDependencies (A.toValue recordExpr)) updateExprDeps
      
    Can.Record fieldExprs ->
      Set.unions (map (collectDependencies . A.toValue) (Map.elems fieldExprs))

    Can.Tuple e1 e2 maybeE3 ->
      let e1Deps = collectDependencies (A.toValue e1)
          e2Deps = collectDependencies (A.toValue e2)
          e3Deps = case maybeE3 of
                     Nothing -> Set.empty
                     Just e3 -> collectDependencies (A.toValue e3)
      in Set.unions [e1Deps, e2Deps, e3Deps]

    -- Literals and other constructs that don't directly contain callable dependencies
    Can.Chr _ -> Set.empty
    Can.Str _ -> Set.empty
    Can.Int _ -> Set.empty
    Can.Float _ -> Set.empty
    Can.Unit -> Set.empty
    Can.Accessor _ -> Set.empty -- This is a field name, not a call dependency
    -- Kernel calls are not user-defined dependencies in this context
    Can.VarKernel _ _ -> Set.empty
    -- Debug functions are specially handled by the compiler, not typical user dependencies
    Can.VarDebug _ _ _ -> Set.empty 
    Can.Shader _ _ -> Set.empty

collectDefDependencies :: Can.Def -> Set Text
collectDefDependencies def =
  case def of
    Can.Def _ patterns expr ->
      -- Patterns introduce local bindings. We only care about dependencies in the expression.
      -- Dependencies from the function arguments (patterns) are not "call dependencies" from other modules.
      collectDependencies (A.toValue expr)
    Can.TypedDef _ _ patTypes expr _typeAnnotation ->
      -- Similar to Def, patterns (fst <$> patTypes) introduce local bindings.
      collectDependencies (A.toValue expr)

collectBranchDependencies :: Can.CaseBranch -> Set Text
collectBranchDependencies (Can.CaseBranch _pattern branchExpr) =
  -- Pattern introduces local bindings.
  collectDependencies (A.toValue branchExpr)
