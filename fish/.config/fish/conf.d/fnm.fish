#fnm
if status is-interactive
    fnm env --shell fish | source
    fnm completions --shell fish | source
end
