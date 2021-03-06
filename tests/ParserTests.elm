module ParserTests exposing (portNameAndDirection, suite)

import Expect exposing (Expectation)
import Parser.Context
import Test exposing (..)
import TypeScript.Data.Port
import TypeScript.Data.Program
import TypeScript.Parser


portNameAndDirection : TypeScript.Data.Port.Port -> ( String, TypeScript.Data.Port.Direction )
portNameAndDirection (TypeScript.Data.Port.Port context name kind _) =
    ( name, kind )


suite : Test
suite =
    describe "parser"
        [ test "program with no ports" <|
            \_ ->
                [ """
                  module Main exposing (main)

                  thereAreNoPorts = True
                """
                ]
                    |> toContexts
                    |> Result.map TypeScript.Parser.extractPorts
                    |> Result.map (List.map portNameAndDirection)
                    |> Expect.equal (Ok [])
        , test "program with flags" <|
            \_ ->
                """
port module Main exposing (main)

import Html exposing (..)

type Msg
    = NoOp


type alias Model =
    Int


view : Model -> Html Msg
view model =
    div []
        [ text (toString model) ]


init : String -> ( Model, Cmd Msg )
init flags =
    ( 0, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


main : Program String Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = \\_ -> Sub.none
        }
                """
                    |> toSourceFile
                    |> TypeScript.Parser.parseSingle
                    |> (\parsedProgram ->
                            case parsedProgram of
                                Ok (TypeScript.Data.Program.ElmProgram flagsType _ ports) ->
                                    Expect.pass

                                unexpected ->
                                    Expect.fail ("Expected program with flags, got " ++ toString unexpected)
                       )
        , test "program without flags" <|
            \_ ->
                """
port module Main exposing (main)

import Html exposing (..)

type Msg
    = NoOp


type alias Model =
    Int


view : Model -> Html Msg
view model =
    div []
        [ text (toString model) ]


init : ( Model, Cmd Msg )
init flags =
    ( 0, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \\_ -> Sub.none
        }
                """
                    |> toSourceFile
                    |> TypeScript.Parser.parseSingle
                    |> (\parsedProgram ->
                            case parsedProgram of
                                Ok (TypeScript.Data.Program.ElmProgram [ { flagsType } ] _ ports) ->
                                    flagsType
                                        |> Expect.equal Nothing

                                unexpected ->
                                    Expect.fail ("Expected program without flags, got " ++ toString unexpected)
                       )
        , test "main with simple Html return value" <|
            \_ ->
                """
port module Main exposing (main)

import Html exposing (..)


main : Html msg
main =
    text "Hello World!"
                                       """
                    |> toSourceFile
                    |> TypeScript.Parser.parseSingle
                    |> (\parsedProgram ->
                            case parsedProgram of
                                Ok (TypeScript.Data.Program.ElmProgram [ { flagsType } ] _ ports) ->
                                    flagsType
                                        |> Expect.equal Nothing

                                unexpected ->
                                    Expect.fail ("Expected program without flags, got " ++ toString unexpected)
                       )
        , test "program with an outbound ports" <|
            \_ ->
                [ """
                  module Main exposing (main)

                  port showSuccessDialog : String -> Cmd msg

                  port showWarningDialog : String -> Cmd msg
                """
                ]
                    |> toContexts
                    |> Result.map TypeScript.Parser.extractPorts
                    |> Result.map (List.map portNameAndDirection)
                    |> Expect.equal
                        (Ok
                            [ ( "showSuccessDialog", TypeScript.Data.Port.Outbound )
                            , ( "showWarningDialog", TypeScript.Data.Port.Outbound )
                            ]
                        )
        , test "program with an inbound ports" <|
            \_ ->
                [ """
                                 module Main exposing (main)

                                 port localStorageReceived : (String -> msg) -> Sub msg

                                 port suggestionsReceived : (String -> msg) -> Sub msg
                               """
                ]
                    |> toContexts
                    |> Result.map TypeScript.Parser.extractPorts
                    |> Result.map (List.map portNameAndDirection)
                    |> Expect.equal
                        (Ok
                            [ ( "localStorageReceived", TypeScript.Data.Port.Inbound )
                            , ( "suggestionsReceived", TypeScript.Data.Port.Inbound )
                            ]
                        )
        ]


toContexts : List String -> Result String (List Parser.Context.Context)
toContexts fileContents =
    fileContents
        |> List.map
            (\fileContent -> { path = "FAKE", contents = fileContent })
        |> TypeScript.Parser.extractContexts


toSourceFile : a -> { contents : a, path : String }
toSourceFile fileContent =
    { path = "FAKE", contents = fileContent }
