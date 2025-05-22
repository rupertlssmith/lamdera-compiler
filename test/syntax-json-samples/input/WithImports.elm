module WithImports exposing (aliasedFunction)

import Dict
import List
import Maybe as M
import Set exposing (Set)

aliasedFunction : M.Maybe Int -> Int
aliasedFunction maybeVal =
    M.withDefault 0 maybeVal

listProcessing : List Int -> List String
listProcessing nums =
    List.map String.fromInt nums

setCount : Set comparable -> Int
setCount s =
    Set.size s

dictLookup : Dict.Dict String Int -> String -> M.Maybe Int
dictLookup d k =
    Dict.get k d
