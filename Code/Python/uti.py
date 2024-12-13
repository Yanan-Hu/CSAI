import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from sklearn.metrics import roc_curve, auc, roc_auc_score, brier_score_loss, precision_recall_curve, \
    average_precision_score
from sklearn.calibration import CalibrationDisplay, calibration_curve
from dcurves import dca, plot_graphs
import shap
import random
import plotly.graph_objects as go
from plotly.offline import plot


def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)


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
    set_seed(42)
    n_samples = len(X_test)
    roc_scores = np.empty(n_bootstraps)
    prc_scores = np.empty(n_bootstraps)
    brier_scores = np.empty(n_bootstraps)
    bounds_roc = np.empty([len(methods), 2])
    bounds_prc = np.empty([len(methods), 2])
    bounds_brier = np.empty([len(methods), 2])
    for j, method in enumerate(methods):
        for i in range(n_bootstraps):
            bootstrap_indices = np.random.randint(0, n_samples, n_samples)
            bootstrap_X_test = X_test.iloc[bootstrap_indices]
            bootstrap_y_test = y_test.iloc[bootstrap_indices]
            y_prob = method.predict_proba(bootstrap_X_test)[:, 1]
            roc_scores[i] = roc_auc_score(bootstrap_y_test, y_prob)
            prc_scores[i] = average_precision_score(bootstrap_y_test, y_prob)
            brier_scores[i] = brier_score_loss(bootstrap_y_test, y_prob)
        lower_bound_roc, upper_bound_roc = np.percentile(roc_scores, 2.5), np.percentile(roc_scores, 97.5)
        bounds_roc[j, :] = np.array([lower_bound_roc, upper_bound_roc])
        lower_bound_prc, upper_bound_prc = np.percentile(prc_scores, 2.5), np.percentile(prc_scores, 97.5)
        bounds_prc[j, :] = np.array([lower_bound_prc, upper_bound_prc])
        lower_bound_brier, upper_bound_brier = np.percentile(brier_scores, 2.5), np.percentile(brier_scores, 97.5)
        bounds_brier[j, :] = np.array([round(lower_bound_brier, 3), round(upper_bound_brier, 3)])
    return bounds_roc, bounds_prc, bounds_brier


def multi_models_roc(data_name, model_names, methods, colors, X_test, y_test, save=True, dpin=100):
    bounds_roc, _, _ = bootstrap_metrics(methods, X_test, y_test)
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
    aucs_sorted, fprs_sorted, tprs_sorted, model_names_sorted, colors_sorted, bounds_sorted = sort_all(aucs, fprs, tprs,
                                                                                                       model_names,
                                                                                                       colors,
                                                                                                       bounds_roc)
    # plot by sorted auc
    for i, (auc_score, fpr, tpr, name, bounds, colorname) in enumerate(
            zip(aucs_sorted, fprs_sorted, tprs_sorted, model_names_sorted, bounds_sorted, colors_sorted)):
        plt.plot(fpr, tpr,
                 label='{} (AUROC={:.3f}; 95% CI: {:.3f} - {:.3f})'.format(name, auc_score, bounds[0], bounds[1]),
                 color=colorname)
    if save:
        plt.plot([0, 1], [0, 1], linestyle='--', color='grey')
        plt.xlim([0, 1])
        plt.ylim([0, 1])
        plt.ylabel('True Positive Rate')
        plt.xlabel('False Positive Rate')
        plt.title(f'{data_name}')
        plt.legend(loc='lower right')
        plt.savefig(f'../plot/multi_models_roc_{data_name}.png', bbox_inches='tight')
    return plt


def multi_groups_roc(data_name, subgroup_names, group_names, method, colors, X_test, y_test, save=True, dpin=100):
    y_prob = method.predict_proba(X_test)[:, 1]
    age_bins = [0, 20, 25, 30, 34, np.inf]
    age_labels = ['<20 years', '20 - 24 years', '25 - 29 years', '30 - 34 years', '>34 years']
    bmi_bins = [0, 18.5, 24.9, 29.9, np.inf]
    bmi_labels = ['Underweight', 'Normal weight', 'Overweight', 'Obesity']
    X_test['mother_age_group'] = pd.cut(X_test['mother_age'], bins=age_bins, labels=age_labels, right=False)
    X_test['bmi_group'] = pd.cut(X_test['bmi'], bins=bmi_bins, labels=bmi_labels, right=False)
    group_names['mother_age_group'] = age_labels
    group_names['bmi_group'] = bmi_labels
    for idx, (subgroup, group_names) in enumerate(group_names.items()):
        subgroup_name = subgroup_names[idx]
        plt.figure(figsize=(8, 8), dpi=dpin)
        fprs, tprs, aucs = [], [], []
        # calculate auc/fpr/tpr for each subgroup
        for group_idx, group_name in enumerate(group_names):
            if subgroup in ['cob_region', 'seifa', 'rurality']:
                mask = (X_test[subgroup] == (group_idx + 1)) & (X_test[subgroup] != 9)
            else:
                mask = (X_test[subgroup] == group_name)
            y_test_group = y_test[mask]
            y_prob_group = y_prob[mask]
            if len(y_test_group) < 10:
                continue
            fpr, tpr, thresholds = roc_curve(y_test_group, y_prob_group, pos_label=1)
            auc_score = auc(fpr, tpr)
            fprs.append(fpr)
            tprs.append(tpr)
            aucs.append(auc_score)
        # plot by sorted auc
        for i, (auc_score, fpr, tpr, name, colorname) in enumerate(
                zip(aucs, fprs, tprs, group_names, colors)):
            plt.plot(fpr, tpr,
                     label='{} (AUROC={:.3f})'.format(name, auc_score),
                     color=colorname)
        if save:
            plt.plot([0, 1], [0, 1], linestyle='--', color='grey')
            plt.xlim([0, 1])
            plt.ylim([0, 1])
            plt.ylabel('True Positive Rate')
            plt.xlabel('False Positive Rate')
            plt.title(f'{data_name}_{subgroup_name}')
            plt.legend(loc='lower right')
            plt.savefig(f'../plot/multi_groups_roc_{data_name}_{subgroup_name}.png', bbox_inches='tight')
    return plt


def interactive_roc(data_name, model_names, methods, colors, X_test, y_test):
    bounds_roc, _, _ = bootstrap_metrics(methods, X_test, y_test)
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
    aucs_sorted, fprs_sorted, tprs_sorted, model_names_sorted, colors_sorted, bounds_sorted = sort_all(aucs, fprs, tprs,
                                                                                                       model_names,
                                                                                                       colors,
                                                                                                       bounds_roc)
    # create Plotly figure
    fig = go.Figure()
    # plot by sorted auc
    for i, (auc_score, fpr, tpr, name, bounds, colorname) in enumerate(
            zip(aucs_sorted, fprs_sorted, tprs_sorted, model_names_sorted, bounds_sorted, colors_sorted)):
        fig.add_trace(go.Scatter(x=fpr, y=tpr, mode='lines',
                                 name=f'{name} (AUROC={auc_score:.3f}; 95% CI: {bounds[0]:.3f} - {bounds[1]:.3f})',
                                 line=dict(color=colorname),
                                 hovertemplate='<b>%{text}</b><br>True Positive Rate: %{y:.3f}<extra></extra>',
                                 text=[f'{name}'] * len(fpr)))
        fig.add_trace(
            go.Scatter(x=[0, 1], y=[0, 1], mode='lines', line=dict(dash='dash', color='grey'), showlegend=False))
        fig.update_layout(title=f'{data_name}', xaxis_title='False Positive Rate', yaxis_title='True Positive Rate',
                          xaxis=dict(range=[0, 1], hoverformat='.3f'),
                          yaxis=dict(range=[0, 1]), legend=dict(x=1, y=0, xanchor='right'), hovermode='x unified')
    plot(fig, filename=f'../plot/interactive_roc_{data_name}.html', auto_open=False)
    return fig


def multi_groups_prc(data_name, subgroup_names, group_names, method, colors, X_test, y_test, save=True, dpin=100):
    y_prob = method.predict_proba(X_test)[:, 1]
    age_bins = [0, 20, 25, 30, 34, np.inf]
    age_labels = ['<20 years', '20 - 24 years', '25 - 29 years', '30 - 34 years', '>34 years']
    bmi_bins = [0, 18.5, 24.9, 29.9, np.inf]
    bmi_labels = ['Underweight', 'Normal weight', 'Overweight', 'Obesity']
    X_test['mother_age_group'] = pd.cut(X_test['mother_age'], bins=age_bins, labels=age_labels, right=False)
    X_test['bmi_group'] = pd.cut(X_test['bmi'], bins=bmi_bins, labels=bmi_labels, right=False)
    group_names['mother_age_group'] = age_labels
    group_names['bmi_group'] = bmi_labels
    for idx, (subgroup, group_names) in enumerate(group_names.items()):
        subgroup_name = subgroup_names[idx]
        plt.figure(figsize=(8, 8), dpi=dpin)
        recalls, precisions, aucs = [], [], []
        # calculate auc/fpr/tpr for each subgroup
        for group_idx, group_name in enumerate(group_names):
            if subgroup in ['cob_region', 'seifa', 'rurality']:
                mask = (X_test[subgroup] == (group_idx + 1)) & (X_test[subgroup] != 9)
            else:
                mask = (X_test[subgroup] == group_name)
            y_test_group = y_test[mask]
            y_prob_group = y_prob[mask]
            if len(y_test_group) < 10:
                continue
            precision, recall, thresholds = precision_recall_curve(y_test_group, y_prob_group, pos_label=1)
            auc_score = auc(recall, precision)
            precisions.append(precision)
            recalls.append(recall)
            aucs.append(auc_score)
            baseline_precision = y_test_group.mean()
        # plot by sorted auc
        for i, (auc_score, precision, recall, name, colorname) in enumerate(
                zip(aucs, precisions, recalls, group_names, colors)):
            plt.plot(recall, precision,
                     label='{} (AUPRC={:.3f})'.format(name, auc_score),
                     color=colorname)
        if save:
            plt.plot([0, 1], [baseline_precision, baseline_precision], linestyle='--', color='grey')
            plt.xlim([0, 1])
            plt.ylim([0, 1])
            plt.ylabel('Precision')
            plt.xlabel('Recall')
            plt.title(f'{data_name}_{subgroup_name}')
            plt.legend(loc='lower right')
            plt.savefig(f'../plot/multi_groups_prc_{data_name}_{subgroup_name}.png', bbox_inches='tight')
    return plt


def interactive_prc(data_name, model_names, methods, colors, X_test, y_test):
    _, bounds_prc, _ = bootstrap_metrics(methods, X_test, y_test)
    recalls, precisions, aucs = [], [], []
    # calculate auc/recall/precision for each method
    for i, method in enumerate(methods):
        y_prob = method.predict_proba(X_test)[:, 1]
        precision, recall, thresholds = precision_recall_curve(y_test, y_prob, pos_label=1)
        auc_score = auc(recall, precision)
        precisions.append(precision)
        recalls.append(recall)
        aucs.append(auc_score)
    # sort by auc:
    aucs_sorted, precisions_sorted, recalls_sorted, model_names_sorted, colors_sorted, bounds_sorted = sort_all(aucs,
                                                                                                                precisions,
                                                                                                                recalls,
                                                                                                                model_names,
                                                                                                                colors,
                                                                                                                bounds_prc)
    # create Plotly figure
    fig = go.Figure()
    # plot by sorted auc
    for i, (auc_score, precision, recall, name, bounds, colorname) in enumerate(
            zip(aucs_sorted, precisions_sorted, recalls_sorted, model_names_sorted, bounds_sorted, colors_sorted)):
        fig.add_trace(go.Scatter(x=recall, y=precision, mode='lines',
                                 name=f'{name} (AUPRC={auc_score:.3f}; 95% CI: {bounds[0]:.3f} - {bounds[1]:.3f})',
                                 line=dict(color=colorname),
                                 hovertemplate='<b>%{text}</b><br>Precision: %{y:.3f}<extra></extra>',
                                 text=[f'{name}'] * len(recall)))
        fig.add_trace(
            go.Scatter(x=[0, 1], y=[sum(y_test) / len(y_test)] * 2, mode='lines', line=dict(dash='dash', color='grey'),
                       showlegend=False))
        fig.update_layout(title=f'{data_name}', xaxis_title='Recall', yaxis_title='Precision',
                          xaxis=dict(range=[0, 1], hoverformat='.3f'),
                          yaxis=dict(range=[0, 1]), legend=dict(x=1, y=0, xanchor='right'), hovermode='x unified')
    plot(fig, filename=f'../plot/interactive_prc_{data_name}.html', auto_open=False)
    return fig


def sort_all(list1, list2, list3, list4, list5, array):
    df = pd.DataFrame({'list1': list1, 'list2': list2, 'list3': list3, 'list4': list4, 'list5': list5})
    for i in range(array.shape[1]):
        df[f'array_col{i + 1}'] = array[:, i]
    df_sorted = df.sort_values(by='list1', ascending=False)
    list1_sorted, list2_sorted, list3_sorted, list4_sorted, list5_sorted = (
        df_sorted['list1'].tolist(), df_sorted['list2'].tolist(),
        df_sorted['list3'].tolist(), df_sorted['list4'].tolist(), df_sorted['list5'].tolist())
    array_sorted = df_sorted[[f'array_col{i + 1}' for i in range(array.shape[1])]].to_numpy()
    return list1_sorted, list2_sorted, list3_sorted, list4_sorted, list5_sorted, array_sorted


def multi_models_calib(data_name, model_names, methods, colors, X_test, y_test, save=True, dpin=100):
    fig = plt.figure(figsize=(25, 25), dpi=dpin)
    gs = GridSpec(len(methods), 2)
    ax_calib_curve = fig.add_subplot(gs[:2, :2])
    calib_displays = {}
    for i, (name, method, colorname) in enumerate(zip(model_names, methods, colors)):
        display = CalibrationDisplay.from_estimator(method, X_test, y_test, n_bins=10, name=name, ax=ax_calib_curve,
                                                    color=colorname)
        calib_displays[name] = display
    ax_calib_curve.grid(True)
    ax_calib_curve.set_aspect('equal')
    if save:
        plt.plot([0, 1], [0, 1], linestyle='--', color='grey')
        plt.legend()
        plt.xlim([0, 1])
        plt.ylim([0, 1])
        plt.ylabel('Observed probability')
        plt.xlabel('Predicted probability')
        plt.title(f'{data_name}')
        plt.savefig(f'../plot/multi_models_calib_{data_name}.png', bbox_inches='tight')
    return plt


def multi_groups_calib(data_name, subgroup_names, group_names, method, colors, X_test, y_test, save=True, dpin=200):
    fig = plt.figure(figsize=(25, 25), dpi=dpin)
    gs = GridSpec(len(subgroup_names), 1)
    calib_displays = {}
    X_test_copy = X_test.copy()
    age_bins = [0, 20, 25, 30, 34, np.inf]
    age_labels = ['<20 years', '20 - 24 years', '25 - 29 years', '30 - 34 years', '>34 years']
    bmi_bins = [0, 18.5, 24.9, 29.9, np.inf]
    bmi_labels = ['Underweight', 'Normal weight', 'Overweight', 'Obesity']
    X_test_copy['mother_age_group'] = pd.cut(X_test['mother_age'], bins=age_bins, labels=age_labels, right=False)
    X_test_copy['bmi_group'] = pd.cut(X_test['bmi'], bins=bmi_bins, labels=bmi_labels, right=False)
    group_names['mother_age_group'] = age_labels
    group_names['bmi_group'] = bmi_labels
    for idx, (subgroup, group_names) in enumerate(group_names.items()):
        subgroup_name = subgroup_names[idx]
        ax_calib_curve = fig.add_subplot(gs[idx, 0])
        for group_idx, group_name in enumerate(group_names):
            if subgroup in ['cob_region', 'seifa', 'rurality']:
                mask = (X_test[subgroup] == (group_idx + 1)) & (X_test[subgroup] != 9)
            else:
                mask = (X_test_copy[subgroup] == group_name)
            X_test_group = X_test[mask]
            y_test_group = y_test[mask]
            if len(y_test_group) < 10:
                continue
            display = CalibrationDisplay.from_estimator(method, X_test_group, y_test_group, n_bins=10, name=group_name,
                                                        ax=ax_calib_curve,
                                                        color=colors[group_idx])
            calib_displays[group_name] = display
            ax_calib_curve.grid(True)
            ax_calib_curve.set_aspect('equal')

        if save:
            plt.plot([0, 1], [0, 1], linestyle='--', color='grey')
            plt.legend()
            plt.xlim([0, 1])
            plt.ylim([0, 1])
            plt.ylabel('Observed probability')
            plt.xlabel('Predicted probability')
            plt.title(f'{data_name}_{subgroup_name}')
            plt.legend()
            plt.savefig(f'../plot/multi_groups_calib_{data_name}_{subgroup_name}.png', bbox_inches='tight')
            plt.clf()
    return plt


def subgroup_calib(data_name, subgroup_names, group_names, method, colors, X_test, y_test, save=True, dpin=100):
    y_prob = method.predict_proba(X_test)[:, 1]
    X_test_copy = X_test.copy()
    age_bins = [0, 20, 25, 30, 35, np.inf]
    age_labels = ['<20', '20 - 24', '25 - 29', '30 - 34', '>34']
    bmi_bins = [0, 18.5, 25, 30, np.inf]
    bmi_labels = ['<18.5', '18.5 - 24.9', '25.0 - 29.9', '>29.9']
    X_test_copy['mother_age_group'] = pd.cut(X_test['mother_age'], bins=age_bins, labels=age_labels, right=False)
    X_test_copy['bmi_group'] = pd.cut(X_test['bmi'], bins=bmi_bins, labels=bmi_labels, right=False)
    X_test_copy['rurality_group'] = X_test['rurality'].replace(
        {1: 'Major city', 2: 'Inner regional', 3: 'Outer regional', 4: 'Remote', 5: 'Remote',
         9: 'Missing'})
    rurality_labels = ['Major city', 'Inner regional', 'Outer regional', 'Remote']
    group_names['rurality_group'] = rurality_labels
    group_names['mother_age_group'] = age_labels
    group_names['bmi_group'] = bmi_labels
    for idx, (subgroup, group_names) in enumerate(group_names.items()):
        subgroup_name = subgroup_names[idx]
        fig, ax = plt.subplots(figsize=(len(group_names)*1.5, 4), dpi=dpin)
        observed_probs = []
        predicted_probs = []
        group_labels = []
        for group_idx, group_name in enumerate(group_names):
            if subgroup in ['cob_region', 'seifa', 'rurality']:
                mask = (X_test[subgroup] == (group_idx + 1)) & (X_test[subgroup] != 9)
            else:
                mask = (X_test_copy[subgroup] == group_name)
            y_test_group = y_test[mask]
            y_prob_group = y_prob[mask]
            if len(y_test_group) < 5:
                continue
            observed_prob = np.mean(y_test_group)
            predicted_prob = np.mean(y_prob_group)
            observed_probs.append(observed_prob)
            predicted_probs.append(predicted_prob)
            cs_count = np.sum(y_test_group == 1)
            group_labels.append(f'{group_name}\n(n={len(y_test_group):,.0f},\n{cs_count:,.0f} cases)')
        bar_width, bar_gap = 0.25, 0.05
        index = np.arange(len(group_labels))
        ax.grid(True, axis='y', zorder=0)
        ax.bar(index - bar_gap/2, observed_probs, bar_width, label='Observed Probability', color='steelblue', zorder=2)
        ax.bar(index + bar_width + bar_gap/2, predicted_probs, bar_width, label='Average Predicted Probability', color='#335D7F',
               zorder=2)
        ax.set_xlabel(f'{subgroup_name}')
        ax.set_ylabel('Probability, %')
        ax.set_ylim(0, 0.4)
        ax.set_title(f'{data_name}')
        ax.set_xticks(index + bar_width / 2)
        ax.set_xticklabels(group_labels)
        ax.legend(loc='upper left')
        if save:
            plt.tight_layout
            plt.savefig(f'../plot/subgroup_calib_{data_name}_{subgroup_name[:3]}.png', bbox_inches='tight')
            plt.close(fig)
    return plt


def interactive_calib(data_name, model_names, methods, colors, X_test, y_test):
    # create Plotly figure
    fig = go.Figure()
    for name, method, colorname in zip(model_names, methods, colors):
        y_prob = method.predict_proba(X_test)[:, 1]
        prob_true, prob_pred = calibration_curve(y_test, y_prob, n_bins=10)
        fig.add_trace(go.Scatter(x=prob_pred, y=prob_true, mode='lines+markers',
                                 name=name, line=dict(color=colorname), marker=dict(symbol='square'),
                                 hovertemplate='<b>%{text}</b><br>Observed Probability: %{y:.3f}<extra></extra>',
                                 text=[f'{name}'] * len(prob_pred)))
        fig.add_trace(
            go.Scatter(x=[0, 1], y=[0, 1], mode='lines', line=dict(dash='dash', color='grey'), showlegend=False))
        fig.update_layout(title=f'{data_name}', xaxis_title='Predicted Probability', yaxis_title='Observed Probability',
                          xaxis=dict(range=[0, 1], hoverformat='.3f'), yaxis=dict(range=[0, 1]),
                          legend=dict(x=1, y=0, xanchor='right'), hovermode='x unified')
    plot.plot(fig, filename=f'../plot/interactive_calib_{data_name}.html', auto_open=False)
    return fig


def multi_models_dc(data_name, model_names, methods, colors, X_test, y_test, dpin=100):
    plt.figure(figsize=(8, 6), dpi=dpin)
    plt.title(f'{data_name}')
    dc_data = pd.DataFrame({'true_outcome': y_test})
    for name, method in zip(model_names, methods):
        y_prob = method.predict_proba(X_test)[:, 1]
        dc_data[name] = y_prob
    dcurves_results = dca(data=dc_data, outcome='true_outcome', modelnames=model_names)
    dcurves_results.to_csv(f'../results/dc_results_{data_name}.csv')
    plot_graphs(plot_df=dcurves_results, graph_type='net_benefit', y_limits=[-0.05, 0.25], color_names=colors,
                file_name=f'../plot/multi_models_dc_{data_name}.png')
    # plt.figure(figsize=(8, 6), dpi=dpin)
    # plot_graphs(plot_df=dcurves_results, graph_type='net_intervention_avoided', color_names=colors, file_name=f'../plot/multi_models_dc_nia_{data_name}.png')


def ineractive_dc(data_name, model_names, model_names_dc, methods, colors, X_test, y_test):
    dc_data = pd.DataFrame({'true_outcome': y_test})
    for name, method in zip(model_names, methods):
        y_prob = method.predict_proba(X_test)[:, 1]
        dc_data[name] = y_prob
    dcurves_results = dca(data=dc_data, outcome='true_outcome', modelnames=model_names)
    # create Plotly figure
    fig = go.Figure()
    for name, color in zip(model_names_dc, colors):
        model_data = dcurves_results[dcurves_results['model'] == name]
        fig.add_trace(go.Scatter(x=model_data['threshold'], y=model_data['net_benefit'], mode='lines',
                                 name=f'{name}', line=dict(color=color),
                                 hovertemplate='<b>%{text}</b><br>Net Benefit: %{y:.2%}<extra></extra>',
                                 text=[f'{name}'] * len(model_data)))

    fig.update_layout(title=f'{data_name}', xaxis_title='Threshold Probability', yaxis_title='Net Benefit',
                      yaxis=dict(range=[-0.05, 0.25]), xaxis=dict(hoverformat='.0%'),
                      legend=dict(x=1, y=0.25, xanchor='right'), hovermode='x unified')
    plot(fig, filename=f'../plot/interactive_dc_{data_name}.html', auto_open=False)
    return fig


def brier_score_cal(methods, X_test, y_test):
    _, _, bounds_brier = bootstrap_metrics(methods, X_test, y_test)
    brier_score_list = []
    for i, method in enumerate(methods):
        y_prob = method.predict_proba(X_test)[:, 1]
        brier_score = brier_score_loss(y_test, y_prob)
        brier_score_list.append(round(brier_score, 3))
    return brier_score_list, bounds_brier


def log_odds_to_probability(log_odds):
    return 1 / (1 + np.exp(-log_odds))


def plot_shap(X_train, methods, model_names, single_index):
    for name, method in zip(model_names, methods):
        # transform X to selected features, lose feature names
        transform_X = method.named_steps['feature_selection'].transform(X_train)

        # get the selected feature names
        selected_features = method.named_steps['feature_selection'].get_support(indices=True)
        feature_names = [X_train.columns[i] for i in selected_features]

        # best classifier
        best_classifier = method.named_steps['classification']

        # get SHAP values
        if name == 'Random Forest':
            explainer = shap.Explainer(best_classifier, transform_X)
            shap_values_train = explainer(transform_X)[:, :, -1]
            lower_bound = -0.5
        elif name == 'AdaBoost':
            explainer = shap.Explainer(best_classifier.predict_proba, transform_X)
            shap_values_train = explainer(transform_X)[:, :, -1]
            lower_bound = -0.1
        else:
            explainer = shap.Explainer(best_classifier, transform_X)
            shap_values_train = explainer(transform_X)
            lower_bound = -2
        shap_values_train.feature_names = feature_names

        # limit the range of SHAP value to display
        upper_bound = 1.5
        clipped_shap_values_train = np.clip(shap_values_train.values, lower_bound, upper_bound)

        # plot
        shap.plots.beeswarm(
            shap.Explanation(values=clipped_shap_values_train, base_values=shap_values_train.base_values,
                             feature_names=shap_values_train.feature_names, data=shap_values_train.data),
            max_display=18, show=False)

        ax = plt.gca()
        mean_shap_values = np.mean(np.abs(shap_values_train.values), axis=0)
        feature_names = shap_values_train.feature_names
        feature_order = np.argsort(mean_shap_values)
        for i, feature_idx in enumerate(feature_order):
            mean_value = mean_shap_values[feature_idx]
            ax.barh(i, mean_value, color='darkcyan', height=0.5, left=lower_bound)
        plt.gcf().set_size_inches(10, 8)
        plt.gcf().set_dpi(200)
        plt.tight_layout()
        plt.savefig(f'../plot/beeswarm_{name}.jpg')
        plt.clf()

        # waterfall plot for a single sample
        single_data = shap_values_train.data[single_index]
        single_shapvalue = shap_values_train.values[single_index]
        single_base = shap_values_train.base_values[single_index]

        # covert base value and SHAP values to probability
        base_value_prob = log_odds_to_probability(single_base)

        prob_step = log_odds_to_probability(single_base + np.cumsum(single_shapvalue))
        pro_step_all = np.insert(prob_step, 0, base_value_prob)
        shap_value_prob = np.diff(pro_step_all)

        shap_explanation_prob = shap.Explanation(values=shap_value_prob, base_values=base_value_prob,
                                                 data=single_data,
                                                 feature_names=feature_names)

        # plot
        shap.plots.waterfall(shap_explanation_prob, max_display=18, show=False)
        plt.gcf().set_size_inches(8, 8)
        plt.gcf().set_dpi(100)
        plt.tight_layout()
        plt.savefig(f'../plot/waterfall_{name}_{single_index}.jpg')
        plt.clf()
