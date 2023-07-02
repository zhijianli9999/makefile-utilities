# cd {your_code_repo}
# make -Bnd | make2graph > mfgraph.dot


mfxml2graph <- function(file, outfile, datadir, codedir) {
    library(stringr)

    # file extensions for coloring
    codeexts = c(".R", ".do", ".ipynb", ".jl")
    dataexts = c(".dta", ".csv", ".tsv", "data/")
    logexts = c(".log")

    f <- readLines(file)
    f_out <- ""
    allnode <- character(0)
    for (i in 1:length(f)) {

        l <- str_replace_all(f[i], datadir, "")
        l <- str_replace_all(l, codedir, "")
        writeline <- TRUE
        if (str_detect(l, "label=\"all\"")){
            allnode <- str_split(l, "\\[")[[1]][1]
            writeline <- FALSE
        }
        if (length(allnode)>0 && str_detect(l, paste0(allnode, " "))){
            writeline <- FALSE
        }
        
        if (str_detect(l, "label")){ 
            #if line is a node declaration, replace color depending on extension
            if (any(str_detect(l, codeexts))){
                colorstr <- "color=\"coral1\""
            }
            else if (any(str_detect(l, dataexts))) {
                l <- str_replace(l, "data/", "")
                colorstr <- "color=\"deepskyblue\""
            }
            else if (any(str_detect(l, logexts))) {
                colorstr <- "color=\"yellow\""
                l <- str_replace(l, "logs/", "")
            }
            else {
                colorstr <- "color=\"dimgray\""
            }
            l <- str_replace(l, "color=\"[a-zA-Z0-9]+\"", colorstr)
        }

        if (writeline){
            f_out <- c(f_out, l)
        }
    }

    writeLines(f_out, outfile)
}

############################################
# mfxml2graph(file = "/export/storage_covidvaccine/Code/mfgraph.dot",
#     outfile = "/mnt/staff/zhli/mfgraph_.dot",
#     datadir = "/export/storage_covidvaccine/Data/",
#     codedir = "/export/storage_covidvaccine/Code/")


# import to Gephi (fix layout, label scaling, etc)