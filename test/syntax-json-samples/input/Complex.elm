module Complex exposing (..)

import Basic exposing (Model, Msg(..)) -- Importing type and constructors
import WithImports

type alias ComplexModel =
    { basic : Basic.Model
    , name : String
    }

type ComplexMsg
    = BasicMsg Basic.Msg
    | SetName String

initialComplexModel : ComplexModel
initialComplexModel =
    { basic = Basic.init
    , name = "complex"
    }

updateComplex : ComplexMsg -> ComplexModel -> ComplexModel
updateComplex msg model =
    case msg of
        BasicMsg basicMsg ->
            { model | basic = Basic.update basicMsg model.basic }

        SetName newName ->
            let
                trimmedName =
                    String.trim newName
            in
            { model | name = WithImports.aliasedFunction (String.toInt trimmedName) |> String.fromInt } -- Deliberately convoluted call

anotherConstant : Int
anotherConstant =
    42

-- A function calling another local function
localCall : Int -> Int
localCall x =
    anotherConstant + x

-- A function calling an imported constructor
makeBasicModel : Int -> Basic.Model
makeBasicModel c =
    Basic.Model c
