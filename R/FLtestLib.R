#' @include FLMatrix.R
NULL

#' @export
setGeneric("FLexpect_equal",
           function(object,expected,...)
               standardGeneric("FLexpect_equal"))
setMethod("FLexpect_equal",
          signature(object="FLMatrix",expected="ANY"),
          function(object,expected,...){
            if(is.RSparseMatrix(expected))
            expected <- matrix(expected,dim(expected))
            if(class(expected)=="dist")
            return(testthat::expect_equal(as.dist(as.matrix(object)),
                                     expected,...))

            testthat::expect_equal(as.matrix(object),
                                     expected,...)
          })
setMethod("FLexpect_equal",
          signature(object="FLMatrix",expected="FLMatrix"),
          function(object,expected,...)
              testthat::expect_equal(as.matrix(object),
                                     as.matrix(expected),...))
setMethod("FLexpect_equal",
          signature(object="ANY",expected="FLMatrix"),
          function(object,expected,...){
            if(is.RSparseMatrix(object))
            object <- matrix(object,dim(object))
            if(class(object)=="dist")
            return(testthat::expect_equal(object,
                        as.dist(as.matrix(expected))
                        ,...))
            testthat::expect_equal(object,
                                     as.matrix(expected),...)
          })
setMethod("FLexpect_equal",
          signature(object="FLSimpleVector",expected="ANY"),
          function(object,expected,...)
              testthat::expect_equal(as.vector(object),
                                     expected,...))
setMethod("FLexpect_equal",
          signature(object="FLVector",expected="ANY"),
          function(object,expected,...)
              testthat::expect_equal(as.vector(object),
                                     expected,...))
setMethod("FLexpect_equal",
          signature(object="FLSkalarAggregate",expected="ANY"),
          function(object,expected,...)
              testthat::expect_equal(as.vector(object),
                                     expected,...))
setMethod("FLexpect_equal",
          signature(object="FLVector",expected="FLVector"),
          function(object,expected,...)
              testthat::expect_equal(as.vector(object),
                                     as.vector(expected),...))
setMethod("FLexpect_equal",signature(object="list",expected="list"),
          function(object,expected,...)
              llply(names(object),
                    function(i)
                        FLexpect_equal(object[[i]],
                                       expected[[i]],...)))
setMethod("FLexpect_equal",
          signature(object="ANY",expected="FLSimpleVector"),
          function(object,expected,...){
            if(is.numeric(object) || is.integer(object) || is.vector(object)){
                return(FLexpect_equal(expected,object,...))
            }
            else FLexpect_equal(as.FLVector(object),
                                expected,...)
          })
setMethod("FLexpect_equal",
          signature(object="ANY",expected="FLVector"),
          function(object,expected,...){
            if(is.numeric(object) || is.integer(object) || is.vector(object)){
                # object <- as.vector(object)
                # return(testthat::expect_equal(object,as.R(expected),...))
                return(FLexpect_equal(expected,object,...))
            }
            else FLexpect_equal(as.FLVector(object),
                                expected,...)
          })
setMethod("FLexpect_equal",
          signature(object="ANY",expected="FLSkalarAggregate"),
          function(object,expected,...){
            if(is.numeric(object) || is.integer(object) || is.vector(object)){
                # object <- as.vector(object)
                # return(testthat::expect_equal(object,as.R(expected),...))
                return(FLexpect_equal(expected,object,...))
            }
            else FLexpect_equal(as.FLVector(object),
                                expected,...)
          })

setMethod("FLexpect_equal",
          signature(object="ANY",expected="ANY"),
          function(object,expected,...){
            if(is.FL(object))
            object <- as.R(object)
            if(is.FL(expected))
            expected <- as.R(expected)
            testthat::expect_equal(object,
                                     expected,...)
          })

setMethod("FLexpect_equal",signature(object="FLTable",expected="ANY"),
          function(object,expected,...)
              testthat::expect_equal(as.data.frame(object),
                                     as.data.frame(expected),...))


##' Evaluates the expression e in an R and an FL environment, tests assignment for equality.
##' 
##' Tests all variables in expectation and new variable names for equality in R and FL environments.
##' Created objects will be in both environments.
##' The results of both expressions will be returned together with benchmarking statistics.
##' 
##' TDOD: collect more information: length of sql sent, amount of data fetched
##'
##'
##' @param e the expression that will be evaluated in both environments
##' @param Renv 
##' @param FLenv 
##' @param description if not supplied will default to deparse of the expression
##' @param runs if runs>1 the expressions are evaluated several times.  Make sure you do not re-assign the variables in environments that are evaluated on.
##' @param expectation provide variable names to check for equality when environments did already contain these variables.
##' @param noexpectation You can exclude names from
##' @param ... arguments passed to FLexpect_equal, e.g.  check.attributes = FALSE
##' @return a data frame with the description
##' @author  Gregor Kappler <gregor.kappler@@fuzzylogix.com>
#' @export
eval_expect_equal <- function(e, Renv, FLenv,
                              description=NULL,
                              runs=1,
                              expectation=c(),
                              noexpectation=c(),
                              verbose=FALSE,
                              ...){
    if(runs>=1)
        e <- substitute(e)
    if(runs>1)
        return(ldply(1:runs,
                     function(i) eval_expect_equal(e,
                                                   Renv, FLenv,
                                                   description=description,
                                                   runs=-1,...)))
    if(is.null(description)) description <- paste(deparse(e),collapse="\n")
    oldNames <- ls(envir = Renv)
    rStartT <- Sys.time()
    re <- tryCatch({
        eval(expr = e, envir=Renv)
        NULL
    }, error=function(err) {
        print(err)
        err
    })
    rEndT <- Sys.time()
    flStartT <- Sys.time()
    fle <- tryCatch({
        eval(expr = e, envir=FLenv)
        NULL
    }, error=function(err) {
        print(err)
        err
    })
    flEndT <- Sys.time()
    if(is.null(re))
        expect_null(fle,label=fle)
    ##expect_equal(e,fle)
    newNames <- ls(envir = Renv)
    vToCheckNames <- setdiff(newNames,oldNames)
    if(length(noexpectation)>0)
    vToCheckNames <- setdiff(vToCheckNames,noexpectation)
    if(length(expectation)>0)
    vToCheckNames <- c(expectation,vToCheckNames)

    for(n in unique(vToCheckNames)){
        rObject <- get(n,envir = Renv)
        flObject <- get(n,envir = FLenv)
        if(verbose) {
            cat(paste0("---------\n Testing for equality: ",n,"\n R:\n"))
            str(rObject)
            cat(paste0(" FL:\n"))
            str(flObject)
        }
        FLexpect_equal(rObject, flObject,label=n,...)
    }
    ## TODO: store statistics in database
    ## TODO: cbind values set in expression
    return(data.frame(description  = description,
                      r.Runtime    = rEndT-rStartT,
                      fl.Runtime   = flEndT-flStartT))
}




#' DEPRECATED: use eval_expect_equal
#' @export
expect_eval_equal <- function(initF,FLcomputationF,RcomputationF,...)
{
  I <- initF(...)
   FLexpect_equal(FLcomputationF(I$FL),
                 RcomputationF(I$R),
                 check.attributes=FALSE)
}

#' @export
expect_flequal <- function(a,b,...){
    if(is.list(a))
        for(i in 1:length(a))
            expect_flequal(a[[i]],b[[i]],...)

    FLexpect_equal(a,b,...)
}


## gk: refactor such that initF code is used for one-time creation of huge testing tables (on demand)
## gk: and that all actual testing is done by creating references to that permanent table
## type should be in c("float","int","character")
#' @export
initF.FLVector <- function(n,isRowVec=FALSE,type = "float",...)
{
    
  if(n>1000000)
  stop("maximum n allowed is 1000000 \n ")
  else if(!isRowVec){
    if(type=="float")
    {
      select <- new("FLSelectFrom",
                    connectionName = getFLConnectionName(), 
                    ##database = getOption("ResultDatabaseFL"), 
                    table_name = paste0(getOption("TestDatabase"),".fzzlserial"),
                    variables = list(obs_id_colname="SERIALVAL"),
                    whereconditions=paste0(getRemoteTableName(tableName = paste0(getOption("TestDatabase"),".fzzlserial"),
                                                              temporaryTable=FALSE),".SERIALVAL < ",n+1),
                    order = "")
      flv <- newFLVector(
                select=select,
                Dimnames=list(1:n,"RANDVAL"),
                isDeep=FALSE)
    }
    # else if(is.null(getOption("FLTestVectorTable")) ||
    #         !getOption("FLTestVectorTable"))
    else
    {
      # if(!checkRemoteTableExistence(tableName="ARTestIntVectorTable"))
      if(type=="int"){
        vtableName <- "ARTestIntVectorTable"
        vtemp <- createTable(pTableName="ARTestIntVectorTable",
                            pSelect=paste0(" SELECT a.serialval AS vectorIndexColumn, \n ",
                                " CAST(FLSimUniform(a.serialval,-100,100) AS INT) AS vectorValueColumn \n ",
                                " FROM fzzlserial a "),
                            pTemporary=FALSE)
      }
      else{
        vtemp <- createTable(pTableName="ARTestCharVectorTable",
                          pSelect=paste0(" SELECT a.serialval AS vectorIndexColumn, \n ",
                                        " b.string1 AS vectorValueColumn \n ",
                                        " FROM fzzlserial a, \n ",
                                            "(SELECT ROW_NUMBER()OVER(ORDER BY string1) AS obsid, \n ",
                                              "string1 \n ",
                                            " FROM tblstring ) AS b \n ",
                                        " WHERE FLMOD(a.serialval,5) + 1 = b.obsid "),
                          pTemporary=FALSE)
        vtableName <- "ARTestCharVectorTable"
      }
      # options(FLTestVectorTable=TRUE)
      select <- new("FLSelectFrom",
                    connectionName = getFLConnectionName(), 
                    table_name = vtableName,
                    variables = list(obs_id_colname="vectorIndexColumn"),
                    whereconditions=paste0(vtableName,".vectorIndexColumn < ",n+1),
                    order = "")
      flv <- newFLVector(
                  select=select,
                  Dimnames=list(1:n,"vectorValueColumn"),
                  isDeep=FALSE)
    }
  }
  else{
    if(type == "character"){
      widetable<-FLTable(getRemoteTableName(tableName = "tblAutoMpg",temporaryTable = FALSE),"ObsID")
      flv <- widetable[1,rep("CarName",n)]
    }
    else{
      vmaxId <- getMaxVectorId()
      sqlSendUpdate(getFLConnection(),
                          c(paste0("INSERT INTO ",getOption("ResultVectorTableFL")," \n ",
                              " SELECT ",vmaxId," AS vectorIdColumn, \n ",
                                        " a.serialval AS vectorIndexColumn, \n ",
                                        #CAST(RANDOM(0,100) AS FLOAT)AS VECTOR_VALUE  
                                        "a.RANDVAL +1 AS vectorValueColumn \n ",
                              " FROM ", getRemoteTableName(tableName = "fzzlserial", temporaryTable=FALSE)," a \n ",
                              " WHERE a.serialval <=  ",n)))

      table <- FLTable(getOption("ResultVectorTableFL"),
                       "vectorIndexColumn",
                       whereconditions=paste0(getOption("ResultVectorTableFL"),
                                            ".vectorIdColumn = ",vmaxId)
                     )
      flv <- table[,"vectorValueColumn"]
    }
  }
  Rvector <- as.vector(flv)
  if(type=="int")
  Rvector <- as.integer(Rvector)
  return(list(FL=flv,R=Rvector))
}

## Increase the value of n to increase the dimensions of FLMatrix returned.
## Returns n*n or n*(n-1) based on isSquare.
## type should be in c("float","int","character")
#' @export
initF.FLMatrix <- function(n,isSquare=FALSE,type="float",...)
{
  if(any(n>1000))
  stop("maximum rows,cols allowed is 1000 \n ")

  ## here manually set option as true if tables exist.
  vFromTable <- paste0(getOption("TestDatabase"),".fzzlserial")
  valExpression <- " FLSimUniform(a.serialval*100+b.serialval,0,1)*1000 "
  if(is.Hadoop())
  valExpression <- paste0(" CASE WHEN ",getMODSQL(pColumn1="(a.serialval+b.serialval)",pColumn2=2),
                              " = 0 THEN (a.randval+b.randval+b.randval)*100 ",
                              " ELSE (a.randval-b.randval-b.randval)*100 END ")
  if(type=="int")
  {
      vtableName <- "ARTestIntMatrixTable"
      valExpression <- paste0(" CAST( ",valExpression," AS INT)")
  }
  else if(type=="character"){
      vtableName <- "ARTestCharMatrixTable"
      valExpression <- paste0(" CAST( ",valExpression," AS VARCHAR)")
  }
  else if(type=="float"){
      vtableName <- "ARTestMatrixTable"
  }
  else stop("type should be int,float,character")
  if(!checkRemoteTableExistence(tableName=vtableName))
      vtemp <- createTable(pTableName=vtableName,
                           pSelect=paste0(" SELECT a.serialval AS rowIdColumn, \n ",
                                          " b.serialval AS colIdColumn, \n ",
                                          valExpression, " AS valueColumn \n ",
                                          " FROM ",vFromTable," a,",
                                                   vFromTable," b \n ",
                                          " WHERE a.serialval < 1001 \n ",
                                          " AND b.serialval < 1001 "),
                           pTemporary=FALSE,
                           pDrop=TRUE
                           )
  else
      vtemp <- vtableName
  select <- new("FLSelectFrom",
                connectionName = getFLConnectionName(),
                table_name = c(mtrx=vtableName),
                variables=list(MATRIX_ID="'%insertIDhere%'",
                               rowIdColumn=paste0("mtrx.rowIdColumn"),
                               colIdColumn=paste0("mtrx.colIdColumn"),
                               valueColumn=paste0("mtrx.valueColumn")),
                whereconditions=c(paste0("mtrx.rowIdColumn < ",n+1),
                                  paste0("mtrx.colIdColumn < ",ifelse(isSquare,n+1,n))),
                order = "")
  
  flm <- newFLMatrix(
            select = select,
            dims = as.integer(c(n,ifelse(isSquare,n,n-1))),
            Dimnames = list(NULL,NULL))

  return(list(FL=flm,R=as.matrix(flm)))
}

#' @export
initF.FLTable <- function(rows,cols,...)
{
  WideTable <- FLTable(c(flt=getRemoteTableName(tableName = paste0(getOption("TestDatabase"),
                                                                    ".fzzlserial"),
                                                temporaryTable=FALSE)),
                       "SERIALVAL",
                       whereconditions=paste0("SERIALVAL < ",rows+1))
  return(WideTable[1:rows,base::sample(c("RANDVAL","SERIALVAL"),cols,replace=TRUE)])
}


initF.numeric <- initF.FLVector
initF.data.frame <- initF.FLTable
initF.matrix <- initF.FLMatrix

##' initF.default helps to return a list of list.
##' Can be used for comparing results of R and FL functions which require two objects.



initFgeneric<- function(specs=list(numberattribute =5,featureattribute = TRUE,...),
                        class = "FLMatrix"){
  #browser()
  if(class%in%c("FLVector","FLMatrix","FLTable")){
    obj<-do.call(paste0("initF.",class),specs)
  }
  else{
    obj<-do.call(paste0("initF.",class),specs)
    if(class == "numeric")
    obj<-do.call("as.vector",list(obj))
    else
    obj<-do.call(paste0("as.",class),list(obj))
  }
  return(obj) 
}


## gk: think of a better name FL_test_operators
## gk: document
FL_test_generic<-function(specs=list(list(n=5,isSquare = TRUE,...),
                                     list(n =5,isRowVec = FALSE,...)),
                          classes = c("FLMatrix","FLVector"),
                          operator = "+"){
    
  FLenv<-new.env()
  ##browser()
  lapply(1:length(classes),function(i){
    obj<-initFgeneric(specs[[i]],classes[i])
    x=i
    assign(paste0("a",x),obj,envir = FLenv)
  })
  Renv<-as.R(FLenv)
  obj1<-do.call(operator,lapply(ls(FLenv),function(x)do.call("$",list(FLenv,paste0(x)))))
  obj2<-do.call(operator,lapply(ls(Renv),function(x)do.call("$",list(Renv,paste0(x)))))
  
  FLexpect_equal(obj1,obj2,check.attributes =FALSE)
}

##' initF.default helps to return a list of list.
##' Can be used for comparing results of R and FL functions which require two objects.

initFdefault<- function(specs=list(c(n=5,isSquare = TRUE),c(n =5,isRowVec = FALSE)),
        classes = c("FLMatrix","FLVector")){
        #browser()
        l<-lapply(1:length(classes),function(x){
            #browser()
            I <- do.call(paste0("initF.",classes[x]),list(specs[[x]]))
            return(I)
            })
        FL <- lapply(1:length(l),function(x){
                    #browser()
                    if(classes[x] %in% c("FLMatrix","FLVector","FLTable"))
                    subscript <- "FL"
                    else subscript <- "R"
                    return(do.call("$",list(l[[x]],subscript)))
            })
        R <- lapply(1:length(l),function(x)l[[x]]$"R")
    return(list(FL=FL,R=R)) 
}

##' tests if a R matrix is correctly stored and
##' represented when casting the R matrix into FLMatrix
##' and correctly recieved back, when cast to a vector.
##' checking dimnames, checking for subsetting.
##' For an optical check, both matrices are printed.
##' 
##' @param a an R Matrix
##' @author  Gregor Kappler <g.kappler@@gmx.net>
##' @export
expect_equal_RMatrix_FLMatrix <- function(a){
    # browser()
    debugOld <- getOption("debugSQL")
    options(debugSQL=FALSE)
    b <- as.FLMatrix(a)
    a <- Matrix(a)
    options(debugSQL=debugOld)
    expect_equal_Matrix(a,b,
                        "cast Matrix equal")

    test_Matrix_Subsetting(a,b,"as.FLMatrix")
}

##' converts FLMatrix to r matrix and checks if
##' recursive identical subsetting results in identical
##' matrices.
##'
##' @param b FLMatrix
##' @author  Gregor Kappler <g.kappler@@gmx.net>
##' @export
test_equal_FLMatrix_RMatrix<- function(b){
    # browser()
    debugOld <- getOption("debugSQL")
    options(debugSQL=FALSE)
    a <- as.matrix(b)
    options(debugSQL=debugOld)
    expect_equal_Matrix(a,b,
                        "cast Matrix equal")

    test_Matrix_Subsetting(a,b,"as.FLMatrix")
}


##' tests matrix subsetting by names and by index recursively.
##' 
##' @param a 
##' @param b 
##' @param desc 
##' @author  Gregor Kappler <g.kappler@@gmx.net>
##' @export
test_Matrix_Subsetting <- function(a,b, desc=""){
    if(nrow(a)<3) return()
    nr <- nrow(a) -2 ##%/% 2
    nc <- ncol(a) -2 ## %/% 2
    rowi <- sample(1:nrow(a),nr)
    coli <- sample(1:ncol(a),nc)
    asel <- a[rowi,coli,drop=FALSE]
    bsel <- b[rowi,coli,drop=FALSE]
    expect_equal_Matrix(asel,bsel,
                        paste0(
                            "subset by index of ",
                            desc))
    ## recursively test!
    test_Matrix_Subsetting(asel,bsel,
                        paste0(
                            "indexed subset of ",
                            desc))
    
    if(!is.null(rownames(a)))
        rowi <- sample(rownames(a),nr)
    if(!is.null(colnames(a)))
        coli <- sample(colnames(a),nc)
    asel <- a[rowi,coli,drop=FALSE]
    bsel <- b[rowi,coli,drop=FALSE]
    expect_equal_Matrix(asel,bsel,
                        paste0(
                            "subset by names of ",
                            desc))
    ## recursively test!
    test_Matrix_Subsetting(asel,bsel,
                        paste0(
                            "named subset of ",
                            desc))
}

##' @export
expect_equal_Matrix <- function(a,b,desc="",verbose=FALSE){
    if(verbose==TRUE){
        cat("\n-------------- ",desc,"\nR Matrix Object:\n")
        print(a)
        cat("\nFL Matrix Object:\n")
        print(b)
    }
    stripNames <- function(x) {
        if(is.null(x)) return(NULL)
        if(is.numeric(x) & all(x==as.numeric(names(x))))
            x <- NULL
        else 
            names(x) <- NULL
        if(is.list(x)) x <- llply(x,stripNames)
        ##if(is.null(unlist(x))) x <- NULL
        x
    }
    test_that(desc,{
        testthat::expect_equal(dimnames(a),stripNames(dimnames(b)))
        testthat::expect_equal(rownames(a),stripNames(rownames(b)))
        testthat::expect_equal(colnames(a),stripNames(colnames(b)))
        testthat::expect_equal(as.vector(a),as.vector(b))
    })
}

expect_equal_RVector_FLVector <- function(a){
    # browser()
    debugOld <- getOption("debugSQL")
    options(debugSQL=FALSE)
    b <- as.FLVector(a)
    options(debugSQL=debugOld)
    expect_equal_Vector(a,b,
                        "cast Vector equal")

    test_Vector_Subsetting(a,b,"as.FLVector")
    if(!is.null(names(a)))
    test_Vector_Subsetting(a,b,"as.FLVector",index=FALSE)
}

#' @export
expect_equal_FLSimpleVector_RVector <- function(a){
    # browser()
    debugOld <- getOption("debugSQL")
    options(debugSQL=FALSE)
    b <- as.vector(a)
    options(debugSQL=debugOld)
    expect_equal_Vector(b,a,
                        "cast Vector equal")

    test_Vector_Subsetting(b,a,"as.FLVector")
    if(!is.null(names(a)))
    test_Vector_Subsetting(b,a,"as.FLVector",index=FALSE)
}
##' tests vector subsetting by names and by index recursively.
##' 
##' @param a 
##' @param b 
##' @param desc 
##' @author  Gregor Kappler <g.kappler@@gmx.net>
##' @export
test_Vector_Subsetting <- function(a,b, desc="",index=TRUE){
    if(length(a)<3) return()
    len <- length(a)-2
    if(index){
      leni <- sample(1:length(a),len)
      ## cat("index is ... ",leni,"\n")
      asel <- a[leni]
      bsel <- b[leni]
      expect_equal_Vector(asel,bsel,
                          paste0(
                              "subset by index of ",
                              desc))
      ## recursively test!
      test_Vector_Subsetting(asel,bsel,
                            paste0(
                              "indexed subset of ",
                              desc),index=index)
    }
    else{
      leni <- sample(names(a),len)
      ## cat("index is ... ",leni,"\n")
      asel <- a[leni]
      bsel <- b[leni]
      expect_equal_Vector(asel,bsel,
                          paste0(
                              "subset by names of ",
                              desc))
      ## recursively test!
      test_Vector_Subsetting(asel,bsel,
                          paste0(
                              "named subset of ",
                              desc),index=index)
    }
}

##' @export
expect_equal_Vector <- function(a,b,desc="",debug=FALSE){
    if(debug==TRUE){
        cat("\n-------------- ",desc,"\nR vector Object:\n")
        print(a)
        cat("\nFLVector Object:\n")
        print(b)
    }
    # stripNames <- function(x) {
    #     if(is.null(x)) return(NULL)
    #     if(is.numeric(x) & all(x==as.numeric(names(x))))
    #         x <- NULL
    #     else 
    #         names(x) <- NULL
    #     if(is.list(x)) x <- llply(x,stripNames)
    #     ##if(is.null(unlist(x))) x <- NULL
    #     x
    # }
    test_that(desc,{
        if(!is.null(names(a)))
            testthat::expect_equal(names(a),as.character(as.vector(names(b))))
        testthat::expect_equal(a,as.vector(b))
    })
}
initF.numeric <- initF.FLVector
initF.data.frame <- initF.FLTable
initF.matrix <- initF.FLMatrix

#' @export
dropFLTestTable <- function(){
    dropTable(pTableName="ARBaseTestTempTable")
}
