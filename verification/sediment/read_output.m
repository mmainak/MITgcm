% read_output.m
% MITgcm Output Analysis for Cycle 7: Sediment Buoyancy Coupling
%
% Tests:
% 1. Lock-exchange dynamics (temperature-driven)
% 2. Sediment settling (Cycle 3)
% 3. Sediment-buoyancy coupling (Cycle 7) - sediment increases density
%
% Expected physics with buoyancy coupling:
% - Sediment-laden water is DENSER than clear water
% - Cold+sediment water should sink even faster
% - Sediment gradients create additional pressure gradients

clear; close all;

%% ========================================================================
% CONFIGURATION (match SIZE.h and data)
%==========================================================================
fprintf('============================================================\n');
fprintf('MITgcm Cycle 7: Sediment Buoyancy Coupling Analysis\n');
fprintf('============================================================\n\n');

% Grid parameters
Nx = 100;  Ny = 100;  Nr = 20;
dx = 10;   dy = 10;   dz = 5;   % meters
deltaT = 0.2;  % seconds

% Physical parameters (from data and data.sediment)
rhoConst = 1035;      % Reference density [kg/m³]
tAlpha = 2.0E-4;      % Thermal expansion [1/°C]
sBeta = 7.4E-4;       % Haline contraction [1/psu]
gammaC = 6.2E-4;      % Sediment density coefficient [m³/kg]
gravity = 9.81;

% Reference state
T_ref = 15;  % Mean of 10 and 20°C
S_ref = 35;

% Data precision
prec = 'float32';

% Create coordinates
x = (0.5:Nx-0.5) * dx;
y = (0.5:Ny-0.5) * dy;
z = -((0.5:Nr-0.5) * dz);

fprintf('Grid: %d x %d x %d\n', Nx, Ny, Nr);
fprintf('Domain: %.0fm x %.0fm x %.0fm\n', Nx*dx, Ny*dy, Nr*dz);
fprintf('Resolution: dx=%.0fm, dz=%.0fm\n', dx, dz);
fprintf('Sediment γC = %.2e m³/kg\n', gammaC);

%% ========================================================================
% AUTO-DETECT TIMESTEPS
%==========================================================================
fprintf('\n--- Detecting timesteps ---\n');

t_files = dir('T.*.data');
iters = [];
for i = 1:length(t_files)
    name = t_files(i).name;
    iter_str = regexp(name, 'T\.(\d+)\.data', 'tokens');
    if ~isempty(iter_str)
        iters = [iters, str2double(iter_str{1}{1})];
    end
end
iters = sort(unique(iters));

if isempty(iters)
    error('No output files found!');
end

fprintf('Found %d timesteps: %d to %d\n', length(iters), min(iters), max(iters));
fprintf('Time range: %.1f to %.1f seconds\n', min(iters)*deltaT, max(iters)*deltaT);

%% ========================================================================
% READ ALL DATA AND COMPUTE STATISTICS
%==========================================================================
fprintf('\n--- Reading data and computing statistics ---\n');

nT = length(iters);
stats = struct();
stats.time = zeros(nT,1);
stats.T_mean = zeros(nT,1); stats.T_min = zeros(nT,1); stats.T_max = zeros(nT,1);
stats.C_mean = zeros(nT,1); stats.C_min = zeros(nT,1); stats.C_max = zeros(nT,1);
stats.C_total = zeros(nT,1);
stats.U_max = zeros(nT,1); stats.W_max = zeros(nT,1);
stats.rho_T_max = zeros(nT,1);  % Density anomaly from T
stats.rho_C_max = zeros(nT,1);  % Density anomaly from sediment
stats.rho_ratio = zeros(nT,1);  % Ratio of sediment to thermal density effect

for i = 1:nT
    iter = iters(i);
    stats.time(i) = iter * deltaT;
    
    if mod(i, 10) == 0
        fprintf('  Reading iter %d (%d/%d)\n', iter, i, nT);
    end
    
    % Temperature
    T = readbin(sprintf('T.%010d.data', iter), [Nx,Ny,Nr], prec);
    stats.T_mean(i) = mean(T(:));
    stats.T_min(i) = min(T(:));
    stats.T_max(i) = max(T(:));
    
    % Sediment
    C = readbin(sprintf('PTRACER01.%010d.data', iter), [Nx,Ny,Nr], prec);
    stats.C_mean(i) = mean(C(:));
    stats.C_min(i) = min(C(:));
    stats.C_max(i) = max(C(:));
    stats.C_total(i) = sum(C(:)) * dx * dy * dz;
    
    % Velocities
    U = readbin(sprintf('U.%010d.data', iter), [Nx,Ny,Nr], prec);
    W = readbin(sprintf('W.%010d.data', iter), [Nx,Ny,Nr], prec);
    stats.U_max(i) = max(abs(U(:)));
    stats.W_max(i) = max(abs(W(:)));
    
    % Density anomalies (key for buoyancy coupling test)
    % Δρ_T = -ρ₀ * α * (T - T_ref)  [cold water is denser]
    % Δρ_C = ρ₀ * γC * C            [sediment makes water denser]
    dT = T - T_ref;
    drho_T = -rhoConst * tAlpha * dT;  % Thermal density anomaly
    drho_C = rhoConst * gammaC * C;     % Sediment density anomaly
    
    stats.rho_T_max(i) = max(abs(drho_T(:)));
    stats.rho_C_max(i) = max(drho_C(:));
    
    % Ratio: how important is sediment vs temperature for density?
    if stats.rho_T_max(i) > 0
        stats.rho_ratio(i) = stats.rho_C_max(i) / stats.rho_T_max(i);
    end
end

fprintf('  Done.\n');

%% ========================================================================
% FIGURE 1: TIME SERIES - BUOYANCY COUPLING DIAGNOSTICS
%==========================================================================
fprintf('\n--- Creating diagnostic plots ---\n');

figure('Position', [50, 50, 1400, 900], 'Name', 'Cycle 7: Buoyancy Coupling');

% Panel 1: Temperature
subplot(3,3,1);
plot(stats.time, stats.T_mean, 'b-', 'LineWidth', 2); hold on;
plot(stats.time, stats.T_min, 'b--');
plot(stats.time, stats.T_max, 'b--');
xlabel('Time (s)'); ylabel('T (°C)');
title('Temperature');
legend('Mean', 'Min', 'Max', 'Location', 'best');
grid on;

% Panel 2: Sediment concentration
subplot(3,3,2);
plot(stats.time, stats.C_max, 'm-', 'LineWidth', 2); hold on;
plot(stats.time, stats.C_mean, 'm--');
xlabel('Time (s)'); ylabel('C (kg/m³)');
title('Sediment Concentration');
legend('Max', 'Mean', 'Location', 'best');
grid on;

% Panel 3: Mass conservation
subplot(3,3,3);
mass_change = (stats.C_total - stats.C_total(1)) / stats.C_total(1) * 100;
plot(stats.time, mass_change, 'k-', 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Mass Change (%)');
title('Sediment Mass Conservation');
yline(0, 'g--', 'LineWidth', 1);
grid on;
text(0.5, 0.9, sprintf('Final: %.2f%%', mass_change(end)), ...
    'Units', 'normalized', 'FontSize', 10);

% Panel 4: Velocities
subplot(3,3,4);
plot(stats.time, stats.U_max, 'r-', 'LineWidth', 2); hold on;
plot(stats.time, stats.W_max, 'g-', 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Max Velocity (m/s)');
title('Maximum Velocities');
legend('|U|_{max}', '|W|_{max}', 'Location', 'best');
grid on;

% Panel 5: DENSITY ANOMALIES - KEY FOR BUOYANCY COUPLING
subplot(3,3,5);
plot(stats.time, stats.rho_T_max, 'b-', 'LineWidth', 2); hold on;
plot(stats.time, stats.rho_C_max, 'm-', 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Δρ (kg/m³)');
title('Density Anomalies');
legend('From Temperature', 'From Sediment', 'Location', 'best');
grid on;

% Panel 6: Ratio of sediment to thermal effect
subplot(3,3,6);
plot(stats.time, stats.rho_ratio * 100, 'k-', 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Ratio (%)');
title('Sediment/Thermal Density Ratio');
grid on;
text(0.5, 0.9, sprintf('Sediment is %.1f%% of thermal effect', ...
    mean(stats.rho_ratio(stats.rho_ratio>0))*100), ...
    'Units', 'normalized', 'FontSize', 10);

% Panel 7: CFL check
subplot(3,3,7);
CFL_u = stats.U_max * deltaT / dx;
CFL_w = stats.W_max * deltaT / dz;
plot(stats.time, CFL_u, 'r-', 'LineWidth', 2); hold on;
plot(stats.time, CFL_w, 'g-', 'LineWidth', 2);
yline(1, 'k--');
xlabel('Time (s)'); ylabel('CFL');
title('CFL Numbers');
legend('CFL_u', 'CFL_w', 'Location', 'best');
grid on;

% Panel 8: Expected buoyancy effect
subplot(3,3,8);
% For C = 0.1 kg/m³: Δρ = 1035 * 6.2e-4 * 0.1 = 0.064 kg/m³
% For ΔT = 10°C: Δρ = 1035 * 2e-4 * 10 = 2.07 kg/m³
expected_drho_C = rhoConst * gammaC * 0.1;  % For C = 0.1 kg/m³
expected_drho_T = rhoConst * tAlpha * 10;   % For ΔT = 10°C
bar([expected_drho_T, expected_drho_C]);
set(gca, 'XTickLabel', {'ΔT=10°C', 'C=0.1 kg/m³'});
ylabel('Δρ (kg/m³)');
title('Expected Density Anomalies');
grid on;
text(1.5, max([expected_drho_T, expected_drho_C])*0.8, ...
    sprintf('Ratio: %.1f%%', expected_drho_C/expected_drho_T*100), 'FontSize', 10);

% Panel 9: Summary text
subplot(3,3,9);
axis off;
text(0.1, 0.9, 'CYCLE 7: BUOYANCY COUPLING TEST', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.75, sprintf('γC = %.2e m³/kg', gammaC), 'FontSize', 10);
text(0.1, 0.60, sprintf('Max Δρ from sediment: %.4f kg/m³', max(stats.rho_C_max)), 'FontSize', 10);
text(0.1, 0.45, sprintf('Max Δρ from temperature: %.4f kg/m³', max(stats.rho_T_max)), 'FontSize', 10);
text(0.1, 0.30, sprintf('Sediment/Thermal ratio: %.1f%%', ...
    max(stats.rho_C_max)/max(stats.rho_T_max)*100), 'FontSize', 10);
text(0.1, 0.15, sprintf('Mass conservation: %.2f%%', mass_change(end)), 'FontSize', 10);

if abs(mass_change(end)) < 1
    text(0.1, 0.0, '✓ Mass conserved!', 'FontSize', 10, 'Color', 'g');
else
    text(0.1, 0.0, '✗ Mass not conserved', 'FontSize', 10, 'Color', 'r');
end

sgtitle('Cycle 7: Sediment Buoyancy Coupling Diagnostics', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'plot_cycle7_diagnostics.png');
fprintf('  Saved: plot_cycle7_diagnostics.png\n');

%% ========================================================================
% FIGURE 2: SPATIAL SNAPSHOTS AT FINAL TIME
%==========================================================================
iter_final = iters(end);
time_final = iter_final * deltaT;

T = readbin(sprintf('T.%010d.data', iter_final), [Nx,Ny,Nr], prec);
C = readbin(sprintf('PTRACER01.%010d.data', iter_final), [Nx,Ny,Nr], prec);
U = readbin(sprintf('U.%010d.data', iter_final), [Nx,Ny,Nr], prec);
W = readbin(sprintf('W.%010d.data', iter_final), [Nx,Ny,Nr], prec);

% Compute density anomalies
drho_T = -rhoConst * tAlpha * (T - T_ref);
drho_C = rhoConst * gammaC * C;
drho_total = drho_T + drho_C;

jmid = round(Ny/2);

figure('Position', [50, 50, 1600, 1000], 'Name', 'Final State Analysis');

% Row 1: Basic fields
subplot(3,4,1);
pcolor(x, z, squeeze(T(:,jmid,:))'); shading flat; colorbar;
title('Temperature (°C)'); ylabel('Depth (m)');

subplot(3,4,2);
pcolor(x, z, squeeze(C(:,jmid,:))'); shading flat; colorbar;
title('Sediment (kg/m³)');

subplot(3,4,3);
pcolor(x, z, squeeze(U(:,jmid,:))'); shading flat; colorbar;
caxis([-1 1]*max(abs(U(:)))); colormap(gca, bluewhitered(64));
title('U velocity (m/s)');

subplot(3,4,4);
pcolor(x, z, squeeze(W(:,jmid,:))'); shading flat; colorbar;
caxis([-1 1]*max(abs(W(:)))); colormap(gca, bluewhitered(64));
title('W velocity (m/s)');

% Row 2: Density anomalies (KEY FOR BUOYANCY COUPLING)
subplot(3,4,5);
pcolor(x, z, squeeze(drho_T(:,jmid,:))'); shading flat; colorbar;
caxis([-1 1]*max(abs(drho_T(:)))); colormap(gca, bluewhitered(64));
title('Δρ from Temperature (kg/m³)'); ylabel('Depth (m)');

subplot(3,4,6);
pcolor(x, z, squeeze(drho_C(:,jmid,:))'); shading flat; colorbar;
title('Δρ from Sediment (kg/m³)');

subplot(3,4,7);
pcolor(x, z, squeeze(drho_total(:,jmid,:))'); shading flat; colorbar;
caxis([-1 1]*max(abs(drho_total(:)))); colormap(gca, bluewhitered(64));
title('Total Δρ (T + Sediment)');

subplot(3,4,8);
% Ratio of sediment contribution
ratio = drho_C ./ (abs(drho_T) + 1e-10);
pcolor(x, z, squeeze(ratio(:,jmid,:))'); shading flat; colorbar;
caxis([0 0.2]);
title('Sediment/|Thermal| Ratio');

% Row 3: Profiles
subplot(3,4,9);
i1 = round(Nx*0.25); i2 = round(Nx*0.5); i3 = round(Nx*0.75);
plot(squeeze(T(i1,jmid,:)), z, 'b-', 'LineWidth', 2); hold on;
plot(squeeze(T(i2,jmid,:)), z, 'g-', 'LineWidth', 2);
plot(squeeze(T(i3,jmid,:)), z, 'r-', 'LineWidth', 2);
xlabel('T (°C)'); ylabel('Depth (m)');
title('Temperature Profiles');
legend(sprintf('x=%dm', round(x(i1))), sprintf('x=%dm', round(x(i2))), ...
    sprintf('x=%dm', round(x(i3))), 'Location', 'best');
grid on;

subplot(3,4,10);
plot(squeeze(C(i1,jmid,:)), z, 'b-', 'LineWidth', 2); hold on;
plot(squeeze(C(i2,jmid,:)), z, 'g-', 'LineWidth', 2);
plot(squeeze(C(i3,jmid,:)), z, 'r-', 'LineWidth', 2);
xlabel('C (kg/m³)'); ylabel('Depth (m)');
title('Sediment Profiles');
grid on;

subplot(3,4,11);
plot(squeeze(drho_total(i1,jmid,:)), z, 'b-', 'LineWidth', 2); hold on;
plot(squeeze(drho_total(i2,jmid,:)), z, 'g-', 'LineWidth', 2);
plot(squeeze(drho_total(i3,jmid,:)), z, 'r-', 'LineWidth', 2);
xlabel('Δρ_{total} (kg/m³)'); ylabel('Depth (m)');
title('Total Density Anomaly');
grid on;

subplot(3,4,12);
plot(squeeze(U(i1,jmid,:)), z, 'b-', 'LineWidth', 2); hold on;
plot(squeeze(U(i2,jmid,:)), z, 'g-', 'LineWidth', 2);
plot(squeeze(U(i3,jmid,:)), z, 'r-', 'LineWidth', 2);
xlabel('U (m/s)'); ylabel('Depth (m)');
title('U Velocity Profiles');
grid on;

sgtitle(sprintf('Final State at t=%.1fs - Buoyancy Coupling Analysis', time_final), ...
    'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'plot_cycle7_final.png');
fprintf('  Saved: plot_cycle7_final.png\n');

%% ========================================================================
% FIGURE 3: TIME EVOLUTION OF KEY SECTIONS
%==========================================================================
% Select 4 times
if length(iters) >= 4
    snap_idx = round(linspace(1, length(iters), 4));
else
    snap_idx = 1:length(iters);
end

figure('Position', [50, 50, 1600, 800], 'Name', 'Time Evolution');

for p = 1:length(snap_idx)
    iter = iters(snap_idx(p));
    time = iter * deltaT;
    
    T = readbin(sprintf('T.%010d.data', iter), [Nx,Ny,Nr], prec);
    C = readbin(sprintf('PTRACER01.%010d.data', iter), [Nx,Ny,Nr], prec);
    
    drho_T = -rhoConst * tAlpha * (T - T_ref);
    drho_C = rhoConst * gammaC * C;
    drho_total = drho_T + drho_C;
    
    % Temperature
    subplot(3, length(snap_idx), p);
    pcolor(x, z, squeeze(T(:,jmid,:))'); shading flat; colorbar;
    caxis([9 21]);
    title(sprintf('T @ t=%.0fs', time));
    if p == 1, ylabel('Depth (m)'); end
    
    % Sediment
    subplot(3, length(snap_idx), length(snap_idx) + p);
    pcolor(x, z, squeeze(C(:,jmid,:))'); shading flat; colorbar;
    caxis([0 0.12]);
    if p == 1, ylabel('Depth (m)'); end
    title('Sediment');
    
    % Total density anomaly
    subplot(3, length(snap_idx), 2*length(snap_idx) + p);
    pcolor(x, z, squeeze(drho_total(:,jmid,:))'); shading flat; colorbar;
    caxis([-2.5 2.5]); colormap(gca, bluewhitered(64));
    if p == 1, ylabel('Depth (m)'); end
    xlabel('X (m)');
    title('Δρ_{total}');
end

sgtitle('Time Evolution: T, Sediment, and Total Density Anomaly', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'plot_cycle7_evolution.png');
fprintf('  Saved: plot_cycle7_evolution.png\n');

%% ========================================================================
% FIGURE 4: BUOYANCY COUPLING IMPACT ANALYSIS
%==========================================================================
% Quantify the DYNAMIC IMPACT of sediment buoyancy on the flow
%
% Physics:
%   Horizontal pressure gradient from density anomaly:
%     dP/dx = g * ∫(ρ - ρ₀) dz
%   
%   This creates acceleration:
%     du/dt = -1/ρ₀ * dP/dx
%
% We compare the pressure gradient from sediment vs temperature

fprintf('\n--- Buoyancy Coupling Impact Analysis ---\n');

% Use final state data (already loaded)
% T, C, drho_T, drho_C, drho_total are available

% Compute vertically-integrated density anomalies [kg/m²]
int_drho_T = squeeze(sum(drho_T, 3)) * dz;  % Integrated Δρ from T
int_drho_C = squeeze(sum(drho_C, 3)) * dz;  % Integrated Δρ from sediment
int_drho_total = int_drho_T + int_drho_C;

% Compute horizontal gradients of integrated density [kg/m³]
% This is proportional to the baroclinic pressure gradient
dIdT_dx = zeros(Nx-1, Ny);
dIdC_dx = zeros(Nx-1, Ny);
for j = 1:Ny
    dIdT_dx(:,j) = diff(int_drho_T(:,j)) / dx;
    dIdC_dx(:,j) = diff(int_drho_C(:,j)) / dx;
end

% Pressure gradient acceleration [m/s²]
% a = g/ρ₀ * d(∫Δρ dz)/dx
accel_from_T = gravity / rhoConst * dIdT_dx;
accel_from_C = gravity / rhoConst * dIdC_dx;
accel_total = accel_from_T + accel_from_C;

% Statistics
max_accel_T = max(abs(accel_from_T(:)));
max_accel_C = max(abs(accel_from_C(:)));
max_accel_total = max(abs(accel_total(:)));

% Estimate velocity contribution
% If acceleration acts over time t: Δu ~ a * t
% But actually, the gravity current develops over the simulation time
% A rough estimate of sediment's contribution to velocity
accel_ratio = max_accel_C / max_accel_T;

% Compute the actual correlation between sediment and velocity
% Where there is more sediment, is there more velocity?
C_bottom = squeeze(C(:,:,Nr));  % Bottom sediment
U_bottom = squeeze(U(:,:,Nr));  % Bottom U velocity

% Create figure
figure('Position', [50, 50, 1400, 900], 'Name', 'Buoyancy Coupling Impact');

% Panel 1: Integrated density anomaly from T
subplot(3,3,1);
pcolor(x, y, int_drho_T'); shading flat; colorbar;
caxis([-1 1]*max(abs(int_drho_T(:))));
colormap(gca, bluewhitered(64));
title('∫Δρ_T dz (kg/m²)');
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;

% Panel 2: Integrated density anomaly from sediment
subplot(3,3,2);
pcolor(x, y, int_drho_C'); shading flat; colorbar;
title('∫Δρ_C dz (kg/m²)');
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;

% Panel 3: Ratio of sediment to total
subplot(3,3,3);
ratio_map = int_drho_C ./ (abs(int_drho_T) + 0.01);
pcolor(x, y, ratio_map'); shading flat; colorbar;
caxis([0 0.1]);
title('Sediment/|Thermal| Ratio');
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;

% Panel 4: Pressure acceleration from T
subplot(3,3,4);
x_edge = (x(1:end-1) + x(2:end))/2;
pcolor(x_edge, y, accel_from_T'); shading flat; colorbar;
caxis([-1 1]*max(abs(accel_from_T(:))));
colormap(gca, bluewhitered(64));
title('Acceleration from T (m/s²)');
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;

% Panel 5: Pressure acceleration from sediment
subplot(3,3,5);
pcolor(x_edge, y, accel_from_C'); shading flat; colorbar;
caxis([-1 1]*max(abs(accel_from_C(:))));
colormap(gca, bluewhitered(64));
title('Acceleration from Sediment (m/s²)');
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;

% Panel 6: X-profiles of acceleration at mid-Y
subplot(3,3,6);
jmid = round(Ny/2);
plot(x_edge, accel_from_T(:,jmid), 'b-', 'LineWidth', 2); hold on;
plot(x_edge, accel_from_C(:,jmid)*10, 'r-', 'LineWidth', 2);  % Scaled 10x for visibility
plot(x_edge, accel_total(:,jmid), 'k--', 'LineWidth', 1);
xlabel('X (m)'); ylabel('Acceleration (m/s²)');
title('Pressure Gradient Acceleration (mid-Y)');
legend('From T', 'From Sed (×10)', 'Total', 'Location', 'best');
grid on;

% Panel 7: Correlation of bottom sediment and velocity
subplot(3,3,7);
scatter(C_bottom(:), abs(U_bottom(:)), 10, 'filled', 'MarkerFaceAlpha', 0.3);
xlabel('Bottom Sediment (kg/m³)');
ylabel('Bottom |U| (m/s)');
title('Sediment vs Velocity Correlation');
grid on;
% Compute correlation coefficient
valid = C_bottom(:) > 0.01 & ~isnan(U_bottom(:));
if sum(valid) > 10
    R = corrcoef(C_bottom(valid), abs(U_bottom(valid)));
    text(0.1, 0.9, sprintf('R = %.3f', R(1,2)), 'Units', 'normalized', 'FontSize', 10);
end

% Panel 8: Bar chart of max accelerations
subplot(3,3,8);
bar_data = [max_accel_T, max_accel_C, max_accel_C/max_accel_T*max_accel_T];
bar(bar_data);
set(gca, 'XTickLabel', {'From T', 'From Sed', 'Ratio×T'});
ylabel('Max Acceleration (m/s²)');
title('Forcing Comparison');
text(2, max_accel_C*1.2, sprintf('%.1f%% of thermal', accel_ratio*100), 'FontSize', 10);
grid on;

% Panel 9: Summary text
subplot(3,3,9);
axis off;
text(0.05, 0.95, 'BUOYANCY COUPLING IMPACT', 'FontSize', 12, 'FontWeight', 'bold');
text(0.05, 0.80, sprintf('Max acceleration from T: %.2e m/s²', max_accel_T), 'FontSize', 10);
text(0.05, 0.65, sprintf('Max acceleration from Sed: %.2e m/s²', max_accel_C), 'FontSize', 10);
text(0.05, 0.50, sprintf('Sediment/Thermal ratio: %.2f%%', accel_ratio*100), 'FontSize', 10, 'FontWeight', 'bold');
text(0.05, 0.35, ' ', 'FontSize', 10);
text(0.05, 0.20, 'Interpretation:', 'FontSize', 10, 'FontWeight', 'bold');
if accel_ratio > 0.01
    text(0.05, 0.05, sprintf('Sediment adds %.1f%% to the driving force', accel_ratio*100), 'FontSize', 10, 'Color', 'b');
else
    text(0.05, 0.05, 'Sediment effect is negligible', 'FontSize', 10, 'Color', 'r');
end

sgtitle(sprintf('Buoyancy Coupling Impact Analysis (t=%.1fs)', time_final), ...
    'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'plot_cycle7_impact.png');
fprintf('  Saved: plot_cycle7_impact.png\n');

% Store impact metrics
impact = struct();
impact.max_accel_T = max_accel_T;
impact.max_accel_C = max_accel_C;
impact.accel_ratio = accel_ratio;
impact.int_drho_T_max = max(abs(int_drho_T(:)));
impact.int_drho_C_max = max(abs(int_drho_C(:)));

%% ========================================================================
% PRINT SUMMARY
%==========================================================================
fprintf('\n============================================================\n');
fprintf('CYCLE 7 BUOYANCY COUPLING - SUMMARY\n');
fprintf('============================================================\n');
fprintf('Simulation time: %.1f seconds\n', max(stats.time));
fprintf('Number of outputs: %d\n', nT);
fprintf('\nPhysics check:\n');
fprintf('  γC = %.2e m³/kg\n', gammaC);
fprintf('  For C=0.1 kg/m³: Δρ = %.4f kg/m³\n', rhoConst * gammaC * 0.1);
fprintf('  For ΔT=10°C: Δρ = %.4f kg/m³\n', rhoConst * tAlpha * 10);
fprintf('  Ratio: %.1f%%\n', (gammaC * 0.1) / (tAlpha * 10) * 100);
fprintf('\nResults:\n');
fprintf('  Max |U|: %.4f m/s\n', max(stats.U_max));
fprintf('  Max |W|: %.4f m/s\n', max(stats.W_max));
fprintf('  Max Δρ from sediment: %.4f kg/m³\n', max(stats.rho_C_max));
fprintf('  Max Δρ from temperature: %.4f kg/m³\n', max(stats.rho_T_max));
fprintf('  Mass conservation: %.2f%%\n', mass_change(end));

fprintf('\n*** BUOYANCY COUPLING IMPACT ***\n');
fprintf('  Max pressure accel from T: %.2e m/s²\n', impact.max_accel_T);
fprintf('  Max pressure accel from C: %.2e m/s²\n', impact.max_accel_C);
fprintf('  SEDIMENT CONTRIBUTION: %.2f%% of thermal forcing\n', impact.accel_ratio*100);

fprintf('\nBuoyancy coupling assessment:\n');
if max(stats.rho_C_max) > 0.01
    fprintf('  ✓ Sediment density effect is measurable\n');
else
    fprintf('  ✗ Sediment density effect is very small\n');
end
if abs(mass_change(end)) < 1
    fprintf('  ✓ Sediment mass is conserved\n');
else
    fprintf('  ✗ Sediment mass NOT conserved (%.2f%% change)\n', mass_change(end));
end
if impact.accel_ratio > 0.01
    fprintf('  ✓ Sediment contributes %.1f%% to flow forcing\n', impact.accel_ratio*100);
else
    fprintf('  ✗ Sediment contribution to flow is negligible\n');
end
fprintf('============================================================\n');

%% ========================================================================
% HELPER FUNCTIONS
%==========================================================================

function data = readbin(fname, dims, prec)
    fid = fopen(fname, 'r', 'ieee-be');
    if fid < 0
        warning('Cannot open: %s', fname);
        data = zeros(dims);
        return;
    end
    data = fread(fid, prod(dims), prec);
    fclose(fid);
    data = reshape(data, dims);
end

function cmap = bluewhitered(n)
    if nargin < 1, n = 64; end
    r = [linspace(0, 1, n/2), ones(1, n/2)];
    g = [linspace(0, 1, n/2), linspace(1, 0, n/2)];
    b = [ones(1, n/2), linspace(1, 0, n/2)];
    cmap = [r', g', b'];
end
