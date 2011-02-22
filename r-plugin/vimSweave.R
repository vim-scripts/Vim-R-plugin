
.vim.Sweave <- function(rnowebfile, latexcmd = "pdflatex", bibtex = FALSE, ...)
{
    Sres <- Sweave(rnowebfile, ...)
    if(exists('Sres')){
        system(paste(latexcmd, Sres))
        if(bibtex){
            system(paste("bibtex", sub("\\.tex$", ".aux", Sres)))
            system(paste(latexcmd, Sres))
            system(paste(latexcmd, Sres))
        }
    }
}
