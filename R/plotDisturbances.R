## R/plotDisturbances.R -- disturbance-map diagnostic helpers (terra / tidyterra / ggplot2).
## Used by the anthroDisturbance_Generator `plot` event via SpaDES.core::Plots(), so the PNGs are
## saved to figurePath() and registered as module outputs. YT-generic: driven by the module's actual
## currentDisturbanceLayer output, not hardcoded layers.

## Recursively collect the terra objects (SpatRaster/SpatVector) from a (possibly nested) list.
flattenTerra <- function(x) {
  if (inherits(x, c("SpatRaster", "SpatVector"))) {
    return(list(x))
  }
  if (is.list(x)) {
    out <- list()
    for (el in x) {
      out <- c(out, flattenTerra(el))
    }
    return(out)
  }
  list()
}

## Combine the (possibly nested) currentDisturbanceLayer list into a single presence SpatRaster on
## rasterToMatch's grid (values where any disturbance, NA elsewhere). Returns NULL if there is nothing
## to plot (e.g. before any disturbance has been generated).
disturbancePresenceRaster <- function(distLayers, rasterToMatch) {
  objs <- flattenTerra(distLayers)
  rs <- lapply(objs, function(o) {
    if (inherits(o, "SpatVector")) {
      if (terra::nrow(o) == 0L) {
        return(NULL)
      }
      terra::rasterize(o, rasterToMatch, background = NA)
    } else if (inherits(o, "SpatRaster")) {
      o
    } else {
      NULL
    }
  })
  rs <- rs[!vapply(rs, is.null, logical(1))]
  if (!length(rs)) {
    return(NULL)
  }
  combined <- Reduce(function(a, b) terra::cover(a, b), rs)
  names(combined) <- "disturbance"
  combined
}

## The Plots() plotting function: a ggplot of a disturbance SpatRaster via tidyterra, with an optional
## study-area outline. `data` is the SpatRaster; `studyArea`/`title` are passed through by Plots(...).
plotDisturbanceRaster <- function(data, studyArea = NULL, title = NULL) {
  g <- ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = data) +
    ggplot2::scale_fill_viridis_c(na.value = "transparent", name = NULL) +
    ggplot2::labs(title = title) +
    ggplot2::theme_minimal()
  if (!is.null(studyArea)) {
    g <- g +
      tidyterra::geom_spatvector(data = studyArea, fill = NA, colour = "grey20", linewidth = 0.3)
  }
  g
}
