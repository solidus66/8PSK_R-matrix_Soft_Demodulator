function R = getRMatrix(region)
angles_b0 = [
    -7*pi/8, 7*pi/8;  % область i
    -5*pi/8, 7*pi/8;  % область ii
    -3*pi/8, pi/8;    % область iii
    -pi/8,   pi/8;    % область iv
    -pi/8,   pi/8;    % область v
    -pi/8,   3*pi/8;  % область vi
    -7*pi/8, 5*pi/8;  % область vii
    -7*pi/8, 7*pi/8   % область viii
    ];

phi_1_b0 = angles_b0(region, 1);
phi_0_b0 = angles_b0(region, 2);

cos_diff_b0 = cos(phi_1_b0) - cos(phi_0_b0);
sin_diff_b0 = sin(phi_1_b0) - sin(phi_0_b0);

angles_b1 = [
    -7*pi/8, -3*pi/8; % область i
    -5*pi/8, -3*pi/8; % область ii
    -5*pi/8, -3*pi/8; % область iii
    -5*pi/8, -pi/8;   % область iv
    5*pi/8, pi/8;    % область v
    5*pi/8, 3*pi/8;  % область vi
    5*pi/8, 3*pi/8;  % область vii
    7*pi/8, 3*pi/8;  % область viii
    ];

phi_1_b1 = angles_b1(region, 1);
phi_0_b1 = angles_b1(region, 2);

cos_diff_b1 = cos(phi_1_b1) - cos(phi_0_b1);
sin_diff_b1 = sin(phi_1_b1) - sin(phi_0_b1);

angles_b2 = [
    -5*pi/8, -7*pi/8; % область i
    -5*pi/8, -7*pi/8; % область ii
    -3*pi/8, -pi/8;   % область iii
    -3*pi/8, -pi/8;   % область iv
    3*pi/8,  pi/8;   % область v
    3*pi/8,  pi/8;   % область vi
    5*pi/8,  7*pi/8; % область vii
    5*pi/8,  7*pi/8; % область viii
    ];

phi_1_b2 = angles_b2(region, 1);
phi_0_b2 = angles_b2(region, 2);

cos_diff_b2 = cos(phi_1_b2) - cos(phi_0_b2);
sin_diff_b2 = sin(phi_1_b2) - sin(phi_0_b2);

R = [
    cos_diff_b0, cos_diff_b1, cos_diff_b2;
    sin_diff_b0, sin_diff_b1, sin_diff_b2;
    ];
end