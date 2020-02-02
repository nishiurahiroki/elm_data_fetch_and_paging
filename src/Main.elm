module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Http
import Json.Decode exposing (Decoder, field)
import Task exposing (Task)


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
    id : Int,
    content : String,
    create_date : String
  }

type alias ApiResult =
  {
    result : List Todo
  }

type alias Model =
  {
    key : Nav.Key,
    url : Url.Url,
    todoList : List Todo,
    fetchResult : Maybe String
  }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  ({
    key = key,
    url = url,
    todoList = [],
    fetchResult = Nothing
  }, Cmd.batch [
    Cmd.none
  ])


type Msg =
  LinkClicked Browser.UrlRequest |
  UrlChanged Url.Url |
  GetTodoListTask |
  GetTodoList (Result Http.Error ApiResult)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LinkClicked url ->
      (model, Cmd.none)

    UrlChanged url ->
      (model, Cmd.none)

    GetTodoListTask ->
      (model, Task.attempt GetTodoList fetchTodoTask)

    GetTodoList result ->
      case result of
        Err _ ->
          ({model | fetchResult = Just "fetch fail."}, Cmd.none)

        Ok fetchResult ->
          ({
            model |
              todoList = fetchResult.result,
              fetchResult = Nothing
          }, Cmd.none)


view : Model -> Html Msg
view model =
  div [] [
    div [] [
      text "TODO ID : ",
      input [ type_ "input" ] []
    ],
    div [] [
      button [ onClick GetTodoListTask ] [ text "検索" ]
    ],
    text <| Maybe.withDefault "" <| model.fetchResult,
    table [] [
      tr [] [
        th [] [ text "id" ],
        th [] [ text "内容" ],
        th [] [ text "作成日時" ]
      ],
      tbody []
        <| List.map (\todo ->
            tr [] [
              td [] [ text <| String.fromInt todo.id ],
              td [] [ text todo.content ],
              td [] [ text todo.create_date ]
            ]
           )
        <| model.todoList
    ]
  ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    Sub.none
  ]


apiReusltDecoder : Decoder ApiResult
apiReusltDecoder =
  Json.Decode.map ApiResult
    (field "result" <| Json.Decode.list todoDecoder)


todoDecoder : Decoder Todo
todoDecoder =
  Json.Decode.map3 Todo
    (field "id" Json.Decode.int)
    (field "content" Json.Decode.string)
    (field "create_date" Json.Decode.string)


fetchTodoTask : Task Http.Error ApiResult
fetchTodoTask =
  Http.task {
    method = "GET",
    headers = [],
    url = "/api/v1/todo",
    body = Http.emptyBody,
    resolver = Http.stringResolver <| handleJsonResponse <| apiReusltDecoder,
    timeout = Nothing
  }


handleJsonResponse : Decoder a -> Http.Response String -> Result Http.Error a
handleJsonResponse decoder response =
  case response of
    Http.BadUrl_ url ->
      Err (Http.BadUrl url)

    Http.Timeout_ ->
      Err Http.Timeout

    Http.NetworkError_ ->
      Err Http.NetworkError

    Http.BadStatus_ { statusCode } _ ->
      Err (Http.BadStatus statusCode)

    Http.GoodStatus_ _ body ->
      case Json.Decode.decodeString decoder body of
        Err err ->
          let _ = Debug.log "elm : json parse Error :" err in
          Err (Http.BadBody body)

        Ok result ->
          Ok result
