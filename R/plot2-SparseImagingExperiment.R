
#### X-Y plotting for SparseImagingExperiment ####
## ------------------------------------------------

setMethod("plot", c(x = "SparseImagingExperiment", y = "formula"),
	function(x, y, ...) plot(x, formula = y, ...))

setMethod("plot", c(x = "SparseImagingExperiment", y = "missing"),
	function(x, formula,
		pixel,
		pixel.groups,
		groups = NULL,
		superpose = FALSE,
		strip = TRUE,
		key = superpose || !is.null(groups),
		fun = mean,
	    ...,
		xlab, xlim,
		ylab, ylim,
		layout,
		col = discrete.colors,
		subset = TRUE,
		add = FALSE)
{
	.checkForIncompleteProcessing(x)
	if ( missing(formula) ) {
		xnm <- setdiff(ls(as.env(featureData(x))), names(featureData(x)))
		if ( length(xnm) > 0L ) {
			xnm <- xnm[1L]
		} else {
			xnm <- names(featureData(x))[1L]
		}
		ynm <- names(imageData(x))[1L]
		fm <- paste0(ynm, "~", xnm)
		formula <- as.formula(fm, env=parent.frame(2))
	}
	e <- environment(formula)
	elhs <- as.env(featureData(x), enclos=e)
	if ( !missing(pixel) && !is.null(names(imageData(x))) ) {
		xi <- as.list(imageData(x)[,pixel,drop=FALSE])
		multiassign(names(xi), xi, envir=elhs)
	}
	args <- .parseFormula2(formula,
		lhs.e=elhs, rhs.e=as.env(featureData(x), enclos=e),
		g.e=as.env(pixelData(x), enclos=e))
	if ( length(args$rhs) != 1L )
		.stop("rhs of formula must include exactly 1 variables")
	if ( missing(pixel.groups) ) {
		pixel.groups <- NULL
	} else if ( !is.null(pixel.groups) ) {
		pixel.groups <- .try_eval(substitute(pixel.groups),
			envir=as.env(pixelData(x), enclos=e))
		if ( !is.factor(pixel.groups) ) {
			pixel.groups <- factor(pixel.groups,
				levels=unique(pixel.groups))
		} else {
			pixel.groups <- droplevels(pixel.groups)
		}
		if ( length(pixel.groups) < length(pixel) ) {
			pixel.groups <- rep_len(pixel.groups, length(pixel))
		} else if ( length(pixel.groups) > length(pixel) ) {
			pixel.groups <- pixel.groups[pixel]
		}
	}
	if ( !missing(groups) ) {
		groups <- .try_eval(substitute(groups),
			envir=as.env(featureData(x), enclos=e))
		if ( !is.factor(groups) ) {
			groups <- factor(groups, levels=unique(groups))
		} else {
			groups <- droplevels(groups)
		}
		if ( length(groups) != nrow(x) )
			groups <- rep_len(groups, nrow(x))
	}
	if ( !missing(subset) ) {
		subset <- .try_eval(substitute(subset),
			envir=as.env(featureData(x), enclos=e))
		if ( is.logical(subset) )
			subset <- rep_len(subset, nrow(x))
	}
	if ( !missing(pixel) ) {
		if ( !is.null(args$g) ) {
			condition <- as.data.frame(args$g)[pixel,,drop=FALSE]
		} else {
			condition <- data.frame(row.names=pixel)
		}
		if ( !is.null(pixel.groups) ) {
			condition$`..pixel.groups..` <- pixel.groups
		} else {
			condition$`..pixel.groups..` <- factor(1)
		}
		condition[] <- lapply(condition, function(ci) {
			if ( !is.factor(ci) ) {
				ci <- factor(ci, levels=unique(ci))
			} else {
				ci <- droplevels(ci)
			}
		})
		if ( is.null(args$lhs) ) {
			xi <- iData(x)[,pixel,drop=FALSE]
			args$lhs <- .fastFeatureApply2(xi, fun, condition)
			if ( is.null(pixel.groups) && !is.null(names(imageData(x))) ) {
				names(args$lhs) <- rep_len(names(imageData(x))[1], length(args$lhs))
			} else {
				names(args$lhs) <- unique(condition)$`..pixel.groups..`
			}
		} else {
			val.groups <- factor(names(args$lhs))
			args$lhs <- lapply(args$lhs, function(xi) {
				if ( isTRUE(ncol(xi) == nrow(condition)) ) {
					.fastFeatureApply2(xi, fun, condition)
				} else {
					list(as.vector(xi))
				}
			})
			condition <- unique(condition)
			val.groups <- rep.int(val.groups, lengths(args$lhs))
			if ( sum(lengths(args$lhs)) > nrow(condition) ) {
				condition <- lapply(lengths(args$lhs), function(l) {
					if ( l != nrow(condition) ) {
						condition[nrow(condition) + 1L,] # returns NA's
					} else {
						condition
					}
				})
				condition <- do.call("rbind", condition)
				condition$`..val.groups..` <- val.groups
			}
			args$lhs <- unlist(args$lhs, recursive=FALSE)
			names(args$lhs) <- val.groups
		}
		condition <- unique(condition)
		if ( superpose ) {
			if ( is.null(pixel.groups) ) {
				if ( length(args$g) == 1L ) {
					names(args$lhs) <- as.character(condition[[names(args$g)]])
					condition[[names(args$g)]] <- NULL
				} else if ( length(args$g) > 1L ) {
					.stop("can't superpose multiple conditioning variables")
				} else {
					condition$`..val.groups..` <- NULL
				}
			} else {
				if ( nlevels(val.groups) > 1L ) {
					names(args$lhs) <- as.character(condition$`..val.groups..`)
					condition$`..val.groups..` <- NULL
				} else {
					names(args$lhs) <- as.character(condition$`..pixel.groups..`)
					condition$`..pixel.groups..` <- NULL
				}
			}
		}
		if ( is.null(pixel.groups) )
			condition$`..pixel.groups..` <- NULL
		if ( length(condition) > 0L ) {
			facets <- condition
		} else {
			facets <- NULL
		}
	} else {
		facets <- NULL
	}
	facet.plot(args, formula=formula, obj=x,
		facets=facets, groups=groups,
		superpose=superpose,
		strip=strip, key=key,
		...,
		xlab=xlab, xlim=xlim,
		ylab=ylab, ylim=ylim,
		layout=layout, col=col,
		subset=subset, add=add)
})

.fastFeatureApply2 <- function(x, fun, groups) {
	all.groups <- groups
	groups <- unique(groups)
	glevels <- lapply(seq_len(nrow(groups)),
		function(i) groups[i,,drop=FALSE])
	if ( ncol(x) == 1L ) {
		x <- list(drop(x))
	} else if ( length(glevels) == 1L ) {
		x <- list(apply(x, 1L, fun))
	} else {
		x <- lapply(glevels, function(g) {
			i <- subrows(all.groups, g)
			apply(x[,i,drop=FALSE], 1L, fun)
		})
	}
	x
}
