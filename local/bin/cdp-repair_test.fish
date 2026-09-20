#!/usr/bin/env fish
#
# Tests for cdp-repair. Run with: fishtape local/bin/cdp-repair_test.fish
#
# Scope: everything that does not require a live SSH master -- argument
# handling, precondition failures, and the two fish-level bugs that made the
# script misbehave in exactly the dead-tunnel situation it exists for.
#
# The repair path itself is deliberately untested: it is I/O against a live
# master and a remote sshd, which cannot be faked meaningfully here.

function setup_hermetic_env
    functions -e __cdp_run __cdp_remote __cdp_healthy ssh curl
    builtin cd (status dirname)
end

# Shared watchdog implementation, kept byte-identical to the one in cdp-repair
# so the timeout tests exercise the real logic.
function watchdog_under_test --argument-names seconds outfile
    set -l cmd $argv[3..-1]
    $cmd >$outfile 2>/dev/null &
    set -l pid $last_pid
    for tick in (seq (math "round($seconds * 10)"))
        if not kill -0 $pid 2>/dev/null
            wait $pid 2>/dev/null
            return 0
        end
        sleep 0.1
    end
    kill -TERM $pid 2>/dev/null
    sleep 0.2
    kill -KILL $pid 2>/dev/null
    wait $pid 2>/dev/null
    return 1
end

# --- CLI contract ---------------------------------------------------------

@test "cdp-repair --help prints usage and exits 0" (
    setup_hermetic_env
    set -l script (status dirname)/cdp-repair
    set -l output ($script --help)
    set -l code $status
    string match -q "*Usage: cdp-repair*" "$output"
    set -l match_ok $status
    if test $code -eq 0; and test $match_ok -eq 0
        echo pass
    else
        echo "fail: code=$code match=$match_ok"
    end
) = pass

@test "cdp-repair exits 1 on an unknown option" (
    setup_hermetic_env
    set -l script (status dirname)/cdp-repair
    $script --not-a-real-flag >/dev/null 2>&1
    echo $status
) = 1

@test "cdp-repair rejects --force combined with --check" (
    setup_hermetic_env
    set -l script (status dirname)/cdp-repair
    set -l output ($script --force --check 2>&1)
    set -l code $status
    string match -q "*mutually exclusive*" "$output"
    set -l match_ok $status
    if test $code -eq 2; and test $match_ok -eq 0
        echo pass
    else
        echo "fail: code=$code (expected 2) match=$match_ok"
    end
) = pass

# --- Preconditions --------------------------------------------------------

@test "cdp-repair exits 1 when nothing serves CDP locally" (
    setup_hermetic_env
    set -l script (status dirname)/cdp-repair
    # Port 1 is privileged and never has a CDP server on it, so the local
    # precondition must fail before any ssh work is attempted.
    set -l output ($script --port 1 2>&1)
    set -l code $status
    string match -q "*Nothing is serving CDP*" "$output"
    set -l match_ok $status
    if test $code -eq 1; and test $match_ok -eq 0
        echo pass
    else
        echo "fail: code=$code match=$match_ok"
    end
) = pass

@test "cdp-repair probes 127.0.0.1 rather than localhost" (
    # localhost resolves to ::1 first on macOS, but the forward is pinned to
    # 127.0.0.1. Probing a different address than the one forwarded produces
    # spurious failures, so the literal must not reappear.
    setup_hermetic_env
    set -l script (status dirname)/cdp-repair
    if grep -q 'localhost:\$port' $script
        echo "fail: script still probes localhost"
    else
        echo pass
    end
) = pass

# --- Regression: fish-level bugs -----------------------------------------

@test "empty probe output does not trigger a test parse error" (
    # An inline command substitution expanding to zero arguments makes `test`
    # emit "Missing argument at index 3". That is precisely the dead-tunnel
    # case, so the value must be assigned to a variable before comparison.
    setup_hermetic_env
    set -l code (printf "")
    test "$code" = 200
    set -l rc $status
    if test $rc -eq 1
        echo pass
    else
        echo "fail: rc=$rc"
    end
) = pass

@test "watchdog loop variable is not the read-only _" (
    # `for _ in ...` aborts immediately in fish 4.x, which silently defeated
    # the timeout and let probes run unbounded.
    setup_hermetic_env
    set -l script (status dirname)/cdp-repair
    if grep -qE '^\s*for _ in ' $script
        echo "fail: script loops over the read-only _ variable"
    else
        echo pass
    end
) = pass

@test "watchdog kills a command that overruns its deadline" (
    setup_hermetic_env
    set -l tmp (mktemp)
    set -l t0 (date +%s)
    watchdog_under_test 1 $tmp sleep 30
    set -l rc $status
    set -l elapsed (math (date +%s) - $t0)
    rm -f $tmp

    if test $rc -eq 1; and test $elapsed -lt 10
        echo pass
    else
        echo "fail: rc=$rc elapsed=$elapsed"
    end
) = pass

@test "watchdog returns command output when it finishes in time" (
    setup_hermetic_env
    set -l tmp (mktemp)
    # A single argument containing spaces must survive being passed through.
    watchdog_under_test 5 $tmp sh -c "echo 200"
    set -l rc $status
    set -l out (cat $tmp)
    rm -f $tmp

    if test $rc -eq 0; and test "$out" = 200
        echo pass
    else
        echo "fail: rc=$rc out=$out"
    end
) = pass

# --- Config invariants ----------------------------------------------------

@test "ssh_config.template does not reintroduce ExitOnForwardFailure" (
    # It escalates benign secondary-session warnings to exit 255, which breaks
    # concurrent sessions and makes scloud retry forever.
    setup_hermetic_env
    set -l template (status dirname)/../../ssh_config.template
    if grep -qiE '^\s*ExitOnForwardFailure\s+yes' $template
        echo "fail: ExitOnForwardFailure yes is back in the template"
    else
        echo pass
    end
) = pass

@test "ssh_config.template declares each forwarded port exactly once" (
    # Two blocks racing for the same port is the original bug.
    setup_hermetic_env
    set -l template (status dirname)/../../ssh_config.template
    set -l ports (grep -oE '^[ 	]*(Remote|Local)Forward[ 	]+[0-9]+' $template | grep -oE '[0-9]+$')
    set -l unique (printf '%s\n' $ports | sort -u)
    if test (count $ports) -gt 0; and test (count $ports) -eq (count $unique)
        echo pass
    else
        echo "fail: ports=("(string join ',' $ports)") unique=("(string join ',' $unique)")"
    end
) = pass
