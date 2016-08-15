module Components.LiveSearch exposing (update, view, search, Msg)

import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import String
import Material
import Material.Textfield as Textfield
import Material.Color as Color
import Material.Options as Options

import Models exposing (..)


type Msg
    = SearchInput String
    | SearchEscape
    | Mdl (Material.Msg Msg)


compareCaseInsensitve : String -> String -> Bool
compareCaseInsensitve s1 s2 =
    String.contains (String.toLower s1) (String.toLower s2)


{-| Filter project by Project name or Jobset name
-}
searchProject : String -> Project -> Project
searchProject searchstring project =
    let
        projectFilteredJobsets =
            { project | jobsets = List.map (filterByName searchstring) project.jobsets }

        hasJobsets =
            List.any (\j -> j.isShown) projectFilteredJobsets.jobsets

        newproject =
            filterByName searchstring project
    in
        if
            newproject.isShown
            -- if project matches, display all jobsets
        then
            { newproject | jobsets = List.map (\j -> { j | isShown = True }) newproject.jobsets }
        else if
            hasJobsets
            -- if project doesn't match, only display if any of jobsets match
        then
            { projectFilteredJobsets | isShown = True }
        else
            newproject


filterByName : String -> { b | name : String, isShown : Bool } -> { b | name : String, isShown : Bool }
filterByName searchstring project =
    if compareCaseInsensitve searchstring project.name then
        { project | isShown = True }
    else
        { project | isShown = False }


{-| Filter any record by isShown field

    TODO: recursively apply all lists in the structure
-}
search : List { a | isShown : Bool } -> List { a | isShown : Bool }
search projects =
    List.filter (\x -> x.isShown) projects


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update msg model =
    case msg of
        SearchInput searchstring ->
            let
                newprojects =
                    List.map (searchProject searchstring) model.projects
            in
                ( { model
                    | projects = newprojects
                    , searchString = searchstring
                  }
                , Cmd.none
                )

        -- on Escape, clear search bar and return all projects/jobsets
        SearchEscape ->
            ( { model
                | searchString = ""
                , projects = List.map (searchProject "") model.projects
              }
            , Cmd.none
            )
        Mdl msg' ->
              Material.update msg' model


view : AppModel -> Html (Msg)
view model =
  Textfield.render Mdl [0] model.mdl
    [ Textfield.label "Search"
    , Textfield.floatingLabel
    , Textfield.text'
    , Textfield.onInput SearchInput
    , onEscape SearchEscape
    , Textfield.value model.searchString
    , Textfield.style [ Options.css "border-radius" "0.5em"
                      , Color.background Color.primaryDark ]
    ]

onEscape : msg -> Textfield.Property msg
onEscape msg =
    Textfield.on "keydown" (Json.map (always msg) (Json.customDecoder keyCode isEscape))


isEscape : Int -> Result String ()
isEscape code =
    case code of
        27 ->
            Ok ()

        _ ->
            Err "not the right key code"
