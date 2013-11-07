
if(.Platform$OS.type == "windows"){
    .rpf <- Sys.getenv("R_PROFILE_USER")
    if(.rpf == ""){
        if(Sys.getenv("R_USER") == "")
            stop("R_USER environment variable not set.")
        .rpf <- paste0(Sys.getenv("R_USER"), "\\.Rprofile")
    }
} else {
    if(Sys.getenv("HOME") == ""){
        stop("HOME environment variable not set.")
    } else {
        .rpf <- paste0(Sys.getenv("HOME"), "/.Rprofile")
    }
}
if(file.exists(.rpf)){
    .rpflines <- readLines(.rpf)
} else {
    .rpflines <- ""
}
if(length(grep("vimcom", .rpflines)) > 0){
    writeLines(c(.rpf, "vimcom_found"),
	       con = paste0(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/configR_result"))
} else {
    .rpflines <- c(.rpflines,
                   '',
                   '# Added by Vim-R-plugin command  :RpluginConfig :',
                   'if(interactive()){',
                   '    library("vimcom.plus")')
    if(.Platform$OS.type == "windows"){
        .rpflines <- c(.rpflines, '    options(editor = \'"C:/Program Files (x86)/Vim/vim74/gvim.exe" "-c" "set filetype=r"\')')
    } else {
        .rpflines <- c(.rpflines, 
                       '    if(nchar(Sys.getenv("DISPLAY")) > 1)',
                       '        options(editor = \'gvim -f -c "set ft=r"\')',
                       '    else',
                       '        options(editor = \'vim -c "set ft=r"\')',
                       '    library(colorout)',
                       '    if(Sys.getenv("TERM") != "linux" && Sys.getenv("TERM") != ""){',
                       '        # Choose the colors for R output among 256 options.',
                       '        # You should run show256Colors() and help(setOutputColors256) to',
                       '        # know how to change the colors according to your taste:',
                       '        setOutputColors256(verbose = FALSE)',
                       '    }',
                       '    library(setwidth)')
    }
    .rpflines <- c(.rpflines, "}")
    writeLines(.rpflines, con = .rpf)
    writeLines(c(.rpf, "new_Rprofile"),
	       con = paste0(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/configR_result"))
}

