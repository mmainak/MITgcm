% generate_input.m
% Generate input files for MITgcm sediment LES test case
% Creates bathymetry, initial T/S, and initial sediment concentration
%
% LES Configuration: 1km x 1km x 100m domain with 10m horizontal, 5m vertical resolution

clear all; close all;

%==========================================================================
% Grid parameters (must match SIZE.h)
%==========================================================================
sNx = 100;  % Grid points in X
sNy = 100;  % Grid points in Y  
Nr = 20;    % Number of vertical levels

% Grid spacing (must match data file) - LES configuration
delX = 10;     % m (finer for LES)
delY = 10;     % m (finer for LES)
delZ = 5;      % m (finer for LES)

% Domain size
Lx = sNx * delX;  % 1000 m = 1 km
Ly = sNy * delY;  % 1000 m = 1 km
Lz = Nr * delZ;   % 100 m depth

fprintf('============================================================\n');
fprintf('MITgcm Sediment LES Test Case - Input File Generator\n');
fprintf('============================================================\n');
fprintf('Grid: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('Spacing: dx=%gm, dy=%gm, dz=%gm\n', delX, delY, delZ);
fprintf('Domain: %.0fm x %.0fm x %.0fm (%.2fkm x %.2fkm x %.0fm)\n', ...
    Lx, Ly, Lz, Lx/1000, Ly/1000, Lz);
fprintf('============================================================\n\n');

% Create coordinate arrays
x = (0.5:sNx-0.5) * delX;  % Cell centers in X [m]
y = (0.5:sNy-0.5) * delY;  % Cell centers in Y [m]
z = -((0.5:Nr-0.5) * delZ)';  % Cell centers in Z (negative downward) [m]

[X, Y] = meshgrid(x, y);

fprintf('X range: %.0f to %.0f m\n', min(x), max(x));
fprintf('Y range: %.0f to %.0f m\n', min(y), max(y));
fprintf('Z range: %.0f to %.0f m\n', min(z), max(z));

%==========================================================================
% 1. BATHYMETRY - Uniform depth (all ocean, no land)
%==========================================================================
fprintf('\n============================================================\n');
fprintf('1. Creating bathymetry...\n');
fprintf('============================================================\n');

bathy = -Lz * ones(sNx, sNy);  % Depth matches Nr*delZ

% Write bathymetry (big-endian, 32-bit float)
fid = fopen('bathy.bin', 'w', 'ieee-be');
fwrite(fid, bathy, 'float32');
fclose(fid);

fprintf('✓ Created bathy.bin\n');
fprintf('  Size: %dx%d\n', sNx, sNy);
fprintf('  Depth: uniform %.0fm (all ocean)\n', -bathy(1,1));
fileinfo = dir('bathy.bin');
fprintf('  File size: %d bytes\n', fileinfo.bytes);

%==========================================================================
% 2. TEMPERATURE - Lock-exchange setup (cold left, warm right)
%==========================================================================
fprintf('\n============================================================\n');
fprintf('2. Creating temperature field (lock-exchange)...\n');
fprintf('============================================================\n');

theta = zeros(sNx, sNy, Nr);

% Lock-exchange: cold dense water on left, warm light water on right
T_cold = 10.0;  % Cold side temperature [°C]
T_warm = 20.0;  % Warm side temperature [°C]

for i = 1:sNx
    if x(i) < Lx/2
        % Left half: cold water
        theta(i, :, :) = T_cold;
    else
        % Right half: warm water
        theta(i, :, :) = T_warm;
    end
end

% Write temperature (big-endian, 32-bit float)
fid = fopen('theta.init', 'w', 'ieee-be');
fwrite(fid, theta, 'float32');
fclose(fid);

fprintf('✓ Created theta.init\n');
fprintf('  Size: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('  Left half (x < %.0fm): T = %.1f°C (cold/dense)\n', Lx/2, T_cold);
fprintf('  Right half (x >= %.0fm): T = %.1f°C (warm/light)\n', Lx/2, T_warm);
fileinfo = dir('theta.init');
fprintf('  File size: %d bytes\n', fileinfo.bytes);

%==========================================================================
% 3. SALINITY - Uniform
%==========================================================================
fprintf('\n============================================================\n');
fprintf('3. Creating salinity field...\n');
fprintf('============================================================\n');

salt = 35.0 * ones(sNx, sNy, Nr);

% Write salinity (big-endian, 32-bit float)
fid = fopen('salt.init', 'w', 'ieee-be');
fwrite(fid, salt, 'float32');
fclose(fid);

fprintf('✓ Created salt.init\n');
fprintf('  Size: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('  S: uniform %.1f psu\n', salt(1,1,1));
fileinfo = dir('salt.init');
fprintf('  File size: %d bytes\n', fileinfo.bytes);

%==========================================================================
% 4. SEDIMENT CONCENTRATION - In cold (left) half only
%==========================================================================
fprintf('\n============================================================\n');
fprintf('4. Creating sediment concentration field...\n');
fprintf('============================================================\n');

ptracer01 = zeros(sNx, sNy, Nr);

% Sediment in cold (left) half - uniform through depth
C_sediment = 0.1;  % Sediment concentration [kg/m³]

for i = 1:sNx
    if x(i) < Lx/2
        % Left half: has sediment
        ptracer01(i, :, :) = C_sediment;
    end
end

% Write sediment concentration (big-endian, 32-bit float)
fid = fopen('ptracer01.init', 'w', 'ieee-be');
fwrite(fid, ptracer01, 'float32');
fclose(fid);

fprintf('✓ Created ptracer01.init\n');
fprintf('  Size: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('  Left half (x < %.0fm): C = %.2f kg/m³\n', Lx/2, C_sediment);
fprintf('  Right half (x >= %.0fm): C = 0 kg/m³\n', Lx/2);
fprintf('  Total mass: %.2f kg\n', sum(ptracer01(:)) * delX * delY * delZ);
fileinfo = dir('ptracer01.init');
fprintf('  File size: %d bytes\n', fileinfo.bytes);

%==========================================================================
% 5. CREATE VISUALIZATION
%==========================================================================
fprintf('\n============================================================\n');
fprintf('5. Creating visualization...\n');
fprintf('============================================================\n');

figure('Position', [100, 100, 1200, 800]);

% Temperature at mid-depth
subplot(2, 3, 1);
mid_k = round(Nr/2);
pcolor(X, Y, squeeze(theta(:, :, mid_k))');
shading flat; colorbar;
title(sprintf('Temperature at z=%.0fm (°C)', z(mid_k)));
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;
colormap(gca, 'jet');

% Sediment at mid-depth
subplot(2, 3, 2);
pcolor(X, Y, squeeze(ptracer01(:, :, mid_k))');
shading flat; colorbar;
title(sprintf('Sediment at z=%.0fm (kg/m³)', z(mid_k)));
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;

% Bathymetry
subplot(2, 3, 3);
pcolor(X, Y, bathy');
shading flat; colorbar;
title('Bathymetry (m)');
xlabel('X (m)'); ylabel('Y (m)');
axis equal tight;
caxis([-Lz 0]);

% Vertical section of temperature (mid-Y)
subplot(2, 3, 4);
mid_j = round(sNy/2);
imagesc(x, z, squeeze(theta(:, mid_j, :))');
axis xy; colorbar;
title('Temperature X-Z Section');
xlabel('X (m)'); ylabel('Depth (m)');
colormap(gca, 'jet');

% Vertical section of sediment (mid-Y)
subplot(2, 3, 5);
imagesc(x, z, squeeze(ptracer01(:, mid_j, :))');
axis xy; colorbar;
title('Sediment X-Z Section');
xlabel('X (m)'); ylabel('Depth (m)');

% Horizontal profiles at mid-depth
subplot(2, 3, 6);
yyaxis left;
plot(x, squeeze(theta(:, mid_j, mid_k)), 'r-', 'LineWidth', 2);
ylabel('Temperature (°C)');
yyaxis right;
plot(x, squeeze(ptracer01(:, mid_j, mid_k)), 'b-', 'LineWidth', 2);
ylabel('Sediment (kg/m³)');
xlabel('X (m)');
title('Horizontal Profile at Mid-Depth');
grid on;
legend('Temperature', 'Sediment', 'Location', 'best');

sgtitle(sprintf('Lock-Exchange Initial Conditions: %.0fm x %.0fm x %.0fm', Lx, Ly, Lz));
saveas(gcf, 'initial_conditions.png');
fprintf('✓ Created initial_conditions.png\n');

%==========================================================================
% SUMMARY
%==========================================================================
fprintf('\n============================================================\n');
fprintf('SUMMARY - All input files created successfully!\n');
fprintf('============================================================\n\n');
fprintf('LES Configuration:\n');
fprintf('  Domain: %.0fm x %.0fm x %.0fm\n', Lx, Ly, Lz);
fprintf('  Resolution: dx=%.0fm, dy=%.0fm, dz=%.0fm\n', delX, delY, delZ);
fprintf('  Grid points: %d x %d x %d = %d\n', sNx, sNy, Nr, sNx*sNy*Nr);
fprintf('\n');
fprintf('Files created:\n');
fprintf('  1. bathy.bin        - bathymetry (flat %.0fm)\n', Lz);
fprintf('  2. theta.init       - temperature (lock-exchange: %.0f/%.0f°C)\n', T_cold, T_warm);
fprintf('  3. salt.init        - salinity (uniform 35 psu)\n');
fprintf('  4. ptracer01.init   - sediment (left half: %.2f kg/m³)\n', C_sediment);
fprintf('  5. initial_conditions.png - visualization\n\n');

binfo = dir('bathy.bin');
tinfo = dir('theta.init');
sinfo = dir('salt.init');
pinfo = dir('ptracer01.init');
total_bytes = binfo.bytes + tinfo.bytes + sinfo.bytes + pinfo.bytes;

fprintf('Total data size: %.2f MB\n\n', total_bytes/1e6);
fprintf('Expected physics:\n');
fprintf('  - Cold dense water (left) will sink and flow right along bottom\n');
fprintf('  - Warm light water (right) will rise and flow left along surface\n');
fprintf('  - Sediment will be advected with the gravity current\n');
fprintf('  - Sediment will also settle due to ws0 = 0.01 m/s\n');
fprintf('\n');
fprintf('Next steps:\n');
fprintf('  1. Copy binary files to HPC run/ directory\n');
fprintf('  2. Rebuild if code changed: make clean && make -j8\n');
fprintf('  3. Run: mpirun -np 4 ./mitgcmuv\n');
fprintf('============================================================\n');
