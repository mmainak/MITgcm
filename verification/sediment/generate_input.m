% generate_input.m
% Generate input files for MITgcm sediment test case
% Creates bathymetry, initial T/S, and initial sediment concentration

clear all; close all;

%==========================================================================
% Grid parameters (must match SIZE.h)
%==========================================================================
sNx = 100;  % Grid points in X
sNy = 100;  % Grid points in Y  
Nr = 20;    % Number of vertical levels

% Grid spacing (must match data file)
delX = 100;    % m
delY = 100;    % m
delZ = 10;     % m (uniform spacing)

fprintf('============================================================\n');
fprintf('MITgcm Sediment Test Case - Input File Generator\n');
fprintf('============================================================\n');
fprintf('Grid: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('Spacing: dx=%gm, dy=%gm, dz=%gm\n', delX, delY, delZ);
fprintf('Domain: %.1fkm x %.1fkm x %gm\n', ...
    sNx*delX/1000, sNy*delY/1000, Nr*delZ);
fprintf('============================================================\n\n');

% Create coordinate arrays
x = (0.5:sNx-0.5) * delX;  % Cell centers in X
y = (0.5:sNy-0.5) * delY;  % Cell centers in Y
z = -((0.5:Nr-0.5) * delZ)';  % Cell centers in Z (negative downward)

[X, Y] = meshgrid(x, y);

fprintf('X range: %.0f to %.0f m\n', min(x), max(x));
fprintf('Y range: %.0f to %.0f m\n', min(y), max(y));
fprintf('Z range: %.0f to %.0f m\n', min(z), max(z));

%==========================================================================
% 1. BATHYMETRY - Uniform 200m depth (all ocean, no land)
%==========================================================================
fprintf('\n============================================================\n');
fprintf('1. Creating bathymetry...\n');
fprintf('============================================================\n');

bathy = -200 * ones(sNx, sNy);  % 200m depth everywhere

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
% 2. TEMPERATURE - Stratified water column
%==========================================================================
fprintf('\n============================================================\n');
fprintf('2. Creating temperature field...\n');
fprintf('============================================================\n');

theta = zeros(sNx, sNy, Nr);
for k = 1:Nr
    depth = abs(z(k));
    if depth < 50
        % Surface mixed layer: 20°C
        theta(:, :, k) = 20.0;
    elseif depth < 100
        % Thermocline: linear transition
        theta(:, :, k) = 20.0 - (depth - 50) / 50 * 10.0;
    else
        % Deep water: 10°C
        theta(:, :, k) = 10.0;
    end
end

% Write temperature (big-endian, 32-bit float)
fid = fopen('theta.init', 'w', 'ieee-be');
fwrite(fid, theta, 'float32');
fclose(fid);

fprintf('✓ Created theta.init\n');
fprintf('  Size: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('  T range: %.1f to %.1f °C\n', min(theta(:)), max(theta(:)));
fprintf('  Surface (k=1): %.1f°C\n', theta(1,1,1));
fprintf('  Bottom (k=%d): %.1f°C\n', Nr, theta(1,1,Nr));
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
% 4. WIND STRESS - Generate flow!
%==========================================================================
fprintf('\n============================================================\n');
fprintf('4. Creating wind stress fields...\n');
fprintf('============================================================\n');

% Constant eastward wind stress (0.05 N/m² = moderate wind ~5 m/s)
taux = 0.05 * ones(sNx, sNy);  % Eastward wind stress [N/m²]
tauy = 0.0 * ones(sNx, sNy);   % No meridional wind

% Write wind stress files (big-endian, 32-bit float)
fid = fopen('taux.bin', 'w', 'ieee-be');
fwrite(fid, taux, 'float32');
fclose(fid);

fid = fopen('tauy.bin', 'w', 'ieee-be');
fwrite(fid, tauy, 'float32');
fclose(fid);

fprintf('✓ Created taux.bin (zonal wind stress)\n');
fprintf('  Eastward stress: %.3f N/m² (uniform)\n', taux(1,1));
fprintf('  Approximate wind speed: ~%.0f m/s\n', sqrt(taux(1,1)/1.225*1000));
fprintf('✓ Created tauy.bin (meridional wind stress)\n');
fprintf('  Meridional stress: %.3f N/m² (no north-south wind)\n', tauy(1,1));

%==========================================================================
% 5. SEDIMENT CONCENTRATION - Localized bottom plume
%==========================================================================
fprintf('\n============================================================\n');
fprintf('5. Creating sediment concentration field...\n');
fprintf('============================================================\n');

ptracer01 = zeros(sNx, sNy, Nr);

% Create a localized sediment plume at the center bottom
center_x = round(sNx/2);
center_y = round(sNy/2);
plume_radius = 10;  % 10 cells = 1 km

fprintf('  Plume center: (%d, %d) = (%.1fkm, %.1fkm)\n', ...
    center_x, center_y, center_x*delX/1000, center_y*delY/1000);
fprintf('  Plume radius: %d cells = %.1fkm\n', ...
    plume_radius, plume_radius*delX/1000);

% Add sediment to bottom 5 layers
for k = (Nr-4):Nr  % Bottom 5 layers
    for i = 1:sNx
        for j = 1:sNy
            dist = sqrt((i - center_x)^2 + (j - center_y)^2);
            if dist < plume_radius
                % Gaussian-like profile
                factor = (1 - dist/plume_radius)^2;
                ptracer01(i, j, k) = 0.01 * factor;  % max 0.01 kg/m³
            end
        end
    end
end

% Write sediment concentration (big-endian, 32-bit float)
fid = fopen('ptracer01.init', 'w', 'ieee-be');
fwrite(fid, ptracer01, 'float32');
fclose(fid);

fprintf('✓ Created ptracer01.init\n');
fprintf('  Size: %dx%dx%d\n', sNx, sNy, Nr);
fprintf('  Sediment range: %.6f to %.6f kg/m³\n', ...
    min(ptracer01(:)), max(ptracer01(:)));
fprintf('  Non-zero cells: %d\n', sum(ptracer01(:) > 0));
fprintf('  Total mass: %.2f kg\n', ...
    sum(ptracer01(:)) * delX * delY * delZ);
fileinfo = dir('ptracer01.init');
fprintf('  File size: %d bytes\n', fileinfo.bytes);

%==========================================================================
% 6. CREATE VISUALIZATION
%==========================================================================
fprintf('\n============================================================\n');
fprintf('6. Creating visualization...\n');
fprintf('============================================================\n');

figure('Position', [100, 100, 1400, 800]);

% Bathymetry
subplot(2, 3, 1);
pcolor(X/1000, Y/1000, bathy');
shading flat; colorbar;
title('Bathymetry (m)');
xlabel('X (km)'); ylabel('Y (km)');
axis equal tight;
caxis([-200 0]);

% Temperature at surface
subplot(2, 3, 2);
pcolor(X/1000, Y/1000, squeeze(theta(:, :, 1))');
shading flat; colorbar;
title('Surface Temperature (°C)');
xlabel('X (km)'); ylabel('Y (km)');
axis equal tight;

% Sediment at bottom
subplot(2, 3, 3);
pcolor(X/1000, Y/1000, squeeze(ptracer01(:, :, Nr))');
shading flat; colorbar;
title('Sediment at Bottom (kg/m³)');
xlabel('X (km)'); ylabel('Y (km)');
axis equal tight;

% Vertical section of temperature (middle)
subplot(2, 3, 4);
imagesc(x/1000, z, squeeze(theta(round(sNx/2), :, :))');
axis xy; colorbar;
title('Temperature Section (mid-Y)');
xlabel('X (km)'); ylabel('Depth (m)');

% Vertical section of sediment (middle)
subplot(2, 3, 5);
imagesc(x/1000, z, squeeze(ptracer01(round(sNx/2), :, :))');
axis xy; colorbar;
title('Sediment Section (mid-Y)');
xlabel('X (km)'); ylabel('Depth (m)');

% Vertical profile at plume center
subplot(2, 3, 6);
plot(squeeze(ptracer01(center_x, center_y, :)), z, 'b-o', 'LineWidth', 2);
grid on;
xlabel('Sediment (kg/m³)');
ylabel('Depth (m)');
title('Sediment Profile at Center');

saveas(gcf, 'initial_conditions.png');
fprintf('✓ Created initial_conditions.png\n');

%==========================================================================
% SUMMARY
%==========================================================================
fprintf('\n============================================================\n');
fprintf('SUMMARY - All input files created successfully!\n');
fprintf('============================================================\n\n');
fprintf('Files created:\n');
fprintf('  1. bathy.bin        - bathymetry (flat 200m)\n');
fprintf('  2. theta.init       - temperature (stratified)\n');
fprintf('  3. salt.init        - salinity (uniform 35 psu)\n');
fprintf('  4. taux.bin         - zonal wind stress (eastward)\n');
fprintf('  5. tauy.bin         - meridional wind stress (zero)\n');
fprintf('  6. ptracer01.init   - sediment concentration (bottom plume)\n');
fprintf('  7. initial_conditions.png - visualization\n\n');

binfo = dir('bathy.bin');
tinfo = dir('theta.init');
sinfo = dir('salt.init');
xinfo = dir('taux.bin');
yinfo = dir('tauy.bin');
pinfo = dir('ptracer01.init');
total_bytes = binfo.bytes + tinfo.bytes + sinfo.bytes + xinfo.bytes + yinfo.bytes + pinfo.bytes;

fprintf('Total data size: %.2f MB\n\n', total_bytes/1e6);
fprintf('Next steps:\n');
fprintf('  1. Copy these files to HPC input/ directory\n');
fprintf('  2. Compile the model: make depend && make\n');
fprintf('  3. Link files to run/: ln -s ../input/* .\n');
fprintf('  4. Run: mpirun -np 4 ./mitgcmuv\n');
fprintf('============================================================\n');

