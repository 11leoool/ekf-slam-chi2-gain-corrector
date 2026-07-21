function C = thrun_params(nLandmarks)
% thrun_params  Configuration for the Thrun-model (3-state) foundational sims.
%
%   C = thrun_params(nLandmarks)   nLandmarks in {1, 3, 10}, default 3
%
% These are the 3-state, commanded-input replacements for the legacy
% 5-state Mao-model scripts (One_landmark.m, SLAM_threestates.m,
% five_range.m, *_unkown_correspondance.m in ..\ch3_foundational_slam\).
% Landmark coordinates and noise variances are kept IDENTICAL to the
% legacy sims for comparability; what changes is the model:
%
%   Mao (legacy) : state [x y theta omega v], velocities are random-walk
%                  STATES the filter must estimate (no known input).
%   Thrun (here) : state [x y theta], commanded input u = [v; omega] known
%                  to the filter; actuation noise = process noise mapped
%                  through the control Jacobian V (Probabilistic Robotics,
%                  Ch. 5.3); exact-arc propagation for the EKF.

if nargin < 1, nLandmarks = 3; end

% ---- timing / trajectory (commanded circle) ----
C.dt    = 0.1;            % [s]
C.T     = 600;            % steps (60 s, one+ lap)
C.x0    = [5; 5; 0];      % initial pose (known to filter, matches legacy)
C.v_cmd = 1.0;            % [m/s]
C.w_cmd = 0.1;            % [rad/s]  -> circle radius v/w = 10 m

% ---- noise ----
C.Qu = diag([0.01, 0.01]);     % actuation noise var on (v, omega) (legacy)
% Measurement noise DELIBERATELY differs from the legacy sims. The legacy
% bearing variance 1e-6 (sigma = 0.06 deg) is physically implausible and,
% at this scenario's 20-35 m ranges, makes the EKF-SLAM filter so
% overconfident that its own linearization error dominates (the classic
% EKF-SLAM inconsistency of Bailey et al.) -- which in turn wrecks
% Mahalanobis data association (duplicate-landmark storms). Realistic
% values below keep the filter consistent and the DA gates meaningful.
C.R  = diag([0.01, 1e-4]);     % range var (sigma 0.1 m), bearing var (sigma 0.01 rad)

% ---- landmarks (legacy coordinates) ----
switch nLandmarks
    case 1
        C.lm = [20, 50];
    case 3
        C.lm = [-16,  15.3;  15.8, 14.3; -14.5, -14.9];
    case 10
        C.lm = [-16,  15.3;  15.8, 14.3; -14.5, -14.9;
                 14, -18;    13.3, 12.3;  33,    23;
                 12,  -1.3;  12.3, -3.3;   5.6,   7.5;  2.4, -11.2];
    otherwise
        error('thrun_params: nLandmarks must be 1, 3 or 10');
end
C.N = size(C.lm, 1);

% ---- filter initialization ----
C.P0pose = 1e-6;          % pose known at start (legacy convention)
C.lm_prior_var = 1e6;     % landmark prior at first sighting (SLAM)

% ---- data association (unknown-correspondence variants) ----
% Dual-threshold rule (standard practice): associate when the best
% Mahalanobis distance is below gate_gamma; create a NEW landmark only
% when it exceeds newlm_gamma for ALL mapped landmarks; discard the
% measurement in the ambiguous band between the two. A single shared
% threshold spawns duplicate landmarks whenever a transient pose error
% exceeds the (here very tight, sigma_phi = 1e-3 rad) measurement noise.
C.gate_gamma  = 9.21;     % chi2(2) 99% association gate
C.newlm_gamma = 100;      % new-landmark threshold (>> gate)
end
