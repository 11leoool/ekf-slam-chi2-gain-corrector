function [x_hist, P_hist, gate_active] = run_mlp_corrector(sim, landmarks, Q, R)
% RUN_MLP_CORRECTOR - EKF-SLAM with MLP-predicted gain correction
%
% NOTE: requires a trained model saved as mlp_corrector.mat (variable: net).
% If not present, falls back to identity correction (no-op).

    [T, M, ~] = size(sim.observations);
    state_dim = 3 + 2*M;
    dt = sim.dt;

    % --- Load trained MLP (cached across calls) ---
    persistent mlp_net mlp_loaded
    if isempty(mlp_loaded)
        try
            data = load('mlp_corrector.mat');
            mlp_net = data.net;
        catch
            warning('MLP model not found in mlp_corrector.mat - using identity');
            mlp_net = [];
        end
        mlp_loaded = true;
    end

    % --- Initialise ---
    x = zeros(state_dim, 1);
    x(1:3) = sim.initial_pose;
    x(4:end) = reshape(landmarks', [], 1);
    P = blkdiag(0.001*eye(3), 1.0*eye(2*M));

    x_hist = zeros(T, state_dim);
    P_hist = zeros(state_dim, state_dim, T);
    gate_active = false(T, 1);

    for t = 1:T
        u = sim.controls_noisy(t, :)';
        [x, P] = ekf_predict_step(x, P, u, Q, dt);

        % --- Compute features for the MLP ---
        nis_sum = 0;
        nu_norm_sum = 0;
        n_visible = 0;
        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [nu, S, ~, ~] = ekf_innovation(x, P, z, i, R);
                nis_sum = nis_sum + nu' * (S \ nu);
                nu_norm_sum = nu_norm_sum + norm(nu);
                n_visible = n_visible + 1;
            end
        end

        if n_visible > 0
            chi2_global = nis_sum / n_visible;
            avg_innov = nu_norm_sum / n_visible;
        else
            chi2_global = 0;
            avg_innov = 0;
        end

        features = [chi2_global; avg_innov; trace(P(1:3,1:3))];

        % --- Predict gain scalar with MLP ---
        if ~isempty(mlp_net)
            s_delta = predict(mlp_net, features');
            s = max(min(1.0 + s_delta, 1.0), 0.15);
        else
            s = 1.0;  % fallback if model unavailable
        end

        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [x, P] = ekf_update_step_scaled(x, P, z, i, R, s);
            end
        end

        x_hist(t, :) = x';
        P_hist(:, :, t) = P;
    end
end
