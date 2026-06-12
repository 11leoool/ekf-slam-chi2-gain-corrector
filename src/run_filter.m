function [x_hist, P_hist, gate_active] = run_filter(filter_name, sim, landmarks, Q_nominal, R_nominal)
% RUN_FILTER - Dispatch to the appropriate EKF-SLAM variant
%
% INPUTS:
%   filter_name - 'nominal' | 'sage_husa' | 'mlp' | 'proposed'
%   sim         - Output of simulate_trajectory
%   landmarks   - [M x 2] true landmark positions (used for state init only;
%                 filter does NOT receive ground-truth positions during runtime)
%   Q_nominal, R_nominal - Filter's assumed noise covariances
%
% OUTPUTS:
%   x_hist      - [T x (3+2M)] state estimate history
%   P_hist      - [(3+2M) x (3+2M) x T] covariance history
%   gate_active - [T x 1] logical, true if corrector activated at that step
%                 (always false for nominal and sage_husa; meaningful for proposed)

    switch lower(filter_name)
        case 'nominal'
            [x_hist, P_hist, gate_active] = run_nominal_ekf(sim, landmarks, Q_nominal, R_nominal);

        case 'sage_husa'
            [x_hist, P_hist, gate_active] = run_sage_husa_full(sim, landmarks, Q_nominal, R_nominal);

        case 'mlp'
            [x_hist, P_hist, gate_active] = run_mlp_corrector(sim, landmarks, Q_nominal, R_nominal);

        case 'proposed'
            [x_hist, P_hist, gate_active] = run_proposed_corrector(sim, landmarks, Q_nominal, R_nominal);

        case 'strong_tracking'
            [x_hist, P_hist, gate_active] = run_strong_tracking(sim, landmarks, Q_nominal, R_nominal);

        otherwise
            error('Unknown filter: %s', filter_name);
    end
end
