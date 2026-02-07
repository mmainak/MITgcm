%==========================================================================
% TRACK_SEDIMENT_EVOLUTION.m
%
% Track sediment field evolution to identify WHERE and WHEN NaN appears
%==========================================================================

clear; close all; clc;

% Add MITgcm utilities
addpath(genpath('/scratch/mm10845/mbase_MITgcm/utils/matlab'));

fprintf('=== Tracking Sediment Evolution ===\n\n');

%% Read grid
XC = rdmds('XC'); YC = rdmds('YC'); RC = squeeze(rdmds('RC'));
hFacC = rdmds('hFacC');
[Nx, Ny, Nr] = size(hFacC);
fprintf('Grid: %dx%dx%d\n', Nx, Ny, Nr);

xgrid = XC(:,1); ygrid = YC(1,:);
mid_y = round(Ny/2);

%% Find all sediment timesteps
files = dir('PTRACER01.*.data');
if isempty(files), files = dir('S.*.data'); end
if isempty(files), error('No output files found!'); end

timesteps = [];
for k = 1:length(files)
    num = regexp(files(k).name, '\.([0-9]+)\.', 'tokens', 'once');
    if ~isempty(num), timesteps(end+1) = str2double(num{1}); end
end
timesteps = sort(unique(timesteps));
fprintf('Found %d timesteps: %d to %d\n\n', length(timesteps), min(timesteps), max(timesteps));

%% Track evolution
sed_max = nan(length(timesteps), 1);
sed_min = nan(length(timesteps), 1);
sed_mean = nan(length(timesteps), 1);
nan_count = zeros(length(timesteps), 1);
inf_count = zeros(length(timesteps), 1);

% Also track LOCATION of max
max_i = zeros(length(timesteps), 1);
max_j = zeros(length(timesteps), 1);
max_k = zeros(length(timesteps), 1);

fprintf('Reading sediment evolution...\n');
for t_idx = 1:length(timesteps)
    iter = timesteps(t_idx);
    
    try
        C = rdmds('PTRACER01', iter);
    catch
        fprintf('Could not read timestep %d\n', iter);
        continue;
    end
    
    sed_max(t_idx) = max(C(:));
    sed_min(t_idx) = min(C(:));
    sed_mean(t_idx) = mean(C(:));
    nan_count(t_idx) = sum(isnan(C(:)));
    inf_count(t_idx) = sum(isinf(C(:)));
    
    % Find location of max
    [~, idx] = max(C(:));
    [max_i(t_idx), max_j(t_idx), max_k(t_idx)] = ind2sub([Nx Ny Nr], idx);
    
    if mod(t_idx, 10) == 0
        fprintf('  Processed %d/%d timesteps\n', t_idx, length(timesteps));
    end
end

time_sec = timesteps * 0.25; % dt = 0.25s

%% Find when NaN first appears
nan_idx = find(nan_count > 0, 1, 'first');
if ~isempty(nan_idx)
    fprintf('\n*** NaN FIRST APPEARS at timestep %d (t=%.1fs) ***\n', ...
        timesteps(nan_idx), time_sec(nan_idx));
    fprintf('    Previous max: %.6e at iter %d\n', sed_max(nan_idx-1), timesteps(nan_idx-1));
    fprintf('    NaN location: i=%d, j=%d, k=%d\n', ...
        max_i(nan_idx), max_j(nan_idx), max_k(nan_idx));
else
    fprintf('\nNo NaN detected in sediment field.\n');
end

%% Plot evolution
fig = figure('Position', [100 100 1200 800]);

% Plot 1: Sediment statistics over time (log scale)
subplot(2,2,1);
semilogy(time_sec, sed_max, 'r-', 'LineWidth', 2); hold on;
semilogy(time_sec, sed_mean, 'b-', 'LineWidth', 2);
semilogy(time_sec, abs(sed_min), 'g--', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('Sediment [kg/m³] (log scale)');
title('Sediment Evolution');
legend('Max', 'Mean', '|Min|', 'Location', 'best');

% Mark where NaN appears
if ~isempty(nan_idx)
    plot(time_sec(nan_idx), sed_max(nan_idx-1), 'ro', 'MarkerSize', 15, 'LineWidth', 3);
    text(time_sec(nan_idx), sed_max(nan_idx-1), '  ← NaN', 'Color', 'r', 'FontSize', 12);
end

% Plot 2: NaN count over time
subplot(2,2,2);
plot(time_sec, nan_count, 'r-', 'LineWidth', 2);
grid on;
xlabel('Time [s]'); ylabel('Number of NaN cells');
title('NaN Count Evolution');

% Plot 3: Location of maximum sediment
subplot(2,2,3);
plot(time_sec, max_k, 'b.-', 'LineWidth', 1.5);
hold on;
yline(Nr-1, 'r--', 'Bottom (k=Nr)', 'LineWidth', 2);
yline(1, 'g--', 'Surface (k=1)', 'LineWidth', 2);
grid on;
xlabel('Time [s]'); ylabel('k-index of max sediment');
title('Vertical Location of Max Sediment');
ylim([0 Nr+1]);
set(gca, 'YDir', 'reverse'); % k increases downward

% Plot 4: Horizontal location
subplot(2,2,4);
plot(time_sec, max_i, 'r.-', 'LineWidth', 1.5); hold on;
plot(time_sec, max_j, 'b.-', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('Grid index');
title('Horizontal Location of Max Sediment');
legend('i-index (X)', 'j-index (Y)', 'Location', 'best');

sgtitle('Sediment Evolution Diagnostics');
saveas(fig, 'sediment_evolution_diagnostics.png');
fprintf('\nSaved: sediment_evolution_diagnostics.png\n');

%% Summary report
fprintf('\n=== SUMMARY REPORT ===\n');
fprintf('Total timesteps analyzed: %d\n', length(timesteps));
fprintf('Simulation time: %.1f seconds\n', max(time_sec));
fprintf('\nSediment statistics:\n');
fprintf('  Max value: %.6e kg/m³\n', max(sed_max));
fprintf('  Growth rate: %.2fx from start to end\n', sed_max(end)/max(sed_max(1), 1e-10));

if ~isempty(nan_idx)
    fprintf('\n⚠️  NaN APPEARED:\n');
    fprintf('    First NaN at timestep %d (t=%.1fs)\n', timesteps(nan_idx), time_sec(nan_idx));
    fprintf('    Max before NaN: %.6e\n', sed_max(nan_idx-1));
    fprintf('    Location: i=%d (x=%.1fm), j=%d (y=%.1fm), k=%d (z=%.1fm)\n', ...
        max_i(nan_idx), xgrid(max_i(nan_idx)), ...
        max_j(nan_idx), ygrid(max_j(nan_idx)), ...
        max_k(nan_idx), RC(max_k(nan_idx)));
    
    % Identify region
    if max_k(nan_idx) <= 5
        fprintf('    Region: NEAR SURFACE\n');
    elseif max_k(nan_idx) >= Nr-5
        fprintf('    Region: NEAR BOTTOM\n');
    else
        fprintf('    Region: MID-DEPTH\n');
    end
    
    if max_i(nan_idx) <= 2
        fprintf('    Boundary: WEST (conduit)\n');
    elseif max_i(nan_idx) >= Nx-2
        fprintf('    Boundary: EAST (sponge)\n');
    else
        fprintf('    Boundary: INTERIOR\n');
    end
else
    fprintf('\n✓ No NaN detected\n');
    if max(sed_max) > 100
        fprintf('⚠️  But sediment is growing to %.2e (unstable!)\n', max(sed_max));
    elseif max(sed_max) < 10
        fprintf('✓ Sediment values are reasonable (< 10 kg/m³)\n');
    end
end

fprintf('\n=== DONE ===\n');
