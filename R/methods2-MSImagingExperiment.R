
#### Methods for MSImagingExperiment ####
## ------------------------------------------

MSImagingExperiment <- function(imageData = matrix(nrow=0, ncol=0),
	featureData = MassDataFrame(), pixelData = PositionDataFrame(),
	metadata = list(), processing = SimpleList(), centroided=FALSE)
{
	if ( is.matrix(imageData) || is(imageData, "matter_matc") ) {
		imageData <- MSContinuousImagingSpectraList(imageData)
	} else if ( is(imageData, "sparse_matc") ) {
		imageData <- MSProcessedImagingSpectraList(imageData)
	} else if ( !is(imageData, "ImageArrayList") ) {
		imageData <- ImageArrayList(imageData)
		if ( is.null(names(imageData)) ) {
			inames <- .format.numbered("intensity", length(imageData))
			names(imageData) <- inames
		}
	}
	if ( length(imageData) != 0L ) {
		iData <- imageData[[1]]
		if ( missing(featureData) ) {
			rownames <- rownames(iData)
			featureData <- new("DataFrame", nrows=nrow(iData),
				rownames=rownames)
		}
		if ( missing(pixelData) ) {
			colnames <- colnames(iData)
			coord=expand.grid(x=seq_len(ncol(iData)), y=1L)
			pixelData <- PositionDataFrame(coord=coord,
				row.names=colnames)
		}
	}
	if ( is(imageData, "MSContinuousImagingSpectraList") ) {
		.MSContinuousImagingExperiment(
			imageData=imageData,
			featureData=featureData,
			elementMetadata=pixelData,
			metadata=metadata,
			processing=processing,
			centroided=centroided)
	} else if ( is(imageData, "MSProcessedImagingSpectraList") ) {
		.MSProcessedImagingExperiment(
			imageData=imageData,
			featureData=featureData,
			elementMetadata=pixelData,
			metadata=metadata,
			processing=processing,
			centroided=centroided)
	} else if ( is(imageData, "ImageArrayList") ) {
		.MSImagingExperiment(
			imageData=imageData,
			featureData=featureData,
			elementMetadata=pixelData,
			metadata=metadata,
			processing=processing,
			centroided=centroided)
	}
}

## MS-related methods

setMethod("mz", "MSImagingExperiment", function(object, ...) mz(object@featureData))

setReplaceMethod("mz", "MSImagingExperiment",
	function(object, value) {
		mz(object@featureData) <- value
		object
	})

setMethod("spectra", "MSImagingExperiment", function(object, ...) iData(object))

setReplaceMethod("spectra", "MSImagingExperiment",
	function(object, value) {
		iData(object) <- value
		object
	})

setMethod("centroided", "MSImagingExperiment", function(object) object@centroided)

setReplaceMethod("centroided", "MSImagingExperiment",
	function(object, value) {
		object@centroided <- value
		object
	})

## Filter pixels/features

setMethod("features", "MSImagingExperiment",
	function(object, ..., mz, withNames = TRUE) {
		if ( missing(mz) ) {
			features <- callNextMethod(object, ..., withNames=withNames)
		} else {
			mz <- as.numeric(mz)
			features <- bsearch(mz, mz(object), nearest=TRUE)
			if ( length(list(...)) > 0 ) {
				keep <- features %in% callNextMethod(object, ..., withNames=FALSE)
				features <- features[keep]
			}
			if ( withNames )
				names(features) <- featureNames(object)[features]
		}
		features
	})

setMethod("pixels", "MSImagingExperiment",
	function(object, ..., coord, withNames = TRUE) {
		if ( missing(coord) ) {
			pixels <- callNextMethod(object, ..., withNames=withNames)
		} else {
			if ( !gridded(object) )
				.warning("pixel coordinates are not gridded")
			coord <- as.data.frame(as.list(coord))
			pixels <- unlist(apply(coord, 1, function(xy) {
				lxy <- sapply(seq_along(xy), function(i) {
					nm <- names(xy)[i]
					coord(object)[[nm]] %in% xy[i]
				})
				if ( nrow(coord(object)) == 1 )
					lxy <- t(lxy)
				if ( is.null(dim(lxy)) ) {
					lxy <- which(lxy)
				} else {
					lxy <- which(apply(lxy, 1, all))
				}
			}))
			if ( length(list(...)) > 0 ) {
				keep <- pixels %in% callNextMethod(object, ..., withNames=FALSE)
				pixels <- pixels[keep]
			}
			if ( withNames )
				names(pixels) <- pixelNames(object)[pixels]
		}
		pixels
	})

## rbind/cbind

setMethod("rbind", "MSImagingExperiment",
	function(..., deparse.level=1)
	{
		objects <- unname(list(...))
		is_centroided <- sapply(objects, "centroided")
		if ( !all(is_centroided) && !all(!is_centroided) )
			.warning("all object must be centroided or not centroided")
		result <- callNextMethod(..., deparse.level=deparse.level)
		result@centroided <- centroided(objects[[1]])
		result
    }
)

setMethod("cbind", "MSImagingExperiment",
	function(..., deparse.level=1)
	{
		objects <- unname(list(...))
		is_centroided <- sapply(objects, "centroided")
		if ( !all(is_centroided) && !all(!is_centroided) )
			.warning("all object must be centroided or not centroided")
		result <- callNextMethod(..., deparse.level=deparse.level)
		result@centroided <- centroided(objects[[1]])
		result
    }
)

## coerce to/from MSImageSet

setAs("MSImageSet", "MSImagingExperiment",
	function(from) {
		MSImagingExperiment(imageData=spectra(from),
			featureData=MassDataFrame(mz(from)),
			pixelData=PositionDataFrame(coord(from),
				run=pixelData(from)$sample),
			centroided=centroided(from))
	})

setAs("MSImagingExperiment", "MSImageSet",
	function(from) {
		out <- MSImageSet(spectra=spectra(from),
			mz=mz(from), coord=coord(from))
		pixelData(out)$sample <- run(from)
		centroided(out) <- centroided(out)
		out
	})