import numpy as np
import joblib
import matplotlib.pyplot as plt
from uti import data_import
import shap

seed = 42

# import model
best_pipeline= joblib.load('../model/best_pipeline_catboost.clf')

# import dataset
train_path = '../data/pdc_dev.sas7bdat'
X_train, y_train = data_import(train_path)

#transform X to selected features, lose feature names
transform_X = best_pipeline.named_steps['feature_selection'].transform(X_train)

# get the selected feature names
selected_features = best_pipeline.named_steps['feature_selection'].get_support(indices=True)
feature_names=[X_train.columns[i] for i in selected_features]

# best classifier
best_classifier = best_pipeline.named_steps['classification']

# get SHAP values
explainer = shap.Explainer(best_classifier,transform_X)
shap_values_train = explainer(transform_X)
shap_values_train.feature_names = feature_names

# limit the range of SHAP value to display
lower_bound = -2
upper_bound = 1.5
clipped_shap_values_train = np.clip(shap_values_train.values, lower_bound, upper_bound)

# plot
shap.plots.beeswarm(shap.Explanation(values=clipped_shap_values_train,base_values=shap_values_train.base_values, feature_names=shap_values_train.feature_names, data=shap_values_train.data), max_display=18, show=False )

ax=plt.gca()
mean_shap_values=np.mean(np.abs(shap_values_train.values), axis=0)
feature_names=shap_values_train.feature_names
feature_order=np.argsort(mean_shap_values)
for i, feature_idx in enumerate (feature_order):
    mean_value=  mean_shap_values[feature_idx]
    ax.barh(i,mean_value, color='darkcyan', height=0.5, left=lower_bound)
plt.gcf().set_size_inches(10,8)
plt.gcf().set_dpi(200)
plt.tight_layout()
plt.savefig('../plot/beeswarm_catboost.jpg')
plt.clf()


# example woman

# covert log-odds to probability
def log_odds_to_probability(log_odds):
    return 1/(1+np.exp(-log_odds))

# covert base value and SHAP values to probability
base_value_prob=log_odds_to_probability(shap_values_train.base_values)

shap_value_prob=shap_values_train.values.copy()
for i in range (shap_values_train.values.shape[0]):
    shap_value_prob[i]=log_odds_to_probability(shap_values_train.base_values[i] + shap_values_train.values [i])- base_value_prob[i]
shap_explanation_prob=shap.Explanation(values=shap_value_prob,base_values=base_value_prob, data=shap_values_train.data, feature_names=shap_values_train.feature_names)

# #plot first observation
# shap.plots.waterfall(shap_explanation_prob[5421], max_display=18,show=False)
# plt.gcf().set_size_inches(10,8)
# plt.gcf().set_dpi(200)
# plt.tight_layout()
# plt.savefig('../plot/waterfall_catboost_0.jpg')
# plt.clf()
#
# #plot second observation
# shap.plots.waterfall(shap_explanation_prob[5439], max_display=18,show=False)
# plt.gcf().set_size_inches(10,8)
# plt.gcf().set_dpi(200)
# plt.tight_layout()
# plt.savefig('../plot/waterfall_catboost_1.jpg')
# plt.clf()

#plot third observation
shap.plots.waterfall(shap_explanation_prob[95254], max_display=18,show=False)
plt.gcf().set_size_inches(8,8)
plt.gcf().set_dpi(100)
plt.tight_layout()
plt.savefig('../plot/waterfall_catboost_2.jpg')
