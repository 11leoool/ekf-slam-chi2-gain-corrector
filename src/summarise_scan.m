function summarise_scan(results)
% SUMMARISE_SCAN - Print human-readable summary tables from main_experiment_runner output
%
% Produces three tables:
%   1. Mean RMSE per filter, per condition
%   2. Mean NEES per filter, per condition
%   3. Win rates of proposed vs each baseline
%
% INPUT:
%   results - Output of main_experiment_runner

    cond_keys = fieldnames(results);
    n_cond = length(cond_keys);
    if n_cond == 0
        fprintf('No results to summarise.\n');
        return;
    end

    % Get filter names from first condition
    filter_names = fieldnames(results.(cond_keys{1}));
    n_filt = length(filter_names);

    % --- Sort condition keys by mismatch type then alpha ---
    sorted_keys = sort_condition_keys(cond_keys);

    % ================================================================
    % TABLE 1: Mean RMSE
    % ================================================================
    print_separator('TABLE 1: Mean Pose RMSE (metres)');
    print_table_header(filter_names);
    for i = 1:length(sorted_keys)
        k = sorted_keys{i};
        cond = results.(k);
        vals = zeros(1, n_filt);
        for f = 1:n_filt
            vals(f) = mean(cond.(filter_names{f}).rmse);
        end
        print_table_row(k, vals, '%9.4f');
    end

    % ================================================================
    % TABLE 2: Mean NEES (consistency)
    % ================================================================
    print_separator('TABLE 2: Mean NEES (target ~3.0 for consistent pose filter)');
    print_table_header(filter_names);
    for i = 1:length(sorted_keys)
        k = sorted_keys{i};
        cond = results.(k);
        vals = zeros(1, n_filt);
        for f = 1:n_filt
            vals(f) = mean(cond.(filter_names{f}).nees_avg);
        end
        print_table_row(k, vals, '%9.2f');
    end

    % ================================================================
    % TABLE 3: Gate activation % (for proposed only)
    % ================================================================
    if any(strcmp(filter_names, 'proposed'))
        print_separator('TABLE 3: Gate Activation Rate for Proposed (% of timesteps)');
        fprintf('  %-30s | %s\n', 'Condition', 'Gate active %');
        fprintf('  %s\n', repmat('-', 1, 50));
        for i = 1:length(sorted_keys)
            k = sorted_keys{i};
            v = 100 * mean(results.(k).proposed.gate_pct);
            fprintf('  %-30s | %12.1f\n', k, v);
        end
    end

    % ================================================================
    % TABLE 4: Win rates of proposed vs each baseline
    % ================================================================
    if any(strcmp(filter_names, 'proposed'))
        baselines = setdiff(filter_names, {'proposed'});
        if ~isempty(baselines)
            print_separator('TABLE 4: Win rate of Proposed vs each baseline (% of trials)');
            header = '  Condition                      |';
            for b = 1:length(baselines)
                header = [header sprintf(' vs %-12s |', baselines{b})];
            end
            fprintf('%s\n', header);
            fprintf('  %s\n', repmat('-', 1, length(header) - 2));

            for i = 1:length(sorted_keys)
                k = sorted_keys{i};
                cond = results.(k);
                row = sprintf('  %-30s |', k);
                for b = 1:length(baselines)
                    wins = mean(cond.proposed.rmse < cond.(baselines{b}).rmse);
                    row = [row sprintf(' %12.0f%% |', 100*wins)];
                end
                fprintf('%s\n', row);
            end
        end
    end

    % ================================================================
    % TABLE 5: Mean inference time per timestep
    % ================================================================
    print_separator('TABLE 5: Mean inference time per trial (seconds)');
    print_table_header(filter_names);
    for i = 1:length(sorted_keys)
        k = sorted_keys{i};
        cond = results.(k);
        vals = zeros(1, n_filt);
        for f = 1:n_filt
            vals(f) = mean(cond.(filter_names{f}).time);
        end
        print_table_row(k, vals, '%9.4f');
    end

    fprintf('\nSummary complete.\n');
end

% ====================================================================
% HELPERS
% ====================================================================
function sorted = sort_condition_keys(keys)
    % Sort by mismatch type (alphabetical), then alpha (numerical)
    parsed = cell(length(keys), 4);  % {mismatch_string, alpha_num, original_key, sort_key}
    for i = 1:length(keys)
        k = keys{i};
        % Format: <traj>_lm<N>_<mismatch>_a<alpha>
        parts = strsplit(k, '_');
        mismatch = parts{3};
        if length(parts) > 4
            % handle e.g. "Q_only" which has two parts
            mismatch = strjoin(parts(3:end-1), '_');
        end
        alpha_str = parts{end};
        alpha = sscanf(alpha_str, 'a%d');
        parsed{i, 1} = mismatch;
        parsed{i, 2} = alpha;
        parsed{i, 3} = k;
    end
    [~, order] = sortrows(cell2table(parsed(:, 1:2), 'VariableNames', {'m','a'}), {'m','a'});
    sorted = parsed(order, 3);
end

function print_separator(title)
    fprintf('\n%s\n', repmat('=', 1, 75));
    fprintf('  %s\n', title);
    fprintf('%s\n', repmat('=', 1, 75));
end

function print_table_header(filter_names)
    h = sprintf('  %-30s |', 'Condition');
    for f = 1:length(filter_names)
        h = [h sprintf(' %9s |', filter_names{f})];
    end
    fprintf('%s\n', h);
    fprintf('  %s\n', repmat('-', 1, length(h) - 2));
end

function print_table_row(label, vals, fmt)
    row = sprintf('  %-30s |', label);
    for v = 1:length(vals)
        row = [row sprintf([' ' fmt ' |'], vals(v))];
    end
    fprintf('%s\n', row);
end
