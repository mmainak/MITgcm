%% analyze_plume.m
% Diagnostic visualization for subglacial sediment plume simulation
% 
% Domain: Nx=40, Ny=8, Nr=40 (4 processors)
% Main view: X-Z section (along plume direction)
%
% Variables:
%   - UVEL, WVEL: velocity components
%   - THETA, SALT: temperature, salinity
%   - TRAC01: sediment concentration
%   - ETAN: free surface

clear all; close all;

%% ========== SETUP ==========
% Add MITgcm MATLAB utilities path
addpath(genpath('/scratch/mm10845/mbase_MITgcm/utils/matlab'));

% Output directory
output_dir = 'anim';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');

%% ========== FIND AVAILABLE TIMESTEPS ==========
% Look for state output files (U, W, T, S, PTRACER01)
state_files = dir('U.*.data');
if ~isempty(state_files)
    use_state = true;
    fprintf('Using state output files (U, W, T, S, PTRACER01)\n');
    search_files = state_files;
else
    % Try diagnostic files
    diag_files = dir('diag3D.*.data');
    if ~isempty(diag_files)
        use_state = false;
        fprintf('Using diagnostic output files (diag3D)\n');
        search_files = diag_files;
    else
        error('No output files found!');
    end
end

% Extract timestep numbers
timesteps = [];
for k = 1:length(search_files)
    fname = search_files(k).name;
    numstr = regexp(fname, '\.([0-9]+)\.', 'tokens', 'once');
    if ~isempty(numstr)
        timesteps(end+1) = str2double(numstr{1});
    end
end
timesteps = sort(unique(timesteps));

fprintf('Found %d timesteps: %d to %d\n', length(timesteps), min(timesteps), max(timesteps));

%% ========== READ GRID ==========
% Grid coordinates
XC = rdmds('XC');  % cell center x
YC = rdmds('YC');  % cell center y
RC = squeeze(rdmds('RC'));  % cell center depth (negative)
DRF = squeeze(rdmds('DRF'));  % cell thickness

% hFacC for masking
hFacC = rdmds('hFacC');
hFacC(hFacC == 0) = NaN;

[Nx, Ny, Nr] = size(hFacC);
fprintf('Grid: Nx=%d, Ny=%d, Nr=%d\n', Nx, Ny, Nr);

% X coordinates (cell centers)
xgrid = XC(:,1);
ygrid = YC(1,:);

fprintf('Domain: X = [%.1f, %.1f] m, Y = [%.1f, %.1f] m, Z = [%.1f, %.1f] m\n', ...
    min(xgrid), max(xgrid), min(ygrid), max(ygrid), min(RC), max(RC));

%% ========== SELECT SLICE ==========
% For X-Z view, pick middle Y index
mid_y = round(Ny/2);
fprintf('Plotting X-Z section at Y index = %d (Y = %.1f m)\n', mid_y, ygrid(mid_y));

%% ========== DETERMINE COLOR LIMITS ==========
% Read final timestep to set color limits
final_iter = max(timesteps);
fprintf('Reading final timestep %d for color limits...\n', final_iter);

if use_state
    U = rdmds('U', final_iter);
    W = rdmds('W', final_iter);
    T = rdmds('T', final_iter);
    S = rdmds('S', final_iter);
    % Try to read tracer
    try
        C = rdmds('PTRACER01', final_iter);
    catch
        try
            C = rdmds('TRAC01', final_iter);
        catch
            C = zeros(Nx, Ny, Nr);
            fprintf('Warning: No sediment tracer found\n');
        end
    end
else
    % Read from diagnostics
    diag3D = rdmds('diag3D', final_iter);
    % Assume order: UVEL, WVEL, THETA, SALT, TRAC01
    % Check dimensions
    if ndims(diag3D) == 4
        U = squeeze(diag3D(:,:,:,1));
        W = squeeze(diag3D(:,:,:,2));
        T = squeeze(diag3D(:,:,:,3));
        S = squeeze(diag3D(:,:,:,4));
        if size(diag3D, 4) >= 5
            C = squeeze(diag3D(:,:,:,5));
        else
            C = zeros(Nx, Ny, Nr);
        end
    else
        % Single field, try reading individually
        U = rdmds('UVEL', final_iter);
        W = rdmds('WVEL', final_iter);
        T = rdmds('THETA', final_iter);
        S = rdmds('SALT', final_iter);
        try
            C = rdmds('TRAC01', final_iter);
        catch
            C = zeros(Nx, Ny, Nr);
        end
    end
end

% Apply mask
U = U .* hFacC;
W = W .* hFacC;
T = T .* hFacC;
S = S .* hFacC;
C = C .* hFacC;

% Extract X-Z slices at mid_y
U_xz = squeeze(U(:, mid_y, :))';
W_xz = squeeze(W(:, mid_y, :))';
T_xz = squeeze(T(:, mid_y, :))';
S_xz = squeeze(S(:, mid_y, :))';
C_xz = squeeze(C(:, mid_y, :))';

% Calculate color limits
u_lim = max(abs(U_xz(:)));
w_lim = max(abs(W_xz(:)));
t_lim = [min(T_xz(:)), max(T_xz(:))];
s_lim = [min(S_xz(:)), max(S_xz(:))];
c_lim = [0, max(0.1, max(C_xz(:)))];  % sediment ≥ 0

fprintf('Color limits:\n');
fprintf('  U: [%.3f, %.3f] m/s\n', -u_lim, u_lim);
fprintf('  W: [%.3f, %.3f] m/s\n', -w_lim, w_lim);
fprintf('  T: [%.2f, %.2f] C\n', t_lim(1), t_lim(2));
fprintf('  S: [%.2f, %.2f] psu\n', s_lim(1), s_lim(2));
fprintf('  C: [%.3f, %.3f] kg/m3\n', c_lim(1), c_lim(2));

%% ========== CREATE ANIMATION ==========
% GIF filenames
gif_velocity = fullfile(output_dir, ['plume_velocity_' timestamp '.gif']);
gif_tracers = fullfile(output_dir, ['plume_tracers_' timestamp '.gif']);
gif_sediment = fullfile(output_dir, ['plume_sediment_' timestamp '.gif']);

% Figure setup
fig_vel = figure('Position', [100 100 1000 600], 'Visible', 'off');
fig_tra = figure('Position', [100 100 1000 600], 'Visible', 'off');
fig_sed = figure('Position', [100 100 1000 400], 'Visible', 'on');

% Select timesteps for animation (subsample if too many)
max_frames = 100;
if length(timesteps) > max_frames
    step = ceil(length(timesteps) / max_frames);
    plot_timesteps = timesteps(1:step:end);
else
    plot_timesteps = timesteps;
end

fprintf('\nGenerating animations for %d timesteps...\n', length(plot_timesteps));

for t_idx = 1:length(plot_timesteps)
    iter = plot_timesteps(t_idx);
    
    % Read data
    if use_state
        U = rdmds('U', iter) .* hFacC;
        W = rdmds('W', iter) .* hFacC;
        T = rdmds('T', iter) .* hFacC;
        S = rdmds('S', iter) .* hFacC;
        try
            C = rdmds('PTRACER01', iter) .* hFacC;
        catch
            C = zeros(Nx, Ny, Nr);
        end
    else
        % Read from diag3D combined file
        try
            diag3D = rdmds('diag3D', iter);
            U = squeeze(diag3D(:,:,:,1)) .* hFacC;
            W = squeeze(diag3D(:,:,:,2)) .* hFacC;
            T = squeeze(diag3D(:,:,:,3)) .* hFacC;
            S = squeeze(diag3D(:,:,:,4)) .* hFacC;
            if size(diag3D, 4) >= 5
                C = squeeze(diag3D(:,:,:,5)) .* hFacC;
            else
                C = zeros(Nx, Ny, Nr);
            end
        catch
            continue;
        end
    end
    
    % Extract X-Z slices
    U_xz = squeeze(U(:, mid_y, :))';
    W_xz = squeeze(W(:, mid_y, :))';
    T_xz = squeeze(T(:, mid_y, :))';
    S_xz = squeeze(S(:, mid_y, :))';
    C_xz = squeeze(C(:, mid_y, :))';
    
    % Time in seconds
    dt = 0.25;  % from data file
    time_sec = iter * dt;
    
    %% --- Velocity Figure ---
    figure(fig_vel); clf;
    
    % U velocity
    subplot(2,2,1);
    pcolor(xgrid, RC, U_xz); shading flat;
    colorbar; colormap(gca, redblue(64));
    caxis([-u_lim u_lim]);
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('U velocity [m/s] - t=%.1fs', time_sec));
    set(gca, 'YDir', 'normal');
    
    % W velocity
    subplot(2,2,2);
    pcolor(xgrid, RC, W_xz); shading flat;
    colorbar; colormap(gca, redblue(64));
    caxis([-w_lim w_lim]);
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('W velocity [m/s] - t=%.1fs', time_sec));
    set(gca, 'YDir', 'normal');
    
    % Velocity magnitude
    subplot(2,2,3);
    speed = sqrt(U_xz.^2 + W_xz.^2);
    pcolor(xgrid, RC, speed); shading flat;
    colorbar; colormap(gca, hot(64));
    caxis([0 max(u_lim, w_lim)]);
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('Speed [m/s] - t=%.1fs', time_sec));
    set(gca, 'YDir', 'normal');
    
    % Velocity vectors (subsampled)
    subplot(2,2,4);
    skip_x = max(1, floor(Nx/20));
    skip_z = max(1, floor(Nr/15));
    [Xq, Zq] = meshgrid(xgrid(1:skip_x:end), RC(1:skip_z:end));
    Uq = U_xz(1:skip_z:end, 1:skip_x:end);
    Wq = W_xz(1:skip_z:end, 1:skip_x:end);
    quiver(Xq, Zq, Uq, Wq, 2, 'k');
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('Velocity vectors - t=%.1fs', time_sec));
    axis tight; set(gca, 'YDir', 'normal');
    xlim([min(xgrid) max(xgrid)]); ylim([min(RC) max(RC)]);
    
    sgtitle(sprintf('Plume Velocity (Y=%.1fm) - Iter %d', ygrid(mid_y), iter));
    
    % Save to GIF
    drawnow;
    frame = getframe(fig_vel);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    if t_idx == 1
        imwrite(imind, cm, gif_velocity, 'gif', 'Loopcount', inf, 'DelayTime', 0.15);
    else
        imwrite(imind, cm, gif_velocity, 'gif', 'WriteMode', 'append', 'DelayTime', 0.15);
    end
    
    %% --- Tracer Figure (T, S) ---
    figure(fig_tra); clf;
    
    % Temperature
    subplot(2,1,1);
    pcolor(xgrid, RC, T_xz); shading flat;
    colorbar;
    caxis(t_lim);
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('Temperature [C] - t=%.1fs', time_sec));
    set(gca, 'YDir', 'normal');
    
    % Salinity
    subplot(2,1,2);
    pcolor(xgrid, RC, S_xz); shading flat;
    colorbar;
    caxis(s_lim);
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('Salinity [psu] - t=%.1fs', time_sec));
    set(gca, 'YDir', 'normal');
    
    sgtitle(sprintf('Plume Tracers (Y=%.1fm) - Iter %d', ygrid(mid_y), iter));
    
    % Save to GIF
    drawnow;
    frame = getframe(fig_tra);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    if t_idx == 1
        imwrite(imind, cm, gif_tracers, 'gif', 'Loopcount', inf, 'DelayTime', 0.15);
    else
        imwrite(imind, cm, gif_tracers, 'gif', 'WriteMode', 'append', 'DelayTime', 0.15);
    end
    
    %% --- Sediment Figure ---
    figure(fig_sed); clf;
    
    % Sediment concentration X-Z
    subplot(1,2,1);
    pcolor(xgrid, RC, C_xz); shading flat;
    colorbar;
    caxis(c_lim);
    colormap(gca, parula(64));
    xlabel('X [m]'); ylabel('Z [m]');
    title(sprintf('Sediment [kg/m^3] - X-Z at Y=%.1fm', ygrid(mid_y)));
    set(gca, 'YDir', 'normal');
    
    % Sediment concentration Y-Z (at x near conduit)
    subplot(1,2,2);
    x_near_conduit = 2;  % index near west boundary
    C_yz = squeeze(C(x_near_conduit, :, :))';
    pcolor(ygrid, RC, C_yz); shading flat;
    colorbar;
    caxis(c_lim);
    colormap(gca, parula(64));
    xlabel('Y [m]'); ylabel('Z [m]');
    title(sprintf('Sediment [kg/m^3] - Y-Z at X=%.1fm', xgrid(x_near_conduit)));
    set(gca, 'YDir', 'normal');
    
    sgtitle(sprintf('Sediment Concentration - t=%.1fs (Iter %d)', time_sec, iter));
    
    % Save to GIF
    drawnow;
    frame = getframe(fig_sed);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    if t_idx == 1
        imwrite(imind, cm, gif_sediment, 'gif', 'Loopcount', inf, 'DelayTime', 0.15);
    else
        imwrite(imind, cm, gif_sediment, 'gif', 'WriteMode', 'append', 'DelayTime', 0.15);
    end
    
    % Progress
    fprintf('  Processed iter %d (%d/%d, %.0f%%)\n', iter, t_idx, length(plot_timesteps), ...
        100*t_idx/length(plot_timesteps));
end

close(fig_vel);
close(fig_tra);
close(fig_sed);

fprintf('\n========== ANIMATIONS COMPLETE ==========\n');
fprintf('Saved:\n');
fprintf('  %s\n', gif_velocity);
fprintf('  %s\n', gif_tracers);
fprintf('  %s\n', gif_sediment);

%% ========== FINAL SNAPSHOT ==========
fprintf('\nGenerating final snapshot...\n');

fig_final = figure('Position', [100 100 1400 800]);

% Read final timestep (use last successfully processed iter from animation)
iter = plot_timesteps(end);
fprintf('Reading final timestep iter=%d\n', iter);
try
    if use_state
        U = rdmds('U', iter);
        W = rdmds('W', iter);
        T = rdmds('T', iter);
        S = rdmds('S', iter);
        try
            C = rdmds('PTRACER01', iter);
        catch
            C = zeros(Nx, Ny, Nr);
        end
    else
        diag3D = rdmds('diag3D', iter);
        U = squeeze(diag3D(:,:,:,1));
        W = squeeze(diag3D(:,:,:,2));
        T = squeeze(diag3D(:,:,:,3));
        S = squeeze(diag3D(:,:,:,4));
        if size(diag3D, 4) >= 5
            C = squeeze(diag3D(:,:,:,5));
        else
            C = zeros(Nx, Ny, Nr);
        end
    end
    % Apply mask
    U = U .* hFacC;
    W = W .* hFacC;
    T = T .* hFacC;
    S = S .* hFacC;
    C = C .* hFacC;
catch ME
    fprintf('Warning: Could not read final timestep %d: %s\n', iter, ME.message);
    fprintf('Using data from last animation frame\n');
end

U_xz = squeeze(U(:, mid_y, :))';
W_xz = squeeze(W(:, mid_y, :))';
T_xz = squeeze(T(:, mid_y, :))';
S_xz = squeeze(S(:, mid_y, :))';
C_xz = squeeze(C(:, mid_y, :))';

time_sec = iter * dt;

% 6-panel plot
subplot(2,3,1);
pcolor(xgrid, RC, U_xz); shading flat;
colorbar; colormap(gca, redblue(64)); caxis([-u_lim u_lim]);
xlabel('X [m]'); ylabel('Z [m]'); title('U velocity [m/s]');
set(gca, 'YDir', 'normal');

subplot(2,3,2);
pcolor(xgrid, RC, W_xz); shading flat;
colorbar; colormap(gca, redblue(64)); caxis([-w_lim w_lim]);
xlabel('X [m]'); ylabel('Z [m]'); title('W velocity [m/s]');
set(gca, 'YDir', 'normal');

subplot(2,3,3);
pcolor(xgrid, RC, C_xz); shading flat;
colorbar; colormap(gca, parula(64)); caxis(c_lim);
xlabel('X [m]'); ylabel('Z [m]'); title('Sediment [kg/m^3]');
set(gca, 'YDir', 'normal');

subplot(2,3,4);
pcolor(xgrid, RC, T_xz); shading flat;
colorbar; caxis(t_lim);
xlabel('X [m]'); ylabel('Z [m]'); title('Temperature [C]');
set(gca, 'YDir', 'normal');

subplot(2,3,5);
pcolor(xgrid, RC, S_xz); shading flat;
colorbar; caxis(s_lim);
xlabel('X [m]'); ylabel('Z [m]'); title('Salinity [psu]');
set(gca, 'YDir', 'normal');

subplot(2,3,6);
speed = sqrt(U_xz.^2 + W_xz.^2);
pcolor(xgrid, RC, speed); shading flat;
hold on;
skip_x = max(1, floor(Nx/15));
skip_z = max(1, floor(Nr/12));
[Xq, Zq] = meshgrid(xgrid(1:skip_x:end), RC(1:skip_z:end));
Uq = U_xz(1:skip_z:end, 1:skip_x:end);
Wq = W_xz(1:skip_z:end, 1:skip_x:end);
quiver(Xq, Zq, Uq, Wq, 2, 'k');
colorbar; colormap(gca, hot(64)); caxis([0 max(u_lim, w_lim)]);
xlabel('X [m]'); ylabel('Z [m]'); title('Speed + vectors');
set(gca, 'YDir', 'normal');

sgtitle(sprintf('Subglacial Plume - Final State (t=%.1fs, Y=%.1fm)', time_sec, ygrid(mid_y)));

saveas(fig_final, fullfile(output_dir, ['plume_final_' timestamp '.png']));
fprintf('Saved: %s\n', fullfile(output_dir, ['plume_final_' timestamp '.png']));

%% ========== STATISTICS ==========
fprintf('\n========== FINAL STATE STATISTICS ==========\n');
fprintf('Time: %.1f s (iter %d)\n', time_sec, iter);
fprintf('U velocity: min=%.4f, max=%.4f, mean=%.4f m/s\n', ...
    nanmin(U(:)), nanmax(U(:)), nanmean(U(:)));
fprintf('W velocity: min=%.4f, max=%.4f, mean=%.4f m/s\n', ...
    nanmin(W(:)), nanmax(W(:)), nanmean(W(:)));
fprintf('Temperature: min=%.2f, max=%.2f, mean=%.2f C\n', ...
    nanmin(T(:)), nanmax(T(:)), nanmean(T(:)));
fprintf('Salinity: min=%.2f, max=%.2f, mean=%.2f psu\n', ...
    nanmin(S(:)), nanmax(S(:)), nanmean(S(:)));
fprintf('Sediment: min=%.4f, max=%.4f, mean=%.4f kg/m3\n', ...
    nanmin(C(:)), nanmax(C(:)), nanmean(C(:)));

fprintf('\n========== DONE ==========\n');

%% ========== PLAY ANIMATION ==========
fprintf('\nPlaying sediment animation...\n');
fprintf('Press Ctrl+C to stop\n\n');

% Read the sediment GIF
[gif_data, gif_map] = imread(gif_sediment, 'gif', 'Frames', 'all');
num_frames = size(gif_data, 4);

% Create figure for playback
fig_play = figure('Position', [200 200 1000 400], 'Name', 'Sediment Plume Animation');

% Loop animation
for loop = 1:3  % Play 3 times
    for frame = 1:num_frames
        if ~ishandle(fig_play)
            break;  % Stop if figure closed
        end
        imshow(gif_data(:,:,:,frame), gif_map);
        title(sprintf('Sediment Animation - Frame %d/%d (Loop %d/3)', frame, num_frames, loop));
        drawnow;
        pause(0.15);
    end
end

fprintf('Animation playback complete.\n');

%% ========== HELPER FUNCTION: Red-Blue Colormap ==========
function cmap = redblue(n)
    if nargin < 1, n = 64; end
    % Create diverging red-white-blue colormap
    top = [0.7 0 0];
    mid = [1 1 1];
    bot = [0 0 0.7];
    
    n_half = floor(n/2);
    r = [linspace(bot(1), mid(1), n_half), linspace(mid(1), top(1), n_half)];
    g = [linspace(bot(2), mid(2), n_half), linspace(mid(2), top(2), n_half)];
    b = [linspace(bot(3), mid(3), n_half), linspace(mid(3), top(3), n_half)];
    
    cmap = [r', g', b'];
end
