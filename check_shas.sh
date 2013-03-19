#!/bin/sh

REMOTE_BRANCH="origin/master"
LOCAL_BRANCH="HEAD"
EXEC_CMD=""

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -e \"command_to_run_for_each_sha\""
  echo ""
  echo "Options:"
  echo "-r, --remote-branch     The remote branch to verify against, (default=origin/master)"
  echo "-l, --local-branch      The local branch to which defines the sha set to be checked, (default=HEAD)"
  echo "-e, --exec              Command to execute for each sha"
  echo "-h, --help              Print this message"
  echo ""
}

function print_missing_argument {
    echo ""
    echo "Missing argument for $1"
    echo ""
    print_usage
    exit 1
}

function print_unknown_argument {
    echo ""
    echo "Unknown argument: $1"
    echo ""
    print_usage
    exit 1
}

function process_arguments {
    while [ ! -z $1 ]; do
        case "$1" in
            -r|--remote-branch)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                REMOTE_BRANCH=$2
                shift 2
                ;;
            -l|--local-branch)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                LOCAL_BRANCH=$2
                shift 2
                ;;
            -e|--exec)
                shift 1
                while [ ! -z $1 ] && [[ "$1" != *\" ]]; do
                    EXEC_CMD="$EXEC_CMD $1"
                    shift 1
                done
                EXEC_CMD="$EXEC_CMD $1"
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                print_unknown_argument $1
                shift
                ;;
        esac
    done

    if [ -z "$EXEC_CMD" ]; then
        echo "Please specify the exec option"
        echo $EXEC_CMD
        print_usage
        exit 1;
    fi
}

process_arguments $@
SHAS=$(git log --reverse --oneline $REMOTE_BRANCH..$LOCAL_BRANCH)
echo "$SHAS" > check_shas.txt

while read line; do

    read SHA << $line

    git reset --hard $SHA
    LOG_FILE=out_log_$SHA.txt
    $EXEC_CMD 2>&1> $LOG_FILE
    if [ $? -ne 0 ]; then
        echo "Exited with failure on sha: $SHA"
        exit 1
    fi
    rm $LOG_FILE
done <<< "$SHAS"

echo "SUCCESS!"
