## This is a nonsense code indented in a way that I think is correct.
## Both Vim-R-plugin and Emacs/ESS make (different) mistakes when indenting it.
## The following options are in the ~/.vimrc:
##
## set expandtab
## set shiftwidth=4
## let r_indent_ess_comments = 1
## let r_indent_align_args = 1
##
## and the following is in the ~/.emacs
##
## (add-hook 'ess-mode-hook
##                   (lambda ()
##                         (ess-set-style 'C++)))
##
## If you want to improve the indent/r.vim script, you may want to test your new
## indentation algorithm with this R script: Make a copy of this file, open it
## with Vim, do gg=G, quit and use vimdiff to see what is wrong.


for(i in 1:10){
    if(T){
        a <- 1:10
    }
    else {
        a <- 2:11
        b <- 2:10
    }
}

if(T)

    sim

acabou

x <- DT[really_long_row_subsetting_variable,
        really_long_column_subsetting_variable,
        by = really_long_by_statement]


asas
if(T)
    asas
asas
asas
asas

lkdlks
if(T)
                                        # comment
    andada
ksldks
kslksd

if (!(attr in urls))
    value = escape_txt_chars(value)
## more commented code here.

while(T) {
    lskdlsks
}

if(FALSE){
}

ff <- "hist"
mm <- methods(ff)
l <- length(mm)
for(i in 1:l){
    if(exists(mm[i])){
        arglist <- formals(mm[i])
        if(nothing('ksjs#asq')) # ls()
            a <- b
        k <- length(arglist)
        if(k > 0){
            argnames <- names(arglist)
            for(j in 1:k)
                cat(ff, mm[i], argnames[j], "\n")
        }
        vcov <- if(length(coef))
            solve(oout$he)
        else
            matrix(numeric(0L), 0L, 0L)
        vcov <-
            if(length(coef))
                solve(oout$he)
            else
                matrix(numeric(0L), 0L, 0L)
        xxx
        www
    }
}

if(T)
{
    lskdlsks
    kdlsks

    maes <- subset(b, (age < 40) & (sex == "Female") &
                   ((condfam == "Reference person") | (condfam == "Spouse")) &
                   (tipom > 0), select = c("uf", "sex", "age", "fam.cond", "col",
                                           "school", "urban", "income", "fam.income",
                                           "tipom", "peso"))

    maes$tipom <- factor(maes$tipom, levels = c(1, 2), labels = c("Casada", "Solteira"))
    label(maes$tipom) <- "Tipo de mãe"
                                        # Comment here

    if(T)
        a <- b
    else
        c <- d
    fim()
    comeco
}

while(T)
{
    if(T){

                                        # Another comment here
        kdlskd
    } else {
        dksldk
        iwd <- as.integer(substr(fmt, Iind + 1, regexpr('[\\.\\)]', fmt) - 1))
        iwd <- as.integer(substr(fmt, Iind + 1, regexpr("\\.\\", fmt) - 1))
        iwd <- as.integer(substr(fmt, Iind + 1, regexpr('[\\.\\(]', fmt) - 1))
        sklsdk
    }
}

if(nothing){
    if(everything)
    {
        a <- b
}}

x <- a
for(i1 in lista1)
    for(i2 in lista2)
        for(i3 in lista3)
            for(i4 in lista4)
                cat(i1, i2, i3, i4, "\n")

for(i1 in lista1)
    for(i2 in lista2)
        for(i3 in lista3)
            for(i4 in lista4)
                cat(i1, i2, i3, i4, "\n")

if(T)
{
    if (is.environment(object))
    {
        ls()
    }
    else
    {
        ls()
    }
}

if(nothing('ksjs#asq')) ls()
a <- b

if(inherits(pfit, "try#error")) return(NA)
else {
    zz <- 2*(pfit@min - fitted@min)
    a <- b
}

nothing <- function(x)
{
    if(x == "everything")
        x <- "nothing"
    x
}

if (T)
{
    if(T)
        for(i  in 1:2)
        {
            cat(i, "\n")
        }
    x
}

if(F)
{
    if(T)
        for(i in 1:2){
            x <- 1
        }
    x
}

latlon.format <- function(lat, lon, digits=max(6, getOption("digits") - 1))
{
    n <- length(lon)
    rval <- vector("character", n)
    if (!is.numeric(lat) || !is.numeric(lon))
        return ("(non-numeric lat or lon)")
    for (i in 1:n) {
        if (is.na(lat[i]) || is.na(lon[i]))
            rval[i] <- ""
        else
            rval[i] <- paste(format(abs(lat[i]), digits=digits),
                             if (lat[i] > 0) "N  " else "S  ",
                             format(abs(lon[i]), digits=digits),
                             if (lon[i] > 0) "E" else "W",
                             sep="")
        n <- lon
    }
    rval
}

                                        # indent-test-dk-01.R
if (type == "fill") {
    land <- c("#FBC784","#F1C37A","#E6B670","#DCA865","#D19A5C",
              "#C79652","#BD9248","#B38E3E","#A98A34")
    water <- c("#E1FCF7","#BFF2EC","#A0E8E4","#83DEDE","#68CDD4",
               "#4FBBC9","#38A7BF","#2292B5","#0F7CAB")
} else {
    land <- c("#FBC784","#F1C37A","#E6B670","#DCA865","#D19A5C",
              "#C79652","#BD9248","#B38E3E","#A98A34")
    water <- c("#A4FCE3","#72EFE9","#4FE3ED","#47DCF2","#46D7F6",
               "#3FC0DF","#3FC0DF","#3BB7D3","#36A5C3","#3194B4",
               "#2A7CA4","#205081","#16255E","#100C2F")
}

lon.format <- function(lon, digits=max(6, getOption("digits") - 1))
{
    n <- length(lon)
    if (n < 1) return("")
    rval <- vector("character", n)
    for (i in 1:n)
        if (is.na(lon[i]))
            rval[i] <-  ""
        else
            rval[i] <- paste(format(abs(lon[i]), digits=digits),
                             if (lon[i] > 0) "E" else "S",
                             sep="")
    rval
}

structure(do.something(name = name, exit = NULL, handler = handler,
                       description = description, test = test,
                       interactive = interactive),
          class = "restart")

## store info for loading name space for loadingNamespaceInfo to read
"__LoadingNamespaceInfo__" <- list(libname = package.lib,
                                   pkgname = package)

if(any(missingMethods))
    stop(gettextf("in '%s' methods for export not found: %s",
                  package,
                  paste(expMethods[missingMethods],
                        collapse = ", ")),
         domain = NA)

if(www){
    if(R_version_built_under < "2.10.0")
        stop(gettextf("package '%s' was built before R 2.10.0: please re-install it",
                      basename(pkgpath)), call. = FALSE, domain = NA)
    ## we need to ensure that S4 dispatch is on now if the package
    ## will require it, or the exports will be incomplete.
    dependsMethods <- "methods" %in% names(pkgInfo$Depends)
    if(dependsMethods) loadNamespace("methods")
}

makeRestart <- function(name = "",
                        handler = function(...) NULL,
                        description = "",
                        test = function(c) TRUE,
                        interactive = NULL) {
    structure(list(name = name, exit = NULL, handler = handler,
                   description = description, test = test,
                   interactive = interactive),
              class = "restart")
}

sapply(seq_along(symNames),
       function(i) {
           ## could vectorize this outside of the loop
           ## and assign to different variable to
           ## maintain the original names.
           varName <- names(symNames)[i]
           origVarName <- symNames[i]
           if(exists(varName, envir = env))
               warning("failed to assign NativeSymbolInfo for ",
                       origVarName,
                       ifelse(origVarName != varName,
                              paste(" to", varName), ""),
                       " since ", varName,
                       " is already defined in the ", package,
                       " namespace")
           else
               assign(varName, symbols[[origVarName]],
                      envir = env)

       })

if(xx == aa &&
   yy == bb)
    cat(xx, yy)
cat(aa, bb)

something <- function()
{
    if (file.exists(nsFile))
        directives <- if (!is.na(enc) &&
                          ! Sys.getlocale("LC_CTYPE") %in% c("C", "POSIX")) {
            con <- file(nsFile, encoding=enc)
            on.exit(close(con))
            parse(con)
        } else parse(nsFile)
    else if (mustExist)
        stop(gettextf("package '%s' has no NAMESPACE file", package),
             domain = NA)
    x
}

print.difftime <- function(x, digits = getOption("digits"), ...)
{
    if(is.array(x) || length(x) > 1L) {
        cat("Time differences in ", attr(x, "units"), "\n", sep="")
        y <- unclass(x); attr(y, "units") <- NULL
        print(y)
    }
    else
        cat("Time difference of ", format(unclass(x), digits=digits), " ",
            attr(x, "units"), "\n", sep="")

    invisible(x)
}

print.difftime <- function(x, digits = getOption("digits"), ...)
{
    if(is.array(x) || length(x) > 1L) {
        cat("Time differences in ", attr(x, "units"), "\n", sep="")
        y <- unclass(x); attr(y, "units") <- NULL
        print(y)
    } else
        cat("Time difference of ", format(unclass(x), digits=digits), " ",
            attr(x, "units"), "\n", sep="")

    invisible(x)
}

namespaceImport <- function(self, ...)
    for (ns in list(...)) namespaceImportFrom(self, asNamespace(ns))

x

as.function.default <- function (x, envir = parent.frame(), ...)
    if (is.function(x)) x else .Internal(as.function.default(x, envir))

as.array <- function(x, ...)
    UseMethod("as.array")

bquote <- function(expr, where=parent.frame())
{
    unquote <- function(e)
        if (length(e) <= 1L) e
        else if (e[[1L]] == as.name(".")) eval(e[[2L]], where)
        else if (is.pairlist(e)) as.pairlist(lapply(e,unquote))
        else as.call(lapply(e,unquote))

    unquote(substitute(expr))
}

bquote <- function(expr, where=parent.frame())
{
    unquote <- function(e)
        if (length(e) <= 1L) e else
            if (e[[1L]] == as.name(".")) eval(e[[2L]], where) else
                if (is.pairlist(e)) as.pairlist(lapply(e,unquote)) else
                    as.call(lapply(e,unquote))

    unquote(substitute(expr))
}

for (i in 1:num.stations) {
    thetime <- stn.time[select[1]] # e. g. 2222
    time[i] <- as.numeric(as.POSIXct(paste(substr(thedate,1,4),
                                           " ",
                                           substr(thetime,1,2),
                                           ":",
                                           substr(thetime,3,4),
                                           ":00",sep=""),tz="UTC")) - trefn
    stn[i] <- sub("^ *", "", station.id[select[1]])
    lat[i] <- latitude[select[1]]
}

bquote <-
    function(expr, where=parent.frame())
    {
        unquote <- function(e)
            if (length(e) <= 1L) e else
                if (e[[1L]] == as.name(".")) eval(e[[2L]], where) else
                    if (is.pairlist(e)) as.pairlist(lapply(e,unquote)) else
                        as.call(lapply(e,unquote))

        unquote(substitute(expr))
    }

attr.all.equal <- function(target, current,
                           check.attributes = TRUE,
                           check.names = TRUE, ...)
{
    ##--- "all.equal(.)" for attributes ---
    ##---  Auxiliary in all.equal(.) methods --- return NULL or character()
    msg <- NULL
    if(mode(target) != mode(current))
        msg <- paste("Modes: ", mode(target), ", ", mode(current), sep = "")
    cat(msg)
}

"::" <- function(pkg, name) {
    pkg <- as.character(substitute(pkg))
    name <- as.character(substitute(name))
    ns <- tryCatch(asNamespace(pkg), hasNoNamespaceError = function(e) NULL)
    if (is.null(ns)) {
        pos <- match(paste("package", pkg, sep=":"), search(), 0L)
        if (pos == 0)
            stop(gettextf("package %s has no name space and is not on the search path"), sQuote(pkg), domain = NA)
        get(name, pos = pos, inherits = FALSE)
    }
    else getExportedValue(pkg, name)
}

topenv <- function(envir = parent.frame(),
                   matchThisEnv = getOption("topLevelEnvironment")) {
    while (! identical(envir, emptyenv())) {
        nm <- attributes(envir)[["names", exact = TRUE]]
        if ((is.character(nm) && length(grep("^package:" , nm))) ||
            ## matchThisEnv is used in sys.source
            identical(envir, matchThisEnv) ||
            identical(envir, .GlobalEnv) ||
            identical(envir, baseenv()) ||
            .Internal(isNamespaceEnv(envir)) ||
            ## packages except base and those with a separate namespace have .packageName
            exists(".packageName", envir = envir, inherits = FALSE))
            return(envir)
        else envir <- parent.env(envir)
    }
    return(.GlobalEnv)
}

nsInfoFilePath <- file.path(pkgpath, "Meta", "nsInfo.rds")
nsInfo <- if(file.exists(nsInfoFilePath)) .readRDS(nsInfoFilePath)
    else parseNamespaceFile(package, package.lib, mustExist = FALSE)

pkgInfoFP <- file.path(pkgpath, "Meta", "package.rds")

foo <- function(){
    xxx
    .knownS3Generics <- local({

        ## include the S3 group generics here
        baseGenerics <- c("Math", "Ops", "Summary", "Complex",
                          "as.character", "as.data.frame", "as.environment", "as.matrix", "as.vector",
                          "cbind", "labels", "print", "rbind", "rep", "seq", "seq.int",
                          "solve", "summary", "t")

        utilsGenerics <- c("edit", "str")
    })
    xxx
    tt <- try({
        ns <- loadNamespace(package, c(which.lib.loc, lib.loc),
                            keep.source = keep.source)
        dataPath <- file.path(which.lib.loc, package, "data")
        env <- attachNamespace(ns, pos = pos,
                               dataPath = dataPath, deps)
    })
    xxx
}

foo <- function(){
    xxx
    paths <- c(paths,
               dirs[file.info(dirs)$isdir &
                    file.exists(file.path(dirs,
                                          "DESCRIPTION"))])
    xxx
    if(nzchar(r_arch)
       ## back-compatibility fix: remove before 2.12.0
       ## && (.Platform$OS.type != "windows" || r_arch != "i386")
       && file.exists(file.path(pkgpath, "libs"))
       && !file.exists(file.path(pkgpath, "libs", r_arch)))
        stop(gettextf("package '%s' is not installed for 'arch=%s'",
                      pkgname, r_arch),
             call. = FALSE, domain = NA)
    xxx
    if(!package %in% c("datasets", "grDevices", "graphics", "methods",
                       "splines", "stats", "stats4", "tcltk", "tools",
                       "utils") &&
       isTRUE(getOption("checkPackageLicense", FALSE)))
        checkLicense(package, pkgInfo, pkgpath)
    xxx
    res <- .Fortran("dqrdc2",
                    qr=x,
                    n,
                    n,
                    p,
                    as.double(tol),
                    rank=integer(1L),
                    qraux = double(p),
                    pivot = as.integer(1L:p),
                    double(2*p),
                    PACKAGE="base")[c(1,6,7,8)]# c("qr", "rank", "qraux", "pivot")
    if(!is.null(cn <- colnames(x)))
        colnames(res$qr) <- cn[res$pivot]
    class(res) <- "qr"
    res
}

if(TRUE){
    x <- xx[, c("abc", "bdc", "cde", "def", "efg", "fgh", "ghi", "hij", "ijk",
                "jkl", "klm", "lmn", "mno", "nop")]
    x <- NULL
}

test <- this('the function works',
             {
                 x <- 0
             })

test <- this('the function works', {
                 x <- 0
             })

test_that('the function works',
          {
              x <- 0
          })

test_that('the function works', {
              x <- 0
          })

x <- 1 + 2 + 3 +
    4 + 5
x <- 1 - 2 - 3 -
    4 - 5
x <- 1 * 2 * 3 *
    4 * 5
x <- 1 / 2 / 3 /
    4 / 5
y <- x ~
    x
y =
    x
x <-
    33

ggplot(data, aes(…)) +
    geom <- points() +
    theme <- bw() +
    scale <- fill <- discrete()
x <- 0

x = letters %>%
    sapply(strupper)
message(x)

flights %>%
    group <- by(year, month, day) %>%
    select(arr <- delay, dep <- delay) %>%
    endop <- "END"
x <- 0

############################################################################
## indent/r.vim starts to make mistakes here

y = x &
    x
y = x |
    x

test <- this('the function works',
             {
                 x <- 0
             }
            )

that('the function works', {
         x <- 0
     })

test_that('my unit test', {
              if (some <- condition)
                  result
              else
                  other <- result
          })

data.frame <- function(..., row.names = NULL, check.rows = FALSE, check.names = TRUE,
                       stringsAsFactors = default.stringsAsFactors())
{
    data.row.names <-
        if(check.rows && is.null(row.names))
            function(current, new, i) {
                if(is.character(current)) new <- as.character(new)
                stop(gettextf("mismatch of row names in arguments of 'data.frame\', item %d", i), domain = NA)
            }
        else function(current, new, i) {
            if(is.null(current)) {
                if(anyDuplicated(new)) {
                    warning("some row.names duplicated: ",
                            paste(which(duplicated(new)), collapse=","),
                            " --> row.names NOT used")
                    current
                } else new
            } else current
        }
    xxx
}


foo <- function(){
    xxx
    if (ismat) for (i in seq_len(differences)) r <- r[i1, , drop = FALSE] -
        r[-nrow(r):-(nrow(r) - lag + 1), , drop = FALSE]
    else for (i in seq_len(differences))
        r <- r[i1] - r[-length(r):-(length(r) - lag + 1L)]
    r
    if(is.null(width)) width <- 0L
    else if(width < 0L) { flag <- "-"; width <- -width }
    format.default(x, width=width,
                   justify = if(flag=="-") "left" else "right")
    xxx
}

try <- function(expr, silent = FALSE) {
    if(file == "") file <- stdin()
    else {
        if (isTRUE(keep.source))
            srcfile <- srcfile(file, encoding = encoding)
        file <- file(file, "r", encoding = encoding)
    }
    xxx
    tryCatch(expr, error = function(e) {
                 call <- conditionCall(e)
                 xxx
             },
             xxx)
    xxx
    levels(f) <- ## nl == nL or 1
        if (nl == nL) as.character(labels)
        else paste(labels, seq_along(levels), sep="")
    class(f) <- c(if(ordered)"ordered", "factor")
    f
}

flights %>%
    group <- by(year, month, day) %>%
    select(arr <- delay, dep <- delay) %>%
    summarise(
              arr = mean(arr <- delay, na.rm = TRUE),
              dep = mean(dep <- delay, na.rm = TRUE)
             ) %>%
    filter(arr > 30 | dep > 30)
x <- 0

cat("The End\n")

## vim: expandtab sw=4 cursorcolumn
