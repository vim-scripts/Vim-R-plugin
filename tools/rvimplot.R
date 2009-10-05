
.vimplot <- function(x)
{
  if(is.numeric(x)){
    oldpar <- par(no.readonly = TRUE)
    par(mfrow = c(2, 1))
    hist(idade, col = "lightgray")
    boxplot(idade, main = paste("Boxplot of", deparse(substitute(x))),
        col = "lightgray", horizontal = TRUE)
    par(oldpar)
  } else {
    plot(x)
  }
}

