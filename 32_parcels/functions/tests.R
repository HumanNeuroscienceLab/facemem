library(testthat)
library(plyr)

#--- searchlight ---#


test_that("
Given dimensions of the data
When I call `node_neighbors`
Then I should get the offsets of a node to get the neighbors
", {
  # GIVEN
  dims <- c(10,9,11)
  
  # WHEN
  orig.offsets <- node_neighbors(dims)
  
  # THEN
  ## get offsets other way
  arr  <- array(1:prod(dims), dims)
  offsets <- expand.grid(list(x=-1:1, y=-1:1, z=-1:1))
  crd <- c(5,5,5)
  nei.crds <- sapply(1:nrow(offsets), function(i) {
    nei.crd <- as.integer(offsets[i,] + crd)
    arr[nei.crd[1],nei.crd[2],nei.crd[3]]
  })
  center.ind <- which(rowSums(abs(offsets))==0)
  ref.offsets <- nei.crds - nei.crds[center.ind]
  
  ## compare
  expect_that(orig.offsets, equals(ref.offsets))
})

test_that("
Given dimensions of the data
When I call `node_neighbors`
and set include.self to FALSE
Then I should get the offsets of a node to get the neighbors
", {
  # GIVEN
  dims <- c(10,9,11)
  
  # WHEN
  orig.offsets <- node_neighbors(dims, include.self=FALSE)
  
  # THEN
  ## get offsets other way
  arr  <- array(1:prod(dims), dims)
  offsets <- expand.grid(list(x=-1:1, y=-1:1, z=-1:1))
  crd <- c(5,5,5)
  nei.crds <- sapply(1:nrow(offsets), function(i) {
    nei.crd <- as.integer(offsets[i,] + crd)
    arr[nei.crd[1],nei.crd[2],nei.crd[3]]
  })
  center.ind <- which(rowSums(abs(offsets))==0)
  ref.offsets <- nei.crds - nei.crds[center.ind]
  ref.offsets <- ref.offsets[-center.ind]
  
  ## compare
  expect_that(orig.offsets, equals(ref.offsets))
})

# test that
# find_neighbors(dims, mask=NULL, nei.opt=1:3, verbose=FALSE, parallel=FALSE) 

test_that("
  Given dimensions of the data
  and the node offsets
  When I call `find_neighbors`
  and set all nearest neighbors (nei.opt=3)
  Then I should get a list of nearest neighbors for each node
", {
  # GIVEN
  dims <- c(10,12,11)
  #orig.offsets <- node_neighbors(dims+2, include.self=FALSE) # pad dims
  
  # WHEN 
  orig.lst_neis <- find_neighbors(dims, nei.opt=3)
  
  # THEN
  ## get list another way
  orig_arr  <- array(1:prod(dims), dims)
  arr <- array(NA, dims+2) # pad array
  arr[ (1:dims[1])+1, (1:dims[2])+1, (1:dims[3])+1 ] <- orig_arr
  crds <- expand.grid(list(x=(1:dims[1])+1, y=(1:dims[2])+1, z=(1:dims[3])+1))
  offsets <- expand.grid(list(x=-1:1, y=-1:1, z=-1:1))
  center.ind <- which(rowSums(abs(offsets))==0)
  ref.lst_neis <- lapply(1:nrow(crds), function(ci) {
    nei.crds <- sapply(1:nrow(offsets), function(i) {
      nei.crd <-  as.integer(crds[ci,]) + as.integer(offsets[i,])
      arr[nei.crd[1],nei.crd[2],nei.crd[3]]
    })
    nei.crds <- nei.crds[-center.ind]
    nei.crds <- nei.crds[!is.na(nei.crds)]
#    nei.crds <- nei.crds[nei.crds>0]
    nei.crds
  })
  
  ## compare
  expect_that(orig.lst_neis, equals(ref.lst_neis))
})

#test_that("
#  Given dimensions of the data
#  and a mask
#  When I call `find_neighbors_masked`
#  and set all nearest neighbors (nei.opt=3)
#  Then I should get a list of nearest neighbors for each node in the mask
#", {
#  # GIVEN
#  dims <- c(10,12,11)
#  mask <- vector("logical", prod(dims))
#  mask[sample(prod(dims), 100)] <- T
#  
#  # WHEN
#  orig.lst_neis <- find_neighbors_masked(mask, dims, nei.opt=3)
#  
#  
#})