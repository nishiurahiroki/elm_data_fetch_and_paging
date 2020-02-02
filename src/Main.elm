module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url
import Http
import Task


main : Program () Model Msg
main =
  Browser.application {
    init = init,
    view = \m ->
              {
                title = "elm paging.",
                body = [ view m ]
              },
    update = update,
    subscriptions = subscriptions,
    onUrlChange = UrlChanged,
    onUrlRequest = LinkClicked
  }

type alias Todo =
  {
    id : String,
    content : String,
    createData : String
  }

type alias Model =
  {
    key : Nav.Key,
    url : Url.Url,
    todoList : List Todo
  }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  ({
    key = key,
    url = url,
    todoList = []
  }, Cmd.batch [
    Cmd.none
  ])


type Msg =
  LinkClicked Browser.UrlRequest |
  UrlChanged Url.Url |
  GetTodoListTask


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LinkClicked url ->
      (model, Cmd.none)

    UrlChanged url ->
      (model, Cmd.none)

    GetTodoListTask ->
      (model, Cmd.none)

view : Model -> Html Msg
view model =
  div [] [
    div [] [
      text "TODO ID : ",
      input [ type_ "input" ] []
    ],
    div [] [
      button [] [ text "検索" ]
    ]
  ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    Sub.none
  ]
