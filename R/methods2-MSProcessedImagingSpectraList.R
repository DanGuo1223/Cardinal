#### Methods for MSProcessedImagingSpectraList ####
## ------------------------------------------------

MSProcessedImagingSpectraList <- function(data) {
	if ( !is(data, "SimpleList") ) {
		if ( is.list(data) || !is.null(dim(data)) ) {
			data <- SimpleList(data)
		} else {
			stop("'data' must be a SimpleList, list or matrix")
		}
	}
	if ( is.null(names(data)) ) {
		inames <- .format.numbered("intensity", length(data))
		names(data) <- inames
	}
	object <- as(data, "MSProcessedImagingSpectraList", strict=FALSE)
	if ( validObject(object) )
		object
}

.valid.MSProcessedImagingSpectraList <- function(object) {
	errors <- NULL
	data <- as(object, "SimpleList", strict=FALSE)
	classes <- sapply(data, function(x) class(x))
	if ( length(data) > 0 && !all(classes %in% "sparse_matc") )
		errors <- c(errors , "elements must be of class 'sparse_matc'")
	if ( is.null(errors) ) TRUE else errors
}

setValidity("MSProcessedImagingSpectraList",
	.valid.MSProcessedImagingSpectraList)

setMethod("[", "MSProcessedImagingSpectraList",
	function(x, i, j, ..., drop = NULL)
		.subsetSimpleImageArrayList(x, i, j, drop))