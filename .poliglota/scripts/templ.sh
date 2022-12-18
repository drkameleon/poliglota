#! /bin/bash

## Configuration

## Imports:
##  $STD_CONFIG_PATH
##  $STD_POLI_PATH
##  $STD_REPO_PATH
##  $STD_TEMPL_PATH
##  $STD_PLUGINS_PATH
##  $LAST_PROJECT
# shellcheck source=poli.config
source "poli.config"

set -o noclobber # Prevent overwriting of files by redirection

# --- Global internal functions ---

description() {
    echo "templ                                                               "
    echo "    add                           creates a new template            "
    echo "    rm                            removes an exiting template       "
}


usage() {
    echo "templ command                                                       "
    echo "  poli templ [OPTIONS]... [SUBCOMMANDS]                             "
    echo
    echo "  SUBCOMMANDS                                                       "
    echo
    echo "    add <new-template>            creates a new template            "
    echo "      --from|-f <template2>       uses an existing template as base "
    echo
    echo "    rm <template>                 removes an exiting template       "
    echo
    echo "  OPTIONS                                                           "
    echo "    --help|-h                     shows this help page              "
}


## Sets the minimal arguments required by a command
## Arguments:
##  $wrong_input
## Output:
##  Prints an error message and the usage
## Returns:
##  exit "$E_BADARGS"
raise_wrong_arguments_input() {
    local -r wrong_input="$1"
    local -r E_BADARGS=85 ## Bad Arguments error value

    set +o noclobber
    echo "Wrong input: ${wrong_input}" >> /dev/stderr # > stderr

    echo
    usage
    exit "${E_BADARGS}"

}

## Sets the minimal arguments required by a command
## Arguments:
##  $minimal: minimal arguments to be able run
##  $arg_count: current arguments count
## Output:
##  Prints an error message and the usage
## Returns:
##  raise_wrong_arguments_input, if assert fails
assert_minimal_arguments() {

    local -r -i minimal=$1
    local -r -i arg_count=$2

    if [[ $minimal -gt $arg_count ]]; then
        raise_wrong_arguments_input \
            "The minimal arguments amount is ${minimal}."
    fi

}

assert_arguments_count() {
    local -r -i count_to_match=$1
    local -r -i      arg_count=$2

    if [[ $count_to_match = $arg_count ]]; then
        raise_wrong_arguments_input \
            "The right arguments amount is ${count_to_match}."
    fi
}


## Add a new template to template's folder
## Arguments:
##  $template_folder: template's folder
##  $template_name: template's name
##  $from: the existing template to be used as base
add_template() {

    local -r template_folder="$1"
    local -r template_name="$2"
    local -r from="$3"

    mkdir "${template_folder:?}/${template_name:?}"

    cp -r -b --no-preserve=timestamp            \
        "${template_folder:?}/${from:?}/"**         \
        "${template_folder:?}/${template_name:?}/"

}

## [Command]: Creates a new template
## Command Arguments:
##   $new_template: name of the new template
## Command Options:
##  --from|-f: uses another template as base to the new
## Arguments:
##   $@: arguments to parse
## Globals:
##  $STD_TEMPL_PATH
## Returns:
##  assert_minimal_arguments
##  raise_wrong_arguments_input
add_command() {

    assert_minimal_arguments "1" "$#"

    local -r templ="${STD_TEMPL_PATH}" ## Template's folder path
    local new_template=""           ## The implementation to be used
    local from=".template"

    while  [[ -n "$1" ]]; do
        case "$1" in
        "--from" | "-f")
            from="$2"
            shift
            ;;
        "-"*)
            raise_wrong_arguments_input "$1" # badargs, exits
            ;;
        *)
            new_template="$1"
            ;;
        esac
        shift
    done

    if [[ -z "${new_template}" ]]; then
        raise_wrong_arguments_input "New template name is missing"
    fi

    add_template "${templ:?}" "${new_template:?}" "${from:?}"

}


## [Command]: Removes a template
## Command Arguments:
##   $template: name of the template to be removed
## Arguments:
##   $1: argument to parse
## Globals:
##  $STD_TEMPL_PATH
## Returns:
##  assert_minimal_arguments
##  raise_wrong_arguments_input
rm_command() {

    assert_minimal_arguments "1" "$#"

    local -r templ="${STD_TEMPL_PATH}" ## Template's folder path
    local template="$1"

    if [[ -z "${template}" ]]; then
        raise_wrong_arguments_input \
            "New template name is missing"
    fi

    rm --recursive "${templ:?}/${template:?}/" ||
        ( echo "Couldn't cleanup directory"         \
            >> /dev/stderr                          \
            && raise_cannot_execute )

}


# --- Script functions ---

## [Script] Parses the arguments and calls the right commands
## Script Commands:
##   add
##   rm
## Script Options:
##  --help
##  --description
## Arguments:
##   $@: arguments to parse
## Returns:
##  test_minimal_args
##  create_implementation_with_template
##  create_empty_implementation
##  raise_wrong_arguments_input, for wrong arguments
main() {

    assert_minimal_arguments "1" "$#"

    case "$1" in
    "--description")
        description
        ;;
    "--help" | "-h")
        usage
        ;;
    "add")
        shift
        add_command "$@"
        ;;
    "rm")
        shift
        rm_command "$@"
        ;;
    *)
        raise_wrong_arguments_input "$1"
        ;;
    esac

    exit

}

main "$@"