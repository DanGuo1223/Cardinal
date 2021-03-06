
#### Read imzML files ####
## ----------------------

readImzML <- function(name, folder = getwd(), attach.only = FALSE,
	mass.range = NULL, resolution = 200, units = c("ppm", "mz"),
	as = c("MSImageSet", "MSImagingExperiment"), ...)
{
	# check input
	dots <- list(...)
	if ( "mass.accuracy" %in% names(dots) ) {
		.warning("'mass.accuracy' is deprecated.\n",
			"Use 'resolution' instead.")
		resolution <- dots$mass.accuracy
	}
	if ( "units.accuracy" %in% names(dots) ) {
		.warning("'units.accuracy' is deprecated.\n",
			"Use 'units' instead.")
		units <- dots$units.accuracy
	}
	# get output format
	outclass <- match.arg(as)
	# check for files
	xmlpath <- normalizePath(file.path(folder, paste(name, ".imzML", sep="")),
		mustWork=FALSE)
	if ( !file.exists(xmlpath) ) .stop("readImzML: ", xmlpath, " does not exist")
	ibdpath <- normalizePath(file.path(folder, paste(name, ".ibd", sep="")),
		mustWork=FALSE)
	if ( !file.exists(ibdpath) ) .stop("readImzML: ", ibdpath, " does not exist")
	# read imzML file
	.message("readImzML: Reading imzML file '", xmlpath, "'")
	info <- .readImzML(xmlpath)
	# read ibd file
	metadata(info)[["files"]] <- c(xmlpath, ibdpath)
	metadata(info)[["name"]] <- name
	units <- match.arg(units)
	.message("readImzML: Reading ibd file '", ibdpath, "'")
	object <- .readIbd(ibdpath, info, outclass=outclass, attach.only=attach.only,
		mass.range=mass.range, resolution=resolution, units=units)
	if ( validObject(object) ) {
		.message("readImzML: Done.")
		object
	}
}

.readImzML <- function(file) {
	parse <- .Call("readImzML", normalizePath(file), PACKAGE="Cardinal")
	len <- sapply(parse$experimentMetadata, nchar, type="bytes")
	experimentMetadata <- parse$experimentMetadata[len > 0]
	new("MSImagingInfo",
		scanList=as(parse$scanList, "DataFrame"),
		mzArrayList=as(parse$mzArrayList, "DataFrame"),
		intensityArrayList=as(parse$intensityArrayList, "DataFrame"),
		metadata=experimentMetadata)
}

.readIbd <- function(file, info, outclass, attach.only,
	mass.range, resolution, units)
{
	file <- normalizePath(file)
	ibdtype <- metadata(info)[["ibd binary type"]]
	mz.ibdtype <- mzData(info)[["binary data type"]]
	intensity.ibdtype <- imageData(info)[["binary data type"]]
	# read binary data
	if ( ibdtype == "continuous" ) {
		mz <- matter_vec(paths=file,
			datamode=Ctypeof(mz.ibdtype[1]),
			offset=mzData(info)[["external offset"]][1],
			extent=mzData(info)[["external array length"]][1])
		intensity <- matter_mat(paths=file,
			datamode=Ctypeof(intensity.ibdtype[1]),
			offset=imageData(info)[["external offset"]],
			extent=imageData(info)[["external array length"]])
		if ( attach.only ) {
			spectra <- intensity
		} else {
			spectra <- intensity[]
		}
		mz <- mz[]
	} else if ( ibdtype == "processed" ) {
		mz <- matter_list(paths=file,
			datamode=Ctypeof(mz.ibdtype),
			offset=mzData(info)[["external offset"]],
			extent=mzData(info)[["external array length"]])
		intensity <- matter_list(paths=file,
			datamode=Ctypeof(intensity.ibdtype),
			offset=imageData(info)[["external offset"]],
			extent=imageData(info)[["external array length"]])
		if ( is.null(mass.range) ) {
			mzvec <- as(mz, "matter_vec")
			chunksize(mzvec) <- 1e8L # read chunks of 800 MB
			mz.range <- range(mzvec)
		} else {
			mz.range <- mass.range
		}
		mz.min <- mz.range[1]
		mz.max <- mz.range[2]
		if ( units == "ppm" ) {
			#if ( floor(mz.min) <= 0 )
			#	.stop("readImzML: m/z values must be positive for units='ppm'")
			mzout <- seq.ppm(
				from=floor(mz.min),
				to=ceiling(mz.max),
				ppm=resolution) # ppm == half-bin-widths
			error <- resolution * 1e-6 * mzout
			tol <- c(relative = resolution * 1e-6)
		} else {
			mzout <- seq(
				from=floor(mz.min),
				to=ceiling(mz.max),
				by=resolution * 2)  # by == full-bin-widths
			error <- rep(resolution, length(mzout))
			tol <- c(absolute = resolution)
		}
		mz.bins <- c(mzout[1] - error[1], mzout + error)
		if ( attach.only ) {
			data <- list(keys=mz, values=intensity)
			mz <- mzout
			spectra <- sparse_mat(data, keys=mz,
				nrow=length(mz), ncol=length(intensity),
				tolerance=tol, combiner="sum")
		} else {
			if ( outclass == "MSImageSet" ) {
				data <- list(keys=list(), values=list())
				for ( i in seq_along(mz) ) {
					mzi <- mz[[i]]
					wh <- findInterval(mzi, mz.bins)
					s <- as.vector(tapply(intensity[[i]], wh, sum))
					data$keys[[i]] <- mzout[unique(wh)]
					data$values[[i]] <- s
				}
			} else if ( outclass == "MSImagingExperiment") {
				data <- list(keys=mz[], values=intensity[])
			}
			mz <- mzout
			spectra <- sparse_mat(data, keys=mz,
				nrow=length(mz), ncol=length(intensity),
				tolerance=tol, combiner="sum")
		}
	}
	# set up coordinates
	x <- scans(info)[["position x"]]
	y <- scans(info)[["position y"]]
	z <- scans(info)[["position z"]]
	x3d <- scans(info)[["3DPositionX"]]
	y3d <- scans(info)[["3DPositionY"]]
	z3d <- scans(info)[["3DPositionZ"]]
	if ( all(is.na(z)) && all(is.na(z3d)) ) {
		coord <- data.frame(x=x, y=y)
	} else if ( all(is.na(z3d)) ) {
		coord <- data.frame(x=x, y=y, z=z)
	} else {
		z <- as.integer(as.factor(z3d))
		coord <- data.frame(x=x, y=y, z=z)
	}
	if ( outclass == "MSImageSet" ) {
		experimentData <- new("MIAPE-Imaging")
		processingData <- new("MSImageProcess", files=metadata(info)[["files"]])
		object <- MSImageSet(spectra=spectra, mz=mz, coord=coord,
			processingData=processingData,
			experimentData=experimentData)
		sampleNames(object) <- metadata(info)[["name"]]
	} else if ( outclass == "MSImagingExperiment" ) {
		centroided <- isTRUE(spectrumRepresentation(info) == "centroid spectrum")
		object <- MSImagingExperiment(spectra,
			featureData=MassDataFrame(mz=mz),
			pixelData=PositionDataFrame(coord=coord,
				run=metadata(info)[["name"]]),
			metadata=metadata(info),
			centroided=centroided)
	} else {
		stop("unrecognized outclass")
	}
	object
}

