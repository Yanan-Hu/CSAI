# import packages
import matplotlib.pyplot as plt
import joblib
import pandas as pd
from uti import (data_import_per, multi_models_roc, multi_models_calib, multi_models_dc, brier_score_cal, interactive_roc,
                 interactive_calib, ineractive_dc, interactive_prc, plot_shap, multi_groups_roc,multi_groups_prc,multi_groups_calib,subgroup_calib)
from itertools import chain

# import training dataset
train_path = '../data/pdc_dev.sas7bdat'
X_train, y_train = data_import_per(train_path)

# import external dataset
temporal_path = '../data/npdc_val.sas7bdat'
X_temporal, y_temporal = data_import_per(temporal_path)
geo_path = '../data/vpdc_val.sas7bdat'
X_geo, y_geo = data_import_per(geo_path)

data_list = [[X_train, y_train], [X_temporal, y_temporal], [X_geo, y_geo]]
data_names = ['Training', 'Temporal Validation', 'Geographical Validation']
subgroup_names = ['Women region of birth', 'Socioeconomic disadvantage of residential area, quintile', 'Rurality of residential area', 'Age, years', 'Pre-pregnancy BMI, kg/m\u00B2']

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
new_model_names = [f'{item}_{suffix}' for item in model_names for suffix in ['score', 'LCI', 'UCI']]
methods = [best_pipeline_lr, best_pipeline_rf, best_pipeline_gb, best_pipeline_lightgbm, best_pipeline_catboost,
best_pipeline_xgboost, best_pipeline_adaboost]
colors_1 = ['lightcoral', 'olivedrab', 'darkturquoise', 'darkviolet', 'steelblue', 'navy', 'crimson']
colors_2 = ['lightcoral', 'olivedrab', 'darkturquoise', 'darkviolet', 'steelblue', 'navy', 'crimson', 'gray', 'black']

rob_labels = ['Australia', 'Oceania and Antarctica', 'Europe', 'Africa', 'Asia', 'America']
seifa_labels = ['1', '2', '3', '4','5']
group_names={'cob_region': rob_labels, 'seifa': seifa_labels}

brier_score_total = pd.DataFrame(columns=new_model_names, index=data_names)

for i, data in enumerate(data_list):
    X_test, y_test = data[0], data[1]

# plot all prc (AUPRC and 95% CI) in one figure
    interactive_prc(data_names[i], model_names, methods, colors_1, X_test, y_test)
# plot all roc (AUROC and 95% CI) in one figure
    multi_models_roc(data_names[i], model_names, methods, colors_1, X_test, y_test)
    interactive_roc(data_names[i], model_names, methods, colors_1, X_test, y_test)
# plot all calibration in one figure
    multi_models_calib(data_names[i], model_names, methods, colors_1, X_test, y_test)
    interactive_calib(data_names[i], model_names, methods, colors_1, X_test, y_test)
#plot all decision curve in one figure
    multi_models_dc(data_names[i], model_names, methods, colors_2, X_test, y_test)
    ineractive_dc(data_names[i], model_names, model_names_dc, methods, colors_2, X_test, y_test)
#subgroup analysis for selected model (xgboost)
    multi_groups_roc(data_names[i], subgroup_names, group_names, best_pipeline_xgboost, colors_1, X_test, y_test)
    multi_groups_prc(data_names[i], subgroup_names, group_names, best_pipeline_xgboost, colors_1, X_test, y_test)
    multi_groups_calib(data_names[i], subgroup_names, group_names, best_pipeline_xgboost, colors_1, X_test, y_test)
    subgroup_calib(data_names[i], subgroup_names, group_names, best_pipeline_xgboost, colors_1, X_test, y_test)
#return brier score and 95% CI
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

# cost implication for selected model (xgboost)
train_data = pd.read_sas('../data/pdc_dev.sas7bdat', encoding='latin1')
y_prob = best_pipeline_xgboost.predict_proba(X_train)[:, 1]
train_data['predicted_risk'] = y_prob
train_data.to_csv('pdc_dev_risk.csv', index=False)

temp_data = pd.read_sas('../data/npdc_val.sas7bdat', encoding='latin1')
y_prob=best_pipeline_xgboost.predict_proba(X_temporal)[:, 1]
temp_data['predicted_risk'] = y_prob
temp_data.to_csv('npdc_val_risk.csv', index=False)

geo_data = pd.read_sas('../data/vpdc_val.sas7bdat', encoding='latin1')
y_prob=best_pipeline_xgboost.predict_proba(X_geo)[:, 1]
geo_data['predicted_risk'] = y_prob
geo_data.to_csv('vpdc_val_risk.csv', index=False)

# bar charts by decile of predicted probability in temporal cohort
temporal_data = pd.read_sas('../data/cost_summary.sas7bdat', encoding='latin1')
fig, ax = plt.subplots(figsize=(len(temporal_data['decile']), 4), dpi=100)
group_labels = []
for _, row in temporal_data.iterrows():
    label = f"{int(row['decile'])}\n(n={row['total_mom_birth_cost_N']:,.0f},\nCS={row['total_mom_birth_cost_CS']:.1f}%)"
    group_labels.append(label)
ax.grid(True, axis='y', zorder=0)
bars = ax.bar(temporal_data['decile'], temporal_data['total_mom_birth_cost_Mean'], 0.5, yerr= temporal_data['total_mom_birth_cost_StdErr'], color='steelblue', zorder=2, capsize=3)
for bar, value in zip(bars,temporal_data['total_mom_birth_cost_Mean']):
    ax.text (bar.get_x() + bar.get_width()/2, bar.get_height()+300, f"${value:,.0f}", ha='center', va='bottom')
ax.set_xlabel('Predicted probability group, decile')
ax.set_ylabel('Mean maternal inpatient cost, $')
ax.set_ylim(0, 14000)
ax.set_xticks(temporal_data['decile'].astype(int))
ax.set_xticklabels(group_labels)
plt.tight_layout ()
ax.set_title('Temporal Validation')
plt.savefig('../plot/mom_birth_cost.png', bbox_inches='tight')
plt.clf()


fig, ax = plt.subplots(figsize=(len(temporal_data['decile']), 4), dpi=100)
group_labels = []
for _, row in temporal_data.iterrows():
    label = f"{int(row['decile'])}\n(n={row['total_baby_birth_cost_N']:,.0f},\nCS={row['total_baby_birth_cost_CS']:.1f}%)"
    group_labels.append(label)
ax.grid(True, axis='y', zorder=0)
bars = ax.bar(temporal_data['decile'],temporal_data['total_baby_birth_cost_Mean'], 0.5, yerr= temporal_data['total_baby_birth_cost_StdErr'], color='steelblue', zorder=2, capsize=3)
for bar, value in zip(bars, temporal_data['total_baby_birth_cost_Mean']):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 400, f"${value:,.0f}", ha='center', va='bottom')
ax.set_xlabel('Predicted probability group, decile')
ax.set_ylabel('Mean neonatal inpatient cost, $')
ax.set_ylim(0, 14000)
ax.set_xticks(temporal_data['decile'].astype(int))
ax.set_xticklabels(group_labels)
plt.tight_layout ()
ax.set_title('Temporal Validation')
plt.savefig('../plot/baby_birth_cost.png', bbox_inches='tight')
plt.clf()


fig, ax = plt.subplots(figsize=(len(temporal_data['decile']), 4), dpi=100)
group_labels = []
for _, row in temporal_data.iterrows():
    label = f"{int(row['decile'])}\n(n={row['mom_mean_LENGTH_OF_STAY_N']:,.0f},\nCS={row['mom_mean_LENGTH_OF_STAY_CS']:.1f}%)"
    group_labels.append(label)
ax.grid(True, axis='y', zorder=0)
bars = ax.bar(temporal_data['decile'],temporal_data['mom_mean_LENGTH_OF_STAY_Mean'], 0.5, yerr= temporal_data['mom_mean_LENGTH_OF_STAY_StdErr'], color='steelblue', zorder=2, capsize=3)
for bar, value in zip(bars, temporal_data['mom_mean_LENGTH_OF_STAY_Mean']):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() +0.2, f"{value:,.1f}", ha='center', va='bottom')
ax.set_xlabel('Predicted probability group, decile')
ax.set_ylabel('Mean maternal length of stay, day')
ax.set_ylim(0, 5)
ax.set_xticks(temporal_data['decile'].astype(int))
ax.set_xticklabels(group_labels)
plt.tight_layout ()
ax.set_title('Temporal Validation')
plt.savefig('../plot/mom_LENGTH_OF_STAY.png', bbox_inches='tight')
plt.clf()


fig, ax = plt.subplots(figsize=(len(temporal_data['decile']), 4), dpi=100)
group_labels = []
for _, row in temporal_data.iterrows():
    label = f"{int(row['decile'])}\n(n={row['baby_mean_LENGTH_OF_STAY_N']:,.0f},\nCS={row['baby_mean_LENGTH_OF_STAY_CS']:.1f}%)"
    group_labels.append(label)
ax.grid(True, axis='y', zorder=0)
bars = ax.bar(temporal_data['decile'],temporal_data['baby_mean_LENGTH_OF_STAY_Mean'], 0.5, yerr= temporal_data['baby_mean_LENGTH_OF_STAY_StdErr'], color='steelblue', zorder=2, capsize=3)
for bar, value in zip(bars, temporal_data['baby_mean_LENGTH_OF_STAY_Mean']):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() +0.2, f"{value:,.1f}", ha='center', va='bottom')
ax.set_xlabel('Predicted probability group, decile')
ax.set_ylabel('Mean neonatal length of stay, day')
ax.set_ylim(0, 5)
ax.set_xticks(temporal_data['decile'].astype(int))
ax.set_xticklabels(group_labels)
plt.tight_layout ()
ax.set_title('Temporal Validation')
plt.savefig('../plot/baby_LENGTH_OF_STAY.png', bbox_inches='tight')
plt.clf()
