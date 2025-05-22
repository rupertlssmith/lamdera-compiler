module Basic exposing (..)

import Html exposing (Html, text)
import Html.Attributes as Attr

type Msg
    = Increment
    | Decrement

type alias Model =
    { count : Int }

init : Model
init =
    { count = 0 }

update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { model | count = model.count + 1 }

        Decrement ->
            { model | count = model.count - 1 }

view : Model -> Html Msg
view model =
    Html.div []
        [ Html.button [ Attr.class "decrement", onClick Decrement ] [ text "-" ]
        , Html.div [] [ text (String.fromInt model.count) ]
        , Html.button [ Attr.class "increment", onClick Increment ] [ text "+" ]
        ]

main =
    Html.beginnerProgram
        { model = init
        , view = view
        , update = update
        }
