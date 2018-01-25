#!/bin/bash

# >> GLOBALES VARIABLES

SUCCESS=0
FAILURE=1

HELP="Usage: $0 [OPTION]... [COMMAND] [REQUEST]
OPTION:
  -h		display usage
  -f FILE	json database file
  -j		json formated output for select command"

# > JSON BDD Path

BDD_FILE="${BDSH_File}"

if [ -f ".bdshrc" ]; then
    BDD_FILE="$(cat .bdshrc)"
fi

FILE=""
DB_VALUE=""
TABLE_VALUE=()

# >> Functions

function print_error {
    printf "%s\n" "$1" 1>&2
    return $FAILURE
}

function is_readable {
        if [ -r "$BDD_FILE" ]; then
                return $SUCCESS
        fi
        return $FAILURE
}

function is_writable {
        if [ -w "$BDD_FILE" ]; then
                return $SUCCESS
        fi
        return $FAILURE
}

function database_in_file {
        is_readable "$BDD_FILE"
        if [ $? == $FAILURE ]; then
                print_error "Error: '$BDD_FILE' unreadable."
                return $FAILURE
        fi

        grep -nwF "$1" <"$BDD_FILE" >/dev/null
        if [ $? == $FAILURE ]; then
                print_error "Error: '$DATABASE' not in '$BDD_FILE'"
                return $FAILURE
        fi
        return $SUCCESS
}

function get_value_from_table {
        res="$(grep -wF "$1" <<< $DB_VALUE | cut -d ':' -f2)"
        TABLE_VALUE=()
        for line in $res; do
                line=${line#" "}
                line=${line#"\""}
                line=${line%","}
                line=${line%"\""}
                TABLE_VALUE+=($line'\\')
        done
}

function select_db {
    DATABASE="data_$1"
    find_db_value "$DATABASE"
    tables="$(tr ',' '\n' <<< $2)"
    tables_arr=()
    max_len=()
    i=0
    lines=()
    for table in $tables; do
            get_value_from_table "$table"
            dict_value[$i]=${TABLE_VALUE[*]}
            tables_arr[$i]=$table
            lines[$i]=""
            let i++
    done

    f=0
    for index in "${!dict_value[@]}"; do
           max_len[$index]=${#tables_arr[$index]}
           for value in ${dict_value[$index]}; do
                   if [[ ${#value} > ${max_len[$index]} ]]; then
                           max_len[$index]="$(expr ${#value} - 2)"
                   fi
                   let f++
           done
           if [ $index == 0 ]; then
                   lines[0]+="$(printf "%-${max_len[$index]}s |" "${tables_arr[$index]}")"
           elif [ $index == "$(expr $i - 1)" ]; then
                   lines[0]+="$(printf "  %-${max_len[$index]}s" "${tables_arr[$index]}")"
           else
                   lines[0]+="$(printf "  %-${max_len[$index]}s  |" "${tables_arr[$index]}")"
           fi
           f=2
           for value in ${dict_value[$index]}; do
                   value=${value%"\\\\"}
                   if [ $index == 0 ]; then
                           lines[$f]+="$(printf "%-${max_len[$index]}s |" "$value")"
                   elif [ $index == "$(expr $i - 1)" ]; then
                           lines[$f]+="$(printf "  %-${max_len[$index]}s" "$value")"
                   else
                           lines[$f]+="$(printf "  %-${max_len[$index]}s  |" "$value")"
                   fi
                   let f++
           done
    done

    for ((i=0 ; i < ${#lines[0]} ; i++)); do
            lines[1]+="-"
    done

    f=0
    for line in "${lines[@]}"; do
            printf "%s\n" "$line"
    done
}

function find_db_value {
        START="$(grep -nwF "$DATABASE" < $BDD_FILE | cut -d ':' -f1)"
        LEN="$(expr "$(wc -l < $BDD_FILE | cut -d ' ' -f1)" - $START)"
        END="$(expr "$(tail -n $LEN < $BDD_FILE | grep -nwF "]" | cut -d ':' -f1 | head -n 1)" - 1)"

        DB_VALUE="$(tail -n $LEN < $BDD_FILE | head -n $END)"
}

function describe_db {
        DATABASE="desc_$1"

        database_in_file "$DATABASE"
        if [ $? == $FAILURE ]; then
                return $FAILURE
        fi

        find_db_value "$DATABASE"
        for line in $DB_VALUE; do
                printf "%s\n" "$(echo $line | tr -d "\t, \"")"
        done
        return $SUCCESS
}

function is_creating_db {
        for var in "$@"
        do
                if [ "$var" = "create" ]; then
                        return $SUCCESS
                fi
        done
        return $ERROR
}

function change_bdd_file {
        if [ -e "$BDD_FILE" ]; then
                if [ -f "$BDD_FILE" ]; then
                        FILE="$(cat $BDD_FILE)"
                        return $SUCCESS
                else
                        print_error "Error: '$BDD_FILE' isn't a regular file."
                fi
        else
                is_creating_db "$@"
                if [ $? == $SUCCESS ]; then
                        return $SUCCESS
                fi
                print_error "Error: '$BDD_FILE' doesn't exist."
        fi
        return $FAILURE
}

function new_db {
        if [ ! -e "$BDD_FILE" ]; then
                printf "{\n\t\n}" >> "$BDD_FILE"
        else
                print_error "Error: '$BDD_FILE' already exists."
        fi
}

function create_table_attr {
        table_name="$1"
        shift
        arg=$(echo "$1" | tr "," "\n")
        it=0

        for var in $arg
        do

                if [ "$it" == 0 ]; then
                        FILE=$(sed "/desc_"$table_name"/a\ \t\t\""$var"\"" "$BDD_FILE")
                else
                        FILE=$(sed "/desc_"$table_name"/a\ \t\t\""$var"\"\," "$BDD_FILE")
                fi
                it=1
                echo "$FILE" > "$BDD_FILE"
        done
}

function check_table {
        cat "$BDD_FILE" | grep -qwF "$1"
        if [ $? -eq 0 ]; then
                print_error "Error: '$1': Table already exist"
                exit 1
        fi

}

function is_db_empty {
        cat "$BDD_FILE" | grep -q desc
        return "$?"
}

function new_table {
        check_table "$1"
        is_db_empty
        if [ "$?" -eq 0 ]; then
                sed -i "/]$/a,\n\t\"desc_"$1"\": [\n\t],\n\t\"data_"$1"\": [\n\t]" "$BDD_FILE"
        else
                sed -i "/{/a\ \t\"desc_"$1"\": [\n\t],\n\t\"data_"$1"\": [\n\t]" "$BDD_FILE"
        fi
        create_table_attr "$@"
        exit $?
}

function create_db {
        while [ $# != 0 ]; do
                case "$1" in
                        "database") new_db "$@";;
                        "table") shift
                                new_table "$@";;
                        *) print_error "Error: 'create': Bad argument"
                                exit $FAILURE;;
                esac
                shift
        done
}

function main {
    while [ $# != 0 ]; do
        case "$1" in
            "-h") printf "%s\n" "$HELP"
                  return $SUCCESS;;
            "-f") shift
                  BDD_FILE="$1"
                  change_bdd_file "$1";;
            "-j") ;;
            "select") shift
                      select_db "$@"
                      shift;;
            "describe") shift
                        describe_db "$@";;
            "insert") shift;;
            "create") shift
                        create_db "$@"
                        shift;;
            *) print_error "Error: '$1': Bad argument"
                return $FAILURE;;
        esac
        if [ $? == $FAILURE ]; then
                return $FAILURE
        fi
        shift
    done

    return $SUCCESS
}

# >> Initialization

if [ $# == 0 ]; then
        print_error "$HELP"
else
        main "$@"
fi
