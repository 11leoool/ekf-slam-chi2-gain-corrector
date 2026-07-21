function [d_meas, detected, sigma_rain] = rain_lidar_model(d_true, R_mmh, P)
% rain_lidar_model  Physically-based rain degradation of lidar range returns.
%
%   [d_meas, detected, sigma_rain] = rain_lidar_model(d_true, R_mmh, P)
%
% Implements the Goodin et al. model (Electronics 2019, 8(1):89), whose
% constants were fitted to Filgueira et al.'s (Measurement 2017) VLP-16
% measurements in natural rain:
%
%   extinction   : gamma = a*R^b            with a = 0.01, b = 0.6   (Eq. 5)
%   rel. power   : Pn(z) = beta z^-2 e^(-2 gamma z)                  (Eq. 8)
%   detection    : Pn(z) >= 0.9/(pi zmax^2) (90% target spec)        (Eq. 4)
%   range noise  : sigma = 0.02 z (1 - e^-R)^2   [saturates at 2% z] (Eq. 9)
%
% Inputs
%   d_true  : true ranges (any array shape), metres
%   R_mmh   : rainfall rate, mm/h (scalar; 0 = clear). Natural rain rarely
%             exceeds ~25 mm/h; >40 mm/h is artificial-rain territory.
%   P       : struct (all optional)
%             .zmax     spec-sheet max range in clear conditions for a 90%
%                       diffuse target [m], default 80 (SICK LMS 2xx class)
%             .beta_rel target reflectivity relative to the 90% reference,
%                       default 1 (retro-reflective beacons: >1)
%             .seedless if true, do not add noise (return sigma only)
%
% Outputs
%   d_meas     : rain-noised ranges (rain noise ONLY -- add the sensor's
%                clear-weather noise separately: they are independent, so
%                total variance = sigma_clear^2 + sigma_rain^2)
%   detected   : logical, same shape; false where the return is lost
%                (received power below detection threshold)
%   sigma_rain : the rain-induced range std dev per measurement [m]
%
% Note: the model covers RANGE degradation only. No published model ties
% bearing error to rain rate for scanning lidar (beam direction is set by
% the encoder, not the medium), so keep the clear-weather bearing noise.

if nargin < 3, P = struct(); end
if ~isfield(P,'zmax'),     P.zmax = 80;    end
if ~isfield(P,'beta_rel'), P.beta_rel = 1; end
if ~isfield(P,'seedless'), P.seedless = false; end

gamma = 0.01 * R_mmh^0.6;                          % extinction [1/m]

% --- detection: beta_rel * z^-2 e^(-2 gamma z) >= zmax^-2  (Eq. 3 vs Eq. 4)
detected = d_true.^2 .* exp(2*gamma*d_true) <= P.beta_rel * P.zmax^2;

% --- range noise (Eq. 9) ---
sigma_rain = 0.02 .* d_true .* (1 - exp(-R_mmh)).^2;
if P.seedless
    d_meas = d_true;
else
    d_meas = d_true + sigma_rain .* randn(size(d_true));
end
end
