## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----echo=FALSE----------------------------------------------------------
linreg <- setRefClass(Class = "linreg",
                      
                    
                      fields = list(formula="formula", data="data.frame", regco="matrix",
                                    yf="matrix", e="matrix", dfreedom="numeric", 
                                    Sigma_square="numeric", Var_Beta="matrix", t_Beta="matrix", 
                                    pvalue="matrix",parse="character", stand_res="matrix",
                                    variance="numeric"),
                      
                      methods = list(
                        
                        initialize =function (formula,data)
                        {
                          c<-colnames(data)
                          d<-all.vars(formula)
                          stopifnot(d %in% c)
                          stopifnot (is.data.frame(data))
                          formula <<- formula
                          data <<- data
                          X <- model.matrix(formula,data)
                          dep_y <- all.vars(formula)[1]
                          y <- (data[,dep_y])
                          parse <<- deparse(substitute(data))
                          #Regressions coefficients
                          regco <<- solve((t(X)%*%X))%*%t(X)%*%y
                          #X <- QR
                          #Beta <- solve(R)%*%t(Q)%*%y
                          #Fitted values
                          yf <<- X%*%regco
                          #Residuals
                          e <<- y-yf
                          #Degrees of freedom
                          dfreedom <<- nrow(X)-ncol(X)
                          #Residual variance
                          Sigma_square <<- as.numeric((t(e)%*%e) / dfreedom)
                          #Variance of regression coefficients
                          Var_Beta <<- Sigma_square * solve((t(X)%*%X))
                          #t-values for each coefficient
                          t_Beta <<- regco / sqrt(diag(Var_Beta))
                          #p values for reg coefficients
                          pvalue <<- pt(abs(t_Beta),dfreedom)
                          #variance value
                          variance <<- round(sqrt(Sigma_square),2)
                          #standardised residual for plot2
                          stand_res <<- sqrt(abs((e-mean(e)) / sqrt(Sigma_square)))
                        
                        },
                        
                        #print coefficients and coefficient names
                        print = function(){
                          cat("\n","Call:","\n",
                          paste0("linreg(formula = ", format(formula), ", data = ", parse , ")\n\n ", sep = ""))
                          cat("\n","Coefficients:","\n")
                          (setNames(round(regco[1:nrow(regco)],2),rownames(regco)))
                          
                          },
                        
                        #plot()
                        plot = function(){
                          library(ggplot2)
                          library(ggThemeAssist)
                          # Liu theme
                          LiU_theme <-  theme(
                            axis.title.x = element_text(color = "#38ccd6", size = 14,
                                                        face = "bold"),
                            axis.title.y = element_text(color = "#38ccd6", size = 14,
                                                        face = "bold"),
                            axis.text = element_text(color = "#1c1c19", size = 6),
                            axis.line = element_line(color = "#1c1c19", size = 0.5),
                            axis.ticks = element_line(color = "#38ccd6", size = 0.5),
                            axis.text.x = element_text(size = 8),
                            axis.text.y = element_text(size = 8),
                            panel.background = element_rect(fill = "white", color = NA),
                            panel.grid.major = element_line(color = "#1c1c19", size = 0.5),
                            panel.grid.major.x = element_blank(),
                            panel.grid.minor.x = element_blank(), 
                            panel.grid.major.y = element_blank(),
                            panel.grid.minor.y = element_blank(),
                            panel.grid.minor = element_line(color = "#1c1c19", size = 5),
                            plot.background = element_rect(color = "black"),
                            plot.title = element_text(color = "#38ccd6", size = 20,
                                                      face = "bold",hjust = 0.5),
                            plot.caption = element_text(size = 10,hjust=0.5),
                            plot.margin = unit(c(1.2,1.2,1.2,1.2), "cm")
                            )
                          
                          title <- paste("Fitted values linreg(", formula[2]," ", formula[1], " ",
                                         formula[3], ")")
                              
                          #plotting yf and e
                          data_frame1 <- data.frame(Fitted_values=yf,Residuals=e)
                          p1 <- ggplot(data_frame1,aes(Fitted_values,Residuals))+
                            geom_point(shape = 21, colour = "black", fill = "white", size = 2.8,
                                       stroke = 1.3)+
                            geom_smooth(method = "loess",color = "red", se = FALSE)+
                            ggtitle("Residuals vs Fitted")+
                            xlab(title)+
                            ylab("Residuals")+
                            xlim(1,6)+
                            ylim(-1.5,1.5)+
                            LiU_theme
                                                       
                          
                          data_frame2 <- data.frame(Fitted_values=yf,Residuals=stand_res)
                          p2 <- ggplot(data_frame2,aes(Fitted_values,Residuals))+
                            geom_point(shape = 21, colour = "black", fill = "white", size = 2.8,
                                       stroke = 1.3)+
                            geom_smooth(method = "loess",color = "red", se = FALSE)+
                            ggtitle("Scale-Location")+
                            xlab(title)+
                            ylab(expression(bold(sqrt("Standardized Residuals"))))+
                            xlim(1,6)+
                            ylim(0.0,1.5)+
                            LiU_theme
                                                       
                          return(list(p1,p2))
                        },
                        
                        #vector of residuals e
                        resid = function(){
                          cat("Returning vector of residuals e:", "\n")
                          return(as.vector(round(e,2)))
                        },
                        
                        #predicted values y_hat
                        pred = function(){
                          cat("Returning predicted values yf:", "\n")
                          return(as.vector(round(yf,2)))
                        },
                        
                        #coefficients as a named vector
                        coef = function(){
                          cat("Returning coefficients as a vector:", "\n")
                          return(as.vector(round(regco,2)))
                        },
                        
                        #summary()
                        summary = function(){
                          
                          cat("linreg(formula = ", format(formula), ", data = ", parse, ") :\n\n ", sep = "")
                          x <- setNames(as.data.frame(cbind(regco,as.matrix(sqrt(diag(Var_Beta))),t_Beta, formatC(pvalue, format = "e", digits = 2), p_cal(pvalue))), c("Coefficients","Standard error","t-values", "p-values", ""))
                          print_custom(x)
                          cat("\n\n Residual standard error: ", sqrt(Sigma_square), " on ", dfreedom, " degrees of freedom ", sep = "")
                        }
  
                      ))
print_custom <- function(x){
  print(x)
}

p_cal = function(p_val) {
  x <- ifelse(p_val > 0.1, " ",
              (ifelse(p_val > 0.05, " . ",
                      (ifelse(p_val > 0.01, "*",
                              (ifelse(p_val > 0.001, "**","***")))))))
  return(x)
}

## ----echo=FALSE----------------------------------------------------------
data(iris)
head(iris,10)

## ----echo=FALSE----------------------------------------------------------
mod_object <- linreg(formula=Petal.Length~Species, data = iris)
mod_object$print()

## ----fig.height=5, fig.width=5, message=FALSE, warning=FALSE, paged.print=TRUE, r,echo=FALSE----
mod_object$plot()

## ----echo=FALSE----------------------------------------------------------
mod_object$resid()

## ----echo=FALSE----------------------------------------------------------
mod_object$pred()

## ----echo=FALSE----------------------------------------------------------
mod_object$coef()

## ----echo=FALSE----------------------------------------------------------
mod_object$summary()

## ----ref.label=knitr::all_labels(), echo = T, eval = F-------------------
#  knitr::opts_chunk$set(
#    collapse = TRUE,
#    comment = "#>"
#  )
#  linreg <- setRefClass(Class = "linreg",
#  
#  
#                        fields = list(formula="formula", data="data.frame", regco="matrix",
#                                      yf="matrix", e="matrix", dfreedom="numeric",
#                                      Sigma_square="numeric", Var_Beta="matrix", t_Beta="matrix",
#                                      pvalue="matrix",parse="character", stand_res="matrix",
#                                      variance="numeric"),
#  
#                        methods = list(
#  
#                          initialize =function (formula,data)
#                          {
#                            c<-colnames(data)
#                            d<-all.vars(formula)
#                            stopifnot(d %in% c)
#                            stopifnot (is.data.frame(data))
#                            formula <<- formula
#                            data <<- data
#                            X <- model.matrix(formula,data)
#                            dep_y <- all.vars(formula)[1]
#                            y <- (data[,dep_y])
#                            parse <<- deparse(substitute(data))
#                            #Regressions coefficients
#                            regco <<- solve((t(X)%*%X))%*%t(X)%*%y
#                            #X <- QR
#                            #Beta <- solve(R)%*%t(Q)%*%y
#                            #Fitted values
#                            yf <<- X%*%regco
#                            #Residuals
#                            e <<- y-yf
#                            #Degrees of freedom
#                            dfreedom <<- nrow(X)-ncol(X)
#                            #Residual variance
#                            Sigma_square <<- as.numeric((t(e)%*%e) / dfreedom)
#                            #Variance of regression coefficients
#                            Var_Beta <<- Sigma_square * solve((t(X)%*%X))
#                            #t-values for each coefficient
#                            t_Beta <<- regco / sqrt(diag(Var_Beta))
#                            #p values for reg coefficients
#                            pvalue <<- pt(abs(t_Beta),dfreedom)
#                            #variance value
#                            variance <<- round(sqrt(Sigma_square),2)
#                            #standardised residual for plot2
#                            stand_res <<- sqrt(abs((e-mean(e)) / sqrt(Sigma_square)))
#  
#                          },
#  
#                          #print coefficients and coefficient names
#                          print = function(){
#                            cat("\n","Call:","\n",
#                            paste0("linreg(formula = ", format(formula), ", data = ", parse , ")\n\n ", sep = ""))
#                            cat("\n","Coefficients:","\n")
#                            (setNames(round(regco[1:nrow(regco)],2),rownames(regco)))
#  
#                            },
#  
#                          #plot()
#                          plot = function(){
#                            library(ggplot2)
#                            library(ggThemeAssist)
#                            # Liu theme
#                            LiU_theme <-  theme(
#                              axis.title.x = element_text(color = "#38ccd6", size = 14,
#                                                          face = "bold"),
#                              axis.title.y = element_text(color = "#38ccd6", size = 14,
#                                                          face = "bold"),
#                              axis.text = element_text(color = "#1c1c19", size = 6),
#                              axis.line = element_line(color = "#1c1c19", size = 0.5),
#                              axis.ticks = element_line(color = "#38ccd6", size = 0.5),
#                              axis.text.x = element_text(size = 8),
#                              axis.text.y = element_text(size = 8),
#                              panel.background = element_rect(fill = "white", color = NA),
#                              panel.grid.major = element_line(color = "#1c1c19", size = 0.5),
#                              panel.grid.major.x = element_blank(),
#                              panel.grid.minor.x = element_blank(),
#                              panel.grid.major.y = element_blank(),
#                              panel.grid.minor.y = element_blank(),
#                              panel.grid.minor = element_line(color = "#1c1c19", size = 5),
#                              plot.background = element_rect(color = "black"),
#                              plot.title = element_text(color = "#38ccd6", size = 20,
#                                                        face = "bold",hjust = 0.5),
#                              plot.caption = element_text(size = 10,hjust=0.5),
#                              plot.margin = unit(c(1.2,1.2,1.2,1.2), "cm")
#                              )
#  
#                            title <- paste("Fitted values linreg(", formula[2]," ", formula[1], " ",
#                                           formula[3], ")")
#  
#                            #plotting yf and e
#                            data_frame1 <- data.frame(Fitted_values=yf,Residuals=e)
#                            p1 <- ggplot(data_frame1,aes(Fitted_values,Residuals))+
#                              geom_point(shape = 21, colour = "black", fill = "white", size = 2.8,
#                                         stroke = 1.3)+
#                              geom_smooth(method = "loess",color = "red", se = FALSE)+
#                              ggtitle("Residuals vs Fitted")+
#                              xlab(title)+
#                              ylab("Residuals")+
#                              xlim(1,6)+
#                              ylim(-1.5,1.5)+
#                              LiU_theme
#  
#  
#                            data_frame2 <- data.frame(Fitted_values=yf,Residuals=stand_res)
#                            p2 <- ggplot(data_frame2,aes(Fitted_values,Residuals))+
#                              geom_point(shape = 21, colour = "black", fill = "white", size = 2.8,
#                                         stroke = 1.3)+
#                              geom_smooth(method = "loess",color = "red", se = FALSE)+
#                              ggtitle("Scale-Location")+
#                              xlab(title)+
#                              ylab(expression(bold(sqrt("Standardized Residuals"))))+
#                              xlim(1,6)+
#                              ylim(0.0,1.5)+
#                              LiU_theme
#  
#                            return(list(p1,p2))
#                          },
#  
#                          #vector of residuals e
#                          resid = function(){
#                            cat("Returning vector of residuals e:", "\n")
#                            return(as.vector(round(e,2)))
#                          },
#  
#                          #predicted values y_hat
#                          pred = function(){
#                            cat("Returning predicted values yf:", "\n")
#                            return(as.vector(round(yf,2)))
#                          },
#  
#                          #coefficients as a named vector
#                          coef = function(){
#                            cat("Returning coefficients as a vector:", "\n")
#                            return(as.vector(round(regco,2)))
#                          },
#  
#                          #summary()
#                          summary = function(){
#  
#                            cat("linreg(formula = ", format(formula), ", data = ", parse, ") :\n\n ", sep = "")
#                            x <- setNames(as.data.frame(cbind(regco,as.matrix(sqrt(diag(Var_Beta))),t_Beta, formatC(pvalue, format = "e", digits = 2), p_cal(pvalue))), c("Coefficients","Standard error","t-values", "p-values", ""))
#                            print_custom(x)
#                            cat("\n\n Residual standard error: ", sqrt(Sigma_square), " on ", dfreedom, " degrees of freedom ", sep = "")
#                          }
#  
#                        ))
#  print_custom <- function(x){
#    print(x)
#  }
#  
#  p_cal = function(p_val) {
#    x <- ifelse(p_val > 0.1, " ",
#                (ifelse(p_val > 0.05, " . ",
#                        (ifelse(p_val > 0.01, "*",
#                                (ifelse(p_val > 0.001, "**","***")))))))
#    return(x)
#  }
#  data(iris)
#  head(iris,10)
#  mod_object <- linreg(formula=Petal.Length~Species, data = iris)
#  mod_object$print()
#  mod_object$plot()
#  mod_object$resid()
#  mod_object$pred()
#  mod_object$coef()
#  mod_object$summary()
#  

