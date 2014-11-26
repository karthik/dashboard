[![Build Status](https://travis-ci.org/ropensci/dashboard.png?branch=master)](https://travis-ci.org/ropensci/dashboard)

# Dashboard

This package provides an easy dashboard for any collection of R projects.

## Installation

```r
devtools::install_github("ropensci/dashboard")
```

## Example use

```r

library(dashboard)

package <- c("alm","AntWeb","bmc","bold","clifro","dependencies",
            "ecoengine","ecoretriever","elastic","elife","floras",
            "fulltext","geonames","gistr", "jekyll-knitr","mocker",
            "neotoma","plotly","rAltmetric","rAvis","rbhl","rbison",
            "rcrossref","rdatacite","rdryad","rebird","rentrez","reol",
            "reproducibility-guide","rfigshare","rfishbase","rfisheries",
            "rflybase","rgauges","rgbif","rglobi","rhindawi",
            "rinat","RMendeley","rmetadata","RNeXML","rnoaa","rnpn",
            "traits","rplos","rsnps","rspringer","rvertnet","rWBclimate",
            "solr","spocc","taxize","togeojson","treeBASE","ucipp","testdat",
            "git2r","rdat","EML",'aRxiv','datapackage','dvn','gender','ggit',
            'gigadb','historydata','ICES','mdextract','ots','paleobioDB',
            'pangaear','prism','rDat','rebi','rnbn','rOBIS','rorcid',
            'RSelenium','sheetseeR','USAboundaries','zenodo')

# Add the GitHub organization/user name before each page
pkgs <- add_github(package,"ropensci")

message("Now querying the GitHub API \n")
# Run the stats on all the packages
results <- lapply(pkgs,github_stats)  %>% Filter(Negate(is.null),.)  
# Finally generate a static html page (this bit is unfinished in the package but works manually)
generate_html(results)
```

[![ropensci footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)

