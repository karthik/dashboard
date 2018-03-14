library(jsonlite)
library(jqr)
library(magrittr)
library(usethis)
library(purrr)
pkgs <- readLines("https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/registry.json")
pkgs %>% jq(".packages[] | .url") %>% combine() %>% fromJSON() -> urls
repos <- gsub("https://github.com/", "", urls)
dir.create("~/repos")
path <- paste0("~/repos/", repos)

map(repos, function(r){
  paste0("~/repos/", r)
  create_from_github(r, protocol = "https", destdir = "~/repos", open=FALSE)
  devtools::check(paste0("~/repos/", r))

})