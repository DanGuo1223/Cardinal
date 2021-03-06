
## Subset an imaging dataset by rows/features

setMethod("filter", "ImagingExperiment",
	function(.data, ..., .id)
	{
		idx <- features(.data, ..., .env=parent.frame(2))
		if ( !missing(.id) )
			idx <- intersect(idx, .id)
		.data[idx,]
	})
