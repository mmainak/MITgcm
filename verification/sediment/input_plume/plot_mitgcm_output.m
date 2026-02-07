%==========================================================================
% PLOT_MITGCM_OUTPUT.m
%
% Comprehensive visualization of MITgcm output files
%==========================================================================

clear; close all; clc;

% Add MITgcm utilities
try
    addpath(genpath('/scratch/mm10845/mbase_MITgcm/utils/matlab'));
catch
    fprintf('MITgcm utils not found\n');
end

fprintf('=== MITgcm Output Plotter ===\n\n');

%% List available files
file_types = {'U', 'V', 'W', 'T', 'S', 'PTRACER01', 'Eta'};

for i = 1:length(file_types)
    files = dir([file_types{i} '.*.data']);
    if ~isempty(files)
        fprintf('✓ %s: %d files\n', file_types{i}, length(files));
    end
end

%% Read grid
XC = rdmds('XC'); YC = rdmds('YC'); RC = squeeze(rdmds('RC'));
hFacC = rdmds('hFacC');
[Nx, Ny, Nr] = size(hFacC);
fprintf('\nGrid: %dx%dx%d\n', Nx, Ny, Nr);

% Mask
mask = hFacC; mask(mask==0) = NaN;
xgrid = XC(:,1); ygrid = YC(1,:);

%% Find latest timestep
U_files = dir('U.*.data');
if isempty(U_files), error('No U files!'); end
timesteps = [];
for k = 1:length(U_files)
    num = regexp(U_files(k).name, '\.([0-9]+)\.', 'tokens', 'once');
    if ~isempty(num), timesteps(end+1) = str2double(num{1}); end
end
iter = max(timesteps);
fprintf('Latest iter: %d\n', iter);

%% Read data
U = rdmds('U', iter) .* mask;
W = rdmds('W', iter) .* mask;
T = rdmds('T', iter) .* mask;
S = rdmds('S', iter) .* mask;
try
    C = rdmds('PTRACER01', iter) .* mask;
catch
    C = zeros(Nx,Ny,Nr); fprintf('No sediment\n');
end

%% Plot X-Z slice at mid-y
mid_y = round(Ny/2);
U_xz = squeeze(U(:,mid_y,:))';
W_xz = squeeze(W(:,mid_y,:))';
T_xz = squeeze(T(:,mid_y,:))';
S_xz = squeeze(S(:,mid_y,:))';
C_xz = squeeze(C(:,mid_y,:))';

fig = figure('Position', [100 100 1200 800]);

subplot(2,3,1);
pcolor(xgrid, RC, U_xz); shading flat; colorbar;
title('U [m/s]'); xlabel('X'); ylabel('Z');
set(gca, 'YDir', 'normal');

subplot(2,3,2);
pcolor(xgrid, RC, W_xz); shading flat; colorbar;
title('W [m/s]'); xlabel('X'); ylabel('Z');
set(gca, 'YDir', 'normal');

subplot(2,3,3);
pcolor(xgrid, RC, C_xz); shading flat; colorbar;
title('Sediment [kg/m³]'); xlabel('X'); ylabel('Z');
set(gca, 'YDir', 'normal');

subplot(2,3,4);
pcolor(xgrid, RC, T_xz); shading flat; colorbar;
title('T [°C]'); xlabel('X'); ylabel('Z');
set(gca, 'YDir', 'normal');

subplot(2,3,5);
pcolor(xgrid, RC, S_xz); shading flat; colorbar;
title('S [psu]'); xlabel('X'); ylabel('Z');
set(gca, 'YDir', 'normal');

subplot(2,3,6);
speed = sqrt(U_xz.^2 + W_xz.^2);
pcolor(xgrid, RC, speed); shading flat; colorbar;
title('Speed [m/s]'); xlabel('X'); ylabel('Z');
set(gca, 'YDir', 'normal');

sgtitle(sprintf('MITgcm Output - Iter %d', iter));
saveas(fig, 'output_snapshot.png');
fprintf('\nSaved: output_snapshot.png\n');

%% Statistics
fprintf('\n=== STATISTICS ===\n');
fprintf('U: [%.3f, %.3f] m/s\n', nanmin(U(:)), nanmax(U(:)));
fprintf('W: [%.3f, %.3f] m/s\n', nanmin(W(:)), nanmax(W(:)));
fprintf('T: [%.3f, %.3f] C\n', nanmin(T(:)), nanmax(T(:)));
fprintf('S: [%.3f, %.3f] psu\n', nanmin(S(:)), nanmax(S(:)));
fprintf('C: [%.3e, %.3e] kg/m³\n', nanmin(C(:)), nanmax(C(:)));
if any(isnan(C(:))), fprintf('⚠ Sediment has NaN!\n'); end
if any(isinf(C(:))), fprintf('⚠ Sediment has Inf!\n'); end

fprintf('\nDone!\n');
