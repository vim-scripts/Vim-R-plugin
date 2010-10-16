
.vim.browser.order <- character()
.vim.browser.curlist <- character()

.vim.browserline <- function(x.name, x)
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
    .vim.browser.curlist <<- paste(.vim.browser.curlist, x.name, sep = "-")
    cat(", 'items': {", sep = "")
    x.names <- names(x)

    # Don't include elements of lists with duplicated names
    x.names.dup <- duplicated(x.names)
    if(sum(x.names.dup) > 0) x.names <- x.names[!x.names.dup]

    len <- length(x.names)
    newlistnames <- paste('"', paste(x.names, collapse = '", "'), '"', sep = "")

    .vim.browser.order <<- paste(.vim.browser.order, "'", .vim.browser.curlist, "': [", newlistnames, "], ", sep = "")

    if(len > 1){
      for(i in 1:len){
	.vim.browserline(x.names[i], x[[i]])
      }
    }
    cat("}")
  }
  cat("}, ")
}

sink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/objbrowser", sep = ""))
cat("let b:workspace = {")
for(.i in ls()){
  .vim.browser.curlist <- ""
  .vim.browserline(.i, get(.i))
}
cat("}\n")
.vim.browser.order <- sub(", $", "", .vim.browser.order)
cat("let b:list_order = {", .vim.browser.order, "}\n", sep = "")
sink()
rm(.i, .vim.browser.curlist, .vim.browser.order, .vim.browserline)
unlink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/objbrowserlock", sep = ""))

