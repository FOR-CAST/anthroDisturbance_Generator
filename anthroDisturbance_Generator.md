anthroDisturbance_Generator Manual
================
Last updated: 2026-07-10

- [anthroDisturbance_Generator
  Module](#anthrodisturbance_generator-module)
  - [Authors:](#authors)
  - [Module Overview](#module-overview)
    - [Module summary](#module-summary)
    - [Module inputs and parameters](#module-inputs-and-parameters)
    - [Events](#events)
    - [Plotting](#plotting)
    - [Saving](#saving)
    - [Module outputs](#module-outputs)
    - [Links to other modules](#links-to-other-modules)
    - [Getting help](#getting-help)

# anthroDisturbance_Generator Module

[![made-with-Markdown](figures/markdownBadge.png)](https://commonmark.org)

#### Authors:

Tati Micheletti <tati.micheletti@gmail.com> \[aut, cre\]

## Module Overview

### Module summary

This module generates new anthropogenic disturbances forward in time.
Given the `disturbanceParameters` table and a `disturbanceList` holding
both current and potential disturbances (as produced by
`anthroDisturbance_DataPrep` and, optionally,
`potentialResourcesYT_DataPrep`), it grows, generates, and connects
disturbances year by year according to each type’s rate and size.

The module was originally developed for the Northwest Territories (its
built-in default sample data is the union of BCR6 and NT1), but the
structure is general. This is the FOR-CAST fork used in the Yukon
Northern Mountain Caribou project, where the pipeline supplies Yukon
inputs.

### Module inputs and parameters

The two structuring inputs are `disturbanceList` (from a DataPrep /
potential resources module) and the `disturbanceParameters`
`data.table`, whose columns are:

- `dataName`: sector grouping (e.g., Energy, Settlements, OilGas,
  Mining, Forestry, Roads);
- `dataClass`: the specific class, always prefixed `potential` (e.g.,
  potentialSettlements, potentialWindTurbines, potentialCutblocks);
- `disturbanceType`: one of three general types –
  1.  Enlarging (e.g., potentialSettlements, potentialSeismicLines): the
      potential layer equals the current layer and is only buffered over
      time;
  2.  Generating (e.g., potentialWindTurbines, potentialOilGas,
      potentialMineral, potentialForestry): the potential layer marks
      where structures may appear based on a rate;
  3.  Connecting (e.g., potentialPipelines, potentialTransmission,
      potentialRoads): the potential layer needs the current
      transmission, pipeline, and road network, and depends on what
      Generating produces;
- `disturbanceRate`: yearly generation rate for Enlarging and Generating
  types (NA for Connecting). If missing when needed, the module derives
  it from data (e.g., ECCC), falling back to a yearly average of 0.2% of
  current disturbance;
- `disturbanceSize`: target size in m2 for Generating types (NA for
  Enlarging / Connecting); derived from data if not supplied;
- `disturbanceOrigin`: the `dataClass` used as the “original” to modify
  (Enlarging, Generating) or as the origin point for Connecting types;
- `disturbanceEnd`: end points for Connecting layers (e.g., new wind
  turbines connect into power lines/roads; new oilGas into
  pipelines/roads);
- `disturbanceInterval`: interval at which the disturbance recurs.

Other inputs include the study area (`studyArea`), matching raster
(`rasterToMatch`), current burn raster (`rstCurrentBurn`),
`disturbanceDT`, and optional `DEM` / `featuresToAvoid` layers used to
constrain linear-feature placement.

The full list of module inputs:

| objectName | objectClass | desc | sourceURL |
|:---|:---|:---|:---|
| disturbanceList | list | List (general category) of lists (specific class) needed for generating disturbances. This is generally the output from a potentialResources module (i.e., potentialResourcesYT_DataPrep), where multiple potential layers (i.e., mining and oilGas) we replaced by only one layer with the highestvalues being the ones that need to be filled with new developments first, or prepared potential layers (i.e., potentialCutblocks). | <https://drive.google.com/file/d/1v7MpENdhspkWxHPZMlmx9UPCGFYGbbYm/view?usp=sharing> |
| disturbanceParameters | data.table | Table with the following columns: dataName –\> this column groups the type of data by sector (i.e., Energy, Settlements, OilGas, Mining, Forestry, Roads)dataClass –\> this column details the type of data ALWAYS with ‘potential’ starting (i.e., potentialSettlements potentialWindTurbines, potentialCutblocks, etc.)can harmonize different ones. Potential data classes can be of three general disturbanceType (see below)disturbanceType –\> Potential data classes can be of three general types:1. Enlarging (i.e., potentialSettlements and potentialSeismicLines): where the potential one is exactly the same as the current layer, and we only buffer it with time2. Generating (i.e., potentialWindTurbines, potentialOilGaspotentialMineral, potentialForestry): where the potential layers are only the potential where structures can appear based on a specific rate3. Connecting (i.e., potentialPipelines, potentialTransmission, potentialRoads incl. forestry ones): where the potential layer needs to have the current/latest transmission, pipeline, and road network. This process will depend on what is generated in point 2.disturbanceRate –\> what is the rate of generation for disturbances PER YEAR in % of type Enlarging and Generating. For disturbances type Connecting, disturbanceRate is NA. If not specified when needed, the module will try to derive it from data.disturbanceSize –\> if there is a specific size the disturbance in m2 type Generating should have, it is specified here. If not specified, the module will try to derive it from data. For disturbances type Enlarging anb Connecting, disturbanceSize is NA.If not specified when needed, the module will try to derive it from data.disturbanceOrigin –\> dataClass that should be used as the ‘original’ to be either modified (i.e., Enlarging, Generating) or as origin point for Connecting types.disturbanceEnd –\> end points for Connecting layers (i.e., newly created windTurbines: connect into powerLines, newly created windTurbines: connect into roads, newly created oilGas: connect into pipeline, newly created oilGas: connect into roads, newly created settlements: connect into roads, newly created mines: connect into roadsnewly created cutblocks: connect into roads)disturbanceInterval –\> interval for which this disturbance should happen resolutionVector –\> original resolution of the data that generated this vector It defaults to an example in the Northwest Territories and needs to be provided if the study area is not in this region (i.e., union of BCR6 and NT1) | <https://drive.google.com/file/d/1Y7_3qjq8VQ1xPdii5RMCDp2RxgQ1E-4T/view?usp=sharing> |
| disturbanceDT | data.table | This data.table needs to contain the following columns: dataName –\> this column groups the type of data by sector (i.e., Energy, Settlements, OilGas, Mining, Forestry, Roads)URL –\> URL link for the specific datasetclassToSearch –\> exact polygon type/class to search for when picking from a dataset with multiple types. If this is not used (i.e., your shapefile is alreday all the data needed), you should still specify this so each entry has a different namefieldToSearch –\> where should classToSearch be found? If this is specified, then the function will subset the spatial object (most likely a shapefile) to classToSearch. Only provide this if this is necessary!dataClass –\> this column details the type of data further (i.e., Settlements, potentialSettlements otherPolygons, otherLines, windTurbines, potentialWindTurbines, hydroStations, oilFacilities, pipelines, etc). Common class to rename the dataset to, so we can harmonize different ones. Potential data classes can be of three general types (that will be specified in the disturbanceGenerator module as a parameter – ALWAYS with ‘potential’ starting): 1. Enlarging (i.e., potentialSettlements and potentialSeismicLines): where the potential one is exactly the same as the current layer, and we only buffer it with time2. Generating (i.e., potentialWind, potentialOilGaspotentialMineral, potentialForestry): where the potential layers are only the potential where structures can appear based on a specific rate3. Connecting (i.e., potentialPipelines, potentialRoads incl. forestry ones): where the potential layer needs to have the current/latest transmission, pipeline, and road network. This process will depend on what is generated in point 2.fileName –\> If the original file is a .zip and the features are stored in one of more shapefiles inside the .zip, please provide which shapefile to be useddataType –\> please provide the data type of the layer to be used. These are the current accepted formats: ‘shapefile’ (.shp or .gdb), ‘raster’ (.tif, which will be converted into shapefile), and ‘mif’ (which will be read as a shapefile).It defaults to an example in the Northwest Territories and needs to be provided if the study area is not in this region (i.e., union of BCR6 and NT1) | <https://drive.google.com/file/d/1wHIz_G088T66ygLK9i89NJGuwO3f6oIu/view?usp=sharing> |
| studyArea | SpatVector | Study area to which the module should be constrained to. Defaults to NT1+BCR6. Object can be of class ‘vect’ from terra package | <https://drive.google.com/file/d/1RPfDeHujm-rUHGjmVs6oYjLKOKDF0x09/view?usp=sharing> |
| rasterToMatch | SpatRaster | All spatial outputs will be reprojected and resampled to it. Defaults to NT1+BCR6. Object can be of class ‘rast’ from terra package | <https://drive.google.com/file/d/11yCDc2_Wia2iw_kz0f0jOXrLpL8of2oM/view?usp=sharing> |
| rstCurrentBurn | SpatRaster | A binary raster with 1 values representing burned pixels. This raster is normally produced by either the module historicFires or a fire simulation module (i.e., fireSense, SCFM, LandMine) | NA |
| DisturbanceRate | data.table | Rate of change (disturbance) increase over the study area per year. Defaults to calculating the disturbance (ECCC data) over the entire area per year, if totalDisturbanceRate is not provided. Needs to have:dataName: settlements, oilGas, oilGas, mining, forestry, EnergydataClass: potentialSettlements, potentialSeismicLines, potentialOilGas,potentialMining, potentialCutblocks, potentialWindTurbinesdisturbanceType: Enlarging or Generating (see disturbanceDT object for details)disturbanceOrigin: settlements, seismicLines, oilGas, mining, cutblocks, windTurbinesdisturbanceRate: representing a % of the study area to be newly disturbed per year | NA |
| DEM | SpatRaster | Elevation map of the study area. If not provided, it uses as default the DEM (`elavation_30()`) from the geodata R package. | NA |
| featuresToAvoid | SpatRaster | Raster map of the study area with areas to avoid (i.e., water, wetlands, mountaintops) for linear feature building (excluding seismic lines). If not provided, it uses as default data from the geodata R package. Only used if maskWaterAndMountainsFromLines == TRUE | NA |

This module exposes many parameters controlling generation, clustering,
and data-derived rate calculation. The complete, current list (with
defaults and descriptions) is generated directly from the module
metadata:

| paramName | paramClass | default | min | max | paramDesc |
|:---|:---|:---|:---|:---|:---|
| .plots | character | screen | NA | NA | Used by Plots function, which can be optionally used here |
| .plotInitialTime | numeric | 0 | NA | NA | Describes the simulation time at which the first plot event should occur. |
| .plotInterval | numeric | NA | NA | NA | Describes the simulation time interval between plot events. |
| .saveInitialTime | numeric | NA | NA | NA | Describes the simulation time at which the first save event should occur. |
| .saveInterval | numeric | NA | NA | NA | This describes the simulation time interval between save events. |
| .seed | list |  | NA | NA | Named list of seeds to use for each event (names). |
| .useCache | logical | FALSE | NA | NA | Should caching of events or module be used? |
| runInterval | numeric | 10 | NA | NA | Should the module be run every decade? This speeds up module testing as testing if the events need to be run at every time is time-consuming. If the user knows the disturbances happen every X years, X can be passed here. |
| saveInitialDisturbances | logical | TRUE | NA | NA | Should the disturbance rasters be saved at each step? These are saved to Paths\[\[‘outputPath’\]\] as a RasterLayer, with disturbanceLayer as prefixthe name of the industry and the year as suffix.If TRUE, it saves the initial conditions (IC) |
| generatedDisturbanceAsRaster | logical | FALSE | NA | NA | Should the new disturbances generated be in raster format? This has potential downsides regarding size of disturbances generated (i.e., minimum size possible is the resolution of raster) |
| checkDisturbancesForBuffer | logical | FALSE | NA | NA | Should the module check the recently generated disturbances? This means that the module will buffer the recently disturbed layer and compare it to the previous layer, outputting a message indicating how much of the total area this represents. Note that no objects are created, just the message is outputted. |
| disturbFirstYear | logical | FALSE | NA | NA | Should disturbances be generated already in the initial year? Normally, we would save the initial disturbances (i.e., 2011) as they are coming from data, and only start generating disturbances once we don’t have the data(i.e., post-2015). So this defaults to FALSE.If TRUE, it will already generate disturbances in start(sim) |
| saveCurrentDisturbances | logical | TRUE | NA | NA | Should the disturbance rasters be saved at each step? These are saved to Paths\[\[‘outputPath’\]\] as a RasterLayer, with disturbanceLayer as prefixthe name of the industry and the year as suffix.If TRUE, it saves at the end of each step. |
| disturbanceRateRelatesToBufferedArea | logical | TRUE | NA | NA | Is the DisturbanceRate a % of already buffered (to 500m) disturbance? This is normally what is used for caribou. Seismic lines generation always use buffered-area accounting regardless of this flag. |
| growthStepEnlargingPolys | numeric | 1 | NA | NA | Growth step used for iteratively achieving the total area growth of new disturbances type Enlarging for polygons. If the iterations take too long, one should increase this number. If the summarized value is too far from 0, one should decrease this number. |
| growthStepGenerating | numeric | 0.5 | NA | NA | Increasing factor to speed up total area of new disturbances type Generating. If the iterations take too long, one should increase this number. If the summarized value is too far from 0, one should decrease this number. Not used if disturbanceRateRelatesToBufferedArea == TRUE |
| growthStepEnlargingLines | numeric | NA | NA | NA | Growth step used for iteratively achieving the total area growth of new disturbances type Enlarging for lines. Defaults to NA, which lets the module estimate a reasonable step (notably for seismic clustering). If the iterations take too long, set a larger fixed value; if the summarized value is too large, set a smaller fixed value. |
| connectingBlockSize | numeric |  | NA | NA | connectingBlockSize defaults to NULL. It is used to connecting layers after generation. Applying blocking technique speeds up disturbance. If too high, many lines might connect from the same place. Decreasing the parameter connectingBlockSize or setting it to NULL, will improve |
| .runName | character | run1 | NA | NA | If you would like your simulations’ results to have an appended name (i.e., replicate number, study area, etc) you can use this parameter |
| seismicLineGrids | numeric |  | NA | NA | How many grids concomitantly should the model produce when creating seismic lines? Defaults to NULL, which auto-estimates a value from seismic lines in the study area together with seismic rates and their run interval. If seismic disturbance is being produced over the expected amount, please provide smaller values. |
| .inputFolderFireLayer | character | /tmp/Rtm…. | NA | NA | If you have the fire (i.e., rstCurrBurn) in a folder that is NOT the inputs folder, you can pass it here |
| totalDisturbanceRate | numeric |  | NA | NA | If passed, the module will use ECCC data to calculate the % each disturbance should represent to achieve (as close as possible) the total expected disturbance rate. Mainly used for early in simulations, when value ranges are unknown. |
| aggregateSameDisturbances | logical | TRUE | NA | NA | If TRUE, when using ECCC data to calculate disturbance rates, it aggregates the features that have the same class and dissolves their boundaries. This may influence disturbance rate calculations especially if disturbanceRateRelatesToBufferedArea = TRUE (i.e., overlapping disturbances from the same class will be double counted if aggregateSameDisturbances = FALSE) If DisturbanceRate is provided, this parameter is ignored. |
| maskOutLinesFromPolys | logical | TRUE | NA | NA | If TRUE, when using ECCC data to calculate disturbance rates, it masks out the lines from polygons when these overlap (i.e., more likely when disturbanceRateRelatesToBufferedArea = TRUE). This may influence disturbance rate calculations as these will be double counted if FALSE). If DisturbanceRate is provided, this parameter is ignored. |
| useRoadsPackage | logical | FALSE | NA | NA | If TRUE, uses the roads package to connect all disturbances. It is very slow when area is bigger and does NOT work with generatedDisturbanceAsRaster = TRUE nor connectingBlockSize != NULL). |
| siteSelectionAsDistributing | character | seismicLines | NA | NA | Informs which disturbance should NOT be of type ‘exhausting’: exhausts the area available for new disturbances sequentially, from the most to the least likely. Provided classes will be used with ‘distributing’ to probabilistically select which polygon (i.e., area) the provided disturbance will fall within.There is speed tradeoff in using ‘exhausting’, and ‘disturbing’. While distributing is more accurate, exhausting is likely a good option for uncommon (i.e., windpower), or specific (i.e., forestry, mining, oil facilities) disturbances, which likely won’t cover the whole extent of the area. ‘distributing’ is slower but might be morerealistic for disturbances which have the potential of overtaking an area (i.e., seismic lines). Defaults to NA but can take any of the disturbanceOrigin from the input disturbanceParameters (i.e., oilGas,mining, cutblocks, windTurbines, seismicLines) |
| probabilityDisturbance | list |  | NA | NA | Informs to disturbances passed on siteSelectionAsDistributing the probability of each specific polygon being chosen. If passed, needs to be a list 2-column data.table with names ‘Potential’and ’probPoly’ with Potential matching disturbance ORIGIN from disturbanceParameters and probPoly matching the probabilities for each polygon (generally higher values are more likely to have disturbances happening). Defaults to NULL, which is time consuming, but calculates it automatically from data. |
| maskWaterAndMountainsFromLines | logical | TRUE | NA | NA | If TRUE, masks out steep mountain tops and water (i.e., lakes and rivers)from map, so linear features (i.e., transmission lines and roads) don’tcross these |
| altitudeCut | numeric | 550 | NA | NA | If TRUE, max altitude (in meters) to mask mountain topsfrom map, so linear features (i.e., transmission lines and roads) don’tcross theseOnly used if maskWaterAndMountainsFromLines == TRUE |
| clusterDistance | numeric | 1000 | NA | NA | Used for grouping seismic lines to identify grid characteristics (i.e., lines length, distances, number of lines)Increasing this number likely speeds up the simulation, but may have some compromising with accuracy. Reducing the number also makes seismic lines closer to each otherOnly used if useClusterMethod = TRUE |
| distanceNewLinesFactor | numeric | 1.5 | NA | NA | Used for getting distance threshold for new lines from a center point.The higher, the more distant the lines are allowed to be. It is a factor of clusterDistance(i.e., clusterDistance distanceNewLinesFactor = max distance)Reducing the number also makes seismic lines closer to each otherOnly used if useClusterMethod = TRUE |
| useClusterMethod | logical | TRUE | NA | NA | If want to use clusters to identify seismic lines grouping, TRUE.This alternative generates lines more similar to satellite data, although attention needs to be paid to the fact that satellite data for seismic lines is flawed (i.e., misses a lot of lines due to resolution) |
| runClusteringInParallel | logical | FALSE | NA | NA | If TRUE, runs clusters’ analysis in parallel (within the most internal for loop). This may be slower depending on amount of data |
| maxClusterCores | numeric | NA | NA | NA | Max cores for the parallel line-clustering (when runClusteringInParallel is TRUE). NA = parallelly::availableCores(constraints = ‘connections’). Cap this to prevent nesting under targets branching (reps x scenarios). |
| refinedStructure | logical | FALSE | NA | NA | If TRUE, it tries to copy the structure of the line clusters for seismic lines (if useClusterMethod = TRUE). While this slows down runtime, the final linear structure is generated very similarly (butwith randomness to the structure of original lines in terms of number of parallel and perpendicular lines. |
| diffYears | character | 2010_2015 | NA | NA | Suffix indicating the years compared for thedifference calculation of disturbances rate. Needs to be in the format OLDYEAR_NEWYEAR |
| verboseDiagnostics | logical | FALSE | NA | NA | If TRUE, prints a per-class diagnostics table each decade with origin/potential presence, rate and size flags to help debug gating. |
| archiveNEW | character | ECCC_201…. | NA | NA | Filename of the newer archive dataset (zip file). |
| targetFileNEW | character | BEADline…. | NA | NA | Vector of target filenames within the newer archive to be extracted. |
| urlNEW | character | <https://>…. | NA | NA | URL to download the newer dataset archive. |
| archiveOLD | character | Boreal-e…. | NA | NA | Filename of the older archive dataset (zip file). |
| targetFileOLD | character | EC_borea…. | NA | NA | Vector of target filenames within the older archive to be extracted. |
| urlOLD | character | <https://>…. | NA | NA | URL to download the older dataset archive. |

Note `runClusteringInParallel` (default `FALSE`) enables parallel line
clustering; when enabled, `maxClusterCores` caps the number of workers
so the module cannot over-subscribe cores when nested under `targets`
branching.

### Events

The core events are:

1.  `calculatingSize`: if disturbance sizes are not supplied in
    `disturbanceParameters`, uses current disturbance data to estimate
    the mean and variation of each type’s size, later drawn from a
    normal distribution;
2.  `calculatingRate`: if disturbance growth rates are not supplied,
    derives them – using the 2010 and 2015 human-footprint datasets to
    compute a 5-year growth rate per type – and applies the result in
    `generatingDisturbances`;
3.  `generatingDisturbances`: the core event (`generateDisturbances()`).
    It sizes the study area, masks current disturbances, then (a) grows
    Enlarging types by buffering existing features, (b) generates
    Generating types by iteratively selecting the highest-potential
    areas (from the potential rasters) until the target rate is met,
    and (c) connects new features to linear networks (roads, power
    lines). It rasterizes and merges results so already-chosen pixels
    are unavailable next iteration. Reschedules every `runInterval`;
4.  `updatingDisturbanceList`: incorporates the new roads/power lines,
    adds the generated disturbances to the current ones, and replaces
    enlarged settlements and seismic lines with their buffered versions.
    Reschedules every `runInterval`.

`init` validates inputs and schedules the events; a `plot` event runs on
the `.plotInitialTime`/`.plotInterval` schedule.

### Plotting

The `plot` event routes a disturbance-presence map through
`SpaDES.core::Plots()`. It rasterizes the current disturbance layers to
a presence raster over the study area and draws it with
`tidyterra`/`ggplot2` (viridis fill with the study-area outline),
writing the figure(s) to the module’s figures path and registering them
as outputs.

### Saving

When `saveInitialDisturbances = TRUE` and/or
`saveCurrentDisturbances = TRUE`, per-step disturbance rasters are
written to `Paths[["outputPath"]]` (prefixed by sector name and suffixed
by year) and registered via `SpaDES.core::registerOutputs()` so
`targets` tracks them.

### Module outputs

| objectName | objectClass | desc |
|:---|:---|:---|
| disturbanceList | list | Updated list (general category) of lists (specific class) of disturbances and the potential needed for generating disturbances. |
| currentDisturbanceLayer | list | List (per year) of rasters with all current disturbances.Can be used for other purposes but was created to filter potential pixels that already have disturbances to avoid choosing new pixels in existing disturbed ones |

`disturbanceList` is the updated list of current + potential
disturbances; `currentDisturbanceLayer` is a per-year list of rasters of
all current disturbances, used to filter pixels already disturbed.

### Links to other modules

Part of the anthropogenic-disturbance module collection, run after
`anthroDisturbance_DataPrep` and (optionally)
`potentialResourcesYT_DataPrep`. `rstCurrentBurn` is typically supplied
by a fire module (e.g., `scfm`). The collection combines with
landscape-simulation modules (e.g., `Biomass_core`) and caribou modules
to improve realism in forecasts.

### Getting help

- <https://github.com/FOR-CAST/anthroDisturbance_Generator/issues>
