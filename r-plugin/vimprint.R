
.vim.print <- function(object, classfor)
{
    if(!exists(object))
        stop("object '", object, "' not found")
    if(!missing(classfor) & length(grep(object, names(.knownS3Generics))) > 0){
        curwarn <- getOption("warn")
        options(warn = -1)
        try(classfor <- classfor, silent = TRUE)  # classfor may be a function
        try(.theclass <- class(classfor), silent = TRUE)
        options(warn = curwarn)
        if(exists(".theclass")){
            for(cls in .theclass){
                if(exists(paste(object, ".", .theclass, sep = ""))){
                    .newobj <- get(paste(object, ".", .theclass, sep = ""))
                    warning("Printing ", object, ".", .theclass, "\n", sep = "")
                    break
                }
            }
        }
    }
    if(!exists(".newobj"))
        .newobj <- get(object)
    print(.newobj)
}

