import numpy as np
import joblib
import matplotlib.pyplot as plt
from uti import data_import
import shap
import time

# import best model
best_pipeline = joblib.load('../model/best_pipeline_xgboost.clf')

# import dataset
train_path = '../data/pdc_dev.sas7bdat'
X_train, y_train = data_import(train_path)
# X_train = X_train[:10]

#transform X to selected features, lose feature names
transform_X = best_pipeline.named_steps['feature_selection'].transform(X_train)


# get the selected feature names
selected_features = best_pipeline.named_steps['feature_selection'].get_support(indices=True)
feature_names=[X_train.columns[i] for i in selected_features]

# best classifier
best_classifier = best_pipeline.named_steps['classification']

n_samples, n_bootstraps = len(transform_X), 1000
shap_values = np.empty((10, n_bootstraps))
# get SHAP values
for i in range(n_bootstraps):
    start_time = time.time()

    bootstrap_indices = np.random.randint(0, n_samples, n_samples)
    bootstrap_X_test = transform_X[bootstrap_indices]

    explainer = shap.Explainer(best_classifier, bootstrap_X_test)
    shap_values[:, i] = np.mean(np.abs(explainer(bootstrap_X_test).values), axis=0)

    end_time = time.time()
    execution_time = (end_time - start_time) / 3600
    print(f'Finish the {i+1} bootstraps, using {execution_time:.2f} hours ---------------------')
lower_bound_shap, upper_bound_shap = np.percentile(shap_values, 2.5, axis=1), np.percentile(shap_values, 97.5, axis=1)

explainer = shap.Explainer(best_classifier, transform_X)
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
    mean_value = mean_shap_values[feature_idx]
    lower_b, upper_b = lower_bound_shap[feature_idx], upper_bound_shap[feature_idx]
    print(mean_value, lower_b, upper_b)
    ax.barh(i,mean_value, color='darkcyan', height=0.5, left=lower_bound)
    ax.errorbar(mean_value+lower_bound, i, xerr=[[mean_value-lower_b], [upper_b-mean_value]], color='black', linewidth=1.5, capsize=4, capthick=1.5, elinewidth=1.5)
plt.gcf().set_size_inches(10, 8)
plt.gcf().set_dpi(200)
plt.tight_layout()
plt.savefig('../plot/beeswarm_xgboost_CI.jpg')
plt.clf()


