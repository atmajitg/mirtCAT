#' Generate a CAT patterns
#' 
#' Generate a CAT pattern given various inputs. Returns a character vector or numeric matrix 
#' (depending on whether a \code{df} input was supplied) with columns equal to the test size and
#' rows equal to the number of rows in \code{Theta}. For simulation studies, supplying a 
#' \code{Theta} input with more than 1 row will generate a matrix of responses for
#' running independent CAT session when passed to \code{mirtCAT(..., local_pattern)}. When
#' the returned object is an integer vector then the \code{Theta} values will be stored 
#' as an attribute \code{'Theta'} to be automatically used in Monte Carlo simulations.
#' 
#' @param mo single group object defined by the \code{mirt} package
#'
#' @param Theta a numeric vector indicating the latent theta values for a single person
#' 
#' @param df (optional) data.frame object containing questions, options, and scoring
#'   keys. See \code{\link{mirtCAT}} for details
#' 
#' @export generate_pattern
#' @author Phil Chalmers \email{rphilip.chalmers@@gmail.com}
#' @references 
#' 
#' Chalmers, R., P. (2012). mirt: A Multidimensional Item Response Theory
#' Package for the R Environment. \emph{Journal of Statistical Software, 48}(6), 1-29.
#' \doi{10.18637/jss.v048.i06}
#' 
#' Chalmers, R. P. (2016). Generating Adaptive and Non-Adaptive Test Interfaces for 
#' Multidimensional Item Response Theory Applications. \emph{Journal of Statistical Software, 71}(5), 
#' 1-39. \doi{10.18637/jss.v071.i05}
#' @seealso \code{\link{mirtCAT}}
#' 
#' @examples
#' \dontrun{
#' 
#' # return real response vector given choices and (optional) answers 
#' pat <- generate_pattern(mod, Theta = 0, df=df)
#' # mirtCAT(df, mo=mod, local_pattern = pat)
#' 
#' # generate single pattern observed in dataset used to define mod
#' pat2 <- generate_pattern(mod, Theta = 0)
#' # mirtCAT(mo=mod, local_pattern = pat2)
#'
#' # generate multiple patterns to be analyzed independently 
#' pat3 <- generate_pattern(mod, Theta = matrix(c(0, 2, -2), 3))
#' # mirtCAT(mo=mod, local_pattern = pat3)
#' 
#' }
generate_pattern <- function(mo, Theta, df = NULL){
    nitems <- ncol(mo@Data$data)
    if(!is.matrix(Theta)) Theta <- matrix(Theta, 1L)
    if(nrow(Theta) > 1L && !is.null(df))
        stop('df argument only used for generating single-case response patterns', call.=FALSE)
    N <- nrow(Theta)
    pattern <- matrix(0L, N, nitems)
    if(is.null(df)){
        for(i in seq_len(nitems)){
            ii <- extract.item(mo, i)
            P <- probtrace(ii, Theta)
            pattern[,i] <- mirt:::respSample(P)
        }
        ret <- t(t(pattern) + mo@Data$mins)
        attr(ret, 'Theta') <- Theta
        return(ret)
    } else {
        if(!is.data.frame(df))
            stop('df input must be a data.frame', call.=FALSE)
        if(any(sapply(df, class) == 'factor')){
            dfold <- df
            df <- data.frame(sapply(dfold, as.character), stringsAsFactors = FALSE)
            if(!all(df == dfold)) 
                stop('Coercion of df elements to characters modified one or more elements. 
                     When building the df with the data.frame() function pass the 
                     option stringsAsFactors = FALSE to avoid this issue', call.=FALSE)
        }
        choices <- df[,grepl('Option', colnames(df))]
        item_answers <- df[,grepl('Answer', colnames(df))]
        if(is.matrix(item_answers))
            stop('Only one correct answer is supported when drawing data', call.=FALSE)
    }
    ret <- character(nitems)
    has_item_answers <- length(item_answers) > 0L
    for(i in seq_len(nitems)){
        ii <- extract.item(mo, i)
        P <- probtrace(ii, Theta)
        uniq <- 1L:ncol(P) - 1L
        pattern[i] <- sample(uniq, 1L, prob = P)
        if(has_item_answers){
            ret[i] <- if(pattern[i] == 1L) item_answers[i] else
                sample(as.character(choices[i, ][!choices[i, ] %in% item_answers[i]]), 1L)
        } else {
            ret[i] <- as.character(choices[i, ][pattern[i]+1L])
        }
    }
    ret
}