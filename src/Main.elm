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
import Url.Parser exposing (Parser, (</>), (<?>),  int, map, oneOf, s, string, top)
import Url.Parser.Query as Query
import List.Extra as ListEx

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
    todos : List Todo,
    totalCount : Int,
    totalPage : Int
  }

type alias PagerCondition =
  {
    currentPage : Int,
    totalPage : Int,
    pageRangeDisplayed : Int,
    customPreviousLabel : Maybe String,
    customNextLabel : Maybe String,
    customPageRangeLabel : Maybe String
  }

type alias Model =
  {
    key : Nav.Key,
    url : Url.Url,
    id : String,
    limit : String,
    todoList : List Todo,
    fetchResult : Maybe String,
    currentPage : Int,
    totalPage : Int
  }


type alias SearchCondition =
  {
    id : String,
    limit : String,
    page : Int
  }

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  ({
    key = key,
    url = url,
    id = "",
    todoList = [],
    limit = "20",
    fetchResult = Nothing,
    currentPage = 1,
    totalPage = 0
  }, Cmd.batch [
    Cmd.none
  ])


type Route =
  Search (Maybe String) (Maybe String) (Maybe Int)

routeParser : Parser (Route -> a) a
routeParser =
  oneOf [
    Url.Parser.map Search (top <?> Query.string "id" <?> Query.string "limit" <?> Query.int "page")
  ]


type Msg =
  LinkClicked Browser.UrlRequest |
  UrlChanged Url.Url |
  GetTodoListTask |
  GetTodoList (Result Http.Error ApiResult) |
  InputId String |
  SelectLimit String |
  ClickPager Int


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LinkClicked url ->
      (model, Cmd.none)

    UrlChanged url ->
      case Url.Parser.parse routeParser url of
        Just route ->
          case route of
              Search id limit page ->
                let
                  searchCondition = {
                      id = Maybe.withDefault "" id,
                      limit = Maybe.withDefault "" limit,
                      page = Maybe.withDefault 1 <| page
                    }
                in
                  ({model |
                      id = Maybe.withDefault "" id,
                      limit = Maybe.withDefault "" limit,
                      currentPage = Maybe.withDefault 1 <| page
                    },
                    Task.attempt GetTodoList <| fetchTodoTask searchCondition
                  )

        Nothing->
          (model, Cmd.none)

    GetTodoListTask ->
      let
        limit = if String.isEmpty model.limit then "20" else model.limit
        searchCondition = {
            id = model.id,
            limit = limit,
            page = 1
          }
      in
        ({model | limit = limit},
          Cmd.batch [
            Nav.pushUrl model.key <| queryString searchCondition
          ]
        )

    GetTodoList result ->
      case result of
        Err _ ->
          ({model | fetchResult = Just "fetch fail."}, Cmd.none)

        Ok fetchResult ->
          ({
            model |
              todoList = fetchResult.todos,
              fetchResult = Nothing,
              totalPage = fetchResult.totalPage
          }, Cmd.none)

    InputId id ->
      ({model | id = id }, Cmd.none)

    SelectLimit limit ->
      let
        searchCondition = {
            id = model.id,
            limit = limit,
            page = 1
          }
      in
        ({model | limit = limit, currentPage = 1},
            Cmd.batch [
              Nav.pushUrl model.key <| queryString searchCondition
            ]
        )

    ClickPager page ->
      let
        searchCondition = {
            id = model.id,
            limit = model.limit,
            page = page
          }
      in
        ({ model | currentPage = page },
          Cmd.batch [
            Nav.pushUrl model.key <| queryString searchCondition
          ]
        )

view : Model -> Html Msg
view model =
  div [] [
    div [] [
      text "TODO ID : ",
      input [ type_ "input", onInput InputId, value model.id ] []
    ],
    div [] [
      button [ onClick GetTodoListTask ] [ text "検索" ],
      select [ onChange SelectLimit, value model.limit ] [
        option [ value "10" ] [ text "10" ],
        option [ value "20" ] [ text "20" ],
        option [ value "50"] [ text "50" ],
        option [ value "100" ] [ text "100" ]
      ],
      viewPager {
        currentPage = model.currentPage,
        totalPage = model.totalPage,
        pageRangeDisplayed = 2,
        customPreviousLabel = Nothing,
        customNextLabel = Nothing,
        customPageRangeLabel = Nothing,
        onChangePage = ClickPager
      }
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


viewPager :
  {
    currentPage : Int,
    totalPage : Int,
    pageRangeDisplayed : Int,
    customPreviousLabel : Maybe String,
    customNextLabel : Maybe String,
    customPageRangeLabel : Maybe String,
    onChangePage : Int -> msg
  } -> Html msg
viewPager {
    currentPage,
    totalPage,
    pageRangeDisplayed, -- TODO
    customNextLabel,
    customPreviousLabel,
    customPageRangeLabel, -- TODO
    onChangePage
  } =
    let
      pageButtonList = List.map (\page ->
                                    if currentPage == page then
                                      button [ disabled True, onClick <| onChangePage page ] [ text <| String.fromInt page ]
                                    else
                                      button [ onClick <| onChangePage page ] [ text <| String.fromInt page ]
                                )
                          <| List.range 1 totalPage
      firstButtonList  = List.take pageRangeDisplayed -- TODO current move selected.
                               <| pageButtonList
      secondButtonList = List.take pageRangeDisplayed
                               <| List.reverse pageButtonList

      buttonTotalCount = (List.length firstButtonList) + (List.length secondButtonList)
      betweenText = if buttonTotalCount < totalPage then
                        text "..."
                    else
                        text ""

      isFirstPage = (==) currentPage 1
      isLastPage = (||) (totalPage < 1) <| (==) currentPage totalPage
    in
      span []
        <| List.append [ button [ onClick <| onChangePage <| (-) currentPage 1, disabled isFirstPage ] [ text <| Maybe.withDefault "←" customPreviousLabel ] ]
        <| List.append firstButtonList
        <| List.append [ betweenText ]
        <| List.append secondButtonList
        <| List.singleton (button [ onClick <| onChangePage <| (+) currentPage 1, disabled isLastPage ] [ text <| Maybe.withDefault "→" customNextLabel ])


apiReusltDecoder : Decoder ApiResult
apiReusltDecoder =
  Json.Decode.map3 ApiResult
    (field "todos" <| Json.Decode.list todoDecoder)
    (field "totalCount" Json.Decode.int)
    (field "totalPage" Json.Decode.int)


todoDecoder : Decoder Todo
todoDecoder =
  Json.Decode.map3 Todo
    (field "id" Json.Decode.int)
    (field "content" Json.Decode.string)
    (field "create_date" Json.Decode.string)


fetchTodoTask : SearchCondition -> Task Http.Error ApiResult
fetchTodoTask searchCondition =
  Http.task {
    method = "GET",
    headers = [],
    url = (++) "/api/v1/todo" <| queryString searchCondition,
    body = Http.emptyBody,
    resolver = Http.stringResolver <| handleJsonResponse apiReusltDecoder,
    timeout = Nothing
  }


queryString : SearchCondition -> String
queryString { id, limit, page } =
     "?id=" ++ id ++
     "&limit=" ++ limit ++
     "&page=" ++ String.fromInt page


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


onChange : (String -> msg) -> Attribute msg
onChange handler =
  on "change" <| Json.Decode.map handler Html.Events.targetValue


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    Sub.none
  ]
