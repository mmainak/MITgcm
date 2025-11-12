%% analyze_sediment_output.m
%
% Analyze MITgcm sediment simulation output
%
% PURPOSE:
% --------
% Read and visualize sediment tracer evolution from MITgcm output.
% Computes diagnostics: settling rate, mass budget, vertical profiles.
%
% USAGE:
% ------
% 1. Copy this script to your MITgcm run directory
% 2. Run after simulation: matlab -nodisplay < analyze_sediment_output.m
% 3. Or interactive: matlab, then run this script
%
% REQUIRES:
% ---------
% - MITgcm output files: SEDIMENT.*.data and SEDIMENT.*.meta
% - rdmds.m (MITgcm utility for reading binary output)
%   Download from: $MITGCM_ROOT/utils/matlab/
%
% OUTPUT:
% -------
% - Time series plots of sediment evolution
% - Vertical profiles at different times
% - Mass budget analysis
% - Settling verification
% - Comparison with theoretical predictions
%
%==========================================================================

clear all;
close all;

fprintf('\n');
fprintf('=============================================================\n');
fprintf('  SEDIMENT OUTPUT ANALYSIS\n');
fprintf('=============================================================\n');
fprintf('\n');

%% CONFIGURATION
%==========================================================================

% Grid parameters (must match SIZE.h)
nx = 100;
ny = 100;
nz = 20;
dx = 100;    % [m]
dy = 100;    % [m]
dz = 10;     % [m]

% Time parameters (from data)
dt = 100;    % Time step [s]
dumpFreq = 3600;  % Output frequency [s]

% Physical parameters (from data.sediment)
ws0 = 0.01;       % Settling velocity [m/s]
gammaC = 1.6e-3;  % Density coefficient [m³/kg]
rho_water = 1025; % Water density [kg/m³]
g = 9.81;         % Gravity [m/s²]

% Tracer name (from data.ptracers)
tracerName = 'SEDIMENT';

fprintf('Grid: %d x %d x %d\n', nx, ny, nz);
fprintf('Resolution: %.0f x %.0f x %.0f m\n', dx, dy, dz);
fprintf('Settling velocity: %.4f m/s\n', ws0);
fprintf('\n');

%% COORDINATE ARRAYS
%==========================================================================

x = (0.5:nx-0.5) * dx;
y = (0.5:ny-0.5) * dy;
z = -(0.5:nz-0.5) * dz;  % Depth negative

[X, Y, Z] = meshgrid(x, y, z);

%% FIND OUTPUT FILES
%==========================================================================

% Look for tracer output files
% MITgcm naming: SEDIMENT.0000000000.data, SEDIMENT.0000003600.data, etc.

fprintf('Searching for output files...\n');

% Try different possible names
possibleNames = {'SEDIMENT', 'PTRACERS', 'ptr01', 'Tr01'};
files = {};

for n = 1:length(possibleNames)
    pattern = sprintf('%s.*.data', possibleNames{n});
    fileList = dir(pattern);
    if ~isempty(fileList)
        fprintf('  Found %d files matching %s\n', length(fileList), pattern);
        baseFileName = possibleNames{n};
        files = fileList;
        break;
    end
end

if isempty(files)
    error('No tracer output files found! Check that simulation completed.');
end

% Extract time stamps from file names
nFiles = length(files);
times = zeros(nFiles, 1);

for i = 1:nFiles
    % Extract iteration number from filename
    fname = files(i).name;
    % Format: SEDIMENT.0000003600.data
    tokens = regexp(fname, '\.(\d+)\.data', 'tokens');
    if ~isempty(tokens)
        iter = str2double(tokens{1}{1});
        times(i) = iter * dt;  % Convert to seconds
    end
end

% Sort by time
[times, sortIdx] = sort(times);
files = files(sortIdx);

fprintf('Found %d output times\n', nFiles);
fprintf('  Time range: %.2f to %.2f hours\n', times(1)/3600, times(end)/3600);
fprintf('\n');

%% READ DATA
%==========================================================================

fprintf('Reading sediment concentration fields...\n');

% Preallocate storage
sediment = zeros(ny, nx, nz, nFiles);

for i = 1:nFiles
    fname = files(i).name;
    fname_base = fname(1:end-5);  % Remove .data extension
    
    try
        % Use rdmds if available, otherwise read manually
        if exist('rdmds', 'file')
            data = rdmds(fname_base);
        else
            % Manual binary read
            fid = fopen(fname, 'r', 'ieee-be');
            data = fread(fid, [nx*ny*nz, 1], 'real*8');
            fclose(fid);
            data = reshape(data, ny, nx, nz);
        end
        
        sediment(:,:,:,i) = data;
        
        if mod(i, 10) == 0
            fprintf('  Read %d/%d files\n', i, nFiles);
        end
    catch ME
        fprintf('  Warning: Could not read %s: %s\n', fname, ME.message);
    end
end

fprintf('Data loaded.\n\n');

%% MASS BUDGET ANALYSIS
%==========================================================================

fprintf('Computing mass budget...\n');

% Total sediment mass vs time
totalMass = zeros(nFiles, 1);
cellVolume = dx * dy * dz;

for i = 1:nFiles
    totalMass(i) = sum(sediment(:,:,:,i), 'all') * cellVolume;
end

fprintf('  Initial mass: %.4e kg\n', totalMass(1));
fprintf('  Final mass: %.4e kg\n', totalMass(end));
fprintf('  Loss: %.4e kg (%.2f%%)\n', ...
    totalMass(1) - totalMass(end), ...
    100 * (totalMass(1) - totalMass(end)) / totalMass(1));

% Mass loss rate (should equal settling flux out bottom)
if nFiles > 1
    dMdt = diff(totalMass) ./ diff(times);
    meanLossRate = mean(dMdt);
    fprintf('  Mean loss rate: %.4e kg/s\n', abs(meanLossRate));
end

%% VERTICAL PROFILE EVOLUTION
%==========================================================================

fprintf('Computing vertical profiles...\n');

% Horizontally averaged concentration
C_profile = zeros(nz, nFiles);

for i = 1:nFiles
    C_profile(:,i) = squeeze(mean(mean(sediment(:,:,:,i), 1), 2));
end

%% CENTER OF MASS TRACKING
%==========================================================================

fprintf('Tracking center of mass...\n');

% Vertical center of mass
z_com = zeros(nFiles, 1);

for i = 1:nFiles
    C_total = sum(sediment(:,:,:,i), 'all');
    if C_total > 0
        z_weighted = 0;
        for k = 1:nz
            z_weighted = z_weighted + z(k) * sum(sediment(:,:,k,i), 'all');
        end
        z_com(i) = z_weighted / C_total;
    end
end

% Theoretical settling distance
z_theory = z_com(1) - ws0 * times;

% Compare to theory
if nFiles > 1
    settling_error = abs(z_com - z_theory);
    fprintf('  Center of mass settling:\n');
    fprintf('    Initial: %.2f m\n', z_com(1));
    fprintf('    Final: %.2f m\n', z_com(end));
    fprintf('    Distance settled: %.2f m\n', z_com(1) - z_com(end));
    fprintf('    Theoretical: %.2f m\n', z_theory(1) - z_theory(end));
    fprintf('    RMS error: %.4f m\n', sqrt(mean(settling_error.^2)));
end

%% VISUALIZATION
%==========================================================================

fprintf('\nCreating visualizations...\n');

%% Figure 1: Mass Budget
figure('Position', [100 100 1400 500]);

subplot(1,3,1);
plot(times/3600, totalMass/totalMass(1), 'b-', 'LineWidth', 2);
grid on;
xlabel('Time [hours]');
ylabel('Relative Mass');
title('Total Sediment Mass');
ylim([0 1.1]);

if nFiles > 1
    subplot(1,3,2);
    plot(times(2:end)/3600, -dMdt, 'r-', 'LineWidth', 2);
    grid on;
    xlabel('Time [hours]');
    ylabel('Loss Rate [kg/s]');
    title('Mass Loss Rate');
end

subplot(1,3,3);
plot(times/3600, z_com, 'b-', 'LineWidth', 2);
hold on;
plot(times/3600, z_theory, 'r--', 'LineWidth', 2);
grid on;
xlabel('Time [hours]');
ylabel('Depth [m]');
legend('Simulated', 'Theoretical', 'Location', 'best');
title('Center of Mass Settling');
set(gca, 'YDir', 'reverse');

print('-dpng', '-r150', 'sediment_mass_budget.png');
fprintf('  Saved: sediment_mass_budget.png\n');

%% Figure 2: Vertical Profiles
figure('Position', [100 100 1200 600]);

% Select time snapshots to plot
if nFiles <= 6
    plotTimes = 1:nFiles;
else
    plotTimes = round(linspace(1, nFiles, 6));
end

% Color map for time evolution
colors = jet(length(plotTimes));

subplot(1,2,1);
for i = 1:length(plotTimes)
    idx = plotTimes(i);
    plot(C_profile(:,idx), z, 'Color', colors(i,:), 'LineWidth', 2);
    hold on;
end
grid on;
xlabel('Concentration [kg/m³]');
ylabel('Depth [m]');
title('Vertical Profiles (Evolution)');
set(gca, 'YDir', 'reverse');
legend(arrayfun(@(t) sprintf('t=%.1f h', times(t)/3600), plotTimes, 'UniformOutput', false), ...
    'Location', 'best');

% Hovmoller diagram (depth vs time)
subplot(1,2,2);
pcolor(times/3600, z, C_profile);
shading flat;
colorbar;
xlabel('Time [hours]');
ylabel('Depth [m]');
title('Hovmoller Diagram');
set(gca, 'YDir', 'reverse');
colormap(jet);

print('-dpng', '-r150', 'sediment_vertical_profiles.png');
fprintf('  Saved: sediment_vertical_profiles.png\n');

%% Figure 3: Spatial Snapshots
figure('Position', [100 100 1400 800]);

nSnaps = min(6, nFiles);
snapTimes = round(linspace(1, nFiles, nSnaps));

for s = 1:nSnaps
    idx = snapTimes(s);
    
    % Vertical slice at mid-domain
    subplot(2, nSnaps, s);
    j_mid = round(ny/2);
    pcolor(x/1000, z, squeeze(sediment(j_mid,:,:,idx))');
    shading flat;
    colorbar;
    xlabel('x [km]');
    ylabel('z [m]');
    title(sprintf('t = %.1f h', times(idx)/3600));
    if s == 1, ylabel('z [m]'); end
    
    % Horizontal slice at mid-depth
    subplot(2, nSnaps, s + nSnaps);
    k_mid = round(nz/2);
    pcolor(x/1000, y/1000, sediment(:,:,k_mid,idx));
    shading flat;
    colorbar;
    xlabel('x [km]');
    if s == 1, ylabel('y [km]'); end
    title(sprintf('z = %.0f m', abs(z(k_mid))));
end

print('-dpng', '-r150', 'sediment_spatial_evolution.png');
fprintf('  Saved: sediment_spatial_evolution.png\n');

%% Figure 4: Buoyancy Field (Cycle 2 diagnostic)
figure('Position', [100 100 1200 400]);

% Compute sediment buoyancy contribution at final time
b_sed = -g * gammaC * sediment(:,:,:,end);

subplot(1,2,1);
j_mid = round(ny/2);
pcolor(x/1000, z, squeeze(b_sed(j_mid,:,:))');
shading flat;
colorbar;
xlabel('x [km]');
ylabel('z [m]');
title('Sediment Buoyancy b_{sed} = -g\gamma_C C');
caxis([-max(abs(b_sed(:))) max(abs(b_sed(:)))]);
colormap(redblue);

subplot(1,2,2);
% Density anomaly
delta_rho = rho_water * gammaC * sediment(:,:,:,end);
pcolor(x/1000, z, squeeze(delta_rho(j_mid,:,:))');
shading flat;
colorbar;
xlabel('x [km]');
ylabel('z [m]');
title('Density Anomaly \Delta\rho [kg/m³]');
colormap(jet);

print('-dpng', '-r150', 'sediment_buoyancy_field.png');
fprintf('  Saved: sediment_buoyancy_field.png\n');

%% SUMMARY STATISTICS
%==========================================================================

fprintf('\n');
fprintf('=============================================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('=============================================================\n');
fprintf('\n');
fprintf('Key Results:\n');
fprintf('  Simulation time: %.2f hours\n', times(end)/3600);
fprintf('  Mass conservation: %.2f%% retained\n', 100*totalMass(end)/totalMass(1));
fprintf('  Settling distance: %.2f m (theory: %.2f m)\n', ...
    z_com(1) - z_com(end), ws0 * times(end));
fprintf('  Peak concentration: %.4e kg/m³\n', max(sediment(:)));
fprintf('  Max buoyancy anomaly: %.4e m/s²\n', max(abs(b_sed(:))));
fprintf('  Max density anomaly: %.4f kg/m³\n', max(delta_rho(:)));
fprintf('\n');
fprintf('Figures saved:\n');
fprintf('  - sediment_mass_budget.png\n');
fprintf('  - sediment_vertical_profiles.png\n');
fprintf('  - sediment_spatial_evolution.png\n');
fprintf('  - sediment_buoyancy_field.png\n');
fprintf('\n');

%% Helper function for red-blue colormap
function cmap = redblue(m)
    if nargin < 1
        m = 64;
    end
    
    r = [(0:m/2-1)/(m/2-1), ones(1,m/2)];
    g = [(0:m/2-1)/(m/2-1), (m/2-1:-1:0)/(m/2-1)];
    b = [ones(1,m/2), (m/2-1:-1:0)/(m/2-1)];
    
    cmap = [r', g', b'];
end

