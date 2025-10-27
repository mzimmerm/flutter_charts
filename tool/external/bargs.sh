#!/usr/bin/env bash

# Check current "set -e" status and save it to a variable
if [[ $- == *e* ]]; then
    _BARGS_SET_E_ENABLED=1
else
    _BARGS_SET_E_ENABLED=0
fi

# Check current "set -x" status and save it to a variable
if [[ $- == *x* ]]; then
    _BARGS_SET_X_ENABLED=1
else
    _BARGS_SET_X_ENABLED=0
fi

# Check current "set -o pipefail" status and save it to a variable
if [[ $- == *o* ]]; then
    _BARGS_SET_O_ENABLED=1
else
    _BARGS_SET_O_ENABLED=0
fi

# Disable "set -e", "set -x" and "set -o pipefail"
set +exo pipefail


restore_values(){
    if [[ $_BARGS_SET_E_ENABLED -eq 1 ]]; then
        set -e
    fi
    if [[ $_BARGS_SET_X_ENABLED -eq 1 ]]; then
        set -x
    fi
    if [[ $_BARGS_SET_O_ENABLED -eq 1 ]]; then
        set -o pipefail
    fi
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
ctrl_c() {
    restore_values
    exit 0
}

### Global variables
_BARGS_VARS_PATH=""
_ARGS=""
_NUM_OF_ARGS=0
declare -A _LIST_ARGS_DICTS
_NUM_OF_DICTS=0


### Functions
error_msg(){
    local msg=$1
    local no_usage=$2
    echo -e "[ERROR] $msg"
    [[ -z $no_usage ]] && usage
    export DEBUG=1
    restore_values
    exit 1
}


hint_msg(){
    local msg=$1
    echo -e "[HINT] $msg"
}


export_env_var(){
    local var_name=$1
    local var_value=$2
    export "${var_name}=${var_value}"
    export "${var_name^^}=${var_value}"
}


check_options(){
    local options=$1
    local var_name=$2
    local var_value=$3
    local allow_empty=$4
    local valid=false
    if [[ -n $options ]]; then
        for o in $options; do
            [[ $o = "$var_value" ]] && valid=true
        done
    elif [[ -z $var_value && -n $allow_empty ]]; then
        valid=true
    elif [[ -n $var_value ]]; then
        valid=true
    fi
    echo $valid
}


usage (){
    local usage_msg=
    local i=0
    declare -A arg_dict
    while [[ $i -lt $_NUM_OF_DICTS ]]; do
        eval "arg_dict=(${_LIST_ARGS_DICTS[$i]})"
        if [[ ${arg_dict[name]} = "bargs" ]]; then
            echo -e "\nUsage: ${arg_dict[description]}\n"
        elif [[ ${arg_dict[type]} = "group" ]]; then
            : # group do nothing
        elif [[ -n ${arg_dict[name]} ]]; then
            usage_msg+="\n\t--${arg_dict[name]}~|~-${arg_dict[short]}"
            if [[ -n ${arg_dict[flag]} ]]; then
                usage_msg+="~[FLAG]"
            elif [[ -n ${arg_dict[allow_empty]} ]]; then
                usage_msg+="~[]"
            elif [[ -n ${arg_dict[default]} ]]; then
                usage_msg+="~[${arg_dict[default]}]"
            elif [[ ${arg_dict[allow_env_var]} ]]; then
                usage_msg+="~[ENV_VAR]"
            else
                 usage_msg+="~[REQUIRED]"
            fi

            if [[ -n ${arg_dict[description]} ]]; then
                usage_msg+="~${arg_dict[description]}"
            fi
            usage_msg="$usage_msg\n"
        fi
        i=$((i+1))
    done

    echo -e "$usage_msg" | column -t -s "~"
}


clean_chars(){
    local str=$1
    str=${str//\'/}
    str=${str//\"/}
    echo "$str"
}


check_bargs_vars_path(){
    local bargs_vars_path
    if [[ -n "$BARGS_VARS_PATH" && -f "$BARGS_VARS_PATH" ]]; then
        _BARGS_VARS_PATH="$BARGS_VARS_PATH"
    elif [[ -z "$BARGS_VARS_PATH" || ! -f "$BARGS_VARS_PATH" ]]; then
        bargs_vars_path=$(dirname "${BASH_SOURCE[0]}")/.run_screenshot_create_then_validate_integration_test_bargs_vars
        [[ ! -f $bargs_vars_path ]] && error_msg "Make sure bargs_vars is in the same folder as bargs.sh\n\tAnother option - export BARGS_VARS_PATH=\"\${PWD}/path/to/my_bargs_vars\"" no_usage    
        _BARGS_VARS_PATH="$bargs_vars_path"
    else
        error_msg "Invalid path to bargs_vars: $BARGS_VARS_PATH"
    fi
}


read_bargs_vars(){
    # Reads the file, saving each arg as one string in the string ${args}
    # The arguments are separated with "~" 
    check_bargs_vars_path
    local delimiter="---"
    local arg_name
    local arg_value
    local str
    local line
    while read -r line; do
        if [[ $line != "$delimiter" ]]; then
            line=$(clean_chars "$line")
            arg_name=$(echo "$line"  | cut -f1 -d "=")
            arg_value=$(echo "$line" | cut -f2 -d "=")
            [[ -z $str ]] && \
                str="[${arg_name}]=\"${arg_value}\"" || \
                str="${str} [${arg_name}]=\"${arg_value}\""

        elif [[ $line = "$delimiter" ]]; then
            _NUM_OF_ARGS=$((_NUM_OF_ARGS+1))
            [[ -n $str ]] && _ARGS="$_ARGS~$str"
            unset str
        fi        
    done < "$_BARGS_VARS_PATH"
}


args_to_list_dicts(){
    # _ARGS to list of dictionaries (associative arrays)
    local cut_num=1
    local arg=
    while [[ $cut_num -le $((_NUM_OF_ARGS+1)) ]]; do
        arg=$(echo "${_ARGS[@]}" | cut -d "~" -f $cut_num)
        if [[ ${#arg} -gt 0 ]]; then
            _LIST_ARGS_DICTS[$_NUM_OF_DICTS]=$arg
            _NUM_OF_DICTS=$((_NUM_OF_DICTS+1))
        fi
        cut_num=$((cut_num+1))
    done
}


set_args_to_vars(){
    # The good old 'while case shift'
    declare -A arg_dict
    local i
    local found
    local definition
    local contains_equal
    local value
    while [[ -n $1 ]]; do
        i=0
        found=
        while [[ $i -lt $_NUM_OF_DICTS ]]; do
            eval "arg_dict=(${_LIST_ARGS_DICTS[$i]})"
            contains_equal=$(echo "$1" | grep "^[\-|\-\-]*\w*=")
            if [[ -n $contains_equal ]]; then
                definition=${1%=*} # "--definition=value"
            else
                definition=$1 # "--definition value"
            fi

            case "$definition" in
                -h | --help )
                    usage
                    export DEBUG=0
                    restore_values
                    exit 0
                ;;
                -"${arg_dict[short]}" | --"${arg_dict[name]}" )
                    if [[ -n $contains_equal ]]; then
                        value=${1#*=}
                    elif [[ -z ${arg_dict[flag]} ]]; then
                        shift
                        value=$1
                    elif [[ -n ${arg_dict[flag]} ]]; then
                        value=$1
                    fi

                    if [[ -z $value && -n ${arg_dict[allow_env_var]} ]]; then
                        declare -n env_var_value=${arg_dict[name]^^}
                        export_env_var "${arg_dict[name]}" "$env_var_value"
                    elif [[ -z $value && -z ${arg_dict[default]} ]]; then
                        # arg is empty and default is empty
                        error_msg "Empty argument \"${arg_dict[name]}\""
                    elif [[ -z $value && -n ${arg_dict[default]} ]]; then
                        # arg is empty and default is not empty
                        export_env_var "${arg_dict[name]}" "${arg_dict[default]}"
                        found=${arg_dict[name]}
                    elif [[ -n $value ]]; then
                        # arg is not empty
                        if [[ -n ${arg_dict[flag]} ]]; then
                        # it's a flag
                            export_env_var "${arg_dict[name]}" true
                        else
                        # not a flag, regular argument
                            export_env_var "${arg_dict[name]}" "$value"
                        fi
                        found=${arg_dict[name]}
                    fi
                ;;
            esac
            i=$((i+1))
        done
        [[ -z $found ]] && error_msg "Unknown argument \"$definition\""
        shift
    done
}


export_args_validation(){
    # Export variables only if passed validation test
    declare -A arg_dict
    local result
    local default
    local hidden
    local prompt_value
    local confirm_value
    local valid
    local i=0
    while [[ $i -lt $_NUM_OF_DICTS ]]; do
        eval "arg_dict=(${_LIST_ARGS_DICTS[$i]})"
        result=$(printenv | grep "^${arg_dict[name]}=" | cut -f2 -d "=")
        if [[ -z $result ]]; then
            default=${arg_dict[default]}
            if [[ -n ${arg_dict[allow_env_var]} ]]; then
                # set default to env var only if env var is UPPERCASED
                declare -n env_var_value=${arg_dict[name]^^}
                [[ -n $env_var_value ]] && default=$env_var_value
            fi

            if [[ -n $default ]]; then
                export_env_var "${arg_dict[name]}" "${default}"      
            elif [[ -n ${arg_dict[allow_empty]} || -n ${arg_dict[flag]} ]]; then
                export_env_var "${arg_dict[name]}" ""
            elif [[ -n ${arg_dict[prompt]} ]]; then
                # will not prompt if default is not empty
                hidden=
                [[ -n ${arg_dict[hidden]} ]] && hidden=s
                prompt_value=
                trap 'trap - INT; kill -s HUP -- -$$' INT
                while :; do
                    echo -n "${arg_dict[name]^^}: "
                    read -re${hidden} prompt_value
                    [[ -n $hidden ]] && echo ""
                    if [[ -n ${arg_dict[confirmation]} ]]; then
                        while :; do
                            confirm_value=
                            echo -n "${arg_dict[name]^^} Confirmation: "
                            read -re${hidden} confirm_value
                            [[ -n $hidden ]] && echo ""
                            [[ $prompt_value = "$confirm_value" ]] && break
                        done
                    fi
                    valid=$(check_options "${arg_dict[options]}" "${arg_dict[name]}" "$prompt_value" "${arg_dict[allow_empty]}")
                    if [[ $valid = "true" ]]; then
                        [[ -n ${arg_dict[hidden]} ]] && echo ""
                        break
                    else
                        [[ -n ${arg_dict[options]} ]] && hint_msg "Valid options: ${arg_dict[options]}"
                    fi
                done
                export_env_var "${arg_dict[name]}" "${prompt_value}"
            elif [[ -z $default && ${arg_dict[type]} != "group" ]]; then
                error_msg "Required argument: ${arg_dict[name]}"
            fi
        elif [[ -n $result ]]; then
            valid=$(check_options "${arg_dict[options]}" "${arg_dict[name]}" "$result" "${arg_dict[allow_empty]}")
            if [[ $valid != "true" ]]; then
                hint_msg "Valid options: ${arg_dict[options]// / OR }"
                error_msg "Invalid value \"${result}\" for the argument \"${arg_dict[name]}\""
            fi
            : # argument is valid
        fi
        i=$((i+1))
    done
}

### Main
read_bargs_vars
args_to_list_dicts
set_args_to_vars "$@" # <-- user input
export_args_validation
restore_values
