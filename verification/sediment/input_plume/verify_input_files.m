%==========================================================================
% VERIFY_INPUT_FILES.m
%
% Check all generated binary input files for NaN, Inf, or corrupted data
% This will identify which file is causing the NaN in the simulation
%==========================================================================

clear; close all; clc;

fprintf('=== VERIFYING ALL INPUT FILES ===\n\n');

% Grid parameters (must match SIZE.h)
sNx = 20; sNy = 4; Nr = 40;
nPx = 2; nPy = 2;
Nx = sNx * nPx; Ny = sNy * nPy;

%--------------------------------------------------------------------------
% 1. Check Initial Conditions
%--------------------------------------------------------------------------
fprintf('1. Checking INITIAL CONDITIONS:\n');

% Check sediment_init.bin
if exist('sediment_init.bin', 'file')
    % First check file size
    finfo = dir('sediment_init.bin');
    expected_size = Nx * Ny * Nr * 8; % 8 bytes per float64
    fprintf('   sediment_init.bin: File size = %d bytes (expected %d)\n', finfo.bytes, expected_size);
    
    fid = fopen('sediment_init.bin', 'r', 'ieee-be');
    % Read as vector then reshape (column-major)
    sed_init = fread(fid, Nx*Ny*Nr, 'float64');
    fclose(fid);
    
    if length(sed_init) ~= Nx*Ny*Nr
        warning('*** SIZE MISMATCH: read %d elements, expected %d ***', length(sed_init), Nx*Ny*Nr);
    end
    
    fprintf('      Read %d elements, expected %dx%dx%d = %d\n', length(sed_init), Nx, Ny, Nr, Nx*Ny*Nr);
    fprintf('      Range: [%.6e, %.6e]\n', min(sed_init(:)), max(sed_init(:)));
    fprintf('      NaN count: %d\n', sum(isnan(sed_init(:))));
    fprintf('      Inf count: %d\n', sum(isinf(sed_init(:))));
    
    if any(isnan(sed_init(:)))
        warning('*** NaN DETECTED in sediment_init.bin ***');
    end
    if any(isinf(sed_init(:)))
        warning('*** Inf DETECTED in sediment_init.bin ***');
    end
else
    warning('sediment_init.bin NOT FOUND');
end

% Check T_init.bin
if exist('T_init.bin', 'file')
    finfo = dir('T_init.bin');
    fprintf('   T_init.bin: File size = %d bytes (expected %d)\n', finfo.bytes, Nx*Ny*Nr*8);
    
    fid = fopen('T_init.bin', 'r', 'ieee-be');
    T_init = fread(fid, Nx*Ny*Nr, 'float64');
    fclose(fid);
    
    fprintf('      Range: [%.2f, %.2f]°C, NaN=%d, Inf=%d\n', ...
        min(T_init(:)), max(T_init(:)), sum(isnan(T_init(:))), sum(isinf(T_init(:))));
    
    if any(isnan(T_init(:))) || any(isinf(T_init(:)))
        warning('*** CORRUPTED T_init.bin ***');
    end
else
    warning('T_init.bin NOT FOUND');
end

% Check S_init.bin  
if exist('S_init.bin', 'file')
    finfo = dir('S_init.bin');
    fprintf('   S_init.bin: File size = %d bytes (expected %d)\n', finfo.bytes, Nx*Ny*Nr*8);
    
    fid = fopen('S_init.bin', 'r', 'ieee-be');
    S_init = fread(fid, Nx*Ny*Nr, 'float64');
    fclose(fid);
    
    fprintf('      Range: [%.2f, %.2f] psu, NaN=%d, Inf=%d\n', ...
        min(S_init(:)), max(S_init(:)), sum(isnan(S_init(:))), sum(isinf(S_init(:))));
    
    if any(isnan(S_init(:))) || any(isinf(S_init(:)))
        warning('*** CORRUPTED S_init.bin ***');
    end
else
    warning('S_init.bin NOT FOUND');
end

%--------------------------------------------------------------------------
% 2. Check OBCS Files (West Boundary)
%--------------------------------------------------------------------------
fprintf('\n2. Checking WEST BOUNDARY (OBCS):\n');

obcs_files_west = {'OBWu.bin', 'OBWv.bin', 'OBWt.bin', 'OBWs.bin', 'OBWsed.bin'};
obcs_names = {'U velocity', 'V velocity', 'Temperature', 'Salinity', 'Sediment'};

for idx = 1:length(obcs_files_west)
    fname = obcs_files_west{idx};
    vname = obcs_names{idx};
    
    if exist(fname, 'file')
        finfo = dir(fname);
        expected_size = Ny * Nr * 8;
        
        fid = fopen(fname, 'r', 'ieee-be');
        data = fread(fid, Ny*Nr, 'float64');
        fclose(fid);
        data = reshape(data, Ny, Nr); % Reshape to (Ny, Nr)
        
        fprintf('   %s (%s): %dx%d, file size=%d (expected %d)\n', ...
            fname, vname, Ny, Nr, finfo.bytes, expected_size);
        fprintf('      Range: [%.6e, %.6e]\n', min(data(:)), max(data(:)));
        fprintf('      NaN count: %d\n', sum(isnan(data(:))));
        fprintf('      Inf count: %d\n', sum(isinf(data(:))));
        
        if any(isnan(data(:)))
            warning('*** NaN DETECTED in %s ***', fname);
        end
        if any(isinf(data(:)))
            warning('*** Inf DETECTED in %s ***', fname);
        end
        
        % For OBWsed specifically, check for expected conduit values
        if strcmp(fname, 'OBWsed.bin')
            conduit_k = 36:40; % Bottom 5 layers
            conduit_data = data(:, conduit_k);
            nonzero_count = sum(conduit_data(:) > 0);
            fprintf('      Non-zero entries in conduit region: %d / %d\n', ...
                nonzero_count, numel(conduit_data));
            
            if nonzero_count == 0
                warning('*** OBWsed has NO sediment in conduit! ***');
            end
        end
    else
        warning('%s NOT FOUND', fname);
    end
end

%--------------------------------------------------------------------------
% 3. Check OBCS Files (East Boundary)
%--------------------------------------------------------------------------
fprintf('\n3. Checking EAST BOUNDARY (OBCS):\n');

obcs_files_east = {'OBEu.bin', 'OBEv.bin', 'OBEt.bin', 'OBEs.bin', 'OBEsed.bin'};

for idx = 1:length(obcs_files_east)
    fname = obcs_files_east{idx};
    vname = obcs_names{idx};
    
    if exist(fname, 'file')
        finfo = dir(fname);
        expected_size = Ny * Nr * 8;
        
        fid = fopen(fname, 'r', 'ieee-be');
        data = fread(fid, Ny*Nr, 'float64');
        fclose(fid);
        data = reshape(data, Ny, Nr); % Reshape to (Ny, Nr)
        
        fprintf('   %s (%s): %dx%d, file size=%d (expected %d)\n', ...
            fname, vname, Ny, Nr, finfo.bytes, expected_size);
        fprintf('      Range: [%.6e, %.6e]\n', min(data(:)), max(data(:)));
        fprintf('      NaN count: %d\n', sum(isnan(data(:))));
        fprintf('      Inf count: %d\n', sum(isinf(data(:))));
        
        if any(isnan(data(:)))
            warning('*** NaN DETECTED in %s ***', fname);
        end
        if any(isinf(data(:)))
            warning('*** Inf DETECTED in %s ***', fname);
        end
    else
        warning('%s NOT FOUND', fname);
    end
end

%--------------------------------------------------------------------------
% 4. Check Geometry Files
%--------------------------------------------------------------------------
fprintf('\n4. Checking GEOMETRY FILES:\n');

if exist('bathy.bin', 'file')
    finfo = dir('bathy.bin');
    fprintf('   bathy.bin: File size = %d bytes (expected %d)\n', finfo.bytes, Nx*Ny*8);
    
    fid = fopen('bathy.bin', 'r', 'ieee-be');
    bathy = fread(fid, Nx*Ny, 'float64');
    fclose(fid);
    
    fprintf('      Range: [%.1f, %.1f] m, NaN=%d, Inf=%d\n', ...
        min(bathy(:)), max(bathy(:)), sum(isnan(bathy(:))), sum(isinf(bathy(:))));
    
    if any(isnan(bathy(:))) || any(isinf(bathy(:)))
        warning('*** CORRUPTED bathy.bin ***');
    end
else
    warning('bathy.bin NOT FOUND');
end

if exist('shelfice_topo.bin', 'file')
    finfo = dir('shelfice_topo.bin');
    fprintf('   shelfice_topo.bin: File size = %d bytes (expected %d)\n', finfo.bytes, Nx*Ny*8);
    
    fid = fopen('shelfice_topo.bin', 'r', 'ieee-be');
    ice = fread(fid, Nx*Ny, 'float64');
    fclose(fid);
    
    fprintf('      Range: [%.1f, %.1f] m, NaN=%d, Inf=%d\n', ...
        min(ice(:)), max(ice(:)), sum(isnan(ice(:))), sum(isinf(ice(:))));
    
    if any(isnan(ice(:))) || any(isinf(ice(:)))
        warning('*** CORRUPTED shelfice_topo.bin ***');
    end
else
    warning('shelfice_topo.bin NOT FOUND');
end

%--------------------------------------------------------------------------
% 5. Summary
%--------------------------------------------------------------------------
fprintf('\n=== VERIFICATION COMPLETE ===\n');
fprintf('If any NaN or Inf was detected above, regenerate that file!\n');
