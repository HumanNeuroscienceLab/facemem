#' Root mean square of time-series
#'
#' Returns the RMSE between a set of time-series
#'
#' @param ts.mat matrix of time-series (ntpts x nregions)
#' 
#' @export
#' 
#' @return vector
#'
#' @examples
#' ts.mat <- matrix(rnorm(500), 100, 5)
#' rmse(ts.mat)
rmse <- function(ts.mat) {
    mean.ts <- rowMeans(ts.mat)
    diff.sq <- sweep(ts.mat, 1, mean.ts)^2
    mse     <- rowMeans(diff.sq)
    sqrt(mean(mse))
}

#' Compute rmse-based reho
reho.rmse <- function(ts.mat, mask, ...) {
    searchlight(rmse, ts.mat, mask, ...) 
}

# might want to run this rmse reho on each subject
# then average across the subjects


