
# Code extracted from all.R (src/library/utils)
.vim.help <- function(topic, w)
{
  o <- paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoc", sep = "")
  f <- utils:::index.search(topic, .find.package(NULL, NULL))
  if(length(f) == 0){
    cat('No documentation for "', topic, '" in loaded packages and libraries.\n', sep = "")
    return(invisible(NULL))
  }
  p <- basename(dirname(dirname(f)))
  v <- sub("\\..*", "", R.version$minor)
  v <- as.numeric(paste(R.version$major, ".", v, sep = "")) 
  if(v >= 2.12){
    tools::Rd2txt_options(width = w)
    res <- tools::Rd2txt(utils:::.getHelpFile(f), out = o, package = p)
  } else {
    res <- tools::Rd2txt(utils:::.getHelpFile(f), width = w, out = o, package = p)
  }
  unlink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoclock", sep = ""))
  if(length(res) == 0)
    stop("Error in .vim.help()")
}

