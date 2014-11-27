#' Pipe operator
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
NULL

#' Add GitHub username or organization name to packages
#'
#' @param repo Name of the repository (without org name)
#' @param  org = "ropensci" Your GitHub org name or username. Use this function only if all the repos are part of the same account. Otherwise add manually.
#' @export
#' @examples \dontrun{
#' add_github("alm", "ropensci")
#'}
add_github <- function(repo, org = "ropensci") {
  repo %>% sort %>% sapply(., function(x) paste0(org, "/", x)) %>% unname
}




#' Total downloads from the RStudio CRAN mirror between specified dates.
#'
#' @param pkg Name of package (must not include github org/user name)
#' @param  start Start date for CRAN downloads
#' @param  today End date for CRAN downloads
#' @importFrom lubridate now
#' @importFrom cranlogs cran_downloads
#' @export
#' @examples \dontrun{
#' total_downloads("alm")
#'}
total_downloads <- function(pkg, start = NULL, today = NULL) {
  if(is.null(today)) { today <-  as.Date(now()) }
  if(is.null(start)) { start <-  as.Date("2012-10-01") }

  total <- cranlogs::cran_downloads(package = pkg, from = start, to = today) 
  sum(total$downloads$downloads)
}


#' Authenticate with GitHub and retrieve a token
#'
#' Create a new application in your github settings (https://github.com/settings/applications). Set the Homepage URL and callback URL as \code{http://localhost:1410}. Then copy the app name, client id, and client secret to your \code{.rprofile} as options. e.g. \code{option(gh_appname = "YOUR_APP")} etc. This function will then automatically read those values. Otherwise specify them inline.
#' @param gh_appname Github app name
#' @param  gh_id GitHub client id
#' @param  gh_secret GitHub secret
#' @export
#' @examples \dontrun{
#' token <- github_auth()
#'}
github_auth <- function(gh_appname = getOption("gh_appname"), gh_id = getOption("gh_id"), gh_secret = getOption("gh_secret")) {
myapp <- httr::oauth_app(gh_appname, gh_id, gh_secret)
httr::oauth2.0_token(httr::oauth_endpoints("github"), myapp)
}

#' Generates a full list of GitHub stats and CRAN downloads from the RStudio mirror
#'
#' @param repo Name of a respository. Must include username or organization in format \code{username/repo}
#' @param  verbose = TRUE Prints progress by default.
#' @export
#' @examples \dontrun{
#' github_stats("ropensci/alm")
#'}
github_stats <- function(repo, verbose = TRUE) {

  org_repo <- stringr::str_split(repo, "/") %>% (function(x) length(x[[1]]))
  if(org_repo != 2)
    stop("You must specify repo name as github_account/repo")
  
  
  org <- stringr::str_split(repo, "/")[[1]][1]
  package <- stringr::str_split(repo, "/")[[1]][2]

  # ----------------------------------------------------------------------------
  # Create a new app, set Authorization callback URL = http://localhost:1410 Then
  # copy the keys into your .rprofile with the names below
  token <- github_auth()
  
  
   if(verbose)  message(sprintf("Now working on %s", repo))
    repo_url <- paste0("https://api.github.com/repos/", org, "/", package)
    data <- httr::GET(repo_url, config = c(token = token))
    if (data$status != 404) 
        {
            results <- httr::content(data, "parsed")
            dl <- httr::content(httr::GET(results$downloads_url, config = c(token = token)), 
                "parsed")
            # Need an error handler here for bad gitHub repo names
            # Note: Repo names are case sensitive
            downloads <- ifelse(length(dl) == 0, 0, length(dl))
            collab <- httr::content(httr::GET(results$contributors_url, config = c(token = token)), 
                "parsed")
            collaborators <- length(collab)
            cnames <- lapply(collab, "[", "login")
            cnames <- sapply(cnames, unname)
            collaborator_names <- as.character(paste(cnames, collapse = ", "))
            prs <- length(httr::content(httr::GET(paste0(repo_url, "/pulls"), config = c(token = token)), 
                "parsed"))
            # Didn't add closed issues or version number since neither make sense as a reason
            # for someone to jump in
            commits_raw <- httr::GET(paste0(repo_url, "/stats/commit_activity"), config = c(token = token))
            commits <- jsonlite::fromJSON(httr::content(commits_raw, "text"), flatten = TRUE)$total
            date <- gsub("T", " ", results$pushed_at)
            date <- gsub("Z", " UTC", date)
            # Now check to see if package is on CRAN
            # and if yes, then get the download stats using metacran
            # --------------------------------------------------------
            cran_return <- httr::GET(paste0("http://cran.r-project.org/web/packages/", 
                package, "/index.html"))$status
            cran <- ifelse(cran_return == 200, "label label-success", "label label-default")
            cran_downloads <- ifelse(cran_return == 200, total_downloads(package), 0)
            # --------------------------------------------------------
            
            # Milestones ---------------------------------------------
            milestones <- length(httr::content(httr::GET(paste0(repo_url, "/milestones"), config = c(token = token)), 
                "parsed"))
            milestones_closed <- length(httr::content(httr::GET(paste0(repo_url, "/milestones"), 
                query = list(state = "closed"), config = c(token = token)), "parsed"))
            total_milestones <- milestones + milestones_closed
            tm <- as.character(paste0(milestones, "/", total_milestones))
            mile_ratio <- ifelse(milestones == 0, "-", scales::percent(milestones/total_milestones))
            # --------------------------------------------------------
            
            # Compile everything into a list
            list(package = results$name, 
                 desc = results$description, 
                 updated = date, 
                forks = results$forks, 
                stars = results$stargazers_count, 
                downloads = downloads, 
                cran_downloads = cran_downloads,  
                pull_requests = prs, 
                cran = cran, 
                collaborators = collaborators, 
                collaborator_names = collaborator_names, 
                milestones = mile_ratio, 
                total_milestones = tm, 
                watchers = results$subscribers_count, 
                open_issues = results$open_issues_count, 
                sparkline = commits)
        }  # end the 404 if
}


#' Generates a static html dashboard from GitHub stats and CRAN downloads
#'
#' @param out A list object generated by github_stats()
#' @param path Folder where you need the dashboard rendered
#' @param  browse = TRUE Automatically open index.html in the default browser. Set to \code{FALSE} to disable.
#' @importFrom whisker whisker.render
#' @importFrom lubridate now
#' @export
#' @examples \dontrun{
#' generate_html(results)
#'}
generate_html <- function(out, path = "/tmp", browse = TRUE) {
setwd(path)
last_generated <- lubridate::now("UTC")
message("writing out html \n")
# location of all files and deps
template <- system.file("template.html", package = "dashboard")
css <- system.file("css", package = "dashboard")
style <- system.file("style", package = "dashboard")
js <- system.file("js", package = "dashboard")
html <- whisker::whisker.render(readLines(template))
write(html, "index.html")
file.copy(css, ".", recursive = TRUE, overwrite = TRUE)
file.copy(js, ".", recursive = TRUE, overwrite = TRUE)
file.copy(style, ".", recursive = TRUE, overwrite = TRUE)
message(sprintf("Files written to %s \n", path))
if(browse) browseURL("index.html") 
}
