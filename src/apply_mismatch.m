function [Q_true, R_true] = apply_mismatch(Q_nominal, R_nominal, alpha, mismatch_type)
% APPLY_MISMATCH - Construct true noise covariances under mismatch model
%
% The filter operates with Q_nominal and R_nominal. The "true" data-generating
% process uses inflated covariances determined by the mismatch type and alpha.
%
% INPUTS:
%   Q_nominal     - Filter's assumed process noise covariance [n x n]
%   R_nominal     - Filter's assumed measurement noise covariance [m x m]
%   alpha         - Inflation factor (alpha >= 1)
%   mismatch_type - 'symmetric' (default) | 'Q_only' | 'R_only' | 'none'
%
% OUTPUTS:
%   Q_true        - True process noise covariance for noise generation
%   R_true        - True measurement noise covariance for noise generation
%
% NOTES:
%   - 'symmetric': both Q and R inflated by alpha
%   - 'Q_only':    only Q inflated, R matches filter
%   - 'R_only':    only R inflated, Q matches filter
%   - 'none':      both match filter (matched-noise case)

    if nargin < 4
        mismatch_type = 'symmetric';
    end

    switch lower(mismatch_type)
        case 'symmetric'
            Q_true = alpha * Q_nominal;
            R_true = alpha * R_nominal;

        case 'q_only'
            Q_true = alpha * Q_nominal;
            R_true = R_nominal;

        case 'r_only'
            Q_true = Q_nominal;
            R_true = alpha * R_nominal;

        case 'none'
            Q_true = Q_nominal;
            R_true = R_nominal;

        otherwise
            error('Unknown mismatch type: %s', mismatch_type);
    end

end
