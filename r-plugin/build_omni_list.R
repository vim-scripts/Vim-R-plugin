#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/

### Jakson Alves de Aquino
### Sat, July 17, 2010


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

# Only recent versions of R have the grepl() function. We can replace
# .vim.grepl() with grepl() in the near future.
.vim.grepl <- function(pattern, x){
  res <- grep(pattern, x)
  if(length(res) == 0)
    return(FALSE)
  else
    return(TRUE)
}

.vim.build.omni.list <- function() {
  unlink(.vimomnilistfile)
  cat("Building file with list of objects for vim omni completion.\n")
  envnames <- search()
  sink(.vimomnilistfile)
  for(curenv in envnames){
    noGlobalEnv <- .vim.grepl("/r-plugin/omnilist", .vimomnilistfile)
    if((curenv == ".GlobalEnv" && noGlobalEnv) | (curenv != ".GlobalEnv" && noGlobalEnv == FALSE)) next
    obj.list <- objects(curenv)
    env <- sub("package:", "", curenv)
    l <- length(obj.list)
    if(l > 0){
      for(j in 1:l){
        haspunct <- .vim.grepl("[[:punct:]]", obj.list[j])
        if(haspunct[1]){
          ok <- .vim.grepl("[[:alnum:]]\\.[[:alnum:]]", obj.list[j])
          if(ok[1]){
            haspunct  <- FALSE
            haspp <- .vim.grepl("[[:punct:]][[:punct:]]", obj.list[j])
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
	  if(obj.len > 0){
	    for(k in 1:obj.len){
	      cat(obj.list[j], "$", obj.names[k], ":", class(obj[[k]]), ":", env, ":", "Not a function", "\n", sep="")
	    }
	  }
	}
      }
    }
  }
  sink()
}

.vim.build.omni.list()
unlink(paste(.vimomnilistfile, ".locked", sep = ""))

