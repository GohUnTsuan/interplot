#' Plot Conditional Coefficients in Models with Interaction Terms
#' 
#' Graph based on the data frame of statistics about the conditional effect of an interaction.
#' 
#' @param m A model object including an interaction term, or, alternately, a data frame recording conditional coefficients. This data frame should includes four columns:
#' \itemize{
#'    \item fake: The sequence of \code{var1} (the item whose effect will be conditioned on in the interaction);
#'    \item coef1: The point estimates of the coefficient of \code{var1} at each break point.
#'    \item ub: The upper bound of the simulated 95\% CI.
#'    \item lb: The lower bound of the simulated 95\% CI.
#' }
#' @param var1 The name (as a string) of the variable of interest in the interaction term; its conditional coefficient estimates will be plotted.
#' @param var2 The name (as a string) of the other variable in the interaction term.
#' @param plot A logical value indicating whether the output is a plot or a dataframe including the conditional coefficient estimates of var1, their upper and lower bounds, and the corresponding values of var2.
#' @param steps Desired length of the sequence. A non-negative number, which for seq and seq.int will be rounded up if fractional. The default is 100 or the unique categories in the \code{var2} (when it is less than 100. Also see \code{\link{unique}}).
#' @param ci is a numeric value inherited from the data wrangling functions in this package. Adding it here is just for the method consistency.
#' @param adjCI Succeeded from the data management functions in `interplot` package. 
#' @param hist A logical value indicating if there is a histogram of `var2` added at the bottom of the conditional effect plot.
#' @param var2_dt A numerical value indicating the frequency distribution of `var2`. It is only used when `hist == TRUE`. When the object is a model, the default is the distribution of `var2` of the model. 
#' @param predPro A logical value with default of `FALSE`. When the `m` is an output of a general linear model (class `glm` or `glmerMod`) and the argument is set to `TRUE`, the function will plot predicted probabilities at the values given by `var2_vals`. 
#' @param var2_vals A numerical value indicating the values the predicted probabilities are estimated, when `predPro` is `TRUE`. 
#' @param point A logical value determining the format of plot. By default, the function produces a line plot when var2 takes on ten or more distinct values and a point (dot-and-whisker) plot otherwise; option TRUE forces a point plot.
#' @param sims Number of independent simulation draws used to calculate upper and lower bounds of coefficient estimates: lower values run faster; higher values produce smoother curves.
#' @param xmin A numerical value indicating the minimum value shown of x shown in the graph. Rarely used.
#' @param xmax A numerical value indicating the maximum value shown of x shown in the graph. Rarely used.
#' @param ercolor A character value indicating the outline color of the whisker or ribbon.
#' @param esize A numerical value indicating the size of the whisker or ribbon.
#' @param ralpha A numerical value indicating the transparency of the ribbon.
#' @param rfill A character value indicating the filling color of the ribbon.
#' @param ... Other ggplot aesthetics arguments for points in the dot-whisker plot or lines in the line-ribbon plots. Not currently used.
#' @param ci_diff A numerical vector with a pair of values indicating the confidence intervals of the difference between the conditional effects at the minimum and maximum values. The intervals can be use to interpret the significant
#' 
#' @details \code{interplot.plot} is a S3 method from the \code{interplot}. It generates plots of conditional coefficients.
#' 
#' Because the output function is based on \code{\link[ggplot2]{ggplot}}, any additional arguments and layers supported by \code{ggplot2} can be added with the \code{+}. 
#' 
#' @return The function returns a \code{ggplot} object.
#' 
#' @import  ggplot2
#' @importFrom graphics hist
#' @importFrom dplyr mutate
#' 
#' 
#' @export

## S3 method for class 'data.frame'
interplot.plot <- function(m, var1 = NULL, var2 = NULL, plot = TRUE, steps = NULL, ci = .95, adjCI = FALSE, hist = FALSE, var2_dt = NULL, predPro = FALSE, var2_vals = NULL, point = FALSE, sims = 5000, xmin = NA, xmax = NA, ercolor = NA, esize = 0.5, ralpha = 0.5, rfill = "grey70", ci_diff = NULL, ...) {
    if(is.null(steps)) steps <- nrow(m)
    levels <- sort(unique(m$fake))
    ymin <- ymax <- vector() # to deal with the "no visible binding for global variable" issue
    xdiff <- vector() # to deal with the "no visible binding for global variable" issue
    
    if(predPro == TRUE){
      if(is.null(m$value)) stop("The input data.frame does not include required information.")
    }
    
    if (hist == FALSE) {
      if (steps < 5 | point == T) {
        if (is.na(ercolor)) ercolor <- "black"  # ensure whisker can be drawn
          if(predPro == TRUE){
            coef.plot <- ggplot(m, aes_string(x = "fake", y = "coef1", colour = "value")) + geom_point(...) + geom_errorbar(aes_string(ymin = "lb", ymax = "ub", colour = "value"), width = 0, size = esize) + scale_x_continuous(breaks = levels) + ylab(NULL) + xlab(NULL)
          }else{
            coef.plot <- ggplot(m, aes_string(x = "fake", y = "coef1")) + geom_point(...) + geom_errorbar(aes_string(ymin = "lb", ymax = "ub"), width = 0, color = ercolor, size = esize) + scale_x_continuous(breaks = levels) + ylab(NULL) + xlab(NULL)
          }
      } else {
        if(predPro == TRUE){
          coef.plot <- ggplot(m, aes_string(x = "fake", y = "coef1", colour = "value")) + geom_line(...) + geom_ribbon(aes_string(ymin = "lb", ymax = "ub", fill = "value"), alpha = ralpha) + ylab(NULL) + xlab(NULL)
        }else{
          coef.plot <- ggplot(m, aes_string(x = "fake", y = "coef1")) + geom_line(...) + geom_ribbon(aes_string(ymin = "lb", ymax = "ub"), alpha = ralpha, color = ercolor, fill = rfill) + ylab(NULL) + xlab(NULL)
        }
      }
      
      if(!is.null(ci_diff)){
        coef.plot <- coef.plot + 
          labs(caption = paste0("CI(Max - Min): [", round(ci_diff[1], digits = 3), ", ", round(ci_diff[2], digits = 3), "]"))
      }
      
      return(coef.plot)
    } else {
        if (point == T) {
            if (is.na(ercolor)) ercolor <- "black"  # ensure whisker can be drawn
            
            yrange <- c(m$ub, m$lb, var2_dt)
            maxdiff <- (max(yrange) - min(yrange))
            
            break_var2 <- steps + 1
            if (break_var2 >= 100) 
                break_var2 <- 100
            hist.out <- hist(var2_dt, breaks = seq(min(var2_dt), max(var2_dt), l = break_var2), plot = FALSE)
            
            n.hist <- length(hist.out$mids)
            
            if (steps <10) {
              dist <- (hist.out$mids[2] - hist.out$mids[1])/3
            } else {
              dist <- hist.out$mids[2] - hist.out$mids[1]
              }
            hist.max <- max(hist.out$counts)
            
            if (steps <10) {
              histX <- data.frame(ymin = rep(min(yrange) - maxdiff/5, n.hist),
                                ymax = hist.out$counts/hist.max * maxdiff/5 + min(yrange) - maxdiff/5, 
                                xmin = sort(unique(var2_dt)) - dist/2, 
                                xmax = sort(unique(var2_dt)) + dist/2)
            } else {
              histX <- data.frame(ymin = rep(min(yrange) - maxdiff/5, n.hist), 
                                  ymax = hist.out$counts/hist.max * maxdiff/5 + min(yrange) - maxdiff/5, 
                                  xmin = hist.out$mids - dist/2, 
                                  xmax = hist.out$mids + dist/2)
                                } 
            #when up to 10, the sort(unique(var2_dt)) - dist/2 leads to problemtic histogram
            
            
            if (steps <10) {
              histX_sub <- histX
            } else {
              histX_sub <- mutate(histX, xdiff = xmax - xmin, xmax = xmax - xdiff/2)
            }
            
            coef.plot <- ggplot()
            coef.plot <- coef.plot + geom_rect(data = histX, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), colour = "gray50", alpha = 0, size = 0.5)  #histgram
            
            if(predPro == TRUE){
              coef.plot <- coef.plot + geom_errorbar(data = m, aes_string(x = "fake", ymin = "lb", ymax = "ub", colour = "value"), width = 0, size = esize) + scale_x_continuous(breaks = levels) + ylab(NULL) + xlab(NULL) + geom_point(data = m, aes_string(x = "fake", y = "coef1", colour = "value")) 
            }else{
              coef.plot <- coef.plot + geom_errorbar(data = m, aes_string(x = "fake", ymin = "lb", ymax = "ub"), width = 0, color = ercolor, size = esize) + scale_x_continuous(breaks = levels) + ylab(NULL) + xlab(NULL) + geom_point(data = m, aes_string(x = "fake", y = "coef1")) 
            }
        } else {
            
            yrange <- c(m$ub, m$lb)
            
            maxdiff <- (max(yrange) - min(yrange))
            
            break_var2 <- length(unique(var2_dt))
            if (break_var2 >= 100) 
                break_var2 <- 100
            hist.out <- hist(var2_dt, breaks = break_var2, plot = FALSE)
            
            n.hist <- length(hist.out$mids)
            dist <- hist.out$mids[2] - hist.out$mids[1]
            hist.max <- max(hist.out$counts)
            
            histX <- data.frame(ymin = rep(min(yrange) - maxdiff/5, n.hist), ymax = hist.out$counts/hist.max * maxdiff/5 + min(yrange) - maxdiff/5, xmin = hist.out$mids - dist/2, xmax = hist.out$mids + dist/2)
            
            coef.plot <- ggplot()
            coef.plot <- coef.plot + geom_rect(data = histX, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), colour = "gray50", alpha = 0, size = 0.5)
            
            if(predPro == TRUE){
              coef.plot <- coef.plot + geom_line(data = m, aes_string(x = "fake", y = "coef1", colour = "value")) + geom_ribbon(data = m, aes_string(x = "fake", ymin = "lb", ymax = "ub", fill = "value"), alpha = ralpha) + ylab(NULL) + xlab(NULL)
            }else{
              coef.plot <- coef.plot + geom_line(data = m, aes_string(x = "fake", y = "coef1")) + geom_ribbon(data = m, aes_string(x = "fake", ymin = "lb", ymax = "ub"), alpha = ralpha, color = ercolor, fill = rfill) + ylab(NULL) + xlab(NULL)
            }
        }
      
      if(!is.null(ci_diff)){
        coef.plot <- coef.plot + 
          labs(caption = paste0("CI(Max - Min): [", round(ci_diff[1], digits = 3), ", ", round(ci_diff[2], digits = 3), "]"))
      }
      
      return(coef.plot)
    }
    
} 
