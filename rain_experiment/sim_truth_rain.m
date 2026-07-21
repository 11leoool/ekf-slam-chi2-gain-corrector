function D = sim_truth_rain(C, seed, R_mmh, rainP)
% sim_truth_rain  Thrun-model ground truth + RAIN-DEGRADED measurements.
%
%   D = sim_truth_rain(C, seed, R_mmh, rainP)
%
% Identical to sim_truth_thrun except the range-bearing measurements pass
% through the Goodin et al. (2019) rain model (rain_lidar_model.m):
%   - range noise:  sigma_total^2 = sigma_clear^2 + [0.02 z (1-e^-R)^2]^2
%   - dropout:      return lost when z^2 exp(2*0.01*R^0.6*z) > zmax^2
%     (lost measurements are NaN; filters must skip them)
%   - bearing keeps the clear-weather noise (no published rain dependence)
%
% rainP: struct for rain_lidar_model (.zmax default 80, .beta_rel 1)
% Extra outputs: D.detfrac (fraction of measurements detected),
%                D.R_mmh
%
% The FILTER is configured with the clear-weather C.R -- rain is a
% miscalibration the filter does not know about. That is the experiment.

if nargin < 4, rainP = struct(); end
rng(seed, 'twister');
T = C.T;  dt = C.dt;  N = C.N;

u_cmd  = [C.v_cmd*ones(T,1), C.w_cmd*ones(T,1)];
u_true = u_cmd + randn(T,2) .* sqrt(diag(C.Qu))';

X = zeros(T,3);
X(1,:) = C.x0';
for k = 2:T
    p = exact_arc(X(k-1,:)', u_true(k-1,:)', dt);
    X(k,:) = p';
end

sig = sqrt(diag(C.R))';        % clear-weather sigma_d, sigma_phi
Z = nan(T, 2, N);
ndet = 0;
for k = 1:T
    for i = 1:N
        dx = C.lm(i,1) - X(k,1);
        dy = C.lm(i,2) - X(k,2);
        r_true = sqrt(dx^2 + dy^2);
        rp = rainP;  rp.seedless = true;
        [~, det_ok, sig_rain] = rain_lidar_model(r_true, R_mmh, rp);
        if ~det_ok, continue; end          % dropout -> stays NaN
        ndet = ndet + 1;
        sig_d = sqrt(sig(1)^2 + sig_rain^2);
        Z(k,1,i) = r_true + randn()*sig_d;
        Z(k,2,i) = wrap_pi(atan2(dy,dx) - X(k,3) + randn()*sig(2));
    end
end

D.X_true  = X;
D.Z       = Z;
D.u       = u_cmd;
D.seed    = seed;
D.R_mmh   = R_mmh;
D.detfrac = ndet / (T*N);
end
