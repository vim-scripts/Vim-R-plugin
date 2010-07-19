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


.vim.list.args <- function(ff){
  knownGenerics <- c(names(.knownS3Generics),
    tools:::.get_internal_S3_generics()) # from methods()
  ff <- deparse(substitute(ff))
  keyf <- paste("^", ff, "$", sep="")
  is.generic <- (length(grep(keyf, knownGenerics)) > 0)
  if(is.generic){
    mm <- methods(ff)
    l <- length(mm)
    if(l > 0){
      for(i in 1:l){
        if(exists(mm[i])){
          cat(ff, "[method ", mm[i], "]:\n", sep="")
          print(args(mm[i]))
          cat("\n")
        }
      }
      return(invisible(NULL))
    }
  }
  print(args(ff))
}


.vim.plot <- function(x)
{
  if(is.numeric(x)){
    oldpar <- par(no.readonly = TRUE)
    par(mfrow = c(2, 1))
    hist(x, col = "lightgray")
    boxplot(x, main = paste("Boxplot of", deparse(substitute(x))),
        col = "lightgray", horizontal = TRUE)
    par(oldpar)
  } else {
    plot(x)
  }
}

