

.vim.browser <- function(allnames = FALSE)
{
  vim.browserline <- function(x.name, x, curlist)
  {
    if(is.numeric(x)) x.class <- "numeric"
    else if(is.factor(x)) x.class <- "factor"
    else if(is.character(x)) x.class <- "character"
    else if(is.function(x)) x.class <- "function"
    else if(is.logical(x)) x.class <- "logical"
    else if(is.data.frame(x)) x.class <- "data.frame"
    else if(is.list(x)) x.class <- "list"
    else x.class <- "other"

    cat("'", x.name, "': {'class': \"", x.class, '"', sep = "")
    x.label <- attr(x, "label")
    if(!is.null(x.label)) cat(", 'label': \"", x.label, '"', sep = "")
    if(is.list(x)){
      curlist <- paste(curlist, x.name, sep = "-")
      cat(", 'items': {", sep = "")
      x.names <- names(x)

      # Don't include elements of lists with duplicated names
      x.names.dup <- duplicated(x.names)
      if(sum(x.names.dup) > 0) x.names <- x.names[!x.names.dup]

      newlistnames <- paste('"', paste(x.names, collapse = '", "'), '"', sep = "")
      .vim.browser.order <<- paste(.vim.browser.order, "'", curlist, "': [", newlistnames, "], ", sep = "")

      len <- length(x.names)
      if(len > 0){
	for(i in 1:len){
	  vim.browserline(x.names[i], x[[i]], curlist)
	}
      }
      cat("}")
    }
    cat("}, ")
  }

  # Begin of .vim.browser()
  objlist <- ls(".GlobalEnv", all.names = allnames)
  .vim.browser.order <<- character()
  sink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/objbrowser", sep = ""))
  cat("let b:workspace = {")
  for(obj in objlist){
    vim.browserline(obj, get(obj), "")
  }
  cat("}\n")
  .vim.browser.order <- sub(", $", "", .vim.browser.order)
  cat("let b:list_order = {", .vim.browser.order, "}\n", sep = "")
  liblist <- search()
  liblist <- liblist[grep("package:", liblist)]
  liblist <- sub("package:", "", liblist)
  cat("let b:liblist = ['", paste(liblist, collapse = "', '"), "']\n", sep = "") 
  sink()
  rm(.vim.browser.order, pos = ".GlobalEnv")
  unlink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/objbrowserlock", sep = ""))
}

