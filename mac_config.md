# bash_profile

```
# for color
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# \h:\W \u\ $
export PS1='\[\033[01;33m\]\u@\h\[\033[01;31m\]:\w\$\[\033[00m\] '

export GOPATH=$HOME/Documents/go

oldifs=$IFS
IFS=":"
for item in $GOPATH
do
  tmpbin=$tmpbin:$item/bin
done
IFS=$oldifs
tmpbin=${tmpbin#:}
export PATH=$tmpbin:$PATH

alias ls='ls -G'
alias grep='grep --color'

if [ -f ~/.git-completion.bash ]; then
    source ~/.git-completion.bash
fi
```

# vimrc

```
syntax on
set background=dark

set laststatus=2
set statusline=%<%F\ %h%m%r%=%-14.(%l,%c%V%)\ %P

au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

set rtp+=$GOROOT/misc/vim
autocmd BufWritePost *.go :silent Fmt

set tabstop=4
```

# sublime text 3

```
{
    "color_scheme": "Packages/Color Scheme - Default/Mac Classic.tmTheme",
    "default_line_ending": "unix",
    "font_size": 13,
    "highlight_line": true,
    "highlight_modified_tabs": true,
    "ignored_packages":
    [
    ],
    "rulers":
    [
        80,
        100,
        120
    ],
    "soda_classic_tabs": true,
    "soda_folder_icons": true,
    "tab_size": 4,
    "translate_tabs_to_spaces": true,
    "update_check": false,
    "vintage_start_in_command_mode": true,
    "word_wrap": true,
    "wrap_width": 80
}
```

# gosublime

```
{
    "env": {
        "GOPATH": "/Users/tangjiyuan/Documents/goproj",
        "GOROOT": "/usr/local/go"
    },
    // 打开这个才有下面的 comp_lint_commands 标签里面的内容
    "comp_lint_enabled": true,
    "comp_lint_commands": [
        // run `golint` on all files in the package
        // "shell":true is required in order to run the command through your shell (to expand `*.go`)
        // also see: the documentation for the `shell` setting in the default settings file ctrl+dot,ctrl+4
        {"cmd": ["golint *.go"], "shell": true},

        // run go vet on the package
        {"cmd": ["go", "vet"]},
    ],
    "fmt_cmd": ["goimports"],
    "on_save": [
        // run comp-lint when you save,
        // naturally, you can also bind this command `gs_comp_lint`
        // to a key binding if you want
        {"cmd": "gs_comp_lint"}
    ],
}
```
