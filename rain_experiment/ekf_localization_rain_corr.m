function out = ekf_localization_rain_corr(C, D, corr, const_s)
% ekf_localization_rain_corr  Known-map EKF localization with gain correction.
%
%   out = ekf_localization_rain_corr(C, D, corr, const_s)
%
% corr = 'ekf'   : no correction (baseline)
%        'chi2'  : two-pass normalized-NIS gain scaling (thesis Ch3 rule):
%                  per step, global NIS over AVAILABLE (non-NaN) measurements
%                  from the prior; if nis >= tau, s = clamp(1/nis, smin, 1)
%        'const' : constant gain scale s = const_s
%
% Known data association; missed detections (NaN) skipped. Same filter as
% ekf_localization_thrun otherwise. tau = 1.45, smin = 0.15 (paper values).

if nargin < 3, corr = 'ekf'; end
tau = 1.45;  smin = 0.15;
T = C.T;  dt = C.dt;  N = C.N;

x = C.x0;
P = C.P0pose * eye(3);
Xhat = zeros(T,3);  Xhat(1,:) = x';
s_hist = ones(T,1);

for k = 2:T
    [x, G, V] = exact_arc(x, D.u(k-1,:)', dt);
    P = G*P*G' + V*C.Qu*V';
    P = 0.5*(P+P');

    % ---- corrector: two-pass NIS over available measurements ----
    s_step = 1;
    if strcmp(corr, 'chi2')
        nis = 0;  n_avail = 0;
        for i = 1:N
            z = [D.Z(k,1,i); D.Z(k,2,i)];
            if any(isnan(z)), continue; end
            [zh, ~, S] = predict_meas(x, P, C.lm(i,:), C.R);
            nu = [z(1)-zh(1); wrap_pi(z(2)-zh(2))];
            nis = nis + nu' * (S \ nu);
            n_avail = n_avail + 1;
        end
        if n_avail > 0
            nis = nis / (2*n_avail);
            if nis >= tau, s_step = min(max(1/nis, smin), 1); end
        end
    elseif strcmp(corr, 'const')
        s_step = const_s;
    end
    s_hist(k) = s_step;

    for i = 1:N
        z = [D.Z(k,1,i); D.Z(k,2,i)];
        if any(isnan(z)), continue; end
        [zh, H, S] = predict_meas(x, P, C.lm(i,:), C.R);
        nu = [z(1)-zh(1); wrap_pi(z(2)-zh(2))];
        K  = s_step * (P*H'/S);
        x  = x + K*nu;
        x(3) = wrap_pi(x(3));
        A  = eye(3) - K*H;
        P  = A*P*A' + K*C.R*K';
        P  = 0.5*(P+P');
    end
    Xhat(k,:) = x';
end

ex = Xhat(:,1) - D.X_true(:,1);
ey = Xhat(:,2) - D.X_true(:,2);
out.rmse_pos = sqrt(mean(ex.^2 + ey.^2));
out.s_hist   = s_hist;
out.Xhat     = Xhat;
end

% -------------------------------------------------------------------------
function [zh, H, S] = predict_meas(x, P, lm, R)
dx = lm(1) - x(1);
dy = lm(2) - x(2);
q  = dx^2 + dy^2 + 1e-12;
r  = sqrt(q);
zh = [r; wrap_pi(atan2(dy,dx) - x(3))];
H  = [-dx/r, -dy/r,  0;
       dy/q, -dx/q, -1];
S  = H*P*H' + R;
S  = 0.5*(S+S');
end
