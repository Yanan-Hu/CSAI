import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from sklearn.metrics import roc_curve, auc, roc_auc_score, brier_score_loss
from sklearn.calibration import CalibrationDisplay
from dcurves import dca, plot_graphs

np.random.seed (42)

def data_import(filename):
    data = pd.read_sas(filename, encoding='latin1')
    # split data into features and target
    features = data[['parity', 'gest_weeks', 'seifa', 'rurality', 'smoke_b20', 'smoke_a20', 'pre_diab',
                      'pre_hyper', 'preeclampsia', 'gest_hyper', 'gest_diab', 'bmi', 'mother_age',
                      'private_hospital', 'cob_region', 'gravidity', 'gest_weeks_first_visit', 'num_ant_visit']]
    target = data['cs']
    target = target.to_numpy().astype(int)
    return features, target

def data_import_per(filename):
    data = pd.read_sas(filename, encoding='latin1')
    # split data into features and target
    features = data[['parity', 'gest_weeks', 'seifa', 'rurality', 'smoke_b20', 'smoke_a20', 'pre_diab',
                      'pre_hyper', 'preeclampsia', 'gest_hyper', 'gest_diab', 'bmi', 'mother_age',
                      'private_hospital', 'cob_region', 'gravidity', 'gest_weeks_first_visit', 'num_ant_visit']]
    target = data['cs']
    return features, target

def bootstrap_metrics(methods, X_test, y_test, n_bootstraps=1000):
    n_samples = len(X_test)
    auc_scores = np.empty(n_bootstraps)
    brier_scores = np.empty(n_bootstraps)
    bounds_auc = np.empty([len(methods), 2])
    bounds_brier = np.empty([len(methods), 2])
    for j, method in enumerate(methods):
        for i in range(n_bootstraps):
            bootstrap_indices = np.random.randint(0, n_samples, n_samples)
            bootstrap_X_test = X_test.iloc[bootstrap_indices]
            bootstrap_y_test = y_test.iloc[bootstrap_indices]
            y_prob = method.predict_proba(bootstrap_X_test)[:, 1]
            auc_scores[i] = roc_auc_score(bootstrap_y_test, y_prob)
            brier_scores[i] = brier_score_loss(bootstrap_y_test, y_prob)
        lower_bound_auc, upper_bound_auc = np.percentile(auc_scores, 2.5), np.percentile(auc_scores, 97.5)
        bounds_auc[j, :] = np.array([lower_bound_auc, upper_bound_auc])
        lower_bound_brier, upper_bound_brier = np.percentile(brier_scores, 2.5), np.percentile(brier_scores, 97.5)
        bounds_brier[j, :] = np.array([round(lower_bound_brier, 3), round(upper_bound_brier, 3)])
    return bounds_auc, bounds_brier

def multi_models_roc(data_name, model_names, methods, colors, X_test, y_test, save=True, dpin=100):
    bounds_auc, _ = bootstrap_metrics(methods, X_test, y_test)
    plt.figure(figsize=(8, 8), dpi=dpin)
    fprs, tprs, aucs = [], [], []
    # calculate auc/fpr/tpr for each method
    for i, method in enumerate(methods):
        y_prob = method.predict_proba(X_test)[:, 1]
        fpr, tpr, thresholds = roc_curve(y_test, y_prob, pos_label=1)
        auc_score = auc(fpr, tpr)
        fprs.append(fpr)
        tprs.append(tpr)
        aucs.append(auc_score)
    # sort by auc:
    aucs_sorted, fprs_sorted, tprs_sorted, model_names_sorted, colors_sorted, bounds_sorted = sort_all(aucs, fprs, tprs, model_names, colors, bounds_auc)
    # plot by sorted auc
    for i, (auc_score, fpr, tpr, name, bounds, colorname) in enumerate(zip(aucs_sorted, fprs_sorted, tprs_sorted, model_names_sorted, bounds_sorted, colors_sorted)):
        plt.plot(fpr, tpr,
                 label='{} (AUC={:.3f}; 95% CI: {:.3f} - {:.3f})'.format(name, auc_score, bounds[0], bounds[1]),
                 color=colorname)
    if save:
        plt.plot([0, 1], [0, 1], linestyle='--', color='grey')
        plt.xlim([0, 1])
        plt.ylim([0, 1])
        plt.ylabel('True Positive Rate')
        plt.xlabel('False Positive Rate')
        plt.title(f'{data_name}')
        plt.legend(loc='lower right')
    return plt

def sort_all(list1, list2, list3, list4, list5, array):
    df = pd.DataFrame({'list1': list1, 'list2': list2, 'list3': list3, 'list4': list4, 'list5': list5})
    for i in range(array.shape[1]):
        df[f'array_col{i+1}'] = array[:, i]
    df_sorted = df.sort_values(by='list1', ascending=False)
    list1_sorted, list2_sorted, list3_sorted, list4_sorted, list5_sorted = (df_sorted['list1'].tolist(), df_sorted['list2'].tolist(),
                                                              df_sorted['list3'].tolist(), df_sorted['list4'].tolist(), df_sorted['list5'].tolist())
    array_sorted = df_sorted[[f'array_col{i+1}' for i in range(array.shape[1])]].to_numpy()
    return list1_sorted, list2_sorted, list3_sorted, list4_sorted, list5_sorted, array_sorted

def multi_models_calib(data_name, model_names, methods, colors, X_test, y_test, save=True, dpin=100):
    fig = plt.figure(figsize=(25, 25), dpi=dpin)
    gs = GridSpec(len(methods), 2)
    ax_calib_curve = fig.add_subplot(gs[:2, :2])
    calib_displays = {}
    for i, (name, method, colorname) in enumerate(zip(model_names, methods, colors)):
        display = CalibrationDisplay.from_estimator(method, X_test, y_test, n_bins=10, name=name, ax=ax_calib_curve, color=colorname)
        calib_displays[name] = display
    ax_calib_curve.grid(False)
    ax_calib_curve.set_aspect('equal')
    if save:
        plt.plot([0, 1], [0, 1], linestyle='--', color='grey')
        plt.legend()
        plt.xlim([0, 1])
        plt.ylim([0, 1])
        plt.ylabel('Observed probability')
        plt.xlabel('Predicted probability')
        plt.title(f'{data_name}')
    return plt

def multi_models_dc(data_name, model_names, methods, colors, X_test, y_test, dpin=100):
    plt.figure(figsize=(8, 6), dpi=dpin)
    plt.title(f'{data_name}')
    dc_data = pd.DataFrame({'true_outcome': y_test})
    for i, (name, method) in enumerate(zip(model_names, methods)):
        y_prob = method.predict_proba(X_test)[:, 1]
        dc_data[f'{name}'] = y_prob
    dcurves_results = dca(data=dc_data, outcome='true_outcome', modelnames=model_names)
    dcurves_results.to_csv(f'../results/dc_results_{data_name}.csv')
    plot_graphs(plot_df=dcurves_results, graph_type='net_benefit',  y_limits = [-0.05, 0.25], color_names=colors, file_name=f'../plot/multi_models_dc_{data_name}.png')
    plt.figure(figsize=(8, 6), dpi=dpin)
    plot_graphs(plot_df=dcurves_results, graph_type='net_intervention_avoided', color_names=colors, file_name=f'../plot/multi_models_dc_nia_{data_name}.png')



def brier_score_cal(methods, X_test, y_test):
    _, bounds_brier = bootstrap_metrics(methods, X_test, y_test)
    brier_score_list = []
    for i, method in enumerate(methods):
        y_prob = method.predict_proba(X_test)[:, 1]
        brier_score = brier_score_loss(y_test, y_prob)
        brier_score_list.append(round(brier_score, 3))
    return brier_score_list, bounds_brier
