#!/bin/sh
grass
g.list rast
# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B1.TIF output=L_2021_01 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B2.TIF output=L_2021_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B3.TIF output=L_2021_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B4.TIF output=L_2021_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B5.TIF output=L_2021_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B6.TIF output=L_2021_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Chilika/LC08_L2SP_140046_20210202_20210302_02_T1_SR_B7.TIF output=L_2021_07 extent=region resolution=region
# shaded relief
r.import input=/Users/polinalemenkova/grassdata/Chilika/gebco_2023_2.tif output=shaded_relief1 extent=region --overwrite
r.contour shaded_relief1 out=isolines step=200 --overwrite
#
g.list rast
# ---CLUSTERING AND CLASSIFICATION------------------->
# Set computational region to match the scene
g.region raster=L_2021_01 -p
# grouping data by i.group
i.group group=L_2021 subgroup=res_30m \
  input=L_2021_01,L_2021_02,L_2021_03,L_2021_04,L_2021_05,L_2021_06,L_2021_07 --overwrite
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L_2021 subgroup=res_30m \
  signaturefile=cluster_L_2021 \
  classes=10 reportfile=rep_clust_L_2021.txt --overwrite
# Classification by i.maxlik module
i.maxlik group=L_2021 subgroup=res_30m \
  signaturefile=cluster_L_2021 \
  output=L_2021_clusters reject=L_2021_cluster_reject --overwrite
#
r.colors L_2021_clusters color=roygbiv
r.colors shaded_relief1 color=grey
#
# Mapping
g.region raster=L_2021_01 -p
d.mon wx0
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast L_2021_clusters
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2021_clusters title="Clusters 2021" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Chilika_2021 format=jpg --overwrite
#
# Mapping rejection probability
d.mon wx1
g.region raster=L_2021_clusters -p
r.colors L_2021_cluster_reject color=soilmoisture -e
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast L_2021_cluster_reject
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2021_cluster_reject title="2021" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Chilika_2021_reject format=jpg --overwrite
#
# --------------------- MACHINE LEARNING ------------------------>
# Generating training pixels from an older land cover classification:
r.random input=L_2019_clusters seed=100 npoints=1000 raster=training_pixels --overwrite
# Then use these training pixels to perform a classification on recent Landsat image:
#
# 1. Random Forest ------------------------>
# train a RandomForestClassifier model using r.learn.train
r.learn.train group=L_2021 training_map=training_pixels \
    model_name=RandomForestClassifier n_estimators=500 save_model=rf_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2021 load_model=rf_model.gz output=rf_classification --overwrite
# check raster categories - they are automatically applied to the classification output
r.category rf_classification
# display
r.colors rf_classification color=rainbow -e
d.mon wx0
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast rf_classification
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=rf_classification title="RF 2021" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=RF_2021 format=jpg --overwrite
#
# 2.SVM ------------------------>
# train a SVC model using r.learn.train
r.learn.train group=L_2021 training_map=training_pixels \
    model_name=SVC n_estimators=500 save_model=svc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2021 load_model=svc_model.gz output=svc_classification --overwrite
# check raster categories - they are automatically applied to the classification output
r.category svc_classification
# display
r.colors svc_classification color=bcyr -e
d.mon wx1
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast svc_classification
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=svc_classification title="SVM 2021" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=SVM_2021 format=jpg --overwrite

# 3. MLPClassifier ------------------------>
r.learn.train group=L_2021 training_map=training_pixels \
    model_name=MLPClassifier n_estimators=500 save_model=mlpc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2021 load_model=mlpc_model.gz output=mlpc_classification --overwrite
# check raster categories - they are automatically applied to the classification output
r.category mlpc_classification
# display
r.colors mlpc_classification color=plasma -e
d.mon wx1
d.rast shaded_relief1
d.vect isolines color='100:93:134' width=0
d.rast mlpc_classification
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=mlpc_classification title="MLPC 2021" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief1 title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=MLPC_2021 format=jpg --overwrite
