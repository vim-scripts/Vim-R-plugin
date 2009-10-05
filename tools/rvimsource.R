.vimsource <- function (file, local = FALSE, echo = FALSE, print.eval = echo, 
    verbose = getOption("verbose"), prompt.echo = getOption("prompt"), 
    max.deparse.length = 150, encoding = getOption("encoding"), 
    continue.echo = getOption("continue"), keep.source = getOption("keep.source")) 
{
    eval.with.vis <- function(expr, envir = parent.frame(), enclos = if (is.list(envir) || 
        is.pairlist(envir)) 
        parent.frame()
    else baseenv()) .Internal(eval.with.vis(expr, envir, enclos))
    envir <- if (local) 
        parent.frame()
    else .GlobalEnv
    have_encoding <- !missing(encoding) && encoding != "unknown"
    if (!missing(echo)) {
        if (!is.logical(echo)) 
            stop("'echo' must be logical")
        if (!echo && verbose) {
            warning("'verbose' is TRUE, 'echo' not; ... coercing 'echo <- TRUE'")
            echo <- TRUE
        }
    }
    if (verbose) {
        cat("'envir' chosen:")
        print(envir)
    }
    ofile <- file
    from_file <- FALSE
    srcfile <- NULL
    if (is.character(file)) {
        if (capabilities("iconv")) {
            if (identical(encoding, "unknown")) {
                enc <- utils::localeToCharset()
                encoding <- enc[length(enc)]
            }
            else enc <- encoding
            if (length(enc) > 1L) {
                encoding <- NA
                owarn <- options("warn")
                options(warn = 2)
                for (e in enc) {
                  if (is.na(e)) 
                    next
                  zz <- file(file, encoding = e)
                  res <- try(readLines(zz), silent = TRUE)
                  close(zz)
                  if (!inherits(res, "try-error")) {
                    encoding <- e
                    break
                  }
                }
                options(owarn)
            }
            if (is.na(encoding)) 
                stop("unable to find a plausible encoding")
            if (verbose) 
                cat("encoding =", dQuote(encoding), "chosen\n")
        }
        if (file == "") 
            file <- stdin()
        else {
            if (isTRUE(keep.source)) 
                srcfile <- srcfile(file, encoding = encoding)
            file <- file(file, "r", encoding = encoding)
            on.exit(close(file))
            from_file <- TRUE
            loc <- utils::localeToCharset()[1L]
            encoding <- if (have_encoding) 
                switch(loc, `UTF-8` = "UTF-8", `ISO8859-1` = "latin1", 
                  "unknown")
            else "unknown"
        }
    }
    exprs <- .Internal(parse(file, n = -1, NULL, "?", srcfile, 
        encoding))
    Ne <- length(exprs)
    if (from_file) {
        close(file)
        on.exit()
    }
    if (verbose) 
        cat("--> parsed", Ne, "expressions; now eval(.)ing them:\n")
    if (Ne == 0) 
        return(invisible())
    if (echo) {
        sd <- "\""
        nos <- "[^\"]*"
        oddsd <- paste("^", nos, sd, "(", nos, sd, nos, sd, ")*", 
            nos, "$", sep = "")
    }
    srcrefs <- attr(exprs, "srcref")
    for (i in 1L:Ne) {
        if (verbose) 
            cat("\n>>>> eval(expression_nr.", i, ")\n\t\t =================\n")
        ei <- exprs[i]
        if (echo) {
            if (i > length(srcrefs) || is.null(srcref <- srcrefs[[i]])) {
                dep <- substr(paste(deparse(ei, control = c("showAttributes", 
                  "useSource")), collapse = "\n"), 12, 1e+06)
                dep <- paste(prompt.echo, gsub("\n", paste("\n", 
                  continue.echo, sep = ""), dep), sep = "")
                nd <- nchar(dep, "c") - 1
            }
            else {
                if (i == 1) 
                  lastshown <- min(0, srcref[3L] - 1)
                dep <- getSrcLines(srcfile, lastshown + 1, srcref[3L])
                leading <- srcref[1L] - lastshown
                lastshown <- srcref[3L]
                while (length(dep) && length(grep("^[[:blank:]]*$", 
                  dep[1L]))) {
                  dep <- dep[-1L]
                  leading <- leading - 1L
                }
                dep <- paste(rep.int(c(prompt.echo, continue.echo), 
                  c(leading, length(dep) - leading)), dep, sep = "", 
                  collapse = "\n")
                nd <- nchar(dep, "c")
            }
            if (nd) {
                do.trunc <- nd > max.deparse.length
                dep <- substr(dep, 1L, if (do.trunc) 
                  max.deparse.length
                else nd)
                cat(dep, if (do.trunc) 
                  paste(if (length(grep(sd, dep)) && length(grep(oddsd, 
                    dep))) 
                    " ...\" ..."
                  else " ....", "[TRUNCATED] "), "\n", sep = "")
            }
        }
        yy <- eval.with.vis(ei, envir)
        i.symbol <- mode(ei[[1L]]) == "name"
        if (!i.symbol) {
            curr.fun <- ei[[1L]][[1L]]
            if (verbose) {
                cat("curr.fun:")
                utils::str(curr.fun)
            }
        }
        if (verbose >= 2) {
            cat(".... mode(ei[[1L]])=", mode(ei[[1L]]), "; paste(curr.fun)=")
            utils::str(paste(curr.fun))
        }
        if (print.eval && yy$visible) {
            if (isS4(yy$value)) 
                methods::show(yy$value)
            else print(yy$value)
        }
        if (verbose) 
            cat(" .. after ", sQuote(deparse(ei, control = c("showAttributes", 
                "useSource"))), "\n", sep = "")
    }
    invisible(yy)
}
