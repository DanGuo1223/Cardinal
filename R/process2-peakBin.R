
#### Bin spectra to reference peaks ####
## ------------------------------------

setMethod("peakBin", c("MSImagingExperiment", "numeric"),
	function(object, ref, type=c("height", "area"),
		tolerance = 200, units = c("ppm", "mz"), ...)
	{
		tol <- switch(match.arg(units),
			ppm = c("relative" = tolerance * 1e-6),
			mz = c("absolute" = tolerance))
		cached.mz <- mz(object)
		cached.peaks <- bsearch(ref, cached.mz, tol=tol, tol.ref="key")
		cached.peaks <- cached.peaks[!is.na(cached.peaks)]
		type <- match.arg(type)
		fun <- peakBin_fun(tol, type, cached.peaks, cached.mz)
		postfun <- peakBin_postfun(tol)
		plotfun <- peakBin_plotfun(tol)
		metadata(featureData(object))[["reference peaks"]] <- ref
		object <- process(object, fun=fun, ...,
			label="peakBin", kind="pixel",
			postfun=postfun, plotfun=plotfun,
			delay=TRUE)
		object
	})

setMethod("peakBin", c("MSImagingExperiment", "missing"),
	function(object, type=c("height", "area"),
		tolerance = 200, units = c("ppm", "mz"), ...)
	{
		tol <- switch(match.arg(units),
			ppm = c("relative" = tolerance * 1e-6),
			mz = c("absolute" = tolerance))
		type <- match.arg(type)
		fun <- peakBin_fun(tol, type, NULL, NULL)
		prefun <- peakBin_prefun
		postfun <- peakBin_postfun(tol)
		plotfun <- peakBin_plotfun(tol)
		object <- process(object, fun=fun, ...,
			label="peakBin", kind="pixel",
			prefun=prefun, postfun=postfun,
			plotfun=plotfun,
			delay=TRUE)
		object
	})

peakBin_plotfun <- function(tol) {
	fun <- function(s2, s1, ...,
		main="Peak binning", xlab="m/z", ylab="")
	{
		mz <- mz(attr(s1, "mcols"))
		ref <- metadata(attr(s1, "mcols"))[["reference peaks"]]
		if ( is.null(ref) )
			.stop("couldn't find reference peaks")
		plot(range(mz), range(s2), main=main,
			xlab=xlab, ylab=ylab, type='n', ...)
		lines(mz, s1, col="gray", type='l')
		bins <- attr(s2, "bins")
		if ( !is.null(bins) ) {
			i <- unique(unlist(mapply(":", bins[[1]], bins[[2]])))
			lines(mz[i], s1[i], col=rgb(0, 0, 1, 0.25), type='h')
		}
		lines(ref, s2, col="red", type='h')
	}
	fun
}

peakBin_prefun <- function(object, ..., BPPARAM) {
	s <- summarize(object, .stat="mean",
		.by="feature", BPPARAM=BPPARAM)$mean
	ref <- mz(object)[localMaximaLogical(s)]
	metadata(featureData(object))[["reference peaks"]] <- ref
	object
}

peakBin_fun <- function(tol, type, cached.peaks, cached.mz) {
	fun <- function(x, ...) {
		mzi <- mz(attr(x, "mcols"))
		if ( !identical(cached.mz, mzi) ) {
			ref <- metadata(attr(x, "mcols"))[["reference peaks"]]
			if ( is.null(ref) )
				.stop("couldn't find reference peaks")
			peaks <- bsearch(ref, mzi, tol=tol, tol.ref="key")
			peaks <- peaks[!is.na(peaks)]
		} else {
			peaks <- cached.peaks
		}
		f <- switch(type, height=max, area=sum)
		bounds <- nearestLocalMaxima(-x, seq_along(x), peaks)
		peaks <- bin(x, bins=bounds, fun=f)
		attr(peaks, "bins") <- bounds
		peaks
	}
	fun
}

peakBin_postfun <- function(tol) {
	fun <- function(object, ans, ...) {
		if ( is.matter(ans) ) {
			data <- as(ans, "matter_matc")
		} else {
			data <- as.matrix(simplify2array(ans))
		}
		ref <- metadata(featureData(object))[["reference peaks"]]
		if ( is.null(ref) )
			.stop("couldn't find reference peaks")
		mcols <- MassDataFrame(mz=ref)
		metadata(mcols) <- metadata(featureData(object))
		object <- MSImagingExperiment(data,
			featureData=mcols,
			pixelData=pixelData(object),
			metadata=metadata(object),
			processing=processingData(object),
			centroided=TRUE)
		if ( !is.null(spectrumRepresentation(object)) )
			spectrumRepresentation(object) <- "centroid spectrum"
		.message("binned to ", length(ref), " reference peaks")
		object
	}
	fun
}
