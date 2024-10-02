from flask import Flask, render_template, request
import joblib
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')
import io
import base64
import shap


app = Flask(__name__)

# Load the trained model
model = joblib.load('./best_classifier_catboost.clf')

# Define the feature names in the order expected by the model
feature_names = ['parity', 'gest_weeks', 'seifa', 'rurality','smoke_b20', 'smoke_a20', 'pre_diab',
                      'pre_hyper', 'preeclampsia', 'gest_hyper', 'gest_diab', 'bmi', 'mother_age',
                      'private_hospital', 'cob_region', 'gravidity', 'gest_weeks_first_visit', 'num_ant_visit']
feature_names_full= ['Previous birth', 'Weeks of gestation at induction', 'Residential area of socioeconomic disadvantage', 'Residential area of rurality',
                     'Smoked before 20 weeks of gestation', 'Smoked after 20 weeks of gestation', 'Pre-existing diabetes',
                      'Pre-existing hypertension (excludes preeclampsia)', 'Preeclampsia',
                     'Gestational hypertension', 'Gestational diabetes',
                     'Pre-pregnancy BMI', 'Maternal age',
                      'Private hospital', 'Maternal region of birth',
                     'Number of previous pregnancies', 'Weeks of gestation at first antenatal visit', 'Number of total antenatal visits']

seifa_match = pd.read_excel('./SEIFA_2016postcode.xlsx')
rurality_match = pd.read_excel('./ra_code_2016.xlsx')

@app.route('/', methods=['GET', 'POST'])
def index():
    selected_values = {}
    prediction = None
    shap_image = None
    if request.method == 'POST':
        postcode = request.form.get('postcode')
        seifa_quintile = seifa_match.loc[seifa_match['postcode'] == int(postcode), 'IRSD_quintile'].values
        seifa_quintile = seifa_quintile[0]

        ra_quintile = rurality_match.loc[rurality_match['postcode'] == int(postcode), 'RA_quintile'].values
        ra_quintile = ra_quintile[0]

        # Get user input from the form
        user_input = []
        for feature in feature_names:
            if feature == 'seifa':
                value = seifa_quintile
            elif feature == 'rurality':
                value = ra_quintile
            else:
                value = float(request.form.get(feature))
            user_input.append(value)
            selected_values[feature] = value
        # Convert to numpy array and reshape for prediction
        user_input = np.array(user_input).reshape(1, -1)
        # Make prediction
        prediction = model.predict_proba(user_input)[0][1]*100
        prediction = "{:.1f}".format(prediction)
        # SHAP waterfall plot
        explainer = shap.Explainer(model)
        shap_values = explainer(user_input)
        # covert log-odds to probability
        def log_odds_to_probability(log_odds):
            return 1 / (1 + np.exp(-log_odds))
        # covert base value and SHAP values to probability
        base_value_prob = log_odds_to_probability(shap_values.base_values)
        prob_step = log_odds_to_probability(shap_values.base_values + np.cumsum(shap_values.values))
        prob_step_all = np.insert(prob_step, 0, base_value_prob)
        shap_value_prob = [np.diff(prob_step_all)]
        shap_explanation_prob = shap.Explanation(values=shap_value_prob, base_values=base_value_prob,
                                                 data=shap_values.data,
                                                 feature_names=feature_names_full)

        def create_shap_plot(shap_explanation_prob):
            shap.plots.waterfall(shap_explanation_prob[0], max_display=6)
            plt.tight_layout()
            plt.rc('font', size=10)
            plt.text(0, 0, '  E[f(x)] is the baseline probability.', verticalalignment='bottom', horizontalalignment='left',
                     transform=plt.gcf().transFigure)
            buf = io.BytesIO()
            plt.savefig(buf, format='png', bbox_inches='tight')
            buf.seek(0)
            shap_image = base64.b64encode(buf.getvalue()).decode('ascii')
            buf.close()
            plt.close('all')
            return shap_image

        #Create SHAP plot
        shap_image = create_shap_plot(shap_explanation_prob)
    return render_template('index.html', prediction=prediction, selected_values=selected_values, img_data=shap_image)


if __name__ == '__main__':
    app.run(debug=True)


