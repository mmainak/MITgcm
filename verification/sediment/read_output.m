% read_output.m
% Read and visualize MITgcm lock-exchange sediment output
% For use on HPC or local machine after transferring output files
%
% Created for: Lock-Exchange Sediment Test Case
% Grid: 100x100x20, Cartesian, 10km x 10km x 200m domain

clear all; close all;

%==========================================================================
% CONFIGURATION
%==========================================================================
% Set the run directory (modify as needed)
runDir = './';  % Current directory, or set full path

% Grid parameters (must match SIZE.h and data file)
Nx = 100;  Ny = 100;  Nr = 20;
Lx = 10000;  Ly = 10000;  Lz = 200;  % Domain size in meters

% Grid spacing
dx = Lx / Nx;  dy = Ly / Ny;  dz = Lz / Nr;

% Create coordinate arrays
x = (0.5:Nx-0.5) * dx;  % Cell centers [m]
y = (0.5:Ny-0.5) * dy;
z = -((0.5:Nr-0.5) * dz)';  % Negative = depth [m]

% Time step (check your data file)
deltaT = 100;  % seconds - MODIFY if you changed this

% Auto-detect available timesteps from T.*.data files
fprintf('============================================================\n');
fprintf('MITgcm Lock-Exchange Output Reader\n');
fprintf('============================================================\n');
fprintf('Grid: %dx%dx%d\n', Nx, Ny, Nr);
fprintf('Domain: %.1fkm x %.1fkm x %dm\n', Lx/1000, Ly/1000, Lz);
fprintf('============================================================\n\n');

fprintf('Scanning for output files...\n');
T_files = dir([runDir 'T.*.data']);
if isempty(T_files)
    error('No T.*.data files found in %s', runDir);
end

% Extract iteration numbers from filenames
iters = [];
for i = 1:length(T_files)
    fname = T_files(i).name;
    % Extract the 10-digit iteration number between T. and .data
    iter_str = fname(3:12);  % T.XXXXXXXXXX.data
    iters = [iters, str2double(iter_str)];
end
iters = sort(unique(iters));

fprintf('  Found %d timesteps: ', length(iters));
if length(iters) <= 6
    fprintf('%s\n', num2str(iters));
else
    fprintf('%d, %d, ... %d, %d\n', iters(1), iters(2), iters(end-1), iters(end));
end
fprintf('  Latest timestep: %d (t = %.2f hours)\n', iters(end), iters(end)*deltaT/3600);

%==========================================================================
% 1. READ GRID FILES (static)
%==========================================================================
fprintf('Reading grid files...\n');

try
    depth = rdmds([runDir 'Depth'], -1, Nx, Ny, Nr);
    fprintf('  Depth: min=%.1f, max=%.1f m\n', min(depth(:)), max(depth(:)));
catch
    fprintf('  Warning: Could not read Depth.data, using flat bathymetry\n');
    depth = -200 * ones(Nx, Ny);
end

%==========================================================================
% 2. READ DYNAMIC FIELDS AT DIFFERENT TIMES
%==========================================================================
fprintf('\nReading dynamic fields...\n');

% Preallocate
T_all = cell(length(iters), 1);
S_all = cell(length(iters), 1);
U_all = cell(length(iters), 1);
V_all = cell(length(iters), 1);
W_all = cell(length(iters), 1);
C_all = cell(length(iters), 1);  % Sediment (PTRACER01)
Eta_all = cell(length(iters), 1);

for i = 1:length(iters)
    iter = iters(i);
    t_hours = iter * deltaT / 3600;
    fprintf('  Iteration %d (t = %.2f hours)...\n', iter, t_hours);
    
    try
        T_all{i} = rdmds([runDir 'T'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: T.%010d.data not found\n', iter);
    end
    
    try
        S_all{i} = rdmds([runDir 'S'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: S.%010d.data not found\n', iter);
    end
    
    try
        U_all{i} = rdmds([runDir 'U'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: U.%010d.data not found\n', iter);
    end
    
    try
        V_all{i} = rdmds([runDir 'V'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: V.%010d.data not found\n', iter);
    end
    
    try
        W_all{i} = rdmds([runDir 'W'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: W.%010d.data not found\n', iter);
    end
    
    try
        C_all{i} = rdmds([runDir 'PTRACER01'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: PTRACER01.%010d.data not found\n', iter);
    end
    
    try
        Eta_all{i} = rdmds([runDir 'Eta'], iter, Nx, Ny, Nr);
    catch
        fprintf('    Warning: Eta.%010d.data not found\n', iter);
    end
end

%==========================================================================
% 3. PLOT INITIAL CONDITIONS
%==========================================================================
fprintf('\nPlotting initial conditions...\n');

if ~isempty(T_all{1})
    figure('Position', [50, 50, 1600, 900], 'Name', 'Initial Conditions');
    
    % Temperature surface
    subplot(2,3,1);
    pcolor(x/1000, y/1000, squeeze(T_all{1}(:,:,1))');
    shading flat; colorbar; colormap(gca, jet);
    title('Initial Surface Temperature (°C)', 'FontSize', 12);
    xlabel('X (km)'); ylabel('Y (km)');
    axis equal tight;
    
    % Temperature section (mid-Y)
    subplot(2,3,2);
    T_section = squeeze(T_all{1}(:, round(Ny/2), :))';
    imagesc(x/1000, z, T_section);
    colorbar; colormap(gca, jet);
    title('Initial Temperature Section (Y=5km)', 'FontSize', 12);
    xlabel('X (km)'); ylabel('Depth (m)');
    set(gca, 'YDir', 'normal');
    
    % Sediment section (mid-Y)
    subplot(2,3,3);
    if ~isempty(C_all{1})
        C_section = squeeze(C_all{1}(:, round(Ny/2), :))';
        imagesc(x/1000, z, C_section);
        colorbar; colormap(gca, hot);
        title('Initial Sediment Section (Y=5km)', 'FontSize', 12);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
    
    % U velocity section
    subplot(2,3,4);
    if ~isempty(U_all{1})
        U_section = squeeze(U_all{1}(:, round(Ny/2), :))';
        imagesc(x/1000, z, U_section);
        colorbar; cmap = coolwarm_colormap(); colormap(gca, cmap);
        max_val = max(abs(U_section(:)));
        if max_val > 0
            caxis([-max_val, max_val]);
        end
        title('Initial U Velocity Section (m/s)', 'FontSize', 12);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
    
    % W velocity section
    subplot(2,3,5);
    if ~isempty(W_all{1})
        W_section = squeeze(W_all{1}(:, round(Ny/2), :))';
        imagesc(x/1000, z, W_section);
        colorbar; cmap = coolwarm_colormap(); colormap(gca, cmap);
        max_val = max(abs(W_section(:)));
        if max_val > 0
            caxis([-max_val, max_val]);
        end
        title('Initial W Velocity Section (m/s)', 'FontSize', 12);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
    
    % Statistics
    subplot(2,3,6);
    axis off;
    text(0.1, 0.9, sprintf('Grid: %dx%dx%d', Nx, Ny, Nr), 'FontSize', 12);
    text(0.1, 0.8, sprintf('Domain: %.1fkm x %.1fkm x %dm', Lx/1000, Ly/1000, Lz), 'FontSize', 12);
    text(0.1, 0.7, sprintf('T range: %.2f to %.2f C', min(T_all{1}(:)), max(T_all{1}(:))), 'FontSize', 12);
    if ~isempty(C_all{1})
        text(0.1, 0.6, sprintf('Sed range: %.4f to %.4f kg/m3', min(C_all{1}(:)), max(C_all{1}(:))), 'FontSize', 12);
    end
    if ~isempty(U_all{1})
        text(0.1, 0.5, sprintf('U range: %.4f to %.4f m/s', min(U_all{1}(:)), max(U_all{1}(:))), 'FontSize', 12);
    end
    title('Statistics', 'FontSize', 12);
    
    sgtitle('LOCK-EXCHANGE: Initial Conditions (t=0)', 'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, 'plot_initial.png');
    fprintf('  Saved: plot_initial.png\n');
end

%==========================================================================
% 4. PLOT TIME EVOLUTION (select up to 6 representative timesteps)
%==========================================================================
fprintf('\nPlotting time evolution...\n');

% Select representative timesteps (first, last, and evenly spaced in between)
if length(iters) <= 6
    plot_indices = 1:length(iters);
else
    % Select 6 evenly spaced indices including first and last
    plot_indices = round(linspace(1, length(iters), 6));
end
nplots = length(plot_indices);

figure('Position', [50, 50, 300*nplots, 900], 'Name', 'Time Evolution');

for pi = 1:nplots
    i = plot_indices(pi);
    iter = iters(i);
    t_hours = iter * deltaT / 3600;
    
    if isempty(T_all{i}), continue; end
    
    % Temperature section
    subplot(3, nplots, pi);
    T_section = squeeze(T_all{i}(:, round(Ny/2), :))';
    imagesc(x/1000, z, T_section);
    colorbar; colormap(gca, jet);
    caxis([8 22]);  % Fixed color scale for temperature
    title(sprintf('T (t=%.1fh)', t_hours), 'FontSize', 10);
    xlabel('X (km)'); ylabel('Depth (m)');
    set(gca, 'YDir', 'normal');
    
    % U velocity section
    subplot(3, nplots, nplots + pi);
    if ~isempty(U_all{i})
        U_section = squeeze(U_all{i}(:, round(Ny/2), :))';
        imagesc(x/1000, z, U_section);
        colorbar; cmap = coolwarm_colormap(); colormap(gca, cmap);
        max_u = max(0.01, max(abs(U_all{i}(:))));
        caxis([-max_u, max_u]);
        title(sprintf('U (t=%.1fh)', t_hours), 'FontSize', 10);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
    
    % Sediment section
    subplot(3, nplots, 2*nplots + pi);
    if ~isempty(C_all{i})
        C_section = squeeze(C_all{i}(:, round(Ny/2), :))';
        imagesc(x/1000, z, C_section);
        colorbar; colormap(gca, hot);
        caxis([0, 0.12]);  % Fixed color scale for sediment
        title(sprintf('Sed (t=%.1fh)', t_hours), 'FontSize', 10);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
end

sgtitle('LOCK-EXCHANGE: Time Evolution', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'plot_evolution.png');
fprintf('  Saved: plot_evolution.png\n');

%==========================================================================
% 4B. PLOT TIME SERIES OF KEY QUANTITIES (all timesteps)
%==========================================================================
fprintf('\nPlotting time series...\n');

% Compute statistics for all timesteps
time_hours = iters * deltaT / 3600;
T_min = zeros(length(iters), 1);
T_max = zeros(length(iters), 1);
T_mean = zeros(length(iters), 1);
U_max = zeros(length(iters), 1);
W_max = zeros(length(iters), 1);
C_total = zeros(length(iters), 1);
C_max = zeros(length(iters), 1);

for i = 1:length(iters)
    if ~isempty(T_all{i})
        T_min(i) = min(T_all{i}(:));
        T_max(i) = max(T_all{i}(:));
        T_mean(i) = mean(T_all{i}(:));
    end
    if ~isempty(U_all{i})
        U_max(i) = max(abs(U_all{i}(:)));
    end
    if ~isempty(W_all{i})
        W_max(i) = max(abs(W_all{i}(:)));
    end
    if ~isempty(C_all{i})
        C_total(i) = sum(C_all{i}(:)) * dx * dy * dz;
        C_max(i) = max(C_all{i}(:));
    end
end

figure('Position', [50, 50, 1400, 800], 'Name', 'Time Series');

% Temperature evolution
subplot(2,2,1);
plot(time_hours, T_min, 'b-', 'LineWidth', 2); hold on;
plot(time_hours, T_max, 'r-', 'LineWidth', 2);
plot(time_hours, T_mean, 'k--', 'LineWidth', 1.5);
xlabel('Time (hours)'); ylabel('Temperature (C)');
title('Temperature Evolution', 'FontSize', 12);
legend('Min', 'Max', 'Mean', 'Location', 'best');
grid on;

% Velocity evolution
subplot(2,2,2);
plot(time_hours, U_max, 'b-', 'LineWidth', 2); hold on;
plot(time_hours, W_max, 'r-', 'LineWidth', 2);
xlabel('Time (hours)'); ylabel('Velocity (m/s)');
title('Maximum Velocity Evolution', 'FontSize', 12);
legend('|U|_{max}', '|W|_{max}', 'Location', 'best');
grid on;

% Sediment evolution
subplot(2,2,3);
plot(time_hours, C_total, 'b-', 'LineWidth', 2);
xlabel('Time (hours)'); ylabel('Total Sediment Mass (kg)');
title('Total Sediment Mass (Conservation Check)', 'FontSize', 12);
grid on;

subplot(2,2,4);
plot(time_hours, C_max, 'r-', 'LineWidth', 2);
xlabel('Time (hours)'); ylabel('Max Concentration (kg/m^3)');
title('Maximum Sediment Concentration', 'FontSize', 12);
grid on;

sgtitle('LOCK-EXCHANGE: Time Series Analysis', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'plot_timeseries.png');
fprintf('  Saved: plot_timeseries.png\n');

%==========================================================================
% 5. PLOT FINAL STATE IN DETAIL
%==========================================================================
fprintf('\nPlotting final state...\n');

last_idx = length(iters);
if ~isempty(T_all{last_idx})
    figure('Position', [50, 50, 1600, 1000], 'Name', 'Final State');
    
    iter = iters(last_idx);
    t_hours = iter * deltaT / 3600;
    
    % Temperature at surface
    subplot(2,3,1);
    pcolor(x/1000, y/1000, squeeze(T_all{last_idx}(:,:,1))');
    shading flat; colorbar; colormap(gca, jet);
    title(sprintf('Surface T at t=%.1fh', t_hours), 'FontSize', 12);
    xlabel('X (km)'); ylabel('Y (km)');
    axis equal tight;
    
    % Temperature at bottom
    subplot(2,3,2);
    pcolor(x/1000, y/1000, squeeze(T_all{last_idx}(:,:,Nr))');
    shading flat; colorbar; colormap(gca, jet);
    title(sprintf('Bottom T at t=%.1fh', t_hours), 'FontSize', 12);
    xlabel('X (km)'); ylabel('Y (km)');
    axis equal tight;
    
    % Temperature section
    subplot(2,3,3);
    T_section = squeeze(T_all{last_idx}(:, round(Ny/2), :))';
    imagesc(x/1000, z, T_section);
    colorbar; colormap(gca, jet);
    title(sprintf('T Section at t=%.1fh', t_hours), 'FontSize', 12);
    xlabel('X (km)'); ylabel('Depth (m)');
    set(gca, 'YDir', 'normal');
    
    % Velocity vectors at mid-depth
    subplot(2,3,4);
    k_mid = round(Nr/2);
    skip = 5;  % Plot every 5th vector
    if ~isempty(U_all{last_idx}) && ~isempty(V_all{last_idx})
        U_mid = squeeze(U_all{last_idx}(:,:,k_mid));
        V_mid = squeeze(V_all{last_idx}(:,:,k_mid));
        quiver(x(1:skip:end)/1000, y(1:skip:end)/1000, ...
               U_mid(1:skip:end, 1:skip:end)', V_mid(1:skip:end, 1:skip:end)', 2);
        title(sprintf('Velocity at z=%.0fm, t=%.1fh', z(k_mid), t_hours), 'FontSize', 12);
        xlabel('X (km)'); ylabel('Y (km)');
        axis equal tight;
    end
    
    % Sediment section
    subplot(2,3,5);
    if ~isempty(C_all{last_idx})
        C_section = squeeze(C_all{last_idx}(:, round(Ny/2), :))';
        imagesc(x/1000, z, C_section);
        colorbar; colormap(gca, hot);
        title(sprintf('Sediment at t=%.1fh', t_hours), 'FontSize', 12);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
    
    % U velocity section with contours
    subplot(2,3,6);
    if ~isempty(U_all{last_idx})
        U_section = squeeze(U_all{last_idx}(:, round(Ny/2), :))';
        imagesc(x/1000, z, U_section);
        hold on;
        contour(x/1000, z, T_section, [12 14 16 18], 'k', 'LineWidth', 1);
        colorbar; cmap = coolwarm_colormap(); colormap(gca, cmap);
        title(sprintf('U with T contours, t=%.1fh', t_hours), 'FontSize', 12);
        xlabel('X (km)'); ylabel('Depth (m)');
        set(gca, 'YDir', 'normal');
    end
    
    sgtitle(sprintf('LOCK-EXCHANGE: Final State (t=%.1f hours)', t_hours), ...
            'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, 'plot_final.png');
    fprintf('  Saved: plot_final.png\n');
end

%==========================================================================
% 6. PRINT SUMMARY STATISTICS
%==========================================================================
fprintf('\n============================================================\n');
fprintf('SUMMARY STATISTICS\n');
fprintf('============================================================\n');

for i = 1:length(iters)
    iter = iters(i);
    t_hours = iter * deltaT / 3600;
    
    fprintf('\nTimestep %d (t = %.2f hours):\n', iter, t_hours);
    
    if ~isempty(T_all{i})
        fprintf('  Temperature: min=%.2f, max=%.2f, mean=%.2f C\n', ...
                min(T_all{i}(:)), max(T_all{i}(:)), mean(T_all{i}(:)));
    end
    
    if ~isempty(U_all{i})
        fprintf('  U velocity:  min=%.4f, max=%.4f m/s\n', ...
                min(U_all{i}(:)), max(U_all{i}(:)));
    end
    
    if ~isempty(W_all{i})
        fprintf('  W velocity:  min=%.4f, max=%.4f m/s\n', ...
                min(W_all{i}(:)), max(W_all{i}(:)));
    end
    
    if ~isempty(C_all{i})
        fprintf('  Sediment:    min=%.6f, max=%.6f, total=%.2f kg\n', ...
                min(C_all{i}(:)), max(C_all{i}(:)), sum(C_all{i}(:))*dx*dy*dz);
    end
end

fprintf('\n============================================================\n');
fprintf('Plots saved:\n');
fprintf('  - plot_initial.png   (initial conditions)\n');
fprintf('  - plot_evolution.png (spatial evolution at key times)\n');
fprintf('  - plot_timeseries.png (time series of all timesteps)\n');
fprintf('  - plot_final.png     (final state detail)\n');
fprintf('============================================================\n');

%==========================================================================
% LOCAL FUNCTIONS (must be at end of file)
%==========================================================================

function data = rdmds(basename, iter, Nx, Ny, Nr)
    % Read MITgcm binary output file
    % Handles 2D (Nx,Ny) and 3D (Nx,Ny,Nr) fields
    
    if iter >= 0
        fname = sprintf('%s.%010d.data', basename, iter);
    else
        fname = sprintf('%s.data', basename);
    end
    
    if ~exist(fname, 'file')
        error('File not found: %s', fname);
    end
    
    finfo = dir(fname);
    nvals = finfo.bytes / 8;  % Try 64-bit floats first
    
    % Try 64-bit first
    fid = fopen(fname, 'r', 'ieee-be');
    data = fread(fid, nvals, 'float64');
    fclose(fid);
    
    % Check if values are reasonable, otherwise try 32-bit
    if max(abs(data)) > 1e30 || (nvals ~= Nx*Ny && nvals ~= Nx*Ny*Nr)
        nvals = finfo.bytes / 4;  % 32-bit floats
        fid = fopen(fname, 'r', 'ieee-be');
        data = fread(fid, nvals, 'float32');
        fclose(fid);
    end
    
    % Reshape based on number of values
    if nvals == Nx * Ny
        data = reshape(data, [Nx, Ny]);
    elseif nvals == Nx * Ny * Nr
        data = reshape(data, [Nx, Ny, Nr]);
    else
        warning('Unexpected number of values: %d (expected %d or %d)', ...
                nvals, Nx*Ny, Nx*Ny*Nr);
    end
end

function cmap = coolwarm_colormap()
    % Blue-White-Red colormap for diverging data
    n = 256;
    r = [linspace(0, 1, n/2), ones(1, n/2)];
    g = [linspace(0, 1, n/2), linspace(1, 0, n/2)];
    b = [ones(1, n/2), linspace(1, 0, n/2)];
    cmap = [r', g', b'];
end
