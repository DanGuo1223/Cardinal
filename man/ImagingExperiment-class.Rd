\name{ImagingExperiment-class}
\docType{class}

\alias{class:ImagingExperiment}
\alias{ImagingExperiment}
\alias{ImagingExperiment-class}

\alias{pixels}
\alias{pixels-methods}
\alias{features}
\alias{features-methods}

\alias{imageData}
\alias{imageData<-}
\alias{imageData-methods}
\alias{iData}
\alias{iData<-}
\alias{iData-methods}
\alias{pixelData}
\alias{pixelData<-}
\alias{pixelData-methods}
\alias{pData}
\alias{pData<-}
\alias{pData-methods}
\alias{featureData}
\alias{featureData<-}
\alias{featureData-methods}
\alias{fData}
\alias{fData<-}
\alias{fData-methods}

\alias{pixelNames}
\alias{pixelNames<-}
\alias{pixelNames-methods}
\alias{featureNames}
\alias{featureNames<-}
\alias{featureNames-methods}

\alias{show,ImagingExperiment-method}
\alias{length,ImagingExperiment-method}
\alias{$,ImagingExperiment-method}
\alias{$<-,ImagingExperiment-method}
\alias{[[,ImagingExperiment,ANY,missing-method}
\alias{[[<-,ImagingExperiment,ANY,missing-method}
\alias{dim,ImagingExperiment-method}
\alias{dimnames,ImagingExperiment-method}
\alias{imageData,ImagingExperiment-method}
\alias{imageData<-,ImagingExperiment-method}
\alias{iData,ImagingExperiment,ANY-method}
\alias{iData,ImagingExperiment,missing-method}
\alias{iData<-,ImagingExperiment,ANY-method}
\alias{iData<-,ImagingExperiment,missing-method}
\alias{pixelData,ImagingExperiment-method}
\alias{pixelData<-,ImagingExperiment-method}
\alias{pData,ImagingExperiment-method}
\alias{pData<-,ImagingExperiment-method}
\alias{pData<-,ImagingExperiment,ANY-method}
\alias{pixelNames,ImagingExperiment-method}
\alias{pixelNames<-,ImagingExperiment-method}
\alias{featureData,ImagingExperiment-method}
\alias{featureData<-,ImagingExperiment-method}
\alias{featureData<-,ImagingExperiment,ANY-method}
\alias{fData,ImagingExperiment-method}
\alias{fData<-,ImagingExperiment-method}
\alias{fData<-,ImagingExperiment,ANY-method}
\alias{featureNames,ImagingExperiment-method}
\alias{featureNames<-,ImagingExperiment-method}
\alias{pixels,ImagingExperiment-method}
\alias{features,ImagingExperiment-method}

\title{ImagingExperiment: Abstract class for imaging experiments}

\description{
   The \code{ImagingExperiment} class is a virtual class for biological imaging experiments. It includes slots for pixel metadata and for feature metadata. The class makes very few assumptions about the structure of the underlying imaging data, including the dimensions.

   For a concrete subclass, see the \code{\linkS4class{SparseImagingExperiment}} class, which assumes that the image data can be represented as a matrix where columns represent pixels and rows represent features. The \code{\linkS4class{MSImagingExperiment}} subclass is further specialized for analysis of mass spectrometry imaging experiments.
}

\section{Slots}{
    \describe{
        \item{\code{imageData}:}{An object inheriting from \code{\linkS4class{ImageList}}, storing one or more array-like data elements. No assumption is made about the shape of the arrays.}

        \item{\code{featureData}:}{Contains feature information in a \code{\linkS4class{DataFrame}}. Each row includes the metadata for a single feature (e.g., a color channel, a molecular analyte, or a mass-to-charge ratio).}

        \item{\code{elementMetadata}:}{Contains pixel information in a \code{\linkS4class{DataFrame}}. Each row includes the metadata for a single observation (e.g., a pixel).}

        \item{\code{metadata}:}{A \code{list} containing experiment-level metadata.}
    }
}

\section{Methods}{
    \describe{
        \item{\code{imageData(object), imageData(object) <- value}:}{Get and set the \code{imageData} slot.}

        \item{\code{iData(object, i), iData(object, i, ...) <- value}:}{Get or set the element \code{i} from the \code{imageData}. If \code{i} is missing, the first data element is returned.}

        \item{\code{pixelData(object), pixelData(object) <- value}:}{Get and set the \code{elementMetadata} slot.}

        \item{\code{pixelNames(object), pixelNames(object) <- value}:}{Get and set the row names of the \code{elementMetadata} slot.}

        \item{\code{pData(object), pData(object) <- value}:}{A shortcut for \code{pixelData(object)} and \code{pixelData(object)<-}.}

        \item{\code{featureData(object), featureData(object) <- value}:}{Get and set the \code{featureData} slot.}

        \item{\code{featureNames(object), featureNames(object) <- value}:}{Get and set the row names of the \code{featureData} slot.}

        \item{\code{fData(object), fData(object) <- value}:}{A shortcut for \code{featureData(object)} and \code{featureData(object)<-}.}

        \item{\code{pixels(object, ...)}:}{Returns the row indices of \code{pixelData} corresponding to conditions passed via \dots.}

        \item{\code{features(object, ...)}:}{Returns the row indices of \code{featureData} corresponding to conditions passed via \dots.}

        \item{\code{dim}:}{The dimensions of the object, as determined by the number of features (rows in \code{featureData}) and the number of pixels (rows in \code{pixelData}).}

        \item{\code{object$name, object$name <- value}:}{Get and set the \code{name} column in \code{pixelData}.}

        \item{\code{object[[i]], object[[i]] <- value}:}{Get and set the column \code{i} (a string or integer) in \code{pixelData}.}
    }
}

\author{Kylie A. Bemis}

\seealso{
    \code{\linkS4class{SparseImagingExperiment}},
    \code{\linkS4class{MSImagingExperiment}}
}

\examples{
## Cannot create an ImagingExperiment object
try(new("ImagingExperiment"))

## Create an ImagingExperiment derived class
MyImagingExperiment <- setClass("MyImagingExperiment", contains="ImagingExperiment")
MyImagingExperiment()

removeClass("MyImageSet")
}

\keyword{classes}
