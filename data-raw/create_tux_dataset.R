set.seed(123)
tux <- tibble::tibble(species = "Tux", 
              island = "LaLaLand", 
              bill_length_mm = c( rnorm(25, mean=27, sd = 2), rnorm(25, mean=29, sd = 2)),
              bill_depth_mm = c( rnorm(25, mean=19, sd = 1), rnorm(25, mean=21, sd = 1)),
              flipper_length_mm = c( rnorm(25, mean=210, sd = 9), rnorm(25, mean=218, sd = 12)),
              body_mass_g =c( rnorm(25, mean=2800, sd = 80), rnorm(25, mean=3100, sd = 95)),
              sex= rep(c("female", "male"), each=25),
              year = 2025)
# now scatter some missing data              
tux[sample(1:50, 5), "body_mass_g"] <- NA
tux[8,"bill_length_mm"] <- NA
write.csv(tux, "./inst/template_extra/tux_measurements.csv", row.names = FALSE)
