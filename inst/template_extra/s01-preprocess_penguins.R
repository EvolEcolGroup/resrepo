library(resrepo)
penguins <- read.csv(path_resrepo("/data/raw/default/penguins.csv"))
penguins_na_omit <- na.omit(penguins)
write.csv(penguins_na_omit, 
          file = path_resrepo("/data/intermediate/s01-preprocess_penguins/penguins_na_omit.csv"),
          row.names = FALSE)
