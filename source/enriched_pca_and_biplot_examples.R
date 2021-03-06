# |------------------------------------------------------------------------------------------------------------|
# | Project: Example of Enriched PCA and Biplot                                                                |
# | Script:  Mixed Effect model                                                                                |
# | Depends: data.table                                                                                        |
# | Author:  Davit Sargsyan                                                                                    | 
# | Created: 02/24/2018                                                                                        |
# | Source:                                                                                                    |
# |------------------------------------------------------------------------------------------------------------|
# Header----
# source("https://bioconductor.org/biocLite.R")
# biocLite("qvalue")
require(data.table)
require(ggplot2)
require(nnet)
require(qvalue)

# Simulate data----
nfeat <- 10
nsubj <- 200
ngrp <- 2
set.seed(2018)
dt1 <- data.table(grp = factor(rep(LETTERS[1:ngrp], nsubj)),
                  id = paste("ID", 1:600, sep = ""),
                  matrix(round(rnorm(nsubj*nfeat*ngrp),
                               3), 
                         ncol = nfeat))
dt1$id <- factor(dt1$id,
                 levels = unique(dt1$id))
DT::datatable(dt1,
              caption = "Data",
              rownames = TRUE,
              options = list(searching = TRUE,
                             pageLength = nrow(dt1)))

# Part I: PCA----
m1 <- prcomp(dt1[, -c(1:2)])
summary(m1)

# Biplot while keep only the most important variables (Javier)----
# Select PC-s to pliot (PC1 & PC2)
choices <- 1:2

# Scores, i.e. points (df.u)
dt.scr <- data.table(m1$x[, choices])
# Add grouping variable
dt.scr$grp <- dt1$grp
dt.scr

# Loadings, i.e. arrows (df.v)
dt.rot <- as.data.frame(m1$rotation[, choices])
dt.rot$feat <- rownames(dt.rot)
dt.rot <- data.table(dt.rot)
dt.rot

dt.load <- melt.data.table(dt.rot,
                           id.vars = "feat",
                           measure.vars = 1:2,
                           variable.name = "pc",
                           value.name = "loading")
dt.load$feat <- factor(dt.load$feat,
                     levels = unique(dt.load$feat))

# Plot loadings
p0 <- ggplot(data = dt.load,
             aes(x = feat,
                 y = loading)) +
  facet_wrap(~ pc,
             nrow = 2) +
  geom_bar(stat = "identity") +
  ggtitle("PC Loadings") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45,
                                   hjust = 1))
p0
tiff(filename = "tmp/pc.1.2_loadings.tiff",
     height = 5,
     width = 8,
     units = 'in',
     res = 300,
     compression = "lzw+p")
print(p0)
graphics.off()

# Axis labels
u.axis.labs <- paste(colnames(dt.rot)[1:2], 
                     sprintf('(%0.1f%% explained var.)', 
                             100*m1$sdev[choices]^2/sum(m1$sdev^2)))
u.axis.labs

# Based on Figure p0, keep only a few variables with high loadings in PC1 and PC2----
# var.keep.ndx <- which(dt.rot$feat %in% c("V1",
#                                          "V4",
#                                          "V6",
#                                          "V7",
#                                          "V8"))
# Or select all
var.keep.ndx <- 3:ncol(dt1)

p1 <- ggplot(data = dt.rot[var.keep.ndx,],
             aes(x = PC1,
                 y = PC2)) +
  coord_equal() +
  geom_point(data = dt.scr,
             aes(fill = grp),
             shape = 21,
             size = 2,
             alpha = 0.5) +
  geom_segment(aes(x = 0,
                   y = 0,
                   xend = 10*PC1,
                   yend = 10*PC2),
               arrow = arrow(length = unit(1/2, 'picas')),
               color = "black",
               size = 1.2) +
  geom_text(aes(x = 11*PC1,
                y = 11*PC2,
                label = dt.rot$feat[var.keep.ndx]),
            size = 5,
            hjust = 0.5) +
  scale_x_continuous(u.axis.labs[1]) +
  scale_y_continuous(u.axis.labs[2]) +
  scale_fill_discrete(name = "Group") +
  ggtitle("Biplot") +
  theme(plot.title = element_text(hjust = 0.5,
                                  size = 20))
p1
tiff(filename = "tmp/pca_biplot.tiff",
     height = 10,
     width = 10,
     units = 'in',
     res = 300,
     compression = "lzw+p")
print(p1)
graphics.off()

# Part II: Enriched PCA----
# mm1 <- multinom(grp ~ V1, data = dt1)
# summary(mm1)
# mm1

res <- list()
for (i in 3:ncol(dt1)) {
  out <- glm(dt1$grp ~ unlist(dt1[, i, with = FALSE]),
             family = "binomial")
  s1 <- summary(out)
  res[[i]] <- s1$coefficients[2, 4]
}
res <- do.call("c", res)
res

# NOTE: small number of p-values requires lambda=0
# Source: https://support.bioconductor.org/p/105623/
qval <- qvalue(p = res,
               lambda = 0)
wgt <- diag(-log(qval$qvalues))
wgt

tmp <- as.matrix(dt1[, -c(1:2)])
tmp

dt2 <- data.table(dt1[, 1:2],
                  tmp%*%wgt)
dt2

m1 <- prcomp(dt2[, -c(1:2)])
summary(m1)

# Biplot while keep only the most important variables (Javier)----
# Select PC-s to pliot (PC1 & PC2)
choices <- 1:2

# Scores, i.e. points (df.u)
dt.scr <- data.table(m1$x[, choices])
# Add grouping variable
dt.scr$grp <- dt1$grp
dt.scr

# Loadings, i.e. arrows (df.v)
dt.rot <- as.data.frame(m1$rotation[, choices])
dt.rot$feat <- rownames(dt.rot)
dt.rot <- data.table(dt.rot)
dt.rot

dt.load <- melt.data.table(dt.rot,
                           id.vars = "feat",
                           measure.vars = 1:2,
                           variable.name = "pc",
                           value.name = "loading")
dt.load$feat <- factor(dt.load$feat,
                       levels = unique(dt.load$feat))

# Plot loadings
p0 <- ggplot(data = dt.load,
             aes(x = feat,
                 y = loading)) +
  facet_wrap(~ pc,
             nrow = 2) +
  geom_bar(stat = "identity") +
  ggtitle("PC Loadings, Enriched PCA") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45,
                                   hjust = 1))
p0
tiff(filename = "tmp/enriched_pc.1.2_loadings.tiff",
     height = 5,
     width = 8,
     units = 'in',
     res = 300,
     compression = "lzw+p")
print(p0)
graphics.off()

# Axis labels
u.axis.labs <- paste(colnames(dt.rot)[1:2], 
                     sprintf('(%0.1f%% explained var.)', 
                             100*m1$sdev[choices]^2/sum(m1$sdev^2)))
u.axis.labs

# Based on Figure p0, keep only a few variables with high loadings in PC1 and PC2----
# var.keep.ndx <- which(dt.rot$feat %in% c("V1",
#                                          "V4",
#                                          "V6",
#                                          "V7",
#                                          "V8"))
# Or select all
var.keep.ndx <- 3:ncol(dt2)

p1 <- ggplot(data = dt.rot[var.keep.ndx,],
             aes(x = PC1,
                 y = PC2)) +
  coord_equal() +
  geom_point(data = dt.scr,
             aes(fill = grp),
             shape = 21,
             size = 2,
             alpha = 0.5) +
  geom_segment(aes(x = 0,
                   y = 0,
                   xend = 10*PC1,
                   yend = 10*PC2),
               arrow = arrow(length = unit(1/2, 'picas')),
               color = "black",
               size = 1.2) +
  geom_text(aes(x = 11*PC1,
                y = 11*PC2,
                label = dt.rot$feat[var.keep.ndx]),
            size = 5,
            hjust = 0.5) +
  scale_x_continuous(u.axis.labs[1]) +
  scale_y_continuous(u.axis.labs[2]) +
  scale_fill_discrete(name = "Group") +
  ggtitle("Biplot") +
  theme(plot.title = element_text(hjust = 0.5,
                                  size = 20))
p1
tiff(filename = "tmp/enriched_pca_biplot.tiff",
     height = 10,
     width = 10,
     units = 'in',
     res = 300,
     compression = "lzw+p")
print(p1)
graphics.off()