#' Neighbors for a node
#'
#' Returns the relative indices of neighbors for a node
#'
#' Given a node at the origin, gives the (vector) coordinates of the 
#' neigbouring nodes. Distance of the neighbors is specified by the user.
#'
#' @params dims dimension of array
#' @params nei maximum value for dimensions in x,y,z axis
#' @params nei.dist maximum euclidean distance of neighbor
#'
#' @return vector of offsets relative to the node giving the neighbors
#' 
#' @examples
#' dims <- c(10,12,9)
#' offsets <- node_neighbors(dims)
#' offsets <- node_neighbors(dims, include.self=TRUE)
node_neighbors <- function(dims, nei=1, nei.dist=2, include.self=TRUE) {
	# What are the neighbors for a given node?
    # moffsets gives these neighbors in ijk form
    moffsets    <- expand.grid(list(i=-nei:nei, j=-nei:nei, k=-nei:nei))
    dist        <- sqrt(rowSums(moffsets^2))
    moffsets    <- moffsets[dist<=nei.dist,]
    # offsets gives these neighbors in vector index form
    offsets     <- moffsets$k*dims[1]*dims[2] + moffsets$j*dims[1] + moffsets$i
    if (!include.self) 
	    offsets     <- offsets[offsets!=0]
	return(offsets)
}

#' Find the neighbors for each node in a 3D dataset
#' 
#' Returns a list of neighbors for each node within a mask
#'
#' For each node, a vector of indices to the neighbors are returned.
#'
#' If a mask is provided, any nodes not in the mask will be marked as NA and 
#' neighbors of a node not in the mask will be removed. If a node has no 
#' neighbors, the value of that node will also be marked as NA.
#'
#' @param dims dimensions of the dataset
#' @param mask optional mask of dataset
#' @param nei.opt the number of neighbors to include. 1 = faces touching or 8 
#'  voxels; 2 = faces/corners touching or 16 voxels; 3 = faces/corners/edges 
#'  touching. (default: 1)
#' @param prop.nei minimum proportion of neighbors needed (prop.nei=0)
#' @param verbose more helpful output (default: FALSE)
#' @param parallel to use parallel processing (assuming something like doMC is set already)
#' 
#' @export
#' 
#' @return list
#' 
#' @examples
#' lst_neis <- find_neighbors(c(10,12,11), nei.opt=3)
#' 
find_neighbors <- function(dims, mask=NULL, nei.opt=1:3, prop.nei=0, verbose=FALSE, parallel=FALSE) 
{
  if (verbose) {
    progress <- "text"
  } else {
    progress <- "none"
  }
  
  #--- mask ---#
  
  if (is.null(mask)) {
    mask    <- rep(T, prod(dims))
  } else {
    mask    <- as.vector(mask)
    if (length(mask) != prod(dims)) stop("length(mask) doesn't match prod(dims)")
  }
  
  #--- pad ---#
  
  # pad the data by at least 1 on each side to deal with edge voxels
  # have a mask.pad that allows to map from padded to unpadded dataset
  
  pad <- 1 # later we can adjust this for larger searchlights
  nx <- dims[1]; ny <- dims[2]; nz <- dims[3]
  
  mask.pad <- array(F, c(nx+pad*2, ny+pad*2, nz+pad*2))
  mask.pad[(pad+1):(pad+nx), (pad+1):(pad+ny), (pad+1):(pad+nz)] <- T
  nx <- dim(mask.pad)[1]; ny <- dim(mask.pad)[2]; nz <- dim(mask.pad)[3]
  mask.pad <- as.vector(mask.pad)
  tmp <- rep(F, length(mask.pad))
  tmp[mask.pad] <- mask
  mask <- tmp
  rm(tmp)
  
  pdims     <- dims + pad*2
  nnodes    <- prod(pdims)
  pad_inds  <- which(mask.pad)
  unpad_inds<- vector("integer", nnodes)
  unpad_inds[pad_inds] <- 1:sum(mask.pad)
  
  #--- neighbors ---#
  nei       <- 1  # radius of sphere/box to look for neighbors in
  nei.dist  <- c(1,1.5,2)[nei.opt[1]]  # maximum euclidean distance from node
  offsets   <- node_neighbors(pdims, nei, nei.dist, include.self=FALSE)
  min.nei   <- round(length(offsets) * prop.nei)
  
  #--- all node neighbors ---#
  ## for a given node
  ## 1. we get the neighboring indices
  ## 2. and ensure that the indices aren't outside the box
  ## 3. and ensure that the indices are within the brain mask
  ## 4. and get indices if there were no padding
  max_ind     <- length(mask) + 1
  node_neis   <- llply(pad_inds, function(node_ind) {
    if (mask[node_ind]) {
      nei_inds <- offsets + node_ind # 1.
      nei_inds <- nei_inds[nei_inds > 0 & nei_inds < max_ind] # 2.
      nei_inds <- nei_inds[mask[nei_inds]] # 3.
      nei_inds <- unpad_inds[nei_inds] # 4.
	    if (length(nei_inds) <= min.nei) nei_inds <- NA
      return(nei_inds)
    } else {
      return(NA)
    }
  }, .progress=progress, .parallel=parallel)
  
  return(node_neis)
}

# output, list with each element giving the neighbors
# first get full list
# second mask the list and mask each neighbor indices and replace with the mask indices; you would need to deal with the case of having no neighbors

#' Find the neighbors for each node in a masked 3D dataset
#' 
#' Returns a list of neighbors for each node within a mask
#' 
#' Neighbors are indices in a masked array. This function combines 
#' `find_neighbors` with `neighbors_array2mask`.
#' 
#' @params mask mask of data (must be an array if not setting dims, otherwise vector is ok)
#' @params dims dimensions of data (default: dimensions of mask)
#' @param nei.opt the number of neighbors to include. 1 = faces touching or 8 
#'  voxels; 2 = faces/corners touching or 16 voxels; 3 = faces/corners/edges 
#'  touching. (default: 1)
#' @param prop.nei minimum proportion of neighbors needed (prop.nei=0)
#' @param verbose more helpful output (default: FALSE)
#' @param parallel to use parallel processing (assuming something like doMC is set already)
#' 
#' @export
#' 
#' @return list
find_neighbors_masked <- function(mask, dims=dim(mask), nei.opt=1:3, prop.nei=0, verbose=FALSE, parallel=FALSE)
{
  # Get the neighbors of the node in the full array
  node_neis <- find_neighbors(dims, mask, nei.opt, prop.nei, verbose, parallel)
  
  # Convert node indices to be masked
  node_neis_masked <- neighbors_array2mask(node_neis, mask)
  
  return(node_neis_masked)
}

#' Converts nodes in a list to indexing elements withing mask
#' 
#' Returns a new list of neighbors for each node where the neighbors are indices in a masked array
#' 
#' @params node_neis list of neighbors for each node (e.g., from `find_neighbors`)
#' @params mask logical vector of node indices to use
#'
#' @export
#' 
#' @return list
neighbors_array2mask <- function(node_neis, mask) {
  mask <- as.vector(mask)
  
  # First, exclude any nodes not in mask
  node_neis_masked <- node_neis[mask]
  
  # Second, change the index of the neighbors for each node
  arr2mat_inds    		<- mask*1
  arr2mat_inds[mask]  <- 1:sum(mask)
  node_neis_masked    <- lapply(node_neis_masked, function(x) arr2mat_inds[x])
  
	return(node_neis_masked)
}

#' Perform searchlight analysis
#'
#' Returns vector of searchlight results
#'
#' Applies some function to each node and it's surrounding neighbors
#'
#' @params fun function to apply to each searchlight
#' @params data 2D functional data (ntpts x nregions)
#' @params mask brain mask or something else to constrain nodes/neighbors examined
#' @params include.self for each searchlight, do you include the principal or center node
#' @param nei.opt the number of neighbors to include. 1 = faces touching or 8 
#'  voxels; 2 = faces/corners touching or 16 voxels; 3 = faces/corners/edges 
#'  touching. (default: 1)
#' @params prop.nei the proportion/percentage of neighboring nodes that must exist (default=0.25)
#' @param verbose more helpful output (default: FALSE)
#' @param parallel to use parallel processing (assuming something like doMC is set already)
#'
#' @export
#'
#' @return vector
searchlight <- function(fun, data, mask, 
                        include.self=TRUE, nei.opt=1:3, prop.nei=0.25, 
                        verbose=FALSE, parallel=FALSE, ...) 
{
  progress	<- ifelse(verbose, "text", "none")

  # Find the neighbors for each node within your mask
  node_neis <- find_neighbors_masked(mask, dim(mask), nei.opt, prop.nei, verbose, parallel)
  
  # Apply function
  sl_res <- laply(1:length(node_neis), function(i) {
      neis <- node_neis[[i]]
      if (is.na(neis)) {
          return(0)
      } else if (include.self) {
          return(fun(data[,c(i,neis)], ...))
      } else {
          return(fun(data[,neis], ...))
      }
  }, .progress=progress, .parallel=parallel)
  
  return(sl_res)
}
