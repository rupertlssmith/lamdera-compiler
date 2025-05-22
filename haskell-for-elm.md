|   Elm   | Haskel |
| ------- | ------ |
|    >>   |   Control.Arrow.>>> | |
|    <<   |   .  | Hmmm... |
|    |>   |   &  | |
|    <|   |   $  | |
|    :    |  ::  | |
|   ::    |  :   | Aaahh!  |
|  type ... | data ... |
|  type alias ... | type ... |


Elm:

    length : List a -> Int
    length l =
       case l of
          [] -> 0
          x :: xs -> 1 + length xs

Haskell:

    length :: [a] -> Int
    length [] = 0
    length (x:xs) = 1 + length xs 

Elm: 

    filter : (a -> Bool) -> List a -> List a
    filter isGood list =
      foldr (\x xs -> if isGood x then cons x xs else xs) [] list

Haskell:

    filter :: (a -> Bool) -> [a] -> [a]
    filter pred [] = []
    filter pred (x:xs)
     | pred x = x : filter pred xs
     | otherwise = filter pred xs


 Elm:

     map5 :
        (a -> b -> c -> d -> e -> result)
        -> Task x a
        -> Task x b
        -> Task x c
        -> Task x d
        -> Task x e
        -> Task x result
    map5 func taskA taskB taskC taskD taskE =
        taskA
            |> andThen
                (\a ->
                    taskB
                        |> andThen
                            (\b ->
                                taskC
                                    |> andThen
                                        (\c ->
                                            taskD
                                                |> andThen
                                                    (\d ->
                                                        taskE
                                                            |> andThen (\e -> succeed (func a b c d e))
                                                    )
                                        )
                            )
                )

Haskell:

    map5 ::
      (a -> b -> c -> d -> e -> result) ->
      Task x a ->
      Task x b ->
      Task x c ->
      Task x d ->
      Task x e ->
      Task x result
    map5 func taskA taskB taskC taskD taskE = do
      a <- taskA
      b <- taskB
      c <- taskC
      d <- taskD
      e <- taskE
      pure $ func a b c d e

      