
.vim.list.args <- function(ff){
  knownGenerics <- c(names(.knownS3Generics),
    tools:::.get_internal_S3_generics()) # from methods()
  keyf <- paste("^", ff, "$", sep="")
  is.generic <- (length(grep(keyf, knownGenerics)) > 0)
  if(is.generic){
    mm <- methods(ff)
    l <- length(mm)
    if(l > 0){
      for(i in 1:l){
        if(exists(mm[i])){
          cat(ff, " (method ", mm[i], "):\n", sep="")
          print(args(mm[i]))
          cat("\n")
        }
      }
      return(invisible(NULL))
    }
  }
  print(args(ff))
}

