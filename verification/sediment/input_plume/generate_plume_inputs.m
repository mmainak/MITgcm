%% generate_plume_inputs.m
% Generate all input files for subglacial plume simulation
% 
% PHYSICS:
% --------
% A subglacial conduit releases fresh, cold, sediment-laden water
% at the west boundary (seafloor, z=-200m). The discharge is buoyant
% (fresh water is ~2.5% lighter than ambient) and rises as a
% turbulent plume, entraining ambient water as it ascends.
%
% DOMAIN:
% -------
% - Open water domain (SHELFICE DISABLED for initial testing)
% - 20m x 10m conduit at center of west boundary (seafloor)
% - Open boundary on east (sponge layer)
% - Free-slip walls on north/south
% - Flat bottom at 200m depth
%
% PARALLEL:
% ---------
% - 4 processors (nPx=2, nPy=2)
% - sNx=20, sNy=4 per processor
% - Total: Nx=40, Ny=8, Nr=40
%
% FORCING:
% --------
% OBCS provides CONSTANT boundary conditions:
% - Conduit: u=0.5 m/s, T=0C, S=0 psu, sediment=1 kg/m^3
% - These values are applied at every timestep
% - Creates continuous subglacial discharge
%
% NOTE: SHELFICE is DISABLED to avoid conflict with OBCS west boundary.
%       Re-enable after plume dynamics verified, using ICEFRONT for
%       vertical ice face if needed.
%
% Author: MITgcm Sediment Project
% Date: January 2026

clear all; close all;

fprintf('========================================\n');
fprintf('  Subglacial Plume Input Generator\n');
fprintf('  8-Processor Parallel Configuration\n');
fprintf('========================================\n\n');

%% ========== GRID PARAMETERS ==========
% Parallel configuration (matches HPC SIZE.h)
sNx = 20;       % cells per processor in x
sNy = 4;        % cells per processor in y
nPx = 2;        % processors in x
nPy = 2;        % processors in y

Nx = sNx * nPx; % total cells in x = 40
Ny = sNy * nPy; % total cells in y = 8
Nr = 40;        % cells in z (uniform)

dy = 5.0;       % uniform y-spacing [m]
dz = 5.0;       % uniform z-spacing [m]

% Telescoping grid in x: 5m near ice -> 20m at far field
dx_min = 5.0;   % resolution at ice face [m]
dx_max = 20.0;  % resolution at open boundary [m]

% Geometric stretching: dx(i) = dx_min * r^(i-1)
r = (dx_max / dx_min)^(1/(Nx-1));

% Generate delX array
delX = dx_min * r.^(0:Nx-1);
Lx = sum(delX);

% Uniform delY and delZ
delY = dy * ones(1, Ny);
Ly = sum(delY);
delZ = dz * ones(1, Nr);
Lz = sum(delZ);

fprintf('PARALLEL CONFIGURATION:\n');
fprintf('  Processors: %d (nPx=%d, nPy=%d)\n', nPx*nPy, nPx, nPy);
fprintf('  Per-proc: sNx=%d, sNy=%d\n', sNx, sNy);
fprintf('\nGRID CONFIGURATION:\n');
fprintf('  Nx=%d, Ny=%d, Nr=%d\n', Nx, Ny, Nr);
fprintf('  Lx=%.1f m (dx: %.1f to %.1f m, r=%.4f)\n', Lx, dx_min, dx_max, r);
fprintf('  Ly=%.1f m (dy: %.1f m uniform)\n', Ly, dy);
fprintf('  Lz=%.1f m (dz: %.1f m uniform)\n', Lz, dz);

% Cell centers
xC = cumsum(delX) - delX/2;
yC = cumsum(delY) - delY/2;
zC = -cumsum(delZ) + delZ/2;  % negative depth

%% ========== PHYSICAL PARAMETERS ==========
fprintf('\nPHYSICAL PARAMETERS:\n');

% NOTE: SHELFICE DISABLED - open water domain
% (Ice geometry kept for reference when re-enabling SHELFICE/ICEFRONT)
ice_depth = Lz;     % [m] - not used with SHELFICE disabled
ice_base_k = Nr;    % k-index - not used with SHELFICE disabled
fprintf('  SHELFICE: DISABLED (open water domain)\n');

% Conduit geometry (at DOMAIN BASE = grounding line, centered in y)
conduit_width = 20;   % [m] in y-direction
conduit_height = 10;  % [m] in z-direction

% Conduit indices (centered in y, at DOMAIN BOTTOM in z)
% y: center is at Ly/2 = 20m, conduit spans 10-30m
conduit_j_start = floor((Ly/2 - conduit_width/2) / dy) + 1;  % j=3
conduit_j_end = floor((Ly/2 + conduit_width/2) / dy);        % j=6
% z: conduit at seafloor, spans from z=-190m to z=-200m
conduit_k_start = Nr - conduit_height/dz + 1;  % k=39
conduit_k_end = Nr;                             % k=40

fprintf('  Conduit: %.0fm x %.0fm at DOMAIN BASE (grounding line)\n', conduit_width, conduit_height);
fprintf('    j=%d to %d (y=%.0f to %.0f m)\n', ...
    conduit_j_start, conduit_j_end, (conduit_j_start-1)*dy, conduit_j_end*dy);
fprintf('    k=%d to %d (z=%.0f to %.0f m)\n', ...
    conduit_k_start, conduit_k_end, -(conduit_k_start-1)*dz, -conduit_k_end*dz);

% Discharge properties
conduit_velocity = 0.5;  % inflow velocity [m/s]
T_conduit = 0.0;         % temperature [C]
S_conduit = 0.0;         % salinity [psu]
C_conduit = 1.0;         % sediment [kg/m^3]

% Ambient water properties
T_ambient = 2.0;    % [C]
S_ambient = 34.5;   % [psu]

% Calculate buoyancy
beta_S = 7.4e-4;    % haline contraction [1/psu]
gamma_C = 6.0e-4;   % sediment expansion [m^3/kg]
rho0 = 1028;        % reference density [kg/m^3]

% Density anomaly from freshwater
drho_fresh = -rho0 * beta_S * (S_conduit - S_ambient);  % negative = lighter
% Density anomaly from sediment
drho_sed = rho0 * gamma_C * C_conduit;  % positive = heavier
% Net density anomaly
drho_net = drho_fresh + drho_sed;

fprintf('\nBUOYANCY ANALYSIS:\n');
fprintf('  Freshwater effect: drho = %.2f kg/m^3 (%.1f%% lighter)\n', ...
    drho_fresh, -drho_fresh/rho0*100);
fprintf('  Sediment effect: drho = %.2f kg/m^3 (%.2f%% heavier)\n', ...
    drho_sed, drho_sed/rho0*100);
fprintf('  Net effect: drho = %.2f kg/m^3 (%.1f%% lighter)\n', ...
    drho_net, -drho_net/rho0*100);
fprintf('  --> Plume is STRONGLY BUOYANT, will rise rapidly\n');

% Discharge flux
conduit_area = conduit_width * conduit_height;
Q_volume = conduit_velocity * conduit_area;  % [m^3/s]
Q_sediment = Q_volume * C_conduit;           % [kg/s]

fprintf('\nDISCHARGE RATES:\n');
fprintf('  Conduit area: %.0f m^2\n', conduit_area);
fprintf('  Volume flux: %.1f m^3/s\n', Q_volume);
fprintf('  Freshwater flux: %.1f m^3/s\n', Q_volume);
fprintf('  Sediment flux: %.1f kg/s\n', Q_sediment);

%% ========== NUMERICAL STABILITY CHECK ==========
fprintf('\nSTABILITY CHECK:\n');
dt = 0.25;      % timestep [s]
nu_h = 0.1;     % horizontal viscosity [m^2/s]
nu_z = 1e-4;    % vertical viscosity [m^2/s]
U_max = 1.0;    % expected max velocity [m/s]

% CFL conditions
CFL_adv = U_max * dt / dx_min;
CFL_diff_h = nu_h * dt / dx_min^2;
CFL_diff_z = nu_z * dt / dz^2;

fprintf('  dt = %.3f s\n', dt);
fprintf('  CFL (advective): %.3f (need < 1)\n', CFL_adv);
fprintf('  CFL (horiz diff): %.4f (need < 0.5)\n', CFL_diff_h);
fprintf('  CFL (vert diff): %.6f (need < 0.5)\n', CFL_diff_z);

if CFL_adv < 1 && CFL_diff_h < 0.5 && CFL_diff_z < 0.5
    fprintf('  --> All stability criteria satisfied!\n');
else
    fprintf('  --> WARNING: Some stability criteria violated!\n');
end

%% ========== WRITE GRID FILES ==========
fprintf('\n========== WRITING FILES ==========\n');

% delX.bin
fid = fopen('delX.bin', 'w', 'ieee-be'); 
fwrite(fid, double(delX), 'float64'); 
fclose(fid);
fprintf('delX.bin: %d values, %.1f to %.1f m\n', Nx, min(delX), max(delX));

% delY.bin
fid = fopen('delY.bin', 'w', 'ieee-be'); 
fwrite(fid, double(delY), 'float64'); 
fclose(fid);
fprintf('delY.bin: %d values, all %.1f m\n', Ny, dy);

%% ========== BATHYMETRY ==========
% Flat bottom at Lz depth
bathy = -Lz * ones(Nx, Ny);
fid = fopen('bathy.bin', 'w', 'ieee-be'); 
fwrite(fid, double(bathy), 'float64'); 
fclose(fid);
fprintf('bathy.bin: flat bottom at %.0f m\n', -Lz);

%% ========== SHELFICE TOPOGRAPHY (DISABLED) ==========
% NOTE: SHELFICE is DISABLED in data.pkg to avoid conflict with OBCS
% This file is NOT generated. Domain is open water.
%
% When re-enabling SHELFICE, use this code:
% shelfice_topo = zeros(Nx, Ny);
% n_ice_cells = 2;  % ice extends 2 cells into domain (10m)
% conduit_top_depth = (conduit_k_start - 1) * dz;  % z = -190m
% for i = 1:n_ice_cells
%     for j = 1:Ny
%         if j >= conduit_j_start && j <= conduit_j_end
%             shelfice_topo(i, j) = -conduit_top_depth;
%         else
%             shelfice_topo(i, j) = -Lz;
%         end
%     end
% end
% fid = fopen('shelfice_topo.bin', 'w', 'b'); 
% fwrite(fid, shelfice_topo, 'float64'); 
% fclose(fid);

n_ice_cells = 2;  % Keep for visualization reference
conduit_top_depth = (conduit_k_start - 1) * dz;
fprintf('shelfice_topo.bin: NOT GENERATED (SHELFICE disabled)\n');

%% ========== INITIAL CONDITIONS ==========
% Temperature: uniform ambient
T_init = T_ambient * ones(Nx, Ny, Nr);
fid = fopen('T_init.bin', 'w', 'ieee-be'); 
fwrite(fid, double(T_init), 'float64'); 
fclose(fid);
fprintf('T_init.bin: uniform %.1f C\n', T_ambient);

% Salinity: uniform ambient
S_init = S_ambient * ones(Nx, Ny, Nr);
fid = fopen('S_init.bin', 'w', 'ieee-be'); 
fwrite(fid, double(S_init), 'float64'); 
fclose(fid);
fprintf('S_init.bin: uniform %.1f psu\n', S_ambient);

% Sediment: initially zero
sed_init = zeros(Nx, Ny, Nr);
fid = fopen('sediment_init.bin', 'w', 'ieee-be'); 
fwrite(fid, double(sed_init), 'float64'); 
fclose(fid);
fprintf('sediment_init.bin: zero initial sediment\n');

%% ========== OBCS: WEST BOUNDARY ==========
% This is the KEY for constant forcing!
% Arrays are (Ny, Nr) = (8, 40)
% MITgcm reads these ONCE and applies at EVERY timestep

fprintf('\nOBCS WEST (constant forcing):\n');

% Initialize all fields with ambient/zero
OBWu = zeros(Ny, Nr);      % u-velocity (inflow = positive)
OBWv = zeros(Ny, Nr);      % v-velocity (zero)
OBWt = T_ambient * ones(Ny, Nr);  % temperature
OBWs = S_ambient * ones(Ny, Nr);  % salinity
OBWsed = zeros(Ny, Nr);    % sediment

% Set conduit region
for j = conduit_j_start:conduit_j_end
    for k = conduit_k_start:conduit_k_end
        OBWu(j, k) = conduit_velocity;
        OBWt(j, k) = T_conduit;
        OBWs(j, k) = S_conduit;
        OBWsed(j, k) = C_conduit;
    end
end

% Above ice: set u=0 (ice blocks flow) - already zero
% Below ice base: allow potential return flow (u=0 for now)

% VERIFICATION: Check conduit values before writing
fprintf('\n  PRE-WRITE VERIFICATION:\n');
fprintf('    OBWsed(j=%d:%d, k=%d:%d) = min:%.3f, max:%.3f, mean:%.3f\n', ...
    conduit_j_start, conduit_j_end, conduit_k_start, conduit_k_end, ...
    min(min(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))), ...
    max(max(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))), ...
    mean(mean(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))));
fprintf('    OBWsed elsewhere: min:%.3f, max:%.3f\n', ...
    min(OBWsed(:)), max(OBWsed(:)));

% Write files (ensure double precision)
OBWu = double(OBWu);
OBWv = double(OBWv);
OBWt = double(OBWt);
OBWs = double(OBWs);
OBWsed = double(OBWsed);

% Write as (Ny, Nr) - MATLAB column-major matches Fortran column-major
fid = fopen('OBWu.bin', 'w', 'ieee-be'); fwrite(fid, OBWu, 'float64'); fclose(fid);
fid = fopen('OBWv.bin', 'w', 'ieee-be'); fwrite(fid, OBWv, 'float64'); fclose(fid);
fid = fopen('OBWt.bin', 'w', 'ieee-be'); fwrite(fid, OBWt, 'float64'); fclose(fid);
fid = fopen('OBWs.bin', 'w', 'ieee-be'); fwrite(fid, OBWs, 'float64'); fclose(fid);
fid = fopen('OBWsed.bin', 'w', 'ieee-be'); fwrite(fid, OBWsed, 'float64'); fclose(fid);

% POST-WRITE VERIFICATION: Read back and check
fid = fopen('OBWsed.bin', 'r', 'ieee-be'); 
OBWsed_check = fread(fid, [Ny, Nr], 'float64');  % Read as (Ny, Nr)
fclose(fid);
fprintf('  POST-WRITE VERIFICATION:\n');
fprintf('    OBWsed file: size=%dx%d, conduit_max=%.3f, elsewhere_max=%.3f\n', ...
    size(OBWsed_check,1), size(OBWsed_check,2), ...
    max(max(OBWsed_check(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))), ...
    max(OBWsed_check(:)));

fprintf('  OBWu: conduit u=%.2f m/s, elsewhere u=0\n', conduit_velocity);
fprintf('  OBWt: conduit T=%.1fC, elsewhere T=%.1fC\n', T_conduit, T_ambient);
fprintf('  OBWs: conduit S=%.1f, elsewhere S=%.1f\n', S_conduit, S_ambient);
fprintf('  OBWsed: conduit C=%.1f kg/m^3, elsewhere C=0\n', C_conduit);

%% ========== OBCS: EAST BOUNDARY ==========
% Open boundary with sponge relaxation toward ambient
% IMPORTANT: Only T/S are prescribed at east boundary
%            Velocity uses Orlanski radiation BC (not prescribed)
%            Sediment uses zero-gradient BC in sediment code (not prescribed)
fprintf('\nOBCS EAST (radiation + sponge):\n');

OBEu = zeros(Ny, Nr);        % Generated but NOT used (Orlanski handles u/v)
OBEv = zeros(Ny, Nr);        % Generated but NOT used
OBEt = T_ambient * ones(Ny, Nr);  % USED: Ambient temperature
OBEs = S_ambient * ones(Ny, Nr);  % USED: Ambient salinity
OBEsed = zeros(Ny, Nr);      % Generated but NOT used (zero-grad BC in code)

% Ensure double precision
OBEu = double(OBEu);
OBEv = double(OBEv);
OBEt = double(OBEt);
OBEs = double(OBEs);
OBEsed = double(OBEsed);

% Write as (Ny, Nr) - MATLAB column-major matches Fortran column-major
% Note: OBEu.bin, OBEv.bin, OBEsed.bin are generated for completeness
%       but are not used (commented out in data.obcs)
fid = fopen('OBEu.bin', 'w', 'ieee-be'); fwrite(fid, OBEu, 'float64'); fclose(fid);
fid = fopen('OBEv.bin', 'w', 'ieee-be'); fwrite(fid, OBEv, 'float64'); fclose(fid);
fid = fopen('OBEt.bin', 'w', 'ieee-be'); fwrite(fid, OBEt, 'float64'); fclose(fid);
fid = fopen('OBEs.bin', 'w', 'ieee-be'); fwrite(fid, OBEs, 'float64'); fclose(fid);
fid = fopen('OBEsed.bin', 'w', 'ieee-be'); fwrite(fid, OBEsed, 'float64'); fclose(fid);

fprintf('  Velocity: Orlanski radiation BC (not prescribed)\n');
fprintf('  Temperature: T=%.1fC (prescribed)\n', T_ambient);
fprintf('  Salinity: S=%.1f (prescribed)\n', S_ambient);
fprintf('  Sediment: Zero-gradient BC in code (not prescribed)\n');

%% ========== VISUALIZATION ==========
fprintf('\n========== GENERATING FIGURES ==========\n');

figure('Position', [100 100 1400 500]);

% Plot 1: Domain side view (x-z at center y)
subplot(1,3,1);
hold on;

% Grid lines (sparse for clarity)
xF = [0, cumsum(delX)];
zF = [0, -cumsum(delZ)];
for i = 1:20:length(xF)
    plot([xF(i) xF(i)], [0 -Lz], 'k-', 'LineWidth', 0.3);
end
for k = 1:5:length(zF)
    plot([0 min(500, Lx)], [zF(k) zF(k)], 'k-', 'LineWidth', 0.3);
end

% Open water domain (light blue background)
fill([0 min(500,Lx) min(500,Lx) 0], [0 0 -Lz -Lz], [0.9 0.95 1], ...
     'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Seafloor
fill([0 min(500,Lx) min(500,Lx) 0], [-Lz -Lz -Lz-10 -Lz-10], [0.6 0.4 0.2], ...
     'EdgeColor', 'k', 'LineWidth', 2);

% West boundary wall (solid)
plot([0 0], [0 -Lz], 'b-', 'LineWidth', 3);

% Conduit at WEST BOUNDARY (seafloor)
cond_x = [0 15 15 0];
cond_z = [-(conduit_k_start-1)*dz -(conduit_k_start-1)*dz -conduit_k_end*dz -conduit_k_end*dz];
fill(cond_x, cond_z, 'r', 'FaceAlpha', 0.8);
text(20, -195, 'CONDUIT', 'Color', 'r', 'FontWeight', 'bold');

% Plume path (schematic) - rises from conduit
plume_x = [15 40 80 140 220 350 500];
plume_z = [-195 -160 -120 -80 -40 -10 -5];
plot(plume_x, plume_z, 'r--', 'LineWidth', 2);
quiver(plume_x(1:end-1), plume_z(1:end-1), ...
    diff(plume_x)*0.3, diff(plume_z)*0.3, 0, 'r', 'LineWidth', 1.5);

xlabel('x [m]'); ylabel('z [m]');
title(sprintf('Side View (x-z) - OPEN WATER, %d procs', nPx*nPy));
axis equal;
xlim([0 min(500, Lx)]); ylim([-Lz-10 10]);
legend('Grid', 'Water', 'Seafloor', 'Wall', 'Conduit', 'Plume', 'Location', 'southeast');

% Plot 2: Ice face view (y-z) - showing conduit opening
subplot(1,3,2);
hold on;

yF = [0, cumsum(delY)];
for j = 1:length(yF)
    plot([yF(j) yF(j)], [0 -Lz], 'k-', 'LineWidth', 0.5);
end
for k = 1:5:length(zF)
    plot([0 Ly], [zF(k) zF(k)], 'k-', 'LineWidth', 0.5);
end

% Ice with CONDUIT OPENING
% Left side of ice (j < conduit)
fill([0 (conduit_j_start-1)*dy (conduit_j_start-1)*dy 0], ...
     [0 0 -Lz -Lz], [0.7 0.85 1], 'EdgeColor', 'b', 'LineWidth', 2);
% Right side of ice (j > conduit)
fill([conduit_j_end*dy Ly Ly conduit_j_end*dy], ...
     [0 0 -Lz -Lz], [0.7 0.85 1], 'EdgeColor', 'b', 'LineWidth', 2);
% Ice ABOVE conduit (partial depth)
conduit_top_z = -(conduit_k_start-1)*dz;
fill([(conduit_j_start-1)*dy conduit_j_end*dy conduit_j_end*dy (conduit_j_start-1)*dy], ...
     [0 0 conduit_top_z conduit_top_z], [0.7 0.85 1], 'EdgeColor', 'b', 'LineWidth', 2);

% Conduit OPENING (water, not ice)
cond_y = [(conduit_j_start-1)*dy conduit_j_end*dy conduit_j_end*dy (conduit_j_start-1)*dy];
fill(cond_y, cond_z, 'r', 'FaceAlpha', 0.8);
text(Ly/2, -195, 'CONDUIT', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');

xlabel('y [m]'); ylabel('z [m]');
title('Ice Face View (y-z) - CONDUIT OPENING');
axis equal;
xlim([0 Ly]); ylim([-Lz 10]);

% Plot 3: OBCS west boundary
subplot(1,3,3);
imagesc(1:Ny, -(1:Nr)*dz+dz/2, OBWu');
colorbar;
hold on;
% Mark conduit region
rectangle('Position', [conduit_j_start-0.5, -conduit_k_end*dz, ...
    conduit_j_end-conduit_j_start+1, conduit_height], ...
    'EdgeColor', 'r', 'LineWidth', 2);
xlabel('j index'); ylabel('z [m]');
title('OBWu [m/s] - West Boundary');
set(gca, 'YDir', 'normal');

saveas(gcf, 'plume_setup.png');
fprintf('Saved: plume_setup.png\n');

%% ========== 3D VISUALIZATION ==========
% Create 3D plot showing ice shelf with conduit hole and bathymetry
figure('Position', [100 100 1000 800]);

% Create meshgrid for plotting
[X, Y] = meshgrid(xC, yC);  % Note: MATLAB meshgrid is (y,x) order

% Bathymetry surface (flat bottom)
bathy_surf = -Lz * ones(Ny, Nx);

% Ice shelf surface (with conduit hole)
% Only plot where ice exists (first n_ice_cells in x)
ice_surf = zeros(Ny, Nx);
for ii = 1:Nx
    for jj = 1:Ny
        if ii <= n_ice_cells
            % Ice region
            if jj >= conduit_j_start && jj <= conduit_j_end
                % Conduit opening - ice stops at -190m
                ice_surf(jj, ii) = -conduit_top_depth;
            else
                % Full depth ice (grounded)
                ice_surf(jj, ii) = -Lz;
            end
        else
            % No ice - set to NaN so it won't plot
            ice_surf(jj, ii) = NaN;
        end
    end
end

% Plot bathymetry (seafloor)
surf(X, Y, bathy_surf, 'FaceColor', [0.6 0.4 0.2], 'EdgeColor', 'none', ...
     'FaceAlpha', 0.7);
hold on;

% Plot ice shelf bottom surface
surf(X, Y, ice_surf, 'FaceColor', [0.7 0.85 1], 'EdgeColor', [0 0 0.5], ...
     'LineWidth', 0.5, 'FaceAlpha', 0.8);

% Plot ice shelf top (surface, z=0)
ice_top = zeros(Ny, Nx);
ice_top(:, n_ice_cells+1:end) = NaN;  % Only where ice exists
surf(X, Y, ice_top, 'FaceColor', [0.9 0.95 1], 'EdgeColor', [0 0 0.5], ...
     'LineWidth', 0.5, 'FaceAlpha', 0.9);

% Draw vertical ice walls
% Front face of ice (at x = xF(n_ice_cells+1))
x_front = xF(n_ice_cells+1);
[Y_wall, Z_wall] = meshgrid(yC, linspace(0, -Lz, 20));
X_wall = x_front * ones(size(Y_wall));
% Adjust Z for conduit opening
for jj = 1:Ny
    if jj >= conduit_j_start && jj <= conduit_j_end
        Z_wall(Z_wall(:,jj) < -conduit_top_depth, jj) = NaN;
    end
end
surf(X_wall, Y_wall, Z_wall, 'FaceColor', [0.7 0.85 1], 'EdgeColor', 'none', 'FaceAlpha', 0.6);

% Mark the conduit opening with red
cond_y_range = [(conduit_j_start-1)*dy, conduit_j_end*dy];
cond_z_range = [-conduit_top_depth, -Lz];
% Bottom of conduit (on seafloor)
patch([0 x_front x_front 0], ...
      [cond_y_range(1) cond_y_range(1) cond_y_range(2) cond_y_range(2)], ...
      [cond_z_range(2) cond_z_range(2) cond_z_range(2) cond_z_range(2)], ...
      'r', 'FaceAlpha', 0.9, 'EdgeColor', 'k', 'LineWidth', 2);
% Back wall of conduit (at x=0)
patch([0 0 0 0], ...
      [cond_y_range(1) cond_y_range(2) cond_y_range(2) cond_y_range(1)], ...
      [cond_z_range(1) cond_z_range(1) cond_z_range(2) cond_z_range(2)], ...
      'r', 'FaceAlpha', 0.9, 'EdgeColor', 'k', 'LineWidth', 2);

% Add arrow showing flow direction
quiver3(5, Ly/2, -195, 30, 0, 0, 0, 'r', 'LineWidth', 3, 'MaxHeadSize', 2);
text(40, Ly/2, -195, 'INFLOW', 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');

% Labels and formatting
xlabel('x [m]', 'FontSize', 12);
ylabel('y [m]', 'FontSize', 12);
zlabel('z [m]', 'FontSize', 12);
title('3D View: Ice Shelf with Conduit Opening at Base', 'FontSize', 14);

% Set view angle
view(45, 25);
axis equal;
xlim([0 150]);
ylim([0 Ly]);
zlim([-Lz 10]);
grid on;
box on;

% Add legend
h1 = patch(NaN, NaN, NaN, [0.7 0.85 1]);
h2 = patch(NaN, NaN, NaN, [0.6 0.4 0.2]);
h3 = patch(NaN, NaN, NaN, 'r');
legend([h1 h2 h3], {'Ice Shelf', 'Seafloor', 'Conduit Opening'}, ...
       'Location', 'northeast');

% Add annotation
annotation('textbox', [0.15, 0.02, 0.7, 0.05], ...
    'String', sprintf('Conduit: %dm wide x %dm high at seafloor (z=-200m)', conduit_width, conduit_height), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 11);

saveas(gcf, 'plume_setup_3D.png');
fprintf('Saved: plume_setup_3D.png\n');

%% ========== FILE SUMMARY ==========
fprintf('\n========== FILES GENERATED ==========\n');
files = dir('*.bin');
total_size = 0;
for i = 1:length(files)
    fprintf('  %-20s %8.1f KB\n', files(i).name, files(i).bytes/1024);
    total_size = total_size + files(i).bytes;
end
fprintf('  %-20s %8.1f KB\n', 'TOTAL', total_size/1024);

fprintf('\n========== READY TO RUN ==========\n');
fprintf('PARALLEL CONFIGURATION:\n');
fprintf('  Processors: %d (nPx=%d, nPy=%d)\n', nPx*nPy, nPx, nPy);
fprintf('  Per-processor tile: sNx=%d, sNy=%d\n', sNx, sNy);
fprintf('  Total domain: Nx=%d, Ny=%d, Nr=%d\n', Nx, Ny, Nr);
fprintf('  Domain size: %.1f x %.1f x %.1f m\n', Lx, Ly, Lz);
fprintf('\nGROUNDED ICE PLUME - Expected behavior:\n');
fprintf('  1. Fresh water exits conduit at SEAFLOOR (z=-200m) at %.1f m/s\n', conduit_velocity);
fprintf('  2. Buoyancy (%.1f%% lighter) drives rapid ascent\n', -drho_net/rho0*100);
fprintf('  3. Plume rises 200m along GROUNDED ice face, entraining ambient water\n');
fprintf('  4. At surface, plume spreads horizontally toward open boundary\n');
fprintf('  5. Sediment settles (ws=0.001 m/s) as plume disperses\n');
fprintf('\nRun command: mpirun -np 4 ./mitgcmuv\n');
fprintf('Simulation time: 1 hour (dt=0.25s, nSteps=14400)\n');
