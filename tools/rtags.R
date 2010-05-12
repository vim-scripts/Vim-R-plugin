
# Bugs converting arguments of strOptions(), heatmap(), and some other
# functions with complex arguments.
.vim.formal2char <- function(x){
  if(is.character(x))
    return(paste('"', x, '"', sep = ""))
  if(is.null(x))
    return("NULL")
  if(is.call(x)){
    clist <- as.list(x)
    n <- length(clist)
    if(n > 1){
      a  <- vector(mode = "character", length = n - 1)
      for(i in 2:n)
	a[i-1] <- .vim.formal2char(clist[[i]])[1]
      a <- paste(a, collapse = ", ")
      return(paste(as.character(clist[[1]]), "(", a, ")", sep = ""))
    } else {
      return(paste(as.character(clist[[1]]), "()", sep = ""))
    }
  }
  return(as.character(x))
}

.vim.list.args2 <- function(ff){ 
  knownGenerics <- c(names(.knownS3Generics),
      tools:::.get_internal_S3_generics()) # from methods()
  ff.pat <- gsub('\\?', '\\\\?', ff)
  ff.pat <- gsub('\\*', '\\\\*', ff.pat)
  ff.pat <- gsub('\\(', '\\\\(', ff.pat)
  ff.pat <- gsub('\\[', '\\\\[', ff.pat)
  ff.pat <- gsub('\\{', '\\\\{', ff.pat)
  ff.pat <- gsub('\\|', '\\\\|', ff.pat)
  ff.pat <- gsub('\\+', '\\\\+', ff.pat)
  keyf <- paste("^", ff.pat, "$", sep="")
  is.generic <- (length(grep(keyf, knownGenerics)) > 0)
  if(is.generic){
    if(length(methods(ff)) > 0){
      return("Generic Method")
    }
  }

  ff.formals <- formals(ff)
  if(is.null(ff.formals)){
    return("No arguments")
  } else {
    ff.args <- names(ff.formals)
    ff.defaults <- sapply(ff.formals, .vim.formal2char)
    ff.pretty.args <- sub('=$', '', paste(paste(ff.args, ff.defaults, sep="="), sep=", "))
    ff.all.args <- paste(ff.pretty.args, collapse=", ")
    ff.all.args <- gsub("\n", "\\\\\\n", ff.all.args)
    return(ff.all.args)
  }
}

grepl <- function(pattern, x){
  res <- grep(pattern, x)
  if(length(res) == 0)
    return(FALSE)
  else
    return(TRUE)
}

.vim.rtags <- function() {
  unlink(.vimtagsfile)
  cat("Building 'tags' file for vim omni completion.\n")
  envnames <- search()
  sink(.vimtagsfile)
  for(curenv in envnames){
    noGlobalEnv <- grepl("vim/tools/rtags", .vimtagsfile)
    if((curenv == ".GlobalEnv" && noGlobalEnv) | (curenv != ".GlobalEnv" && noGlobalEnv == FALSE)) next
    obj.list <- objects(curenv)
    env <- sub("package:", "", curenv)
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
              haspunct <- TRUE
          }
        }
	islist <- FALSE
        if(haspunct[1]){
          obj.class <- "unknowClass"
        } else {
          if(obj.list[j] == "break" || obj.list[j] == "for" ||
            obj.list[j] == "function" || obj.list[j] == "if" ||
            obj.list[j] == "repeat" || obj.list[j] == "while"){
            obj.class <- "flow-control"
          } else {
            obj.class <- class(eval(parse(text=obj.list[j])))
            islist <- is.list(eval(parse(text=obj.list[j])))
          }
        }
	if(is.function(get(obj.list[j])))
	  cat(obj.list[j], ":", obj.class[1], ":", env, ":", .vim.list.args2(obj.list[j]), "\n", sep="")
	else
	  cat(obj.list[j], ":", obj.class[1], ":", env, ":", "Not a function", "\n", sep="")
        if(islist){
          obj <- eval(parse(text=obj.list[j]))
          obj.names <- names(obj)
          obj.len <- length(obj)
          for(k in 1:obj.len){
            cat(obj.list[j], "$", obj.names[k], ":", class(obj[[k]]), ":", env, ":", "Not a function", "\n", sep="")
          }
        }
      }
    }
  }
  sink()
}

.vim.rtags()
unlink(paste(.vimtagsfile, ".locked", sep = ""))

