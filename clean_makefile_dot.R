# A simple script to clean up the output of make2graph.

# TODO: This works but it pretty hardcoded and should be improved.

# Before this:
# Install make2graph (https://github.com/lindenb/makefile2graph)
# cd {your_code_repo}
# make -Bnd | make2graph > mfgraph.dot

mfxml2graph <- function(
    file, # path to dot file
    outfile, # path to output dot file
    datadir, # path to data dir
    codedir # path to code dir
    ) {
    library(stringr)

    # file extensions for coloring
    codeexts <- c("\\.R\"", "\\.do\"", "\\.ipynb\"", "\\.jl\"", "\\.py\"")
    dataexts <- c("\\.dta\"", "\\.csv\"", "\\.tsv\"",
                "data/", "raw/",
                "\\.jls\"", "\\.shp\"", "\\.pickle\"")
    logexts <- c("\\.log\"")

    f <- readLines(file)
    f_out <- ""
    allnode <- character(0)
    for (i in seq_along(f)) {

        l <- str_replace_all(f[i], datadir, "")
        l <- str_replace_all(l, codedir, "")
        writeline <- TRUE
        if (str_detect(l, "label=\"all\"")) {
            allnode <- str_split(l, "\\[")[[1]][1]
            writeline <- FALSE
        }
        if (length(allnode) > 0 && str_detect(l, paste0(allnode, " "))) {
            writeline <- FALSE
        }

        if (str_detect(l, "label")) {
            #if line is a node declaration, replace color depending on extension
            if (any(str_detect(l, codeexts))) {
                colorstr <- "color=\"white\""
            } else
            if (any(str_detect(l, dataexts))) {
                l <- str_replace(l, "data/", "")
                colorstr <- "color=\"deepskyblue\""
                if (str_detect(l,  "raw/", )) {
                    colorstr <- "color=\"deepskyblue4\""
                }
            } else
            if (any(str_detect(l, logexts))) {
                colorstr <- "color=\"yellow\""
                l <- str_replace(l, "logs/", "")
            } else {
                colorstr <- "color=\"dimgray\""
            }
            l <- str_replace(l, "color=\"[a-zA-Z0-9]+\"", colorstr)
        }

        if (writeline) {
            f_out <- c(f_out, l)
        }
    }

    writeLines(f_out, outfile)
}

# Next step: import to Gephi (fix layout, label scaling, etc)