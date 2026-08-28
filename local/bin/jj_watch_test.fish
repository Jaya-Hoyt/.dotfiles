#!/usr/bin/env fish

function setup_hermetic_env
    # Clean up mock functions from previous test runs
    functions -e jj stat read sleep printf git \
        __jj_watch_ext_extra_flags __jj_watch_ext_probe \
        __jj_watch_ext_handle_cd_failure __jj_watch_ext_handle_root_failure \
        __jj_watch_ext_check_workspace \
        __jj_watch_file_stats __jj_watch_file_mtime

    # Clean up test-scoped global variables
    set -e recorded_jj_calls recorded_pagers root_call_args bytes_at_diff bytes_at_log \
        err_bytes_at_diff err_bytes_at_log render_count sleep_count loop_sleeps ext_step

    # Strictly isolate public tests from any workstation extensions
    set -gx JJ_WATCH_EXTENSION /dev/null

    # Always ensure test execution starts from the test directory
    builtin cd (status dirname)

    # Source the script into local scope without executing CLI entrypoint
    source (status dirname)/jj_watch
end

@test "jj_watch fails with status 1 if target directory does not exist" (
    setup_hermetic_env
    jj_watch "/non/existent/directory/path/that/cannot/exist" 1 false true true 2>/dev/null
    echo $status
) = 1

@test "jj_watch fails with status 1 if not inside a jj workspace" (
    setup_hermetic_env

    function jj
        return 1
    end

    jj_watch "" 1 false true true >/dev/null 2>&1
    echo $status
) = 1

@test "__jj_watch_probe formats Git / local JJ sentinels correctly" (
    setup_hermetic_env

    set -l tmp_local (mktemp -d)
    mkdir -p "$tmp_local/.jj/repo/op_heads/heads" "$tmp_local/.jj/working_copy"
    touch "$tmp_local/.jj/repo/op_heads/heads/abc123ophead"
    touch "$tmp_local/.jj/working_copy/checkout"
    touch "$tmp_local/.jj/working_copy/tree_state"

    set -l probe_local (__jj_watch_probe "$tmp_local" false)

    rm -rf "$tmp_local"

    string match -q "*:ops=abc123ophead:checkout=*:tree=*" "$probe_local"
    if test $status -eq 0
        echo "pass"
    else
        echo "fail: $probe_local"
    end
) = pass

@test "jj_watch runs once and returns status 0 in a valid mocked workspace" (
    setup_hermetic_env

    set -l tmp_mock (mktemp -d)
    mkdir -p "$tmp_mock/.jj/working_copy"
    touch "$tmp_mock/.jj/working_copy/checkout"

    function jj -V tmp_mock
        switch "$argv"
            case "*root*"
                echo "$tmp_mock"
                return 0
            case "*"
                return 0
        end
    end

    jj_watch "$tmp_mock" 1 false true true >/dev/null 2>&1
    set -l res $status
    rm -rf "$tmp_mock"
    echo $res
) = 0

@test "__jj_watch_render invokes jj with --no-pager and disables pagers in environment" (
    setup_hermetic_env

    set -g recorded_jj_calls
    set -g recorded_pagers

    function jj
        set -g -a recorded_jj_calls (string join " " -- $argv)
        set -g -a recorded_pagers "PAGER=$PAGER:JJ_PAGER=$JJ_PAGER:DELTA_PAGER=$DELTA_PAGER:GIT_PAGER=$GIT_PAGER"
        return 0
    end

    __jj_watch_render "" true >/dev/null

    set -l all_have_no_pager true
    for call in $recorded_jj_calls
        if not string match -q -- "*--no-pager*" "$call"
            set all_have_no_pager false
        end
    end

    set -l all_pagers_cat true
    for p in $recorded_pagers
        if not string match -q -- "PAGER=cat:JJ_PAGER=cat:DELTA_PAGER=cat:GIT_PAGER=cat" "$p"
            set all_pagers_cat false
        end
    end

    if test "$all_have_no_pager" = true; and test "$all_pagers_cat" = true; and test (count $recorded_jj_calls) -ge 2
        echo "pass"
    else
        echo "fail: calls=$recorded_jj_calls pagers=$recorded_pagers"
    end
) = pass

@test "jj_watch invokes jj root with --no-pager" (
    setup_hermetic_env

    set -l tmp_mock (mktemp -d)
    mkdir -p "$tmp_mock/.jj/working_copy"
    touch "$tmp_mock/.jj/working_copy/checkout"

    set -g root_call_args ""
    function jj -V tmp_mock
        switch "$argv"
            case "*root*"
                set -g root_call_args (string join " " -- $argv)
                echo "$tmp_mock"
                return 0
            case "*"
                return 0
        end
    end

    jj_watch "$tmp_mock" 1 false true true >/dev/null 2>&1
    rm -rf "$tmp_mock"

    string match -q -- "*--no-pager*root*" "$root_call_args"
    if test $status -eq 0
        echo "pass"
    else
        echo "fail: $root_call_args"
    end
) = pass

@test "__jj_watch_render outputs diff status and log graph with proper separation" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "M src/foo.txt"
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l output (__jj_watch_render "" true)
    if test (count $output) -eq 3; \
       and test "$output[1]" = "M src/foo.txt"; \
       and test -z "$output[2]"; \
       and test "$output[3]" = "@ commit123"
        echo "pass"
    else
        echo "fail: count="(count $output)" output="(string join "," -- $output)
    end
) = pass

@test "__jj_watch_render omits leading blank line when there are no diff changes" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                return 0
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l output (__jj_watch_render "" true)
    if test "$output[1]" = "@ commit123"
        echo "pass"
    else
        echo "fail: first line is '$output[1]'"
    end
) = pass

@test "__jj_watch_render emits synchronized output and atomic cursor home/clear when no_clear is false" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "M src/foo.txt"
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l raw (__jj_watch_render "" false | string collect -N -a)

    string match -rq "^\x1b\[\?2026h\x1b\[H\x1b\[J" "$raw"
    set -l start_ok $status

    string match -q "*M src/foo.txt*@ commit123*" "$raw"
    set -l content_ok $status

    string match -rq "\x1b\[J\x1b\[\?2026l\$" "$raw"
    set -l end_ok $status

    if test $start_ok -eq 0; and test $content_ok -eq 0; and test $end_ok -eq 0
        echo "pass"
    else
        echo "fail: start=$start_ok content=$content_ok end=$end_ok"
    end
) = pass

@test "__jj_watch_render computes entire frame in memory before emitting to stdout (flicker-free double-buffering)" (
    setup_hermetic_env

    set -l tmp_dir (mktemp -d)
    set -l out_file "$tmp_dir/render_out.txt"

    set -g bytes_at_diff -1
    set -g bytes_at_log -1

    function jj -V out_file
        switch "$argv"
            case "*diff*"
                set -g bytes_at_diff (command stat -c "%s" "$out_file" 2>/dev/null; or command stat -f "%z" "$out_file" 2>/dev/null; or echo 0)
                echo "M src/foo.txt"
            case "*log*"
                set -g bytes_at_log (command stat -c "%s" "$out_file" 2>/dev/null; or command stat -f "%z" "$out_file" 2>/dev/null; or echo 0)
                echo "@ commit123"
        end
    end

    touch "$out_file"
    __jj_watch_render "" false >"$out_file"
    set -l final_bytes (command stat -c "%s" "$out_file" 2>/dev/null; or command stat -f "%z" "$out_file" 2>/dev/null)

    rm -rf "$tmp_dir"

    if test "$bytes_at_diff" = "0"; and test "$bytes_at_log" = "0"; and test "$final_bytes" -gt 0
        echo "pass"
    else
        echo "fail: diff_bytes=$bytes_at_diff log_bytes=$bytes_at_log final=$final_bytes"
    end
) = pass

@test "__jj_watch_render with no_clear true emits no ANSI clear or synchronized output sequences" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "M src/foo.txt"
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l raw (__jj_watch_render "" true | string collect -N -a)

    string match -rq "\x1b\[\?2026[hl]" "$raw"
    set -l has_sync $status

    string match -rq "\x1b\[H" "$raw"
    set -l has_home $status

    string match -rq "\x1b\[J" "$raw"
    set -l has_clear $status

    if test $has_sync -ne 0; and test $has_home -ne 0; and test $has_clear -ne 0
        echo "pass"
    else
        echo "fail: has_sync=$has_sync has_home=$has_home has_clear=$has_clear"
    end
) = pass

@test "__jj_watch_render buffers stderr into frame memory without premature leakage" (
    setup_hermetic_env

    set -l tmp_dir (mktemp -d)
    set -l err_file "$tmp_dir/stderr.txt"
    set -l out_file "$tmp_dir/stdout.txt"

    set -g err_bytes_at_diff -1
    set -g err_bytes_at_log -1

    function jj -V err_file
        switch "$argv"
            case "*diff*"
                set -g err_bytes_at_diff (command stat -c "%s" "$err_file" 2>/dev/null; or command stat -f "%z" "$err_file" 2>/dev/null; or echo 0)
                echo "warning: diff conflict hint" >&2
                echo "M src/foo.txt"
            case "*log*"
                set -g err_bytes_at_log (command stat -c "%s" "$err_file" 2>/dev/null; or command stat -f "%z" "$err_file" 2>/dev/null; or echo 0)
                echo "warning: log hint" >&2
                echo "@ commit123"
        end
    end

    touch "$err_file"
    __jj_watch_render "" false >"$out_file" 2>"$err_file"
    set -l final_err_bytes (command stat -c "%s" "$err_file" 2>/dev/null; or command stat -f "%z" "$err_file" 2>/dev/null)

    read -z rendered_content < "$out_file"
    rm -rf "$tmp_dir"

    string match -q "*warning: diff conflict hint*" "$rendered_content"
    set -l diff_warn_ok $status
    string match -q "*warning: log hint*" "$rendered_content"
    set -l log_warn_ok $status

    if test "$err_bytes_at_diff" = "0"; and test "$err_bytes_at_log" = "0"; and test "$final_err_bytes" = "0"; and test $diff_warn_ok -eq 0; and test $log_warn_ok -eq 0
        echo "pass"
    else
        echo "fail: diff_err=$err_bytes_at_diff log_err=$err_bytes_at_log final_err=$final_err_bytes diff_warn=$diff_warn_ok log_warn=$log_warn_ok"
    end
) = pass

@test "__jj_watch_render handles multiple diff changes and maintains blank line separation from log graph" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "M src/file1.txt"
                echo "A src/file2.txt"
                echo "D src/file3.txt"
            case "*log*"
                echo "@ commit123"
                echo "| parent456"
        end
    end

    set -l output (__jj_watch_render "" true)

    if test "$output[1]" = "M src/file1.txt"; \
       and test "$output[2]" = "A src/file2.txt"; \
       and test "$output[3]" = "D src/file3.txt"; \
       and test -z "$output[4]"; \
       and test "$output[5]" = "@ commit123"; \
       and test "$output[6]" = "| parent456"
        echo "pass"
    else
        echo "fail: output is "(string join "," -- $output)
    end
) = pass

@test "__jj_watch_render preserves ANSI colors in diff and log outputs without corruption" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                printf "\033[32mM src/foo.txt\033[0m\n"
            case "*log*"
                printf "\033[1;34m@ commit123\033[0m\n"
        end
    end

    set -l raw (__jj_watch_render "" false | string collect -N -a)

    string match -rq "\x1b\[32mM src/foo.txt\x1b\[0m" "$raw"
    set -l diff_color_ok $status

    string match -rq "\x1b\[1;34m@ commit123\x1b\[0m" "$raw"
    set -l log_color_ok $status

    if test $diff_color_ok -eq 0; and test $log_color_ok -eq 0
        echo "pass"
    else
        echo "fail: diff_color=$diff_color_ok log_color=$log_color_ok"
    end
) = pass

@test "jj_watch watch loop detects sentinel changes and triggers double-buffered re-render" (
    setup_hermetic_env

    set -l tmp_mock (mktemp -d)
    mkdir -p "$tmp_mock/.jj/working_copy"
    echo "checkout_1" > "$tmp_mock/.jj/working_copy/checkout"

    set -g render_count 0
    set -g sleep_count 0

    function jj -V tmp_mock
        switch "$argv"
            case "*root*"
                echo "$tmp_mock"
                return 0
            case "*"
                return 0
        end
    end

    function __jj_watch_render
        set -g render_count (math $render_count + 1)
    end

    function sleep -V tmp_mock
        set -g sleep_count (math $sleep_count + 1)
        if test $sleep_count -eq 1
            echo "checkout_2" > "$tmp_mock/.jj/working_copy/checkout"
            return 0
        else
            return 1
        end
    end

    jj_watch "$tmp_mock" 1 false false true >/dev/null 2>&1
    rm -rf "$tmp_mock"

    if test $render_count -eq 2
        echo "pass"
    else
        echo "fail: render_count=$render_count"
    end
) = pass

@test "__jj_watch_render interactive frame ensures diff files and log graph appear on separate lines with newline separator" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "M src/modified_file.txt"
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l raw (__jj_watch_render "" false | string collect -N -a)
    set -l stripped (string replace -ra '\x1b(\[[0-9;?]*[a-zA-Z~]|\][^\x1b]*\x1b\\\\)' '' "$raw" | string collect)
    set -l lines (printf '%s' "$stripped")

    set -l count_ok (test (count $lines) -eq 3; and echo 0; or echo 1)
    set -l line1_ok (test "$lines[1]" = "M src/modified_file.txt"; and echo 0; or echo 1)
    set -l line2_ok (test -z "$lines[2]"; and echo 0; or echo 1)
    set -l line3_ok (test "$lines[3]" = "@ commit123"; and echo 0; or echo 1)

    if test $count_ok -eq 0; and test $line1_ok -eq 0; and test $line2_ok -eq 0; and test $line3_ok -eq 0
        echo "pass"
    else
        echo "fail: count="(count $lines)" line1=$lines[1] line2=$lines[2] line3=$lines[3]"
    end
) = pass

@test "__jj_watch_render interactive frame handles multiple modified files with proper separation" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "M src/file1.txt"
                echo "A src/file2.txt"
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l raw (__jj_watch_render "" false | string collect -N -a)
    set -l stripped (string replace -ra '\x1b(\[[0-9;?]*[a-zA-Z~]|\][^\x1b]*\x1b\\\\)' '' "$raw" | string collect)
    set -l lines (printf '%s' "$stripped")

    set -l count_ok (test (count $lines) -eq 4; and echo 0; or echo 1)
    set -l line1_ok (test "$lines[1]" = "M src/file1.txt"; and echo 0; or echo 1)
    set -l line2_ok (test "$lines[2]" = "A src/file2.txt"; and echo 0; or echo 1)
    set -l line3_ok (test -z "$lines[3]"; and echo 0; or echo 1)
    set -l line4_ok (test "$lines[4]" = "@ commit123"; and echo 0; or echo 1)

    if test $count_ok -eq 0; and test $line1_ok -eq 0; and test $line2_ok -eq 0; and test $line4_ok -eq 0
        echo "pass"
    else
        echo "fail: count="(count $lines)" lines="(string join "," -- $lines)
    end
) = pass

@test "__jj_watch_render clears previous screen so modified files do not collide with old graph characters" (
    setup_hermetic_env

    function jj
        switch "$argv"
            case "*diff*"
                echo "A test"
            case "*log*"
                echo "@ commit123"
        end
    end

    set -l raw (__jj_watch_render "" false | string collect -N -a)

    printf '%s' "$raw" | python3 -c '
import sys

raw = sys.stdin.read()
grid = [[" " for _ in range(80)] for _ in range(24)]
prev_line = "@  commit_prev user 2026-08-28 00:01:58 2bcec34ca66823"
for c, ch in enumerate(prev_line):
    grid[0][c] = ch

row, col = 0, 0
i = 0
while i < len(raw):
    if raw[i:i+2] == "\x1b[":
        j = i + 2
        while j < len(raw) and not raw[j].isalpha() and raw[j] not in ["~", "?"]:
            j += 1
        if j < len(raw) and raw[j] == "?":
            while j < len(raw) and not raw[j].isalpha():
                j += 1
        seq = raw[i:j+1]
        i = j + 1
        if seq == "\x1b[H":
            row, col = 0, 0
        elif seq == "\x1b[J":
            for r in range(row, 24):
                for c in range(col if r == row else 0, 80):
                    grid[r][c] = " "
        continue
    elif raw[i] == "\n":
        row += 1
        col = 0
        i += 1
    else:
        if row < 24 and col < 80:
            grid[row][col] = raw[i]
            col += 1
        i += 1

row0 = "".join(grid[0]).rstrip()
row1 = "".join(grid[1]).rstrip()
row2 = "".join(grid[2]).rstrip()

if row0 == "A test" and row1 == "" and row2 == "@ commit123":
    print("pass")
else:
    print(f"fail: row0=[{row0}] row1=[{row1}] row2=[{row2}]")
'
) = pass

@test "jj_watch restores caller working directory when target_dir is specified" (
    setup_hermetic_env

    set -l tmp_mock (mktemp -d)
    mkdir -p "$tmp_mock/.jj/working_copy"
    touch "$tmp_mock/.jj/working_copy/checkout"

    function jj -V tmp_mock
        switch "$argv"
            case "*root*"
                echo "$tmp_mock"
                return 0
            case "*"
                return 0
        end
    end

    set -l before_pwd $PWD
    jj_watch "$tmp_mock" 1 false true true >/dev/null 2>&1
    set -l after_pwd $PWD
    rm -rf "$tmp_mock"

    if test "$before_pwd" = "$after_pwd"
        echo "pass"
    else
        echo "fail: before=$before_pwd after=$after_pwd"
    end
) = pass

@test "jj_watch CLI --help prints usage and exits 0" (
    setup_hermetic_env
    set -l script_path (status dirname)/jj_watch
    set -l output ($script_path --help)
    set -l exit_code $status

    string match -q "*Usage: jj_watch [OPTIONS] [DIRECTORY]*" "$output"
    set -l match_ok $status

    if test $exit_code -eq 0; and test $match_ok -eq 0
        echo "pass"
    else
        echo "fail: code=$exit_code match=$match_ok"
    end
) = pass

@test "jj_watch CLI exits with status 1 on unknown option" (
    setup_hermetic_env
    set -l script_path (status dirname)/jj_watch
    $script_path --unknown-flag >/dev/null 2>&1
    echo $status
) = 1

@test "jj_watch CLI exits with status 1 on multiple positional arguments" (
    setup_hermetic_env
    set -l script_path (status dirname)/jj_watch
    $script_path /dir1 /dir2 >/dev/null 2>&1
    echo $status
) = 1

@test "jj_watch CLI --once executes successfully in valid mocked repo and exits 0" (
    setup_hermetic_env
    set -l script_path (status dirname)/jj_watch
    set -l tmp_env (mktemp -d)
    mkdir -p "$tmp_env/bin" "$tmp_env/repo/.jj/working_copy"
    touch "$tmp_env/repo/.jj/working_copy/checkout"

    printf '#!/bin/sh\ncase "$*" in *root*) echo "%s";; *) exit 0;; esac\n' "$tmp_env/repo" > "$tmp_env/bin/jj"
    chmod +x "$tmp_env/bin/jj"

    set -lx PATH "$tmp_env/bin" $PATH
    $script_path --once "$tmp_env/repo" >/dev/null 2>&1
    set -l exit_code $status
    rm -rf "$tmp_env"
    echo $exit_code
) = 0

@test "jj_watch CLI exits with status 1 on non-existent target directory" (
    setup_hermetic_env
    set -l script_path (status dirname)/jj_watch
    $script_path --once "/non/existent/dir/path/that/cannot/exist" >/dev/null 2>&1
    echo $status
) = 1

@test "jj_watch CLI flags -1, -c, -i, and --no-clear parse correctly" (
    setup_hermetic_env
    set -l script_path (status dirname)/jj_watch
    set -l tmp_env (mktemp -d)
    mkdir -p "$tmp_env/bin" "$tmp_env/repo/.jj/working_copy"
    touch "$tmp_env/repo/.jj/working_copy/checkout"

    printf '#!/bin/sh\ncase "$*" in *root*) echo "%s";; *) exit 0;; esac\n' "$tmp_env/repo" > "$tmp_env/bin/jj"
    chmod +x "$tmp_env/bin/jj"

    set -lx PATH "$tmp_env/bin" $PATH
    $script_path -1 -c -i 2 --no-clear "$tmp_env/repo" >/dev/null 2>&1
    set -l exit_code $status
    rm -rf "$tmp_env"
    echo $exit_code
) = 0

@test "__jj_watch_probe detects untracked file addition in local Git/JJ repo" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    git init "$tmp" >/dev/null 2>&1
    git -C "$tmp" config user.name "Test"
    git -C "$tmp" config user.email "test@example.com"
    echo "init" > "$tmp/init.txt"
    git -C "$tmp" add init.txt
    git -C "$tmp" commit -m "init" >/dev/null 2>&1

    set -l p_init (__jj_watch_probe "$tmp" false)
    echo "file" > "$tmp/untracked.txt"
    set -l p_add (__jj_watch_probe "$tmp" false)
    rm -rf "$tmp"

    set -l probe_changed (test "$p_init" != "$p_add"; and echo 0; or echo 1)
    string match -q "*:git_files=untracked.txt*" "$p_add"
    set -l match_ok $status

    if test $probe_changed -eq 0; and test $match_ok -eq 0
        echo "pass"
    else
        echo "fail: changed=$probe_changed match=$match_ok"
    end
) = pass

@test "__jj_watch_probe detects file modification and deletion in local Git/JJ repo" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    git init "$tmp" >/dev/null 2>&1
    git -C "$tmp" config user.name "Test"
    git -C "$tmp" config user.email "test@example.com"
    echo "init" > "$tmp/init.txt"
    git -C "$tmp" add init.txt
    git -C "$tmp" commit -m "init" >/dev/null 2>&1

    echo "content1" > "$tmp/file.txt"
    set -l p_add (__jj_watch_probe "$tmp" false)
    sleep 1
    echo "content2" >> "$tmp/file.txt"
    set -l p_mod (__jj_watch_probe "$tmp" false)
    rm "$tmp/file.txt"
    set -l p_del (__jj_watch_probe "$tmp" false)
    rm -rf "$tmp"

    set -l mod_changed (test "$p_add" != "$p_mod"; and echo 0; or echo 1)
    set -l del_changed (test "$p_mod" != "$p_del"; and echo 0; or echo 1)
    string match -q "*:git_files=clean*" "$p_del"
    set -l clean_ok $status

    if test $mod_changed -eq 0; and test $del_changed -eq 0; and test $clean_ok -eq 0
        echo "pass"
    else
        echo "fail: mod=$mod_changed del=$del_changed clean=$clean_ok"
    end
) = pass

@test "__jj_watch_probe ignores files matching .gitignore in local Git/JJ repo" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    git init "$tmp" >/dev/null 2>&1
    git -C "$tmp" config user.name "Test"
    git -C "$tmp" config user.email "test@example.com"
    echo "*.log" > "$tmp/.gitignore"
    git -C "$tmp" add .gitignore
    git -C "$tmp" commit -m "init" >/dev/null 2>&1

    set -l p_init (__jj_watch_probe "$tmp" false)
    echo "log entry" > "$tmp/test.log"
    set -l p_after (__jj_watch_probe "$tmp" false)
    rm -rf "$tmp"

    if test "$p_init" = "$p_after"
        echo "pass"
    else
        echo "fail: init=$p_init after=$p_after"
    end
) = pass

@test "__jj_watch_probe ignores files matching .jjignore in local Git/JJ repo" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    git init "$tmp" >/dev/null 2>&1
    git -C "$tmp" config user.name "Test"
    git -C "$tmp" config user.email "test@example.com"
    echo "*.secret" > "$tmp/.jjignore"
    echo "init" > "$tmp/init.txt"
    git -C "$tmp" add init.txt
    git -C "$tmp" commit -m "init" >/dev/null 2>&1

    set -l p_init (__jj_watch_probe "$tmp" false)
    echo "secret data" > "$tmp/my.secret"
    set -l p_after (__jj_watch_probe "$tmp" false)
    rm -rf "$tmp"

    if test "$p_init" = "$p_after"
        echo "pass"
    else
        echo "fail: init=$p_init after=$p_after"
    end
) = pass

@test "__jj_watch_probe ignores working copy changes when commits_only is true in local Git/JJ repo" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    git init "$tmp" >/dev/null 2>&1
    git -C "$tmp" config user.name "Test"
    git -C "$tmp" config user.email "test@example.com"
    echo "init" > "$tmp/init.txt"
    git -C "$tmp" add init.txt
    git -C "$tmp" commit -m "init" >/dev/null 2>&1

    set -l p_init (__jj_watch_probe "$tmp" true)
    echo "newfile" > "$tmp/untracked.txt"
    set -l p_after (__jj_watch_probe "$tmp" true)
    rm -rf "$tmp"

    if test "$p_init" = "$p_after"
        echo "pass"
    else
        echo "fail: init=$p_init after=$p_after"
    end
) = pass

@test "__jj_watch_probe detects changes in non-colocated Git/JJ repo (.jj/repo/store/git_target)" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    jj git init --no-colocate "$tmp" >/dev/null 2>&1

    set -l p_init (__jj_watch_probe "$tmp" false)
    echo "content" > "$tmp/nc_file.txt"
    set -l p_after (__jj_watch_probe "$tmp" false)
    rm -rf "$tmp"

    string match -q "*:git_files=nc_file.txt*" "$p_after"
    set -l match_ok $status
    set -l changed (test "$p_init" != "$p_after"; and echo 0; or echo 1)

    if test $match_ok -eq 0; and test $changed -eq 0
        echo "pass"
    else
        echo "fail: match=$match_ok changed=$changed"
    end
) = pass

@test "jj_watch watch loop detects working copy file additions in local Git/JJ repo" (
    setup_hermetic_env

    set -l tmp_mock (mktemp -d)
    git init "$tmp_mock" >/dev/null 2>&1
    git -C "$tmp_mock" config user.name "Test"
    git -C "$tmp_mock" config user.email "test@example.com"
    echo "init" > "$tmp_mock/init.txt"
    git -C "$tmp_mock" add init.txt
    git -C "$tmp_mock" commit -m "init" >/dev/null 2>&1
    jj git init "$tmp_mock" >/dev/null 2>&1

    set -g render_count 0
    set -g sleep_count 0

    function __jj_watch_render
        set -g render_count (math $render_count + 1)
    end

    function sleep -V tmp_mock
        set -g sleep_count (math $sleep_count + 1)
        if test $sleep_count -eq 1
            echo "new content" > "$tmp_mock/test_file.txt"
            return 0
        else
            return 1
        end
    end

    jj_watch "$tmp_mock" 1 false false true >/dev/null 2>&1
    rm -rf "$tmp_mock"

    if test $render_count -eq 2
        echo "pass"
    else
        echo "fail: render_count=$render_count"
    end
) = pass

# ==============================================================================
# Provider Hook Contract Unit Tests (Generic / Hermetic Mock Testing)
# ==============================================================================

@test "Extension hook 1: __jj_watch_ext_extra_flags injects custom CLI flags into jj invocations" (
    setup_hermetic_env

    function __jj_watch_ext_extra_flags -a target_or_root_dir
        echo "--test-custom-flag"
    end

    set -g recorded_calls
    function jj
        set -g -a recorded_calls (string join " " -- $argv)
        return 0
    end

    __jj_watch_render "/tmp" true >/dev/null

    string match -q -- "*--test-custom-flag*" "$recorded_calls[1]"
    echo $status
) = 0

@test "Extension hook 2: __jj_watch_ext_probe delegates to extension hook when status is 0" (
    setup_hermetic_env

    function __jj_watch_ext_probe -a ws_root commits_only
        echo ":custom_ext_probe_token"
        return 0
    end

    set -l probe (__jj_watch_probe "/tmp" false)
    echo "$probe"
) = :custom_ext_probe_token

@test "Extension hook 2: __jj_watch_ext_probe falls back to generic probe when returning status 1" (
    setup_hermetic_env

    function __jj_watch_ext_probe; return 1; end

    set -l tmp_mock (mktemp -d)
    mkdir -p "$tmp_mock/.jj/repo/op_heads/heads" "$tmp_mock/.jj/working_copy"
    touch "$tmp_mock/.jj/repo/op_heads/heads/abc123head"
    touch "$tmp_mock/.jj/working_copy/checkout"

    set -l probe (__jj_watch_probe "$tmp_mock" false)
    rm -rf "$tmp_mock"

    string match -q "*:ops=abc123head:checkout=*" "$probe"
    echo $status
) = 0

@test "Extension hook 3: __jj_watch_ext_handle_cd_failure recovers target directory navigation" (
    setup_hermetic_env

    set -l tmp_recover (mktemp -d)
    function __jj_watch_ext_handle_cd_failure -V tmp_recover -a target_dir interval no_clear
        mkdir -p "$target_dir"
        return 0
    end

    set -l target "$tmp_recover/unmounted_dir"
    __jj_watch_resolve_target "$target" 1 true
    set -l res $status

    rm -rf "$tmp_recover"
    echo $res
) = 0

@test "Extension hook 4: __jj_watch_ext_handle_root_failure recovers jj root discovery failure" (
    setup_hermetic_env

    set -l tmp_ws (mktemp -d)
    mkdir -p "$tmp_ws/.jj/working_copy"
    touch "$tmp_ws/.jj/working_copy/checkout"

    set -g root_fails 1
    function jj -V tmp_ws
        switch "$argv"
            case "*root*"
                if test $root_fails -eq 1
                    return 1
                end
                echo "$tmp_ws"
                return 0
            case "*"
                return 0
        end
    end

    function __jj_watch_ext_handle_root_failure -a watch_dir interval no_clear
        set -g root_fails 0
        return 0
    end

    set -e _jj_watch_resolved_root
    __jj_watch_resolve_root "$tmp_ws" 1 true >/dev/null
    set -l res $status
    rm -rf "$tmp_ws"
    echo $res
) = 0

@test "Extension hook 5: __jj_watch_ext_check_workspace handles auth pause (status 1) and recovery (status 2)" (
    setup_hermetic_env

    set -g ext_step 0
    function __jj_watch_ext_check_workspace
        set -g ext_step (math $ext_step + 1)
        if test $ext_step -eq 1
            return 1 # In auth wait: sleep again
        else if test $ext_step -eq 2
            return 2 # Reconnected: immediate re-render and re-probe
        end
        return 0
    end

    set -g loop_sleeps 0
    function sleep
        set -g loop_sleeps (math $loop_sleeps + 1)
        test $loop_sleeps -ge 3; and return 1
        return 0
    end

    function jj; return 0; end

    __jj_watch_loop "/tmp" "/tmp" "1:false:true"
    echo "$ext_step:$loop_sleeps"
) = 2:3

@test "Extension hook 5: __jj_watch_ext_check_workspace exits on fatal error (status 3)" (
    setup_hermetic_env

    function __jj_watch_ext_check_workspace
        return 3 # Fatal error: workspace gone
    end

    function sleep; return 0; end

    __jj_watch_loop "/tmp" "/tmp" "1:false:true" >/dev/null 2>&1
    echo $status
) = 1

@test "__jj_watch_load_extensions respects JJ_WATCH_EXTENSION=/dev/null to remain hermetic" (
    setup_hermetic_env
    functions -q __jj_watch_ext_probe
    echo $status
) = 1

@test "__jj_watch_probe accurately reports stats when one file is modified and another is deleted concurrently" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    mkdir -p "$tmp/bin"
    git init "$tmp/repo" >/dev/null 2>&1
    git -C "$tmp/repo" config user.name "Test"
    git -C "$tmp/repo" config user.email "test@example.com"
    echo "init a" > "$tmp/repo/a.txt"
    echo "init b" > "$tmp/repo/b.txt"
    git -C "$tmp/repo" add .
    git -C "$tmp/repo" commit -m "init" >/dev/null 2>&1

    echo "modified a" >> "$tmp/repo/a.txt"
    echo "modified b" >> "$tmp/repo/b.txt"

    set -gx REAL_STAT (command which stat)
    set -gx TEST_TMP "$tmp/repo"

    # Wrapper stat: unlinks b.txt immediately before executing real stat to simulate a true concurrent unlink race
    printf "#!/bin/sh\nif [ -f \"\$TEST_TMP/b.txt\" ]; then rm -f \"\$TEST_TMP/b.txt\"; fi\nexec \$REAL_STAT \"\$@\"\n" > "$tmp/bin/stat"
    chmod +x "$tmp/bin/stat"

    set -lx PATH "$tmp/bin" $PATH
    set -l probe (__jj_watch_probe "$tmp/repo" false)
    rm -rf "$tmp"

    string match -q "*:git_files=a.txt,b.txt:git_stats=*" "$probe"
    set -l format_ok $status
    # Verify no GNU stat superblock error text was captured in git_stats
    string match -q "*Block size*" "$probe"
    set -l superblock_leak $status

    if test $format_ok -eq 0; and test $superblock_leak -ne 0
        echo "pass"
    else
        echo "fail: format_ok=$format_ok superblock_leak=$superblock_leak probe=$probe"
    end
) = pass

@test "jj_watch executes successfully when invoked with concise 2-argument opts format" (
    setup_hermetic_env

    set -l tmp_mock (mktemp -d)
    mkdir -p "$tmp_mock/.jj/working_copy"
    touch "$tmp_mock/.jj/working_copy/checkout"

    function jj -V tmp_mock
        switch "$argv"
            case "*root*"
                echo "$tmp_mock"
                return 0
            case "*"
                return 0
        end
    end

    jj_watch "$tmp_mock" "1:false:true:true" >/dev/null 2>&1
    set -l res $status
    rm -rf "$tmp_mock"
    echo $res
) = 0

@test "__jj_watch_loop preserves colon-delimited opts and does not clobber with positional args" (
    setup_hermetic_env

    set -g captured_interval
    set -g captured_commits_only
    function sleep -a duration
        set -g captured_interval "$duration"
        return 1 # exit loop immediately
    end

    function __jj_watch_probe -a ws_root commits_only
        set -g captured_commits_only "$commits_only"
        return 0
    end

    function jj; return 0; end

    # Call with colon opts in $argv[3] plus extra args in $argv[4] and $argv[5]
    __jj_watch_loop "/tmp" "/tmp" "5:true:true" "ignored1" "ignored2" >/dev/null 2>&1

    if test "$captured_interval" = "5"; and test "$captured_commits_only" = "true"
        echo "pass"
    else
        echo "fail: interval=$captured_interval commits_only=$captured_commits_only"
    end
) = pass

@test "__jj_watch_probe handles git file stats under both GNU and simulated BSD stat capability environments" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    mkdir -p "$tmp/bin"
    git init "$tmp/repo" >/dev/null 2>&1
    git -C "$tmp/repo" config user.name "Test"
    git -C "$tmp/repo" config user.email "test@example.com"
    echo "init a" > "$tmp/repo/a.txt"
    echo "init b" > "$tmp/repo/b.txt"
    git -C "$tmp/repo" add .
    git -C "$tmp/repo" commit -m "init" >/dev/null 2>&1

    echo "modified a" >> "$tmp/repo/a.txt"
    echo "modified b" >> "$tmp/repo/b.txt"

    # 1. Verify GNU stat capability environment (default)
    set -l probe_gnu (__jj_watch_probe "$tmp/repo" false)
    string match -q "*:git_files=a.txt,b.txt:git_stats=*" "$probe_gnu"
    set -l gnu_files_ok $status
    string match -r -q ':git_stats=[0-9]+:[0-9]+,[0-9]+:[0-9]+' "$probe_gnu"
    set -l gnu_stats_ok $status
    string match -q "*Block size*" "$probe_gnu"
    set -l gnu_leak $status

    # 2. Verify simulated BSD stat capability environment (stat -c rejected, stat -f supported)
    printf '#!/bin/sh\nif [ "$1" = "-f" ]; then\n    fmt="$2"\n    shift 2\n    for f in "$@"; do\n        if [ "$fmt" = "%%m:%%z" ]; then\n            echo "1234567890:42"\n        fi\n    done\n    exit 0\nfi\nexit 1\n' > "$tmp/bin/stat"
    chmod +x "$tmp/bin/stat"

    set -lx PATH "$tmp/bin" $PATH
    source (status dirname)/jj_watch

    set -l probe_bsd (__jj_watch_probe "$tmp/repo" false)

    string match -q "*:git_files=a.txt,b.txt:git_stats=1234567890:42,1234567890:42*" "$probe_bsd"
    set -l bsd_stats_ok $status
    string match -q "*Block size*" "$probe_bsd"
    set -l bsd_leak $status

    # 3. Verify capability detection output shape validation (stat -c exits 0 with unexpected output shape, falls back to BSD)
    printf '#!/bin/sh\nif [ "$1" = "-c" ]; then\n    echo "unsupported_stat_output"\n    exit 0\nelif [ "$1" = "-f" ]; then\n    fmt="$2"\n    shift 2\n    for f in "$@"; do\n        if [ "$fmt" = "%%m:%%z" ]; then\n            echo "9999999999:84"\n        fi\n    done\n    exit 0\nfi\nexit 1\n' > "$tmp/bin/stat"
    chmod +x "$tmp/bin/stat"

    source (status dirname)/jj_watch

    set -l probe_shape (__jj_watch_probe "$tmp/repo" false)
    rm -rf "$tmp"

    string match -q "*:git_files=a.txt,b.txt:git_stats=9999999999:84,9999999999:84*" "$probe_shape"
    set -l shape_stats_ok $status

    if test $gnu_files_ok -eq 0; and test $gnu_stats_ok -eq 0; and test $gnu_leak -ne 0; and test $bsd_stats_ok -eq 0; and test $bsd_leak -ne 0; and test $shape_stats_ok -eq 0
        echo "pass"
    else
        echo "fail: gnu_files=$gnu_files_ok gnu_stats=$gnu_stats_ok gnu_leak=$gnu_leak bsd_stats=$bsd_stats_ok bsd_leak=$bsd_leak shape_stats=$shape_stats_ok probe_gnu=$probe_gnu probe_bsd=$probe_bsd probe_shape=$probe_shape"
    end
) = pass

@test "__jj_watch_probe tree_state handles stat flavor without superblock corruption" (
    setup_hermetic_env

    set -l tmp (mktemp -d)
    mkdir -p "$tmp/.jj/working_copy"
    touch "$tmp/.jj/working_copy/checkout"
    touch "$tmp/.jj/working_copy/tree_state"

    # 1. Verify GNU stat flavor (default environment)
    set -l probe_gnu (__jj_watch_probe "$tmp" false)

    string match -r -q ':tree=[0-9]+' "$probe_gnu"
    set -l gnu_has_tree $status
    string match -q "*Block size*" "$probe_gnu"
    set -l gnu_superblock_leak $status

    # Direct test: missing file must return empty and not leak superblock
    set -l missing_gnu (__jj_watch_file_mtime "$tmp/.jj/working_copy/nonexistent")
    test -z "$missing_gnu"
    set -l gnu_missing_empty $status
    string match -q "*Block size*" "$missing_gnu"
    set -l gnu_missing_leak $status

    # 2. Verify simulated BSD stat flavor
    mkdir -p "$tmp/bin"
    printf '#!/bin/sh\nif [ "$1" = "-f" ]; then\n    fmt="$2"\n    shift 2\n    for f in "$@"; do\n        if [ ! -e "$f" ]; then\n            echo "stat: $f: No such file or directory" >&2\n            continue\n        fi\n        if [ "$fmt" = "%%m" ]; then\n            echo "9876543210"\n        fi\n    done\n    exit 0\nfi\nexit 1\n' > "$tmp/bin/stat"
    chmod +x "$tmp/bin/stat"

    set -lx PATH "$tmp/bin" $PATH
    source (status dirname)/jj_watch
    set -l probe_bsd (__jj_watch_probe "$tmp" false)

    string match -q "*:tree=9876543210*" "$probe_bsd"
    set -l bsd_has_tree $status
    string match -q "*Block size*" "$probe_bsd"
    set -l bsd_superblock_leak $status

    # Direct test: missing file under BSD flavor must return empty
    set -l missing_bsd (__jj_watch_file_mtime "$tmp/.jj/working_copy/nonexistent")
    test -z "$missing_bsd"
    set -l bsd_missing_empty $status

    rm -rf "$tmp"

    if test $gnu_has_tree -eq 0; and test $gnu_superblock_leak -ne 0; and test $gnu_missing_empty -eq 0; and test $gnu_missing_leak -ne 0; and test $bsd_has_tree -eq 0; and test $bsd_superblock_leak -ne 0; and test $bsd_missing_empty -eq 0
        echo "pass"
    else
        echo "fail: gnu_has_tree=$gnu_has_tree gnu_leak=$gnu_superblock_leak gnu_missing=$gnu_missing_empty bsd_has_tree=$bsd_has_tree bsd_leak=$bsd_superblock_leak bsd_missing=$bsd_missing_empty probe_gnu=$probe_gnu probe_bsd=$probe_bsd"
    end
) = pass
