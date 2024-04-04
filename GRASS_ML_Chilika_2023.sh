#!/bin/sh

grass
# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B1.TIF output=L_2023_01 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B2.TIF output=L_2023_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B3.TIF output=L_2023_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B4.TIF output=L_2023_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B5.TIF output=L_2023_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B6.TIF output=L_2023_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC09_L2SP_140046_20230304_20230308_02_T1_SR_B7.TIF output=L_2023_07 extent=region resolution=region
#
g.list rast
#
# shaded relief
r.import input=/Users/polinalemenkova/grassdata/Chilika/gebco_2023_1.tif output=shaded_relief extent=region --overwrite
r.contour shaded_relief1 out=isolines step=200 --overwrite

# ---CLUSTERING AND CLASSIFICATION------------------->
# Set computational region to match the scene
g.region raster=L_2023_01 -p
# grouping data by i.group
i.group group=L_2023 subgroup=res_30m \
  input=L_2023_01,L_2023_02,L_2023_03,L_2023_04,L_2023_05,L_2023_06,L_2023_07 --overwrite
#
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L_2023 subgroup=res_30m \
  signaturefile=cluster_L_2023 \
  classes=10 reportfile=rep_clust_L_2023.txt --overwrite

# Classification by i.maxlik module
i.maxlik group=L_2023 subgroup=res_30m \
  signaturefile=cluster_L_2023 \
  output=L_2023_clusters reject=L_2023_cluster_reject --overwrite
# Visualization
r.colors L_2023_clusters color=roygbiv
r.colors shaded_relief1 color=grey
#
# Mapping
g.region raster=L_2023_01 -p
d.mon wx0
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast L_2023_clusters
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2023_clusters title="2023" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Chilika_2023 format=jpg --overwrite
#
# Mapping rejection probability
d.mon wx2
g.region raster=L_2023_clusters -p
r.colors L_2023_cluster_reject color=soilmoisture -e
d.rast shaded_relief1
d.rast L_2023_cluster_reject
d.vect isolines color='100:93:134' width=0
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2023_cluster_reject title="2023" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Chilika_2023_reject format=jpg --overwrite
#
# --------------------- MACHINE LEARNING ------------------------>
#
# Generating training pixels from an older land cover classification:
r.random input=L_2019_clusters seed=100 npoints=1000 raster=training_pixels --overwrite
# Using these training pixels to perform a classification on recent Landsat image:
# 1. train a RandomForestClassifier model using r.learn.train
r.learn.train group=L_2023 training_map=training_pixels \
    model_name=RandomForestClassifier n_estimators=500 save_model=rf_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2023 load_model=rf_model.gz output=rf_classification --overwrite
# check raster categories automatically applied to the classification output
r.category rf_classification
# display
r.colors rf_classification color=rainbow -e
d.mon wx0
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast rf_classification
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=rf_classification title="RF 2023" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=RF_2023 format=jpg --overwrite
#
# 2.SVM ------------------------>
# train a SVC model using r.learn.train
r.learn.train group=L_2023 training_map=training_pixels \
    model_name=SVC n_estimators=500 save_model=svc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2023 load_model=svc_model.gz output=svc_classification --overwrite
# check raster categories automatically applied to the classification output
r.category svc_classification
# display
r.colors svc_classification color=bcyr -e
d.mon wx0
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast svc_classification
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=svc_classification title="SVM 2023" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=SVM_2023 format=jpg --overwrite
#
# 3. MLPClassifier ------------------------>
r.learn.train group=L_2023 training_map=training_pixels \
    model_name=MLPClassifier n_estimators=500 save_model=mlpc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2023 load_model=mlpc_model.gz output=mlpc_classification --overwrite
# check raster categories automatically applied to the classification output
r.category mlpc_classification
# display
r.colors mlpc_classification color=plasma -e
d.mon wx1
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast mlpc_classification
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=mlpc_classification title="MLPC 2023" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=MLPC_2023 format=jpg --overwrite
