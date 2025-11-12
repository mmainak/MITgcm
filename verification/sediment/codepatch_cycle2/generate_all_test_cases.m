%% generate_all_test_cases.m
%
% Batch generation of all sediment test cases
%
% PURPOSE:
% --------
% Generate initial conditions for all 6 sediment test cases in one run.
% Creates separate subdirectories for each case.
%
% USAGE:
% ------
% matlab -nodisplay < generate_all_test_cases.m
%
% OUTPUT:
% -------
% Creates subdirectories: case1/, case2/, ..., case6/
% Each contains: sediment_init.bin, sediment_init.meta, visualization PNG
%
%==========================================================================

clear all;
close all;

fprintf('\n');
fprintf('=============================================================\n');
fprintf('  GENERATING ALL SEDIMENT TEST CASES\n');
fprintf('=============================================================\n');
fprintf('\n');

%% Test case descriptions
testCases = {
    'Uniform concentration (baseline)'
    'Surface layer (settling test)'
    'Lock-exchange (gravity current)'
    'Gaussian blob (dispersion)'
    'Stratified layers (stability)'
    'Bottom resuspension (erosion)'
};

%% Generate each test case
for caseNum = 1:6
    fprintf('\n');
    fprintf('-------------------------------------------------------------\n');
    fprintf('TEST CASE %d: %s\n', caseNum, testCases{caseNum});
    fprintf('-------------------------------------------------------------\n');
    
    % Create subdirectory
    dirname = sprintf('case%d', caseNum);
    if ~exist(dirname, 'dir')
        mkdir(dirname);
    end
    cd(dirname);
    
    % Run generation script
    % (We'll inline it here to avoid external dependencies)
    try
        generate_single_case(caseNum);
        fprintf('✓ Case %d complete\n', caseNum);
    catch ME
        fprintf('✗ ERROR in case %d: %s\n', caseNum, ME.message);
    end
    
    cd('..');
end

fprintf('\n');
fprintf('=============================================================\n');
fprintf('  ALL TEST CASES GENERATED\n');
fprintf('=============================================================\n');
fprintf('\n');
fprintf('Output directories:\n');
for caseNum = 1:6
    fprintf('  case%d/  - %s\n', caseNum, testCases{caseNum});
end
fprintf('\n');
fprintf('To use a test case:\n');
fprintf('  cp case2/sediment_init.* $MITGCM_RUN/\n');
fprintf('  cd $MITGCM_RUN\n');
fprintf('  ../build/mitgcmuv\n');
fprintf('\n');

%% ========================================================================
%  HELPER FUNCTION: Generate single test case
%  ========================================================================

function generate_single_case(testCase)
    % This is a condensed version of generate_sediment_input.m
    
    %% Grid parameters
    nx = 100;
    ny = 100;
    nz = 20;
    dx = 100;
    dy = 100;
    dz = 10;
    
    Lx = nx * dx;
    Ly = ny * dy;
    Lz = nz * dz;
    
    x = (0.5:nx-0.5) * dx;
    y = (0.5:ny-0.5) * dy;
    z = -(0.5:nz-0.5) * dz;
    
    [X, Y, Z] = meshgrid(x, y, z);
    
    %% Physical parameters
    C_ref = 1.0;
    rho_sed = 2650;
    rho_water = 1025;
    ws0 = 0.01;
    gammaC = 1.6e-3;
    g = 9.81;
    
    %% Initialize field
    sediment = zeros(ny, nx, nz);
    
    switch testCase
        case 1  % Uniform
            C_background = 0.1;
            sediment(:,:,:) = C_background;
            
        case 2  % Surface layer
            C_surface = 1.0;
            H_layer = 50;
            for k = 1:nz
                if abs(z(k)) <= H_layer
                    sediment(:,:,k) = C_surface;
                end
            end
            
        case 3  % Lock-exchange
            C_plume = 5.0;
            x_lock = Lx / 2;
            width_lock = Lx / 4;
            for i = 1:nx
                if abs(x(i) - x_lock) <= width_lock/2
                    sediment(:,i,:) = C_plume;
                end
            end
            
        case 4  % Gaussian blob
            C_blob = 2.0;
            x_blob = Lx / 2;
            y_blob = Ly / 2;
            z_blob = -Lz / 2;
            sigma_blob = 500;
            for k = 1:nz
                for j = 1:ny
                    for i = 1:nx
                        r2 = (x(i)-x_blob)^2 + (y(j)-y_blob)^2 + (z(k)-z_blob)^2;
                        sediment(j,i,k) = C_blob * exp(-r2 / (2*sigma_blob^2));
                    end
                end
            end
            
        case 5  % Stratified
            C_layers = [0.5 1.0 1.5 2.0];
            n_layers = 4;
            layer_thickness = Lz / n_layers;
            for k = 1:nz
                z_center = abs(z(k));
                layer_idx = min(floor(z_center / layer_thickness) + 1, n_layers);
                sediment(:,:,k) = C_layers(layer_idx);
            end
            
        case 6  % Bottom resuspension
            C_bottom = 3.0;
            H_bottom = 30;
            for k = 1:nz
                z_center = abs(z(k));
                z_from_bottom = Lz - z_center;
                if z_from_bottom <= H_bottom
                    sediment(:,:,k) = C_bottom;
                end
            end
    end
    
    %% Statistics
    fprintf('  Min: %.4e kg/m³\n', min(sediment(:)));
    fprintf('  Max: %.4e kg/m³\n', max(sediment(:)));
    fprintf('  Mean: %.4e kg/m³\n', mean(sediment(:)));
    fprintf('  Total mass: %.4e kg\n', sum(sediment(:)) * dx * dy * dz);
    
    %% Write binary file
    filename = 'sediment_init.bin';
    fid = fopen(filename, 'w', 'ieee-be');
    count = fwrite(fid, sediment, 'real*8');
    fclose(fid);
    fprintf('  Wrote: %s (%d values)\n', filename, count);
    
    %% Write metadata
    metafile = 'sediment_init.meta';
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
    
    %% Visualization
    figure('Position', [100 100 1200 400], 'Visible', 'off');
    
    % Vertical slice
    subplot(1,3,1);
    j_mid = round(ny/2);
    pcolor(x/1000, z, squeeze(sediment(j_mid,:,:))');
    shading flat;
    colorbar;
    xlabel('x [km]');
    ylabel('z [m]');
    title(sprintf('Case %d: Y-slice', testCase));
    
    % Horizontal slice
    subplot(1,3,2);
    pcolor(x/1000, y/1000, sediment(:,:,1));
    shading flat;
    colorbar;
    xlabel('x [km]');
    ylabel('y [km]');
    title('Surface (k=1)');
    
    % Vertical profile
    subplot(1,3,3);
    C_profile = squeeze(mean(mean(sediment, 1), 2));
    plot(C_profile, z, 'b-', 'LineWidth', 2);
    grid on;
    xlabel('C [kg/m³]');
    ylabel('z [m]');
    title('Vertical Profile');
    set(gca, 'YDir', 'reverse');
    
    figname = sprintf('sediment_init_case%d.png', testCase);
    print('-dpng', '-r100', figname);
    fprintf('  Figure: %s\n', figname);
    
    close all;
end

