#! /usr/bin/env fish

if status is-interactive
    # Commands to run in interactive sessions can go here
    if ! type -q fisher
        curl -sL https://git.io/fisher | source && fisher update
    end

    set -g fish_escape_delay_ms 10
    # Add personal y.pm module to Perl's path. Use it with `perl -My`
    set -l dir_to_add $HOME/.local/bin
    if not contains $dir_to_add (string split ":" $PERL5LIB)
        set -gx PERL5LIB "$dir_to_add":"$PERL5LIB"
    end

    abbr grw 'fd . | entr -r -c go run .'
    abbr gtw 'fd . | entr -r -c go test -run=/'

    # Tmux Search All the whole buffer
    abbr --set-cursor tmsa "$(string join \n -- \
        'tmux capture-pane -S - -E -; tmux show-buffer \\' \
        '| perl -nE \'print if m{%}\' | tac | perl -nE \'print if !$seen{$_}++\' | tac')"
    # Tmux Search the current pane
    abbr --set-cursor tms "$(string join \n -- \
        'tmux capture-pane; tmux show-buffer \\' \
        '| perl -nE \'print if m{%}\' | tac | perl -nE \'print if !$seen{$_}++\' | tac')"

    abbr j z
    abbr ss --position anywhere 'string split \' \''
    abbr sf 'source ~/.config/fish/config.fish'
    abbr st 'tmux source ~/.tmux.conf'
    abbr tm 'tmux new -A -s main'
    abbr v nvim
    abbr vs 'nvim -S'
    abbr b --set-cursor "bash -c '%'"
    abbr c clear
    abbr e exit
    abbr caffeine 'caffeinate -imdsu'
    abbr crl 'curl --remote-name --location'
    abbr lb --set-cursor --position anywhere '~/.local/bin/%'
    abbr cf --set-cursor --position anywhere '~/.config/fish/%'
    abbr cfc --position anywhere '~/.config/fish/config.fish'
    abbr cfcl --position anywhere '~/.config/fish/config.local.fish'
    abbr cfcm --set-cursor --position anywhere '~/.config/fish/completions/%'
    abbr cff --set-cursor --position anywhere '~/.config/fish/functions/%'
    abbr cfh --position anywhere '~/.config/fish/hg.fish'
    abbr fi 'fish -i'
    abbr cn --set-cursor --position anywhere '~/.config/nvim/%'
    abbr cni --position anywhere '~/.config/nvim/init.lua'
    abbr cnl --set-cursor --position anywhere '~/.config/nvim/lua/%'
    abbr cnf --set-cursor --position anywhere '~/.config/nvim/ftplugin/%'
    abbr apti 'sudo apt install -y'
    abbr aptbd 'sudo apt build-dep'
    abbr aptc --set-cursor "apt-cache search . | rg -P '%'" # search for an apt package with PCRE2 regex
    # Deluge console commands
    abbr dlc deluge-console
    abbr dla 'deluge-console add'
    abbr dlid --set-cursor "$(string join \n -- \
        'deluge-console info \\' \
        '| rg -A 1 -i -P "%" \\' \
        '| perl -nE \'print $& if m{(?<=ID: ).*}\''
    )" "deluge show id by search regex"
    abbr dlr --set-cursor "$(string join \n -- \
        'deluge-console info \\' \
        '| rg -A 1 -i -P "%" \\' \
        '| perl -nE \'print $& if m{(?<=ID: ).*}\' \\' \
        '| read id; deluge-console rm $id' \
    )" "deluge remove torrent"
    abbr dli --set-cursor "$(string join \n -- \
        'deluge-console info \\' \
        '| perl -nE \'print if /%/i../^\s*$/\'' \
    )" "deluge show torrent info on a searched regex"
    abbr lks --set-cursor 'sudo ln -s -t ~/plexmediaserver/shows/ ~/plexmediaserver/seed/%'
    abbr lkm --set-cursor 'sudo ln -s -t ~/plexmediaserver/movies/ ~/plexmediaserver/seed/%'
    # Sync histories with other open fish shells
    abbr hm 'history merge'
    # Installation command for pkgsrc
    abbr pkgi "sudo (which bmake) install clean clean-depends"
    abbr --set-cursor whi --position anywhere "$(string join \n -- 'while read line' '% $line' 'end')"
    abbr --set-cursor psb --position anywhere "(echo '%' | psub)"
    abbr --set-cursor cpy --position anywhere "| tty-copy -n"
    abbr --set-cursor tt --position anywhere "tty-copy -n"
    abbr --set-cursor jqf --position anywhere "jq . (echo '%' | psub)"
    abbr --set-cursor ec --position anywhere 'entr -c'
    abbr --set-cursor ecr --position anywhere 'entr -cr'
    abbr --set-cursor ecrs --position anywhere 'entr -crs \'%\''
    abbr --set-cursor fmtn --position anywhere "| numfmt --format \"%'.2f\""
    abbr --set-cursor psa --position anywhere 'ps aux | rg -P "%"'

    # Perl abbreviations
    abbr --set-cursor pc --position anywhere "perl -E 'say ( % )' | numfmt --format \"%'.2f\""
    abbr --set-cursor pe --position anywhere "perl -E 'say %'"
    abbr --set-cursor pp --position anywhere "perl -pE '%'"
    abbr --set-cursor pn --position anywhere "perl -nE '%'"
    abbr --set-cursor pnp --position anywhere "perl -nE 'print if m{%}'"
    abbr --set-cursor pnm --position anywhere 'perl -nE \'print $& if m{%}\''
    abbr --set-cursor pnpa --position anywhere 'fd --type file | xargs -P $(nproc) -n 1000 -d \'\\n\' perl -nE \'print if m{%}\''
    abbr --set-cursor pnu --position anywhere "perl -nE 'print unless m{%}'"
    abbr --set-cursor pnua --position anywhere 'fd --type file | xargs -P $(nproc) -n 1000 -d \'\\n\' perl -nE \'print unless m{%}\''
    # Find files
    abbr --set-cursor pfd "perl -MFile::Find -E 'find(sub { say \$File::Find::name if m{%} }, \".\")'"
    # Show before and after of a Substitute
    abbr --set-cursor pa --position anywhere "perl -aE 'say %'"
    # Field separator as newline, Record separator as a comma
    abbr --set-cursor pfc --position anywhere "perl -F',' -E 'say % @F'"
    # Field separator as newline, Record separator as 2 newlines
    abbr --set-cursor pfn --position anywhere "perl -00 -F'\n' -E 'say % @F'"
    # Field separator as newline, Record separator as a tab
    abbr --set-cursor pft --position anywhere "perl -F'\t' -E 'say % @F'"
    # Record separator as space
    abbr --set-cursor p04 --position anywhere "perl -040 -nE 'print %'"
    # Record separator as 2 newlines
    abbr --set-cursor p00 --position anywhere "perl -00 -nE 'print %'"
    # Slurp whole file into one record
    abbr --set-cursor p07 --position anywhere "perl -0777 -nE 'print %'"
    # Find and Replace
    abbr --set-cursor pr --position anywhere "perl -i -pE"
    # Find and Replace preview
    abbr --set-cursor prv --position anywhere 'fd --type file | xargs -P $(nproc) -n 1000 -d \'\\n\' ppr \'s#%#$&#g\''
    # Grep with perl regex
    abbr --set-cursor rgp --position anywhere "rg -P '%'"
    abbr --set-cursor rgpf --position anywhere "rg -P --files-with-matches '%'"
    # Find with perl regex
    abbr --set-cursor fdp --position anywhere 'fd --type file | xargs -P $(nproc) -n 1000 -d \'\\n\' perl -nE \'print if m{%}\''
    abbr overlen --set-cursor "$(string join \n -- \
        'fd --type file \'.ng.html%\' \\' \
        '| xargs -P $(nproc) -n 1000 -d \'\\n\' \\' \
        'perl -nE \'say "\\n\\\\e[31m$ARGV\\\\e[0m" if $. == 1; \\' \
        '        print "  $.: $_" if length > 100; \\' \
        '        close ARGV if eof\''
    )"
    # xargs abbreviations
    abbr --position anywhere xdn 'xargs -d "\\n"'
    abbr --position anywhere xdnp 'xargs -d "\\n" -P $(nproc)'
    abbr --position anywhere xn 'xargs -n'
    abbr --position anywhere xp 'xargs -P $(nproc)'
    abbr --position anywhere xpn 'xargs -P $(nproc) -n'
    abbr slp --position anywhere --set-cursor 'sleep %m;'

    abbr mu 'mise use -g'
    abbr muu 'mise use -g ubi:'

    # javascript abbreviations
    # javascript newline separated iterable
    abbr --position anywhere --set-cursor jn 'deno eval \'const stdin = await new Response(Deno.stdin.readable).text();
for (let [i, line] of stdin.split("\n").entries()) {
  %
  console.log(line);
}
\''

    # javascript whitespace separated iterable
    abbr --position anywhere --set-cursor js 'deno eval \'const stdin = await new Response(Deno.stdin.readable).text();
for (let [i, line] of stdin.split(/\\s+/).entries()) {
  %
  console.log(line);
}
\''

    # javascript json string
    abbr --position anywhere --set-cursor jj 'deno eval \'const stdin = await new Response(Deno.stdin.readable).json();
console.log(stdin);
\''

    # javascript newline separated async iterable
    abbr --position anywhere --set-cursor jna 'deno eval \'import { createInterface } from "node:readline";
let i = 0; for await (let line of createInterface(process.stdin)) {
  %
  console.log(line); i++;
}
\''

    # javascript whitespace separated async iterable
    abbr --position anywhere --set-cursor jsa 'deno eval \'import { createInterface } from "node:readline";
let i = 0; for await (let line of createInterface(process.stdin)) {
  for (let [j, word] of line.split(/\\s+/).entries()) {
    %
    console.log(word);
  } i++
}
\'
'

    # Renumber debug points
    abbr dr 'perl -i -pE \'s#DEBUGPRINT\[\d+#DEBUGPRINT[@{[++$i]}#\' ***.ts'
    abbr dd 'perl -i -nE \'print unless m{DEBUGPRINT}#\' ***.ts'
    abbr dc 'perl -i -pE \'s#(^\s*)(.*DEBUGPRINT)#$1// $2#\' ***.ts'
    abbr du 'perl -i -pE \'s#// (.*DEBUGPRINT)#$1#\' ***.ts'

    fish_add_path ~/.local/bin

    if type -q perl
        set -x PATH "$HOME/perl5/bin:$PATH"
        set -x PERL5LIB "$HOME/perl5/lib/perl5:$PERL5LIB"
        set -x PERL_LOCAL_LIB_ROOT "$HOME/perl5:$PERL_LOCAL_LIB_ROOT"
        set -x PERL_MB_OPT "--install_base \"$HOME/perl5\""
        set -x PERL_MM_OPT "INSTALL_BASE=$HOME/perl5"
    end

    set -x EDITOR nvim

    if type -q mise
        mise activate fish | source
    end

    source ~/.config/fish/hg.fish
    source ~/.config/fish/config.local.fish

    fzf_configure_bindings --history=\cy --directory=\cf --git_status=\cs
end
