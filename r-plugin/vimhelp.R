
# Code extracted from all.R (src/library/utils)
.vim.help <- function(topic, w)
{
  if(version$major < "2" || (version$major == "2" && version$minor < "11.0"))
      stop("The use of Vim as pager for R requires R >= 2.11.0\n  Please, put in your vimrc:\n  let vimrplugin_vimpager = \"no\"")
  o <- paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoc", sep = "")
  f <- utils:::index.search(topic, .find.package(NULL, NULL))
  if(length(f) == 0){
    cat('No documentation for "', topic, '" in loaded packages and libraries.\n', sep = "")
    return(invisible(NULL))
  }
  p <- basename(dirname(dirname(f)))
  if(version$major > "2" || (version$major == "2" && version$minor >= "12.0")){
    tools::Rd2txt_options(width = w)
    res <- tools::Rd2txt(utils:::.getHelpFile(f), out = o, package = p)
  } else {
    res <- tools::Rd2txt(utils:::.getHelpFile(f), width = w, out = o, package = p)
  }
  unlink(paste(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/Rdoclock", sep = ""))
  if(length(res) == 0)
    stop("length(res) == 0")
}

