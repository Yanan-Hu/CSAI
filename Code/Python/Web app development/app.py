from flask import Flask, render_template, request
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')
import io
import base64
import shap
import csv
from xgboost import XGBClassifier


app = Flask(__name__)

# Load the trained model
model = XGBClassifier()
model.load_model('compatible_model.json')


# Define the feature names in the order expected by the model
feature_names = ['parity', 'gest_weeks', 'rurality','smoke_b20', 'pre_diab','preeclampsia', 'bmi', 'mother_age', 'private_hospital', 'cob_region']
feature_names_full= ['Previous birth', 'Weeks of gestation at induction', 'Residential area of rurality', 'Smoked before 20 weeks of gestation', 'Pre-existing diabetes','Preeclampsia',
                     'Pre-pregnancy BMI', 'Maternal age', 'Private hospital', 'Maternal region of birth']

def read_csv_file(file_path):
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file)
        return list(reader)

rurality_match = read_csv_file('./ra_code_2016.csv')

@app.route('/', methods=['GET', 'POST'])
def index():
    selected_values = {}
    prediction = None
    shap_image = None
    if request.method == 'POST':
        postcode = int(request.form.get('postcode').strip())
        ra_quintile = next((float(row['RA_quintile']) for row in rurality_match if int(row['postcode']) == postcode),
                           9)
        # Get user input from the form
        user_input = []
        for feature in feature_names:
            if feature == 'rurality':
                value = ra_quintile
            else:
                value = float(request.form.get(feature))
            user_input.append(value)
            selected_values[feature] = value

        # Convert to numpy array and reshape for prediction
        user_input = np.array(user_input).reshape(1, -1)

        # Make prediction
        prediction_prob = model.predict_proba(user_input)[0][1]
        prediction = prediction_prob * 100
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


