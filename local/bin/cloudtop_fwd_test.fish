#!/usr/bin/env fish

function setup_hermetic_env
    functions -e ssh lsof sleep __cloudtop_fwd_spawn __cloudtop_fwd_port_owner \
        __cloudtop_fwd_local_cdp_ok __cloudtop_fwd_master_alive \
        __cloudtop_fwd_remote_cdp_ok __cloudtop_fwd_with_deadline
    set -e ssh_calls sleep_delays probed

    # Isolate the pidfile and log in a throwaway state directory.
    set -gx XDG_STATE_HOME (mktemp -d)

    source (status dirname)/cloudtop_fwd

    # Poison external commands so no test can open a real connection.
    function ssh
        echo "UNMOCKED ssh" >&2
        return 1
    end
    # status probes local Chrome with curl; default to "nothing listening".
    function __cloudtop_fwd_local_cdp_ok
        return 1
    end
end

function cleanup_state
    set -l pidfile $XDG_STATE_HOME/cloudtop_fwd/loop.pid
    if test -f $pidfile
        read -l pid <$pidfile
        test -n "$pid"; and kill $pid 2>/dev/null
    end
    rm -rf $XDG_STATE_HOME
end

# Makes `cloudtop_fwd start` record a harmless sleeper as the loop.
function fake_running_loop
    function __cloudtop_fwd_port_owner
        return 1
    end
    function __cloudtop_fwd_spawn -a host log pidfile
        command sleep 30 &
        echo $last_pid >$pidfile
        disown $last_pid 2>/dev/null
    end
    cloudtop_fwd start >/dev/null
end

# Prints the trimmed lines of the ssh_config.template block for a Host line.
function template_block -a host_line
    set -l in_block false
    for line in (cat (status dirname)/../../ssh_config.template)
        if string match -qr '^Host\s' -- $line
            if test "$line" = "$host_line"
                set in_block true
            else
                set in_block false
            end
            continue
        end
        $in_block; and string trim -- $line
    end
end

@test "unknown command returns status 1" (
    setup_hermetic_env
    cloudtop_fwd bogus 2>/dev/null
    set -l res $status
    cleanup_state
    echo $res
) = 1

@test "status reports not running when there is no pidfile" (
    setup_hermetic_env
    set -l out (cloudtop_fwd status)
    cleanup_state
    echo $out[1]
) = "cloudtop_fwd is not running."

@test "start spawns the loop, records its pid, and status reports it running" (
    setup_hermetic_env
    function __cloudtop_fwd_port_owner; return 1; end
    function __cloudtop_fwd_spawn -a host log pidfile
        command sleep 30 &
        echo $last_pid >$pidfile
        disown $last_pid 2>/dev/null
    end

    cloudtop_fwd start >/dev/null
    set -l out (cloudtop_fwd status)
    cleanup_state
    string match -q "cloudtop_fwd is running (pid *) -> cloudtop-fwd." -- $out[1]
    echo $status
) = 0

@test "start does not spawn a second loop when one is already running" (
    setup_hermetic_env
    set -g spawn_count 0
    function __cloudtop_fwd_port_owner; return 1; end
    function __cloudtop_fwd_spawn -a host log pidfile
        set -g spawn_count (math $spawn_count + 1)
        command sleep 30 &
        echo $last_pid >$pidfile
        disown $last_pid 2>/dev/null
    end

    cloudtop_fwd start >/dev/null
    cloudtop_fwd start >/dev/null
    cleanup_state
    echo $spawn_count
) = 1

@test "start refuses when local :9998 is already held" (
    setup_hermetic_env
    set -g spawned false
    function __cloudtop_fwd_port_owner; echo ssh; end
    function __cloudtop_fwd_spawn; set -g spawned true; end

    cloudtop_fwd start >/dev/null 2>&1
    set -l res $status
    cleanup_state
    echo "$res:$spawned"
) = 1:false

@test "stop kills the loop and removes the pidfile" (
    setup_hermetic_env
    function __cloudtop_fwd_port_owner; return 1; end
    function __cloudtop_fwd_spawn -a host log pidfile
        command sleep 30 &
        echo $last_pid >$pidfile
        disown $last_pid 2>/dev/null
    end

    cloudtop_fwd start >/dev/null
    read -l pid <$XDG_STATE_HOME/cloudtop_fwd/loop.pid
    cloudtop_fwd stop >/dev/null
    sleep 0.2
    set -l alive (kill -0 $pid 2>/dev/null; and echo yes; or echo no)
    set -l pidfile_exists (test -f $XDG_STATE_HOME/cloudtop_fwd/loop.pid; and echo yes; or echo no)
    cleanup_state
    echo "$alive:$pidfile_exists"
) = no:no

@test "stop succeeds when nothing is running" (
    setup_hermetic_env
    cloudtop_fwd stop >/dev/null
    set -l res $status
    cleanup_state
    echo $res
) = 0

@test "loop reconnects with exponential backoff capped at 60s" (
    setup_hermetic_env
    set -g ssh_calls 0
    set -g sleep_delays
    function ssh
        set -g ssh_calls (math $ssh_calls + 1)
        return 255
    end
    function sleep -a delay
        set -g -a sleep_delays $delay
        test (count $sleep_delays) -lt 7
    end

    __cloudtop_fwd_loop cloudtop-fwd >/dev/null
    cleanup_state
    echo "$ssh_calls:"(string join , $sleep_delays)
) = 7:2,4,8,16,32,60,60

@test "loop passes -N and the host to ssh" (
    setup_hermetic_env
    set -g ssh_args
    function ssh
        set -g ssh_args $argv
        return 255
    end
    function sleep; return 1; end

    __cloudtop_fwd_loop my-fwd-host >/dev/null
    cleanup_state
    string join " " -- $ssh_args
) = "-N my-fwd-host"

# --- status: end-to-end CDP probe -------------------------------------------

@test "status returns 1 and skips the probe when the loop is not running" (
    setup_hermetic_env
    set -g probed false
    function __cloudtop_fwd_local_cdp_ok
        set -g probed true
    end
    cloudtop_fwd status >/dev/null
    set -l res $status
    cleanup_state
    echo "$res:$probed"
) = 1:false

@test "status reports when local Chrome is not serving CDP" (
    setup_hermetic_env
    fake_running_loop
    set -l out (cloudtop_fwd status)
    set -l res $status
    cleanup_state
    string match -q "CDP: nothing serves 127.0.0.1:9222 locally*" -- $out[2]
    echo "$res:$status"
) = 0:0

@test "status skips the end-to-end check without a main master" (
    setup_hermetic_env
    fake_running_loop
    set -g probed false
    function __cloudtop_fwd_local_cdp_ok; return 0; end
    function __cloudtop_fwd_master_alive; return 1; end
    function __cloudtop_fwd_remote_cdp_ok; set -g probed true; end
    set -l out (cloudtop_fwd status)
    set -l res $status
    cleanup_state
    string match -q "CDP: skipped*" -- $out[2]
    echo "$res:$status:$probed"
) = 0:0:false

@test "status succeeds when the Cloudtop reaches local Chrome" (
    setup_hermetic_env
    fake_running_loop
    function __cloudtop_fwd_local_cdp_ok; return 0; end
    function __cloudtop_fwd_master_alive; return 0; end
    function __cloudtop_fwd_remote_cdp_ok; return 0; end
    set -l out (cloudtop_fwd status)
    set -l res $status
    cleanup_state
    echo "$res:$out[2]"
) = "0:CDP: the Cloudtop reaches local Chrome through :9222."

@test "status fails and suggests restart when the tunnel is dead" (
    setup_hermetic_env
    fake_running_loop
    function __cloudtop_fwd_local_cdp_ok; return 0; end
    function __cloudtop_fwd_master_alive; return 0; end
    function __cloudtop_fwd_remote_cdp_ok; return 1; end
    set -l out (cloudtop_fwd status)
    set -l res $status
    cleanup_state
    string match -q "*cloudtop_fwd restart*" -- $out[2]
    echo "$res:$status"
) = 1:0

@test "remote probe bypasses forwards and the shpool RemoteCommand" (
    setup_hermetic_env
    set -g probe_args
    function __cloudtop_fwd_with_deadline
        set -g probe_args $argv
        echo 200
    end
    __cloudtop_fwd_remote_cdp_ok main
    set -l res $status
    cleanup_state
    contains -- RemoteCommand=none $probe_args
    and contains -- ClearAllForwardings=yes $probe_args
    and contains -- main $probe_args
    echo "$res:$status"
) = 0:0

@test "remote probe fails when the probe prints nothing" (
    setup_hermetic_env
    function __cloudtop_fwd_with_deadline; return 1; end
    __cloudtop_fwd_remote_cdp_ok main 2>&1
    set -l res $status
    cleanup_state
    echo $res
) = 1

# --- watchdog ---------------------------------------------------------------

@test "watchdog kills a command that overruns its deadline" (
    setup_hermetic_env
    set -l started (date +%s)
    __cloudtop_fwd_with_deadline 0.3 sleep 5
    set -l res $status
    set -l elapsed (math (date +%s) - $started)
    cleanup_state
    test $elapsed -lt 3
    echo "$res:$status"
) = 1:0

@test "watchdog returns command output when it finishes in time" (
    setup_hermetic_env
    set -l out (__cloudtop_fwd_with_deadline 5 env echo hello)
    set -l res $status
    cleanup_state
    echo "$res:$out"
) = 0:hello

# --- ssh_config.template invariants ------------------------------------------

@test "interactive host declares no forwards and no ExitOnForwardFailure" (
    # Secondary `ssh main` sessions multiplex onto the master and re-request
    # any forwards; ExitOnForwardFailure turns that into exit 255 and makes
    # scloud reconnect forever. Forwards here also put bulk traffic ahead of
    # keystrokes.
    set -l block (template_block "Host main edit gemini")
    set -l bad (string match -ir '^(RemoteForward|LocalForward|ExitOnForwardFailure)\b.*' -- $block)
    if test (count $block) -eq 0
        echo "fail: Host main edit gemini block not found"
    else if test (count $bad) -gt 0
        echo "fail: "(string join ' | ' $bad)
    else
        echo pass
    end
) = pass

@test "cloudtop-fwd owns both forwards on a non-multiplexed connection" (
    set -l block (template_block "Host cloudtop-fwd")
    contains -- "LocalForward 9998 localhost.corp.google.com:9998" $block
    and contains -- "RemoteForward 9222 127.0.0.1:9222" $block
    and contains -- "ControlMaster no" $block
    and echo pass
    or echo "fail: "(string join ' | ' $block)
) = pass

@test "ssh_config.template declares each forwarded port exactly once" (
    # Two blocks racing for the same port is the original CDP tunnel bug.
    set -l template (status dirname)/../../ssh_config.template
    set -l ports (string match -rg '^\s*(?:Remote|Local)Forward\s+(\d+)' <$template)
    set -l unique (printf '%s\n' $ports | sort -u)
    if test (count $ports) -gt 0; and test (count $ports) -eq (count $unique)
        echo pass
    else
        echo "fail: ports=("(string join ',' $ports)") unique=("(string join ',' $unique)")"
    end
) = pass
