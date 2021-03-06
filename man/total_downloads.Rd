% Generated by roxygen2 (4.0.2): do not edit by hand
\name{total_downloads}
\alias{total_downloads}
\title{Total downloads from the RStudio CRAN mirror between specified dates.}
\usage{
total_downloads(pkg, start = NULL, today = NULL)
}
\arguments{
\item{pkg}{Name of package (must not include github org/user name)}

\item{start}{Start date for CRAN downloads}

\item{today}{End date for CRAN downloads}
}
\description{
Total downloads from the RStudio CRAN mirror between specified dates.
}
\examples{
\dontrun{
total_downloads("alm")
}
}

