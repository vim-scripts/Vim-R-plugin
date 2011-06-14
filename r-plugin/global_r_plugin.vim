
function! RActivateThePlugin()
    runtime ftplugin/r.vim
    call StartR("R")
endfunction

nmap <buffer> <LocalLeader>rf :call RActivateThePlugin()<CR>
