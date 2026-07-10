wrapTerraList <- function(terraList, generalPath, zipFiles = FALSE, uploadZip = NULL){
  
  if (!is.list(terraList)) stop("terraList must be a list")
  if (length(terraList)==0) return(list())
  
  listNames <- lapply(1:length(names(terraList)), function(index1){
    obj <- lapply(1:length(names(terraList[[index1]])), function(index2){
      # message(paste0("Saving ", names(terraList[[index1]][[index2]]), "\n"))
      obj2 <- terra::wrap(terraList[[index1]][[index2]])
      repeat {
        candidate <- paste0(stringi::stri_rand_strings(1,10), ".qs2")
        fileName <- file.path(generalPath, candidate)
        if (!file.exists(fileName)) break
      }
      qs2::qs_save(obj2, fileName)
      return(fileName)
    })
    names(obj) <- names(terraList[[index1]])
    return(obj)
  })
  names(listNames) <- names(terraList)
  if (zipFiles) {
    # Need to save the files together with the list
    qs2::qs_save(listNames, file = file.path(generalPath, "theList.qs2"))
    allFls <- c(file.path(generalPath, "theList.qs2"), 
                unlist(listNames, use.names = FALSE))
    zip::zip(zipfile = file.path(generalPath, "disturbanceList.zip"), 
        files = allFls)
    message(paste0("disturbanceList zipped to ", file.path(generalPath, "disturbanceList.zip")))
    if (!is.null(uploadZip)) {
      googledrive::drive_upload(media = file.path(generalPath, "disturbanceList.zip"), 
                   path = googledrive::as_id(uploadZip))
      message(paste0("disturbanceList uploaded to ", uploadZip))
    } 
  }
  return(listNames)
}

unwrapTerraList <- function(terraList, generalPath){
  
  if (is.list(terraList) && length(terraList) == 0) {
    warning("No items to unwrap. Returning empty list.")
    return(list())
  }
  
  updatePath <- FALSE
  if (all(!is.list(terraList),
          !file.exists(file.path(generalPath, "theList.qs2")))) {
    message(paste0("The terraList file provided seems to be a google drive link. The contents will be",
                   " downloaded and extracted before recovering."))
    # If we pass a URL for the file instead of a list, then first we need to download
    # the file, unzip, and then we update the terraList with the unzipped file theList.qs
    googledrive::drive_download(file = googledrive::as_id(terraList), path = file.path(generalPath, "disturbanceList.zip"))
    unzip(zipfile = file.path(generalPath, "disturbanceList.zip"), 
          exdir = generalPath, 
          junkpaths = TRUE)
    terraList <- qs2::qs_read(file.path(generalPath, "theList.qs2"))
    updatePath <- TRUE
  } else {
    if (all(!is.list(terraList),
            file.exists(file.path(generalPath, "theList.qs2")))){
      # When the path to the object is being passed
      terraList <- qs2::qs_read(file.path(generalPath, "theList.qs2"))
      updatePath <- TRUE
    } else {
      # When the object is directly being passed
      updatePath <- TRUE
    }
  }
  listNames <- lapply(1:length(names(terraList)), function(index1){
    obj <- lapply(1:length(names(terraList[[index1]])), function(index2){
      message(paste0("Recovering ", names(terraList[[index1]][[index2]])))
      if (updatePath){
        print(paste0("terraList was a link. Fixing paths for ", index2))
        pth <- dirname(terraList[[index1]][[index2]])
        terraList[[index1]][[index2]] <- gsub(x = terraList[[index1]][[index2]],
                                              pattern = pth,
                                              replacement = generalPath)
      }
      obj2 <- qs2::qs_read(terraList[[index1]][[index2]])
      return(terra::vect(obj2))
    })
    names(obj) <- names(terraList[[index1]])
    return(obj)
  })
  names(listNames) <- names(terraList)
  return(listNames)
}

