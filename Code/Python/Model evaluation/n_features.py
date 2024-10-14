import joblib
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import csv

# Load the trained models
model_1 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_lr.clf')
model_2 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_rf.clf')
model_3 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_gb.clf')
model_4 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_lightgbm.clf')
model_5 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_catboost.clf')
model_6 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_xgboost.clf')
model_7 = joblib.load('../.././export from MATVAL/Final models/best_pipeline_adaboost.clf')

# List of models and their names
models = [model_1, model_2, model_3, model_4, model_5, model_6, model_7]
model_names = ['Logistic\nRegression', 'Random\nForest', 'Gradient\nBoosting', 'LightGBM', 'CatBoost', 'XGBoost',
               'AdaBoost']

# List of predictors
predictors = ['parity', 'gest_weeks', 'seifa', 'rurality', 'smoke_b20', 'smoke_a20', 'pre_diab', 'pre_hyper',
              'preeclampsia', 'gest_hyper', 'gest_diab', 'bmi', 'mother_age', 'private_hospital', 'cob_region',
              'gravidity', 'gest_weeks_first_visit', 'num_ant_visit']

# Initialize a DataFrame to store rankings
rankings = pd.DataFrame(index=predictors, columns=model_names)


# Function to get feature importances or coefficients
def get_feature_importances(model, model_name):
    if model_name == 'Logistic\nRegression':
        return np.squeeze(np.abs(model.named_steps['classification'].coef_))
    else:
        return model.named_steps['classification'].feature_importances_


# Fill the rankings DataFrame
n_features_list = []
for model, name in zip(models, model_names):
    n_features=model.named_steps['feature_selection'].n_features_
    n_features_list.append((name, n_features))
    feature_importances = get_feature_importances(model, name)
    selected_features = model.named_steps['feature_selection'].support_
    selected_feature_names = np.array(model.named_steps['feature_selection'].feature_names_in_)[selected_features]

    if len(feature_importances) == len(selected_feature_names):
        feature_ranking = pd.Series(feature_importances, index=selected_feature_names).rank(ascending=False, method='min').astype(int)
        rankings.loc[selected_feature_names, name] = feature_ranking
    else:
        print(
            f"Length mismatch in model {name}: feature_importances ({len(feature_importances)}) vs selected_feature_names ({len(selected_feature_names)})")

with open('./model_n_features.csv', mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['Model Name', 'Number of Features'])
    writer.writerows(n_features_list)

# 1. Sort the DataFrame by 'XGBoost' column
rankings = rankings.sort_values(by='XGBoost')
# Fill NaN values with 'NA'
rankings = rankings.fillna('NA')

# 2. Reorder the columns as requested
ordered_columns = ['XGBoost', 'AdaBoost', 'CatBoost', 'LightGBM', 'Gradient\nBoosting', 'Random\nForest', 'Logistic\nRegression']
rankings = rankings[ordered_columns]


# 3. Function to apply a color gradient based on ranking
def color_gradient(val):
    if val == 'NA':
        return 'background-color: white; color: black'
    else:
        # Determine the intensity based on the ranking (1-18) with reverse scaling
        color_intensity = int((val / 18) * 255)
        # Create a deeper shade of red for smaller values
        return f'background-color: rgb(255, {color_intensity}, {color_intensity}); color: black'


# Apply the style and display the DataFrame with color
styled_rankings = rankings.style.applymap(color_gradient)

# Plot the DataFrame and save as high-resolution image
fig, ax = plt.subplots(figsize=(12, 8))  # Set figure size as needed
ax.axis('tight')
ax.axis('off')

# Create table with row and column labels and with bold indices
table = ax.table(cellText=rankings.values, colLabels=rankings.columns, rowLabels=rankings.index, cellLoc='center',
                 loc='center')
for (i, j), cell in table.get_celld().items():
    if j == -1:  # This refers to the row labels
        cell.set_text_props(va='bottom') 

# Adjust column widths using auto_set_column_width
table.auto_set_column_width([6])  # Automatically set width for specific columns

for i in range(1+len(rankings.index)):
    for j in range(len(rankings.columns)):
        table[(i, j)].set_width(0.1117)
        table[(i, j)].set_height(0.05)


# Getting the first cell's width and height for the "Predictors" label
sample_cell = table[(0, 0)]
width, height = sample_cell.get_width(), sample_cell.get_height()

# Create the top left cell with the text "Predictors"
table.add_cell(0, -1, width=width, height=height, text='Predictors', loc='left').set_text_props(weight='bold')

# Apply cell colors based on the rankings DataFrame
for i, row in enumerate(rankings.values):
    for j, val in enumerate(row):
        if val == 'NA':
            cell_color = (1, 1, 1)  # White background
        else:
            color_intensity = int((val / 18) * 255)
            cell_color = (1, color_intensity / 255, color_intensity / 255)
        table[(i + 1, j)].set_facecolor(cell_color)

# Bold the text in row and column index labels
for (i, j), cell in table.get_celld().items():
    if i == 0:
        cell.set_text_props(weight='bold')

# Set cell edges:
for (i, j), cell in table.get_celld().items():
    cell.set_linewidth(0)  # Set line width to 0 for all cells

# Save the table as a high-resolution image
plt.savefig('./styled_feature_rankings.jpg', bbox_inches='tight', dpi=300)



