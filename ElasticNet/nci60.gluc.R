library(gdata)
library(shiny)
library(parallel)
library(matrixStats)
library(glmnet)
library(data.table)

source("../R/elnetFit.R")
source("R/drugResponseProcess/extract.drugmat.nci60.R")

slist <- readRDS("Res/20170110_mq15processLOD2/sites.gluC.RDS")

sapply(drug.nci60, dim)
cbind(colnames(slist$nci60_idtype), colnames(drug.nci60$dtp.gi50))

runMod <- function( drugMat, sites, regsitesOnly = FALSE) {# the drug matrix, rows are drugs columns are samples
  
  if (! identical(gsub("_NCI60", "", colnames(drugMat)), colnames(sites$nci60_expr)))
    stop("check columns order.")
  
  fit <- list()
  for (i in 1:nrow(drugMat)) {
    print(i)
    gi50 <- drugMat[i, ]
    iSample <- !is.na(gi50)
    
    if (sum(iSample) < 12) {
      fit[[i]] <- NA
      next()
    }
    
    ixmat <- sites$fun_prepElnet(x = sites, celllines = iSample, 
                                 regsitesOnly = regsitesOnly)
    fit[[i]] <- try(elnetFit(t(ixmat$imputed), 
                             y = gi50[iSample], 
                             standardizex = TRUE,
                             nboot = 100, 
                             permpvalue = 0, 
                             x.na.index = t(ixmat$na_index),
                             times=1, 
                             cores = 26, 
                             write.table = FALSE) )
  }
  names(fit) <- rownames(drugMat)
  list(fit=fit, mat=ixmat)
}

## all phospho-sites
ccle <- runMod(drugMat = drug.nci60$ccle.auc, sites = slist)
saveRDS(ccle, file = "Res/20170110_mq15processLOD2/nci60.ccle.allsites.gluc.RDS")
# 
# dtp <- runMod(drugMat = drug.nci60$dtp.gi50, sites = slist)
# saveRDS(dtp, file = "Res/20170110_mq15processLOD2/nci60.dtp.allsites.gluc.RDS")
# 
gdsc <- runMod(drugMat = drug.nci60$gdsc.auc, sites = slist)
saveRDS(gdsc, file = "Res/20170110_mq15processLOD2/nci60.gdsc.allsites.gluc.RDS")

ctrp <- runMod(drugMat = drug.nci60$ctrp.auc, sites = slist)
saveRDS(ctrp, file = "Res/20170110_mq15processLOD2/nci60.ctrp.allsites.gluc.RDS")

## regulatory sites only
##
ccle.rs <- runMod(drugMat = drug.nci60$ccle.auc, sites = slist, regsitesOnly = TRUE)
saveRDS(ccle.rs, file = "Res/20170110_mq15processLOD2/nci60.ccle.regsites.gluc.RDS")

# dtp.rs <- runMod(drugMat = drug.nci60$dtp.gi50, sites = slist, regsitesOnly = TRUE)
# saveRDS(dtp.rs, file = "Res/20170110_mq15processLOD2/nci60.dtp.regsites.gluc.RDS")

gdsc.rs <- runMod(drugMat = drug.nci60$gdsc.auc, sites = slist, regsitesOnly = TRUE)
saveRDS(gdsc.rs, file = "Res/20170110_mq15processLOD2/nci60.gdsc.regsites.gluc.RDS")

ctrp.rs <- runMod(drugMat = drug.nci60$ctrp.auc, sites = slist, regsitesOnly = TRUE)
saveRDS(ctrp.rs, file = "Res/20170110_mq15processLOD2/nci60.ctrp.regsites.gluc.RDS")

