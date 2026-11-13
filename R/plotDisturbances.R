## R/plotDisturbances.R -- disturbance-map diagnostic plot (tidyterra / ggplot2).
## Used by the anthroDisturbance_Generator `plot` event via SpaDES.core::Plots(), so the PNGs are
## saved to figurePath() and registered as module outputs. The map it draws comes from
## anthroDisturbanceUtils::disturbancePresenceRaster().

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
