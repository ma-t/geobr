#> DATASET: Intermediate Geographic Regions - 2019
#> Source: IBGE - https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/15774-malhas.html?=&t=o-que-e
#> scale 1:250.000 ?????????????
#> Metadata:
# Titulo: Regioes Geograficas Intermediarias
# Titulo alternativo:
# Frequencia de atualizacao: decenal
#
# Forma de apresentacao: Shape
# Linguagem: Pt-BR
# Character set: Utf-8
#
# Resumo: Regioes Geograficas Intermediarias foram criadas pelo IBGE em 2017 para substituir a meso-regioes
#
# Estado: Em desenvolvimento
# Palavras chaves descritivas:****
# Informacao do Sistema de Referencia: SIRGAS 2000

### Libraries (use any library as necessary)

library(RCurl)
library(stringr)
library(sf)
library(janitor)
library(dplyr)
library(readr)
library(parallel)
library(data.table)
library(xlsx)
library(magrittr)
library(devtools)
library(lwgeom)
library(stringi)

####### Load Support functions to use in the preprocessing of the data -----------------
source("./prep_data/prep_functions.R")


# If the data set is updated regularly, you should create a function that will have
# a `date` argument download the data

update <- 2019


# Root directory
root_dir <- "L:////# DIRUR #//ASMEQ//geobr//data-raw"
setwd(root_dir)

# Directory to keep raw zipped files
dir.create("./intermediate_regions")
setwd("./intermediate_regions")



# Create folders to save clean sf.rds files
destdir_clean <- paste0("./shapes_in_sf_cleaned/",update)
dir.create( destdir_clean , showWarnings = FALSE)



#### 0. Download original Intermediate Regions data sets from IBGE ftp -----------------

if(update == 2019){
  ftp <- 'ftp://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2019/Brasil/BR/br_regioes_geograficas_intermediarias.zip'
  download.file(url = ftp, destfile = "RG2019_rgint_20190430.zip")
}

if(update == 2017){
  ftp <- 'ftp://geoftp.ibge.gov.br/organizacao_do_territorio/divisao_regional/divisao_regional_do_brasil/divisao_regional_do_brasil_em_regioes_geograficas_2017/shp/RG2017_rgint_20180911.zip'
  download.file(url = ftp, destfile = "RG2017_rgint_20180911.zip")
}


########  1. Unzip original data sets downloaded from IBGE -----------------

if(update == 2019){
  unzip("RG2019_rgint_20190430.zip")
}

if(update == 2017){
  unzip("RG2017_rgint_20180911.zip")
}



##### 2. Rename columns -------------------------

# read data
if(update == 2019){
  temp_sf <- st_read("BR_RG_Intermediarias_2019.shp", quiet = F, stringsAsFactors=F, options = "ENCODING=UTF8")

  temp_sf <- dplyr::rename(temp_sf, code_intermediate = CD_RGINT, name_intermediate = NM_RGINT)
}

if(update == 2017){
  temp_sf <- st_read("RG2017_rgint.shp", quiet = F, stringsAsFactors=F, options = "ENCODING=UTF8")

  temp_sf <- dplyr::rename(temp_sf, code_intermediate = rgint, name_intermediate = nome_rgint)
}



# Add state and region information
temp_sf <- add_region_info(temp_sf, column='code_intermediate')
temp_sf <- add_state_info(temp_sf, column='code_intermediate')




# reorder columns
temp_sf <- dplyr::select(temp_sf, 'code_intermediate', 'name_intermediate','code_state', 'abbrev_state',
                         'name_state', 'code_region', 'name_region', 'geometry')




###### 4. ensure every string column is as.character with UTF-8 encoding -----------------

# convert all factor columns to character
temp_sf <- use_encoding_utf8(temp_sf)




###### Harmonize spatial projection -----------------

# Harmonize spatial projection CRS, using SIRGAS 2000 epsg (SRID): 4674
temp_sf <- harmonize_projection(temp_sf)
st_crs(temp_sf)


###### 5. remove Z dimension of spatial data-----------------
temp_sf <- temp_sf %>% st_sf() %>% st_zm( drop = T, what = "ZM")
head(temp_sf)


###### 6. fix eventual topology issues in the data-----------------
temp_sf <- sf::st_make_valid(temp_sf)


# keep code as.numeric()
temp_sf$code_state <- as.numeric(temp_sf$code_state)
temp_sf$code_region <- as.numeric(temp_sf$code_region)
temp_sf$code_intermediate <- as.numeric(temp_sf$code_intermediate )







###### 7. generate a lighter version of the dataset with simplified borders -----------------
# skip this step if the dataset is made of points, regular spatial grids or rater data

# simplify
temp_sf_simplified <- simplify_temp_sf(temp_sf)






###### 8. Clean data set and save it in compact .rds format-----------------

# save original and simplified datasets
sf::st_write(temp_sf, paste0(destdir_clean, "/intermediate_regions_",update,".gpkg") )
sf::st_write(temp_sf_simplified, paste0(destdir_clean, "/intermediate_regions_",update,"_simplified.gpkg"))

