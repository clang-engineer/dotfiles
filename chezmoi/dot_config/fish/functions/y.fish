function y --description 'Yazi를 열고 마지막 디렉터리로 이동'
    set -l tmp (command mktemp -t yazi-cwd.XXXXXX); or return
    command yazi $argv --cwd-file="$tmp"
    set -l result $status

    # NUL 종료와 EOF 모두 허용하고 공백 및 줄바꿈을 그대로 보존한다.
    set -l cwd
    read --null --delimiter '' cwd < "$tmp"
    if test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
        builtin cd -- "$cwd"
        set -l cd_status $status
        if test "$result" -eq 0
            set result $cd_status
        end
    end

    command rm -f -- "$tmp"
    set -l cleanup_status $status
    if test "$result" -eq 0
        set result $cleanup_status
    end
    return "$result"
end
