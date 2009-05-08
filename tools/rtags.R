.opt.showerr <- getOption("show.error.messages")

# Comment the following line if debugging the code:
options(show.error.messages = FALSE)

vim.rtags <- function() {
  unlink(.vimtagsfile)
  cat("Building 'tags' file for vim omni completion.\n")
  envnames <- search()
  sink(.vimtagsfile)
  len <- length(envnames)
  for(i in 1:len){
    env <- envnames[i]
    obj.list <- ls(name=envnames[i])
    env <- sub("package:", "", env)
    l <- length(obj.list)
    if(l > 0){
      for(j in 1:l){
        obj.class <- "unknownClass"
        try( obj.class <- class(eval(parse(text=obj.list[j]))))
        cat(obj.list[j], obj.class, env, "\n")
        if(obj.class[1] == "data.frame" || obj.class[1] == "list" ||
        (length(obj.class) > 1 && (obj.class[2] == "data.frame" ||
        obj.class[2] == "list"))){
          obj <- eval(parse(text=obj.list[j]))
          obj.names <- names(obj)
          obj.len <- length(obj)
          for(k in 1:obj.len){
            cat(obj.list[j], "$", obj.names[k], " ", class(obj[[k]]), " ",
              env, "\n", sep="")
          }
        }
      }
    }
  }
  sink()
}

vim.rtags()

options(show.error.messages = .opt.showerr)
rm(.opt.showerr)

