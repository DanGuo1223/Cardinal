#### Methods for MSImagingInfo ####
## ----------------------------------

.valid.MSImagingInfo <- function(object) {
	errors <- NULL
	nrows <- nrow(object@scanList)
	if ( nrow(object@mzArrayList) != nrows )
		errors <- c(errors , paste("number of rows of 'scanList'",
			"and 'mzArrayList' must be equal"))
	if ( nrow(object@intensityArrayList) != nrows )
		errors <- c(errors , paste("number of rows of 'scanList'",
			"and 'intensityArrayList' must be equal"))
	if ( is.null(errors) ) TRUE else errors
}

setValidity("MSImagingInfo", .valid.MSImagingInfo)

# create MSImagingInfo

setMethod("msiInfo", "MSImageSet",
	function(object, mz.type = "32-bit float", intensity.type = "32-bit float")
	{
		info <- .make.MSContinuousImagingInfo(object, mz.type, intensity.type)
		info@metadata[["ibd binary type"]] <- "continuous"
		if ( validObject(info) )
			info
	})

setMethod("msiInfo", "MSImagingExperiment",
	function(object, mz.type = "32-bit float", intensity.type = "32-bit float")
	{
		info <- .make.MSContinuousImagingInfo(object, mz.type, intensity.type)
		info@metadata[["ibd binary type"]] <- "continuous"
		info@metadata <- append(info@metadata, metadata(object))
		info@metadata <- info@metadata[unique(names(info@metadata))]
		if ( validObject(info) )
			info
	})

setMethod("msiInfo", "MSContinuousImagingExperiment",
	function(object, mz.type = "32-bit float", intensity.type = "32-bit float")
	{
		info <- .make.MSContinuousImagingInfo(object, mz.type, intensity.type)
		info@metadata[["ibd binary type"]] <- "continuous"
		info@metadata <- append(info@metadata, metadata(object))
		info@metadata <- info@metadata[unique(names(info@metadata))]
		if ( validObject(info) )
			info
	})

setMethod("msiInfo", "MSProcessedImagingExperiment",
	function(object, mz.type = "32-bit float", intensity.type = "32-bit float")
	{
		info <- .make.MSProcessedImagingInfo(object, mz.type, intensity.type)
		info@metadata[["ibd binary type"]] <- "processed"
		info@metadata <- append(info@metadata, metadata(object))
		info@metadata <- info@metadata[unique(names(info@metadata))]
		if ( validObject(info) )
			info
	})

.make.MSContinuousImagingInfo <- function(x, mz.type, intensity.type) {
	mz.type <- match.arg(mz.type,
		choices=c("32-bit float", "64-bit float"))
	intensity.type <- match.arg(intensity.type,
		choices=c("32-bit float", "64-bit float",
			"16-bit integer", "32-bit integer", "64-bit integer"))
	scanList <- DataFrame(coord(x)[c(1,2)])
	positionNames <- c("position x", "position y", "position z")
	names(scanList) <- positionNames[seq_along(scanList)]
	mzArrayList <- DataFrame(
		"external offset"=unname(rep(16, ncol(x))),
		"external array length"=unname(rep(nrow(x), ncol(x))),
		"external encoded length"=unname(rep(Csizeof(mz.type) * nrow(x), ncol(x))),
		"binary data type"=rep(mz.type, ncol(x)),
		check.names=FALSE)
	intensityArrayList <- DataFrame(
		"external offset"=unname(rep(16 + Csizeof(mz.type) * nrow(x), ncol(x))),
		"external array length"=unname(rep(nrow(x), ncol(x))),
		"external encoded length"=unname(rep(Csizeof(intensity.type) * nrow(x), ncol(x))),
		"binary data type"=rep(intensity.type, ncol(x)),
		check.names=FALSE)
	offset <- c(0, cumsum(intensityArrayList[["external encoded length"]][-ncol(x)]))
	intensityArrayList[["external offset"]] <- offset + intensityArrayList[["external offset"]]
	spectrumRepresentation <- ifelse(centroided(x),
		"centroid spectrum", "profile spectrum")
	experimentMetadata <- list("spectrum representation"=spectrumRepresentation)
	new("MSImagingInfo",
		scanList=scanList,
		mzArrayList=mzArrayList,
		intensityArrayList=intensityArrayList,
		metadata=experimentMetadata)
}

.make.MSProcessedImagingInfo <- function(x, mz.type, intensity.type) {
	mz.type <- match.arg(mz.type,
		choices=c("32-bit float", "64-bit float"))
	intensity.type <- match.arg(intensity.type,
		choices=c("32-bit float", "64-bit float",
			"16-bit integer", "32-bit integer", "64-bit integer"))
	scanList <- DataFrame(coord(x)[c(1,2)])
	positionNames <- c("position x", "position y", "position z")
	names(scanList) <- positionNames[seq_along(scanList)]
	if ( any(lengths(mzData(x)) != lengths(peakData(x))) )
		.stop("lengths of intensity and m/z arrays differ")
	mzLength <- Csizeof(mz.type) * lengths(mzData(x))
	intensityLength <- Csizeof(intensity.type) * lengths(peakData(x))
	mzOffset <- c(16, 16 + cumsum(mzLength + intensityLength)[-ncol(x)])
	intensityOffset <- c(16 + cumsum(c(mzLength[1L], mzLength[-1L] + intensityLength[-ncol(x)])))
	mzArrayList <- DataFrame(
		"external offset"=unname(mzOffset),
		"external array length"=unname(lengths(mzData(x))),
		"external encoded length"=unname(mzLength),
		"binary data type"=rep(mz.type, ncol(x)),
		check.names=FALSE)
	intensityArrayList <- DataFrame(
		"external offset"=unname(intensityOffset),
		"external array length"=unname(lengths(peakData(x))),
		"external encoded length"=unname(intensityLength),
		"binary data type"=rep(intensity.type, ncol(x)),
		check.names=FALSE)
	spectrumRepresentation <- ifelse(centroided(x),
		"centroid spectrum", "profile spectrum")
	experimentMetadata <- list("spectrum representation"=spectrumRepresentation)
	new("MSImagingInfo",
		scanList=scanList,
		mzArrayList=mzArrayList,
		intensityArrayList=intensityArrayList,
		metadata=experimentMetadata)
}

setMethod("length", "MSImagingInfo", function(x) nrow(x@scanList))

setMethod("as.list", "MSImagingInfo",
	function(x, ...)
	{
		list(scanList=as.list(x@scanList),
			mzArrayList=as.list(x@mzArrayList),
			intensityArrayList=as.list(x@intensityArrayList),
			experimentMetadata=x@metadata)
	})

# scans list

setMethod("scans", "MSImagingInfo",
	function(object) object@scanList)

# m/z array list

setMethod("mzData", "MSImagingInfo",
	function(object) object@mzArrayList)

# intensity array list

setMethod("peakData", "MSImagingInfo",
	function(object) object@intensityArrayList)

setMethod("imageData", "MSImagingInfo",
	function(y) y@intensityArrayList)

# processing metadata

setMethod("normalization", "Vector",
	function(object) object@metadata[["intensity normalization"]])

setReplaceMethod("normalization", "Vector",
	function(object, value) {
		object@metadata[["intensity normalization"]] <- value
		object
	})

setMethod("smoothing", "Vector",
	function(object) object@metadata[["smoothing"]])

setReplaceMethod("smoothing", "Vector",
	function(object, value) {
		object@metadata[["smoothing"]] <- value
		object
	})

setMethod("baselineReduction", "Vector",
	function(object) object@metadata[["baseline reduction"]])

setReplaceMethod("baselineReduction", "Vector",
	function(object, value) {
		object@metadata[["baseline reduction"]] <- value
		object
	})

setMethod("peakPicking", "Vector",
	function(object) object@metadata[["peak picking"]])

setReplaceMethod("peakPicking", "Vector",
	function(object, value) {
		object@metadata[["peak picking"]] <- value
		object
	})

setMethod("spectrumRepresentation", "Vector",
	function(object) object@metadata[["spectrum representation"]])

setReplaceMethod("spectrumRepresentation", "Vector",
	function(object, value) {
		object@metadata[["spectrum representation"]] <- value
		object
	})

# experiment metadata

setMethod("instrumentModel", "Vector",
	function(object) object@metadata[["instrument model"]])

setReplaceMethod("instrumentModel", "Vector",
	function(object, value) {
		object@metadata[["instrument model"]] <- value
		object
	})

setMethod("instrumentVendor", "Vector",
	function(object) object@metadata[["instrument vendor"]])

setReplaceMethod("instrumentVendor", "Vector",
	function(object, value) {
		object@metadata[["instrument vendor"]] <- value
		object
	})

setMethod("matrixApplication", "Vector",
	function(object) object@metadata[["matrix application type"]])

setReplaceMethod("matrixApplication", "Vector",
	function(object, value) {
		object@metadata[["matrix application type"]] <- value
		object
	})

setMethod("massAnalyzerType", "Vector",
	function(object) object@metadata[["mass analyzer type"]])

setReplaceMethod("massAnalyzerType", "Vector",
	function(object, value) {
		object@metadata[["mass analyzer type"]] <- value
		object
	})

setMethod("ionizationType", "Vector",
	function(object) object@metadata[["ionization type"]])

setReplaceMethod("ionizationType", "Vector",
	function(object, value) {
		object@metadata[["ionization type"]] <- value
		object
	})

setMethod("scanPolarity", "Vector",
	function(object) object@metadata[["scan polarity"]])

setReplaceMethod("scanPolarity", "Vector",
	function(object, value) {
		object@metadata[["scan polarity"]] <- value
		object
	})

setMethod("scanType", "Vector",
	function(object) object@metadata[["scan type"]])

setReplaceMethod("scanType", "Vector",
	function(object, value) {
		object@metadata[["scan type"]] <- value
		object
	})

setMethod("scanPattern", "Vector",
	function(object) object@metadata[["scan pattern"]])

setReplaceMethod("scanPattern", "Vector",
	function(object, value) {
		object@metadata[["scan pattern"]] <- value
		object
	})

setMethod("scanDirection", "Vector",
	function(object) object@metadata[["linescan sequence"]])

setReplaceMethod("scanDirection", "Vector",
	function(object, value) {
		object@metadata[["linescan sequence"]] <- value
		object
	})

setMethod("lineScanDirection", "Vector",
	function(object) object@metadata[["line scan direction"]])

setReplaceMethod("lineScanDirection", "Vector",
	function(object, value) {
		object@metadata[["line scan direction"]] <- value
		object
	})

setMethod("pixelSize", "Vector",
	function(object) object@metadata[["pixel size"]])

setReplaceMethod("pixelSize", "Vector",
	function(object, value) {
		object@metadata[["pixel size"]] <- value
		object
	})


