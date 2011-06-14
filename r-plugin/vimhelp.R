
# Code based on all.R (src/library/utils)
.vim.help <- function(topic, w, classfor, package)
{
    if(!missing(classfor) & length(grep(topic, names(.knownS3Generics))) > 0){
        curwarn <- getOption("warn")
        options(warn = -1)
        try(classfor <- classfor, silent = TRUE)  # classfor may be a function
        try(.theclass <- class(classfor), silent = TRUE)
        options(warn = curwarn)
        if(exists(".theclass")){
            for(i in 1:length(.theclass)){
                newtopic <- paste(topic, ".", .theclass[i], sep = "")
                if(length(utils:::index.search(newtopic, .find.package(NULL, NULL))) > 0){
                    topic <- newtopic
                    break
                }
            }
        }
    }
    if(version$major < "2" || (version$major == "2" && version$minor < "11.0"))
        stop("The use of Vim as pager for R requires R >= 2.11.0\n  Please, put in your vimrc:\n  let vimrplugin_vimpager = \"no\"")
    o <- paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoc", sep = "")
    f <- utils:::index.search(topic, .find.package(NULL, NULL))
    if(length(f) == 0){
        cat('No documentation for "', topic, '" in loaded packages and libraries.\n', sep = "")
        return(invisible(NULL))
    }
    if(length(f) > 1){
        if(missing(package)){
            f <- sub("/help/.*", "", f)
            f <- sub(".*/", "", f)
            sink(o)
            cat("The topic \"", topic, "\" was found in ", length(f), " libraries.\n\n", sep = "")
            cat("Please, send one of the lines below to R\nto get the desired documentation:\n\n")
            for(i in 1:length(f))
                cat(f[i], "::", topic, "\n", sep = "")
            sink()
            unlink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoclock", sep = ""))
            return(invisible(NULL))
            f <- f[1]
        } else {
            f <- f[grep(paste("/", package, "/", sep = ""), f)]
            if(length(f) == 0)
                stop("length(f) == 0")
        }
    }
    p <- basename(dirname(dirname(f)))
    if(version$major > "2" || (version$major == "2" && version$minor >= "12.0")){
        tools::Rd2txt_options(width = w)
        res <- tools::Rd2txt(utils:::.getHelpFile(f), out = o, package = p)
    } else {
        res <- tools::Rd2txt(utils:::.getHelpFile(f), width = w, out = o, package = p)
    }
    unlink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoclock", sep = ""))
    if(length(res) == 0)
        stop("length(res) == 0")
}

