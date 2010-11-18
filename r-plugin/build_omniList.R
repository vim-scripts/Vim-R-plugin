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
### Mon, November 08, 2010


# Build Omni List
.vim.bol <- function(omnilist, what = "loaded", allnames = FALSE) {

  # Bugs converting arguments of strOptions(), heatmap(), and some other
  # functions with complex arguments.
  vim.formal2char <- function(x){
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
	  a[i-1] <- vim.formal2char(clist[[i]])[1]
	a <- paste(a, collapse = ", ")
	return(paste(as.character(clist[[1]]), "(", a, ")", sep = ""))
      } else {
	return(paste(as.character(clist[[1]]), "()", sep = ""))
      }
    }
    return(as.character(x))
  }

  vim.list.args2 <- function(ff){ 
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
      ff.defaults <- sapply(ff.formals, vim.formal2char)
      ff.pretty.args <- sub('=$', '', paste(paste(ff.args, ff.defaults, sep="="), sep=", "))
      ff.all.args <- paste(ff.pretty.args, collapse=", ")
      ff.all.args <- gsub("\n", "\\\\\\n", ff.all.args)
      return(ff.all.args)
    }
  }

  # Only recent versions of R have the grepl() function. We can replace
  # vim.grepl() with grepl() in the near future.
  vim.grepl <- function(pattern, x){
    res <- grep(pattern, x)
    if(length(res) == 0){
      return(FALSE)
    } else {
      return(TRUE)
    }
  }

  vim.omni.line <- function(x, envir, printenv, curlevel){
    if(curlevel == 0){
      xx <- get(x, envir)
    } else {
      x.clean <- gsub("$", "", x, fixed = TRUE)
      x.clean <- gsub("_", "", x.clean, fixed = TRUE)
      haspunct <- vim.grepl("[[:punct:]]", x.clean)
      if(haspunct[1]){
	ok <- vim.grepl("[[:alnum:]]\\.[[:alnum:]]", x.clean)
	if(ok[1]){
	  haspunct  <- FALSE
	  haspp <- vim.grepl("[[:punct:]][[:punct:]]", x.clean)
	  if(haspp[1]) haspunct <- TRUE
	}
      }

      # No support for names with spaces
      if(vim.grepl(" ", x)){
	haspunct <- TRUE
      }

      if(haspunct[1]){
	xx <- NULL
      } else {
	xx <- try(eval(parse(text=x)), silent = TRUE)
	if(class(xx)[1] == "try-error"){
	  xx <- NULL
	}
      }
    }

    if(is.null(xx)){
      x.group <- " "
      x.class <- "unknown"
    } else {
      if(x == "break" || x == "next" || x == "for" || x == "if" || x == "repeat" || x == "while"){
	x.group <- "flow-control"
	x.class <- "flow-control"
      } else {
	if(is.function(xx)) x.group <- "function"
	else if(is.numeric(xx)) x.group <- "numeric"
	else if(is.factor(xx)) x.group <- "factor"
	else if(is.character(xx)) x.group <- "character"
	else if(is.logical(xx)) x.group <- "logical"
	else if(is.data.frame(xx)) x.group <- "data.frame"
	else if(is.list(xx)) x.group <- "list"
	else x.group <- " "
	x.class <- class(xx)[1]
      }
    }

    if(x.group == "function"){
      if(curlevel == 0){
	cat(x, ";", "function;function", ";", printenv, ";", vim.list.args2(x), "\n", sep="")
      } else {
	# some libraries have function as list elements
	cat(x, ";", "function;function", ";", printenv, ";", "Unknown arguments", "\n", sep="")
      }
    } else {
      if(is.list(xx)){
	if(curlevel == 0){
	  cat(x, ";", x.class, ";", x.group, ";", printenv, ";", "Not a function", "\n", sep="")
	} else {
	  cat(x, ";", x.class, ";", " ", ";", printenv, ";", "Not a function", "\n", sep="")
	}
      } else {
	cat(x, ";", x.class, ";", x.group, ";", printenv, ";", "Not a function", "\n", sep="")
      }
    }

    if(is.list(xx) && curlevel == 0){
      obj.names <- names(xx)
      curlevel <- curlevel + 1
      if(length(xx) > 0){
	for(k in obj.names){
	  vim.omni.line(paste(x, "$", k, sep=""), envir, printenv, curlevel)
	}
      }
    }
  }

  # Begin of .vim.bol()
  vim.OutDec <- options("OutDec")[[1]]
  options(OutDec = ".")
  if(what == "installed"){
    cat("Loading all installed packages...\n")
    for(vim.pack in installed.packages()[, "Package"]){
      library(vim.pack, character.only = TRUE)
    }
  }
  noGlobalEnv <- vim.grepl("/r-plugin/omniList", omnilist)
  if(noGlobalEnv){
    cat("Building file with list of objects in", what, "packages for omni completion and Object Browser...\n")
  }
  envnames <- search()
  sink(omnilist, append = FALSE)
  for(curenv in envnames){
    if((curenv == ".GlobalEnv" && noGlobalEnv) | (curenv != ".GlobalEnv" && noGlobalEnv == FALSE)) next
    obj.list <- objects(curenv, all.names = allnames)
    envir <- sub("package:", "", curenv)
    l <- length(obj.list)
    if(l > 0){
      for(obj in obj.list) vim.omni.line(obj, curenv, envir, 0)
    }
  }
  sink()
  options(OutDec = vim.OutDec)
  unlink(paste(omnilist, ".locked", sep = ""))
}

