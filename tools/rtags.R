
.vim.rtags <- function() {
  unlink(.vimtagsfile)
  cat("Building 'tags' file for vim omni completion.\n")
  envnames <- search()
  sink(.vimtagsfile)
  len <- length(envnames)
  for(i in 1:len){
    obj.list <- objects(envnames[i])
    env <- sub("package:", "", envnames[i])
    l <- length(obj.list)
    if(l > 0){
      for(j in 1:l){
        haspunct <- grepl("[[:punct:]]", obj.list[j])
        if(haspunct[1]){
          ok <- grepl("[[:alnum:]]\\.[[:alnum:]]", obj.list[j])
          if(ok[1]){
            haspunct  <- FALSE
            haspp <- grepl("[[:punct:]][[:punct:]]", obj.list[j])
            if(haspp[1])
              haspunct = TRUE
          }
        }
        if(haspunct[1]){
          obj.class <- "unknowClass"
        } else {
          if(obj.list[j] == "break" || obj.list[j] == "for" ||
            obj.list[j] == "function" || obj.list[j] == "if" ||
            obj.list[j] == "repeat" || obj.list[j] == "while"){
            obj.class <- "flow-control"
            islist <- FALSE
          } else {
            obj.class <- class(eval(parse(text=obj.list[j])))
            islist <- is.list(eval(parse(text=obj.list[j])))
          }
        }
        cat(obj.list[j], " ", obj.class[1], " ", env, "\n", sep="")
        if(islist){
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

.vim.rtags()

