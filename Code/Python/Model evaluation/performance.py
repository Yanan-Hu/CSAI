# import packages
import joblib
import pandas as pd
from uti import data_import_per, multi_models_roc, multi_models_calib, multi_models_dc, brier_score_cal, \
    interactive_roc, interactive_calib, ineractive_dc, plot_shap
from itertools import chain



# import dataset
train_path = '../data/pdc_dev.sas7bdat'
X_train, y_train = data_import_per(train_path)

# import external dataset
temporal_path = '../data/npdc_val.sas7bdat'
X_temporal, y_temporal = data_import_per(temporal_path)
geo_path = '../data/vpdc_val.sas7bdat'
X_geo, y_geo = data_import_per(geo_path)

data_list = [[X_train, y_train], [X_temporal, y_temporal], [X_geo, y_geo]]
data_names = ['Training', 'Temporal Validation', 'Geographical Validation']

# import best model
best_pipeline_lr = joblib.load('../model/best_pipeline_lr.clf')
best_pipeline_rf = joblib.load('../model/best_pipeline_rf.clf')
best_pipeline_gb = joblib.load('../model/best_pipeline_gb.clf')
best_pipeline_lightgbm = joblib.load('../model/best_pipeline_lightgbm.clf')
best_pipeline_catboost = joblib.load('../model/best_pipeline_catboost.clf')
best_pipeline_xgboost = joblib.load('../model/best_pipeline_xgboost.clf')
best_pipeline_adaboost = joblib.load('../model/best_pipeline_adaboost.clf')

# name the methods
model_names = ['Logistic Regression', 'Random Forest', 'Gradient Boosting', 'LightGBM', 'CatBoost', 'XGBoost',
               'AdaBoost']
model_names_dc = ['Logistic Regression', 'Random Forest', 'Gradient Boosting', 'LightGBM', 'CatBoost', 'XGBoost',
                  'AdaBoost', 'Treat All', 'Treat None']
model_names_fi = ['Logistic\nRegression', 'Random\nForest', 'Gradient\nBoosting', 'LightGBM', 'CatBoost', 'XGBoost',
               'AdaBoost']
new_model_names = [f'{item}_{suffix}' for item in model_names for suffix in ['score', 'LCI', 'UCI']]
methods = [best_pipeline_lr, best_pipeline_rf, best_pipeline_gb, best_pipeline_lightgbm, best_pipeline_catboost,
           best_pipeline_xgboost, best_pipeline_adaboost]
colors_1 = ['lightcoral', 'olivedrab', 'darkturquoise', 'darkviolet', 'steelblue', 'navy', 'crimson']
colors_2 = ['lightcoral', 'olivedrab', 'darkturquoise', 'darkviolet', 'steelblue', 'navy', 'crimson', 'gray', 'black']

brier_score_total = pd.DataFrame(columns=new_model_names, index=data_names)
for i, data in enumerate(data_list):
    X_test, y_test = data[0], data[1]

    # plot all roc (AUC and 95% CI) in one figure
    multi_models_roc(data_names[i], model_names, methods, colors_1, X_test, y_test)
    interactive_roc(data_names[i], model_names, methods, colors_1, X_test, y_test)

    # plot all calibration in one figure
    multi_models_calib(data_names[i], model_names, methods, colors_1, X_test, y_test)
    interactive_calib(data_names[i], model_names, methods, colors_1, X_test, y_test)

    # plot all decision curve in one figure
    multi_models_dc(data_names[i], model_names, methods, colors_2, X_test, y_test)
    ineractive_dc(data_names[i], model_names, model_names_dc, methods, colors_2, X_test, y_test)

    # return brier score and 95% CI
    brier_score, bounds_brier = brier_score_cal(methods, X_test, y_test)
    flat_bounds_brier = list(chain(*bounds_brier))
    merged_b = []
    for num in range(len(brier_score)):
        merged_b.append(brier_score[num])
        merged_b.append(flat_bounds_brier[2 * num])
        merged_b.append(flat_bounds_brier[2 * num + 1])
    brier_score_total.loc[data_names[i]] = merged_b

brier_score_total.to_csv('../results/brier_score.csv', index=data_names)

# beeswarm plot for all models
single_index = 95254
plot_shap(X_train, methods, model_names, single_index)


