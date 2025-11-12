%% generate_sediment_input.m
%
% Generate initial condition files for MITgcm sediment tracer module
%
% PURPOSE:
% --------
% Create binary input files for sediment concentration initial conditions.
% Supports multiple test cases:
%   1. Uniform concentration (baseline test)
%   2. Surface layer initialization (settling test)
%   3. Dense plume (lock-exchange / gravity current)
%   4. Gaussian blob (dispersion test)
%   5. Stratified layers (stability test)
%
% OUTPUT FILES:
% -------------
% sediment_init.bin   - Initial sediment concentration [kg/m³]
% sediment_init.meta  - Metadata for MITgcm
%
% USAGE:
% ------
% 1. Edit grid parameters below to match your SIZE.h
% 2. Choose test case (set testCase variable)
% 3. Run: matlab -nodisplay < generate_sediment_input.m
% 4. Copy *.bin and *.meta to run directory
%
% AUTHOR: MITgcm Sediment Module - Cycle 2
% DATE: November 2025
%
%==========================================================================

clear all;
close all;

%% GRID PARAMETERS (must match SIZE.h and data)
%==========================================================================

% Horizontal grid
nx = 100;              % Number of x-grid points
ny = 100;              % Number of y-grid points
nz = 20;               % Number of z-grid points (vertical levels)

% Grid spacing
dx = 100;              % Horizontal spacing [m]
dy = 100;              % Horizontal spacing [m]
dz = 10;               % Vertical spacing [m] (uniform for now)

% Domain size
Lx = nx * dx;          % Domain length in x [m]
Ly = ny * dy;          % Domain length in y [m]
Lz = nz * dz;          % Domain depth [m]

fprintf('Grid: %d x %d x %d\n', nx, ny, nz);
fprintf('Domain: %.0f m x %.0f m x %.0f m\n', Lx, Ly, Lz);

%% CREATE COORDINATE ARRAYS
%==========================================================================

% Cell centers
x = (0.5:nx-0.5) * dx;                % x-coordinates [m]
y = (0.5:ny-0.5) * dy;                % y-coordinates [m]
z = -(0.5:nz-0.5) * dz;               % z-coordinates [m] (negative down)

% Create 3D meshgrid
[X, Y, Z] = meshgrid(x, y, z);

fprintf('x: %.1f to %.1f m\n', min(x), max(x));
fprintf('y: %.1f to %.1f m\n', min(y), max(y));
fprintf('z: %.1f to %.1f m (depth positive down)\n', max(abs(z)), min(abs(z)));

%% CHOOSE TEST CASE
%==========================================================================
%
% Test cases:
%   1 = Uniform concentration (baseline)
%   2 = Surface layer (settling test)
%   3 = Dense plume / lock-exchange (gravity current)
%   4 = Gaussian blob (3D dispersion)
%   5 = Stratified layers (stability test)
%   6 = Bottom resuspension (erosion test)
%

testCase = 2;  % ← CHANGE THIS

fprintf('\n=== TEST CASE %d ===\n', testCase);

%% PHYSICAL PARAMETERS
%==========================================================================

% Sediment properties (should match data.sediment)
C_ref = 1.0;           % Reference concentration [kg/m³]
rho_sed = 2650;        % Sediment grain density [kg/m³]
rho_water = 1025;      % Water density [kg/m³]
ws0 = 0.01;            % Settling velocity [m/s]
gammaC = 1.6e-3;       % Density expansion coeff [m³/kg]

% Test case specific parameters
switch testCase
    case 1
        C_background = 0.1;        % Uniform concentration [kg/m³]
        
    case 2
        C_surface = 1.0;           % Surface layer concentration [kg/m³]
        H_layer = 50;              % Layer thickness [m]
        
    case 3
        C_plume = 5.0;             % Plume concentration [kg/m³]
        x_lock = Lx / 2;           % Lock position [m]
        width_lock = Lx / 4;       % Lock width [m]
        
    case 4
        C_blob = 2.0;              % Blob peak concentration [kg/m³]
        x_blob = Lx / 2;           % Blob center x [m]
        y_blob = Ly / 2;           % Blob center y [m]
        z_blob = -Lz / 2;          % Blob center z [m]
        sigma_blob = 500;          % Blob radius [m]
        
    case 5
        n_layers = 4;              % Number of layers
        C_layers = [0.5 1.0 1.5 2.0];  % Concentrations [kg/m³]
        
    case 6
        C_bottom = 3.0;            % Bottom layer concentration [kg/m³]
        H_bottom = 30;             % Bottom layer thickness [m]
end

%% INITIALIZE SEDIMENT CONCENTRATION FIELD
%==========================================================================

% Preallocate 3D array
sediment = zeros(ny, nx, nz);  % Note: MITgcm order is (y, x, z)

fprintf('Generating initial conditions...\n');

switch testCase
    
    case 1  % Uniform concentration
        fprintf('  Case 1: Uniform concentration C = %.2f kg/m³\n', C_background);
        sediment(:,:,:) = C_background;
        
    case 2  % Surface layer
        fprintf('  Case 2: Surface layer\n');
        fprintf('    Concentration: %.2f kg/m³\n', C_surface);
        fprintf('    Layer depth: %.0f m\n', H_layer);
        
        for k = 1:nz
            z_center = abs(z(k));  % Depth of this level
            if z_center <= H_layer
                sediment(:,:,k) = C_surface;
            else
                sediment(:,:,k) = 0.0;
            end
        end
        
    case 3  % Dense plume / lock-exchange
        fprintf('  Case 3: Lock-exchange / Dense plume\n');
        fprintf('    Concentration: %.2f kg/m³\n', C_plume);
        fprintf('    Lock position: %.0f m\n', x_lock);
        fprintf('    Lock width: %.0f m\n', width_lock);
        
        for i = 1:nx
            if abs(x(i) - x_lock) <= width_lock/2
                sediment(:,i,:) = C_plume;
            else
                sediment(:,i,:) = 0.0;
            end
        end
        
    case 4  % Gaussian blob (3D)
        fprintf('  Case 4: Gaussian blob (3D dispersion test)\n');
        fprintf('    Peak concentration: %.2f kg/m³\n', C_blob);
        fprintf('    Center: (%.0f, %.0f, %.0f) m\n', x_blob, y_blob, z_blob);
        fprintf('    Radius (sigma): %.0f m\n', sigma_blob);
        
        for k = 1:nz
            for j = 1:ny
                for i = 1:nx
                    r2 = (x(i) - x_blob)^2 + (y(j) - y_blob)^2 + (z(k) - z_blob)^2;
                    sediment(j,i,k) = C_blob * exp(-r2 / (2*sigma_blob^2));
                end
            end
        end
        
    case 5  % Stratified layers
        fprintf('  Case 5: Stratified layers\n');
        fprintf('    Number of layers: %d\n', n_layers);
        fprintf('    Concentrations: ');
        fprintf('%.2f ', C_layers);
        fprintf('kg/m³\n');
        
        layer_thickness = Lz / n_layers;
        for k = 1:nz
            z_center = abs(z(k));
            layer_idx = min(floor(z_center / layer_thickness) + 1, n_layers);
            sediment(:,:,k) = C_layers(layer_idx);
        end
        
    case 6  % Bottom resuspension
        fprintf('  Case 6: Bottom resuspension layer\n');
        fprintf('    Concentration: %.2f kg/m³\n', C_bottom);
        fprintf('    Layer thickness: %.0f m\n', H_bottom);
        
        for k = 1:nz
            z_center = abs(z(k));
            z_from_bottom = Lz - z_center;
            if z_from_bottom <= H_bottom
                sediment(:,:,k) = C_bottom;
            else
                sediment(:,:,k) = 0.0;
            end
        end
        
end

%% STATISTICS
%==========================================================================

fprintf('\n=== INITIAL CONDITION STATISTICS ===\n');
fprintf('Min concentration: %.4e kg/m³\n', min(sediment(:)));
fprintf('Max concentration: %.4e kg/m³\n', max(sediment(:)));
fprintf('Mean concentration: %.4e kg/m³\n', mean(sediment(:)));
fprintf('Total sediment mass: %.4e kg\n', sum(sediment(:)) * dx * dy * dz);

% Check for NaNs or negatives
if any(isnan(sediment(:)))
    error('ERROR: NaN values in sediment field!');
end
if any(sediment(:) < 0)
    error('ERROR: Negative values in sediment field!');
end

%% COMPUTE DERIVED QUANTITIES (for diagnostics)
%==========================================================================

% Buoyancy anomaly due to sediment: b_sed = -g * gammaC * C
g = 9.81;  % gravity [m/s²]
buoyancy_sed = -g * gammaC * sediment;

fprintf('\n=== BUOYANCY DIAGNOSTICS ===\n');
fprintf('Min buoyancy: %.4e m/s²\n', min(buoyancy_sed(:)));
fprintf('Max buoyancy: %.4e m/s²\n', max(buoyancy_sed(:)));
fprintf('(Negative buoyancy = downward forcing)\n');

% Density anomaly: Δρ = ρ₀ * gammaC * C
delta_rho = rho_water * gammaC * sediment;
fprintf('\nMax density anomaly: %.4f kg/m³\n', max(delta_rho(:)));
fprintf('(Relative to reference density %.0f kg/m³)\n', rho_water);

%% WRITE BINARY FILE FOR MITgcm
%==========================================================================

filename = 'sediment_init.bin';
fprintf('\n=== WRITING OUTPUT ===\n');
fprintf('Writing to: %s\n', filename);

% Open file for writing (big-endian, MITgcm default)
fid = fopen(filename, 'w', 'ieee-be');
if fid == -1
    error('Cannot open file %s for writing', filename);
end

% Write data (MITgcm expects single precision _RL)
count = fwrite(fid, sediment, 'real*8');  % Use real*8 for _RL precision
fclose(fid);

fprintf('Wrote %d values (expected %d)\n', count, nx*ny*nz);

if count ~= nx*ny*nz
    error('ERROR: File write mismatch!');
end

% Check file size
fileinfo = dir(filename);
expected_size = nx * ny * nz * 8;  % 8 bytes per real*8
fprintf('File size: %d bytes (expected %d)\n', fileinfo.bytes, expected_size);

%% WRITE METADATA FILE (.meta)
%==========================================================================

metafile = 'sediment_init.meta';
fprintf('Writing metadata: %s\n', metafile);

fid = fopen(metafile, 'w');
fprintf(fid, ' nDims = [   3 ];\n');
fprintf(fid, ' dimList = [\n');
fprintf(fid, ' %6d, %6d, %6d,\n', nx, 1, nx);
fprintf(fid, ' %6d, %6d, %6d,\n', ny, 1, ny);
fprintf(fid, ' %6d, %6d, %6d\n', nz, 1, nz);
fprintf(fid, ' ];\n');
fprintf(fid, ' dataprec = [ ''float64'' ];\n');
fprintf(fid, ' nrecords = [   1 ];\n');
fprintf(fid, ' format = [ ''straight'' ];\n');
fclose(fid);

fprintf('Metadata written.\n');

%% VISUALIZATION (optional)
%==========================================================================

fprintf('\n=== CREATING VISUALIZATION ===\n');

figure('Position', [100 100 1200 800]);

% Vertical slice at mid-domain
subplot(2,2,1);
j_mid = round(ny/2);
squeeze_data = squeeze(sediment(j_mid,:,:))';
pcolor(x/1000, z, squeeze_data);
shading flat;
colorbar;
xlabel('x [km]');
ylabel('z [m]');
title(sprintf('Sediment Concentration (y-slice at j=%d)', j_mid));
colormap(jet);

% Horizontal slice at surface
subplot(2,2,2);
pcolor(x/1000, y/1000, sediment(:,:,1));
shading flat;
colorbar;
xlabel('x [km]');
ylabel('y [km]');
title('Surface Concentration (k=1)');

% Vertical profile (spatial average)
subplot(2,2,3);
C_profile = squeeze(mean(mean(sediment, 1), 2));
plot(C_profile, z, 'b-', 'LineWidth', 2);
grid on;
xlabel('Mean Concentration [kg/m³]');
ylabel('Depth [m]');
title('Vertical Profile (domain average)');
set(gca, 'YDir', 'reverse');

% Histogram
subplot(2,2,4);
histogram(sediment(:), 50);
xlabel('Concentration [kg/m³]');
ylabel('Frequency');
title('Concentration Distribution');
grid on;

% Save figure
figname = sprintf('sediment_init_case%d.png', testCase);
print('-dpng', '-r150', figname);
fprintf('Saved figure: %s\n', figname);

%% SUMMARY
%==========================================================================

fprintf('\n');
fprintf('=============================================================\n');
fprintf('  SEDIMENT INPUT GENERATION COMPLETE\n');
fprintf('=============================================================\n');
fprintf('Output files:\n');
fprintf('  %s  (binary data)\n', filename);
fprintf('  %s  (metadata)\n', metafile);
fprintf('  %s  (visualization)\n', figname);
fprintf('\n');
fprintf('Next steps:\n');
fprintf('  1. Copy *.bin and *.meta to MITgcm run directory\n');
fprintf('  2. Update input/data.ptracers to read this file:\n');
fprintf('     PTRACERS_initialFile(1) = ''sediment_init'',\n');
fprintf('  3. Run MITgcm\n');
fprintf('  4. Monitor settling and density effects\n');
fprintf('=============================================================\n');

fprintf('\nDone.\n');

