%==========================================================================
% CALCULATE_STABILITY_PARAMS.m
%
% Derive optimal timestep and viscosity parameters from domain characteristics
% Based on physical timescales and numerical stability criteria
%==========================================================================

clear; close all; clc;

fprintf('=======================================================\n');
fprintf('  Theoretical Parameter Calculation\n');
fprintf('  Subglacial Plume Simulation\n');
fprintf('=======================================================\n\n');

%% ========== DOMAIN PARAMETERS ==========
fprintf('1. DOMAIN PARAMETERS:\n');

% Grid
Nx = 40; Ny = 8; Nr = 40;
dx_min = 5.0;   % Minimum grid spacing [m]
dx_max = 20.0;  % Maximum grid spacing [m]
dy = 5.0;       % Uniform y-spacing [m]
dz = 5.0;       % Uniform z-spacing [m]
H = 200.0;      % Domain depth [m]
L_horizontal = 435;  % Domain length [m]

fprintf('   Grid: %d x %d x %d\n', Nx, Ny, Nr);
fprintf('   dx: %.1f - %.1f m (telescoping)\n', dx_min, dx_max);
fprintf('   dy: %.1f m (uniform)\n', dy);
fprintf('   dz: %.1f m (uniform)\n', dz);
fprintf('   Domain: %.1f x %.1f x %.1f m\n', L_horizontal, Ny*dy, H);

%% ========== PHYSICAL PARAMETERS ==========
fprintf('\n2. PHYSICAL PARAMETERS:\n');

% Gravity
g = 9.81;  % [m/s²]
fprintf('   g = %.2f m/s²\n', g);

% Density parameters
rho0 = 1028;     % Reference density [kg/m³]
T_conduit = 0;   % Conduit temperature [°C]
S_conduit = 0;   % Conduit salinity [psu]
T_ambient = 2;   % Ambient temperature [°C]
S_ambient = 34.5; % Ambient salinity [psu]

% Thermal and haline expansion
alpha_T = 3.9e-5; % [1/K]
beta_S = 7.4e-4;  % [1/psu]

% Sediment
C_conduit = 1.0;   % Sediment concentration [kg/m³]
gamma_C = 5.95e-4; % Sediment expansion [m³/kg]

% Calculate density anomaly
drho_T = -rho0 * alpha_T * (T_conduit - T_ambient);  % Thermal
drho_S = -rho0 * beta_S * (S_conduit - S_ambient);   % Haline (freshwater lighter)
drho_C = rho0 * gamma_C * C_conduit;                  % Sediment (heavier)
drho_total = drho_T + drho_S + drho_C;

% Reduced gravity
g_prime = g * abs(drho_total) / rho0;

fprintf('   Density anomalies:\n');
fprintf('     Thermal: Δρ = %.2f kg/m³ (%.3f%%)\n', drho_T, 100*drho_T/rho0);
fprintf('     Haline:  Δρ = %.2f kg/m³ (%.3f%%)\n', drho_S, 100*drho_S/rho0);
fprintf('     Sediment: Δρ = %.2f kg/m³ (%.3f%%)\n', drho_C, 100*drho_C/rho0);
fprintf('     TOTAL:   Δρ = %.2f kg/m³ (%.3f%%)\n', drho_total, 100*drho_total/rho0);
fprintf('   Reduced gravity: g'' = %.3f m/s²\n', g_prime);

%% ========== CHARACTERISTIC TIMESCALES ==========
fprintf('\n3. CHARACTERISTIC TIMESCALES:\n');

% Buoyancy timescale: τ_b = sqrt(H/g')
tau_buoy = sqrt(H / g_prime);
fprintf('   Buoyancy rise: τ_b = sqrt(H/g'') = %.1f s\n', tau_buoy);

% Buoyancy velocity: U_b = sqrt(g' * H)
U_buoy = sqrt(g_prime * H);
fprintf('   Buoyancy velocity: U_b = sqrt(g''H) = %.2f m/s\n', U_buoy);

% Conduit velocity
U_conduit = 0.5;  % [m/s]
fprintf('   Conduit inflow: U_c = %.2f m/s\n', U_conduit);

% Expected maximum velocity (max of buoyancy and conduit)
U_max_expected = max(U_buoy, U_conduit);
fprintf('   Expected max velocity: U_max ~ %.2f m/s\n', U_max_expected);

% Advective timescale: τ_adv = L/U
tau_adv_horizontal = L_horizontal / U_max_expected;
tau_adv_vertical = H / U_buoy;
fprintf('   Advective timescales:\n');
fprintf('     Horizontal: τ_h = L/U = %.1f s\n', tau_adv_horizontal);
fprintf('     Vertical: τ_v = H/U = %.1f s\n', tau_adv_vertical);

%% ========== NUMERICAL STABILITY CRITERIA ==========
fprintf('\n4. NUMERICAL STABILITY CRITERIA:\n');

% CFL for advection: U*dt/dx < CFL_max (typically 0.5-1.0)
CFL_max = 0.5;  % Conservative
dt_CFL_advection = CFL_max * dx_min / U_max_expected;
fprintf('   CFL criterion (advection): dt < %.3f s\n', dt_CFL_advection);

% Gravity wave speed (for free surface)
c_wave = sqrt(g * H);
dt_CFL_wave = CFL_max * dx_min / c_wave;
fprintf('   CFL criterion (gravity wave): dt < %.3f s\n', dt_CFL_wave);

% Recommended timestep
dt_recommended = 0.8 * min(dt_CFL_advection, dt_CFL_wave);
fprintf('   RECOMMENDED: dt = %.3f s (80%% of CFL limit)\n', dt_recommended);

%% ========== VISCOSITY SELECTION ==========
fprintf('\n5. VISCOSITY PARAMETERS:\n');

% Grid Reynolds number: Re_grid = U*dx/ν
% For resolved flow: Re_grid should be O(1-100)
% Too low (Re < 1): over-diffusive, kills turbulence
% Too high (Re > 100): under-resolved, numerical oscillations

Re_grid_target = 10;  % Moderate resolution

% Horizontal viscosity: ν_h = U*dx/Re_grid
nu_h_physical = U_max_expected * dx_min / Re_grid_target;
fprintf('   Physical estimate: ν_h = U*dx/Re = %.3f m²/s\n', nu_h_physical);

% Smagorinsky-type: ν_h ~ C_s * dx²
C_smag = 0.2;  % Smagorinsky constant
nu_h_smag = C_smag * dx_min^2;
fprintf('   Smagorinsky: ν_h = C_s*dx² = %.3f m²/s\n', nu_h_smag);

% Recommended (use smaller to be conservative)
nu_h_recommended = min(nu_h_physical, nu_h_smag);
fprintf('   RECOMMENDED: ν_h = %.3f m²/s\n', nu_h_recommended);

% Vertical viscosity (molecular + small turbulent)
nu_z_recommended = 1e-3;  % [m²/s] - enhanced over molecular
fprintf('   RECOMMENDED: ν_z = %.1e m²/s\n', nu_z_recommended);

% Diffusive CFL check: ν*dt/dx² < 0.5
dt_CFL_diffusion = 0.5 * dx_min^2 / nu_h_recommended;
fprintf('   CFL criterion (diffusion): dt < %.3f s\n', dt_CFL_diffusion);

% Final dt (most restrictive)
dt_final = min([dt_CFL_advection, dt_CFL_wave, dt_CFL_diffusion]);
fprintf('   FINAL RECOMMENDED: dt = %.3f s\n', dt_final);

%% ========== TRACER DIFFUSIVITY ==========
fprintf('\n6. TRACER (SEDIMENT) DIFFUSIVITY:\n');

% Prandtl/Schmidt number: Pr = ν/κ
% For turbulent flow: Pr ~ 0.7-1.0
% For molecular: Pr ~ 7 (water), Sc ~ 700 (sediment)

Pr_turb = 1.0;  % Turbulent Prandtl number
kappa_h_tracer = nu_h_recommended / Pr_turb;
kappa_z_tracer = nu_z_recommended / Pr_turb;

fprintf('   Turbulent Pr = %.1f\n', Pr_turb);
fprintf('   RECOMMENDED: κ_h = %.3f m²/s\n', kappa_h_tracer);
fprintf('   RECOMMENDED: κ_z = %.1e m²/s\n', kappa_z_tracer);

% Péclet number: Pe = U*L/κ
Pe_tracer = U_max_expected * dx_min / kappa_h_tracer;
fprintf('   Grid Péclet: Pe = U*dx/κ = %.1f\n', Pe_tracer);
if Pe_tracer < 2
    fprintf('   ⚠️  Pe < 2: Diffusion dominates (too diffusive!)\n');
elseif Pe_tracer > 100
    fprintf('   ⚠️  Pe > 100: Under-resolved (may oscillate!)\n');
else
    fprintf('   ✓ Pe in good range (2-100): advection/diffusion balanced\n');
end

%% ========== SETTLING CONSIDERATIONS ==========
fprintf('\n7. SETTLING VELOCITY:\n');

ws = 0.001;  % Settling velocity [m/s]
fprintf('   ws = %.3f m/s\n', ws);

% Settling CFL: CFL_settle = ws*dt/dz < 0.5
dt_CFL_settling = 0.5 * dz / ws;
fprintf('   CFL criterion (settling): dt < %.1f s\n', dt_CFL_settling);

% Settling number: St = ws*τ_adv/H (ratio of settling to advection)
St = ws * tau_adv_vertical / H;
fprintf('   Stokes number: St = ws*τ/H = %.3f\n', St);
if St < 0.1
    fprintf('   → Sediment stays in suspension (weak settling)\n');
elseif St > 1
    fprintf('   → Sediment settles quickly (strong deposition)\n');
else
    fprintf('   → Moderate settling (realistic plume)\n');
end

%% ========== FINAL RECOMMENDATIONS ==========
fprintf('\n=======================================================\n');
fprintf('  RECOMMENDED PARAMETERS FOR data FILES\n');
fprintf('=======================================================\n\n');

fprintf('*** data (PARM01) ***\n');
fprintf(' deltaT = %.3f,\n', dt_final);
fprintf(' viscAh = %.2f,\n', nu_h_recommended);
fprintf(' viscAz = %.1e,\n', nu_z_recommended);
fprintf(' diffKhT = %.2f,\n', kappa_h_tracer);
fprintf(' diffKzT = %.1e,\n', kappa_z_tracer);
fprintf(' diffKhS = %.2f,\n', kappa_h_tracer);
fprintf(' diffKzS = %.1e,\n', kappa_z_tracer);

fprintf('\n*** data.ptracers (PARM01) ***\n');
fprintf(' PTRACERS_diffKh(1) = %.2f,\n', kappa_h_tracer);
fprintf(' PTRACERS_diffKr(1) = %.1e,\n', kappa_z_tracer);
fprintf(' PTRACERS_advScheme(1) = 7,  ! (3rd order flux-limited)\n');

fprintf('\n*** data.sediment (PARM01) ***\n');
fprintf(' SEDIMENT_ws0 = %.3f,\n', ws);

fprintf('\n=======================================================\n');
fprintf('  STABILITY CHECK\n');
fprintf('=======================================================\n\n');

% Current settings (from your data file)
dt_current = 0.25;
nu_h_current = 0.1;
nu_z_current = 1e-4;
kappa_h_current = 0.1;

fprintf('Current vs Recommended:\n');
fprintf('  dt:     %.3f s (current) vs %.3f s (recommended)\n', dt_current, dt_final);
fprintf('  ν_h:    %.2f m²/s (current) vs %.2f m²/s (recommended)\n', nu_h_current, nu_h_recommended);
fprintf('  κ_h:    %.2f m²/s (current) vs %.2f m²/s (recommended)\n', kappa_h_current, kappa_h_tracer);

% Check CFL numbers with current settings
CFL_adv_current = U_max_expected * dt_current / dx_min;
CFL_diff_current = nu_h_current * dt_current / dx_min^2;
CFL_settle_current = ws * dt_current / dz;

fprintf('\nCurrent CFL numbers:\n');
fprintf('  Advection: %.3f (limit: %.2f) ', CFL_adv_current, CFL_max);
if CFL_adv_current > CFL_max, fprintf('⚠️  TOO HIGH\n'); else, fprintf('✓\n'); end

fprintf('  Diffusion: %.4f (limit: 0.50) ', CFL_diff_current);
if CFL_diff_current > 0.5, fprintf('⚠️  TOO HIGH\n'); else, fprintf('✓\n'); end

fprintf('  Settling:  %.4f (limit: 0.50) ', CFL_settle_current);
if CFL_settle_current > 0.5, fprintf('⚠️  TOO HIGH\n'); else, fprintf('✓\n'); end

%% ========== EXPECTED BEHAVIOR ==========
fprintf('\n=======================================================\n');
fprintf('  EXPECTED PLUME BEHAVIOR\n');
fprintf('=======================================================\n\n');

fprintf('Physical timescales:\n');
fprintf('  Buoyancy rise: %.1f s (plume reaches surface)\n', tau_buoy);
fprintf('  Horizontal spread: %.1f s (plume crosses domain)\n', tau_adv_horizontal);
fprintf('  Settling: %.1f s (particle falls 1 grid cell)\n', dz/ws);

fprintf('\nExpected velocities:\n');
fprintf('  Conduit inflow: %.2f m/s (prescribed)\n', U_conduit);
fprintf('  Buoyant rise: %.2f m/s (from density anomaly)\n', U_buoy);
fprintf('  Maximum expected: %.2f m/s\n', U_max_expected);

fprintf('\nSimulation time needed:\n');
fprintf('  Spinup (5× τ_b): %.1f s = %.1f min\n', 5*tau_buoy, 5*tau_buoy/60);
fprintf('  Quasi-steady: %.1f s = %.1f min\n', 10*tau_buoy, 10*tau_buoy/60);

fprintf('\n=======================================================\n');

%% ========== SAVE RECOMMENDED SETTINGS TO FILE ==========
fid = fopen('RECOMMENDED_SETTINGS.txt', 'w');
fprintf(fid, 'RECOMMENDED SETTINGS FOR SUBGLACIAL PLUME\n');
fprintf(fid, '==========================================\n\n');
fprintf(fid, 'data (PARM01):\n');
fprintf(fid, '  deltaT = %.3f,\n', dt_final);
fprintf(fid, '  viscAh = %.2f,\n', nu_h_recommended);
fprintf(fid, '  viscAz = %.1e,\n', nu_z_recommended);
fprintf(fid, '  diffKhT = %.2f,\n', kappa_h_tracer);
fprintf(fid, '  diffKzT = %.1e,\n', kappa_z_tracer);
fprintf(fid, '  diffKhS = %.2f,\n', kappa_h_tracer);
fprintf(fid, '  diffKzS = %.1e,\n\n', kappa_z_tracer);
fprintf(fid, 'data.ptracers (PARM01):\n');
fprintf(fid, '  PTRACERS_diffKh(1) = %.2f,\n', kappa_h_tracer);
fprintf(fid, '  PTRACERS_diffKr(1) = %.1e,\n', kappa_z_tracer);
fprintf(fid, '  PTRACERS_advScheme(1) = 7,\n\n');
fprintf(fid, 'Expected behavior:\n');
fprintf(fid, '  Buoyancy rise time: %.1f s\n', tau_buoy);
fprintf(fid, '  Max velocity: %.2f m/s\n', U_max_expected);
fclose(fid);

fprintf('Saved: RECOMMENDED_SETTINGS.txt\n\n');
fprintf('=== DONE ===\n');
