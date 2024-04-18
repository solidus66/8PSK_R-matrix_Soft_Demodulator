function printRMatrixValues()
%% Углы b0
%     angles = [
%         -7*pi/8, 7*pi/8;  % область i
%         -5*pi/8, 7*pi/8;  % область ii
%         -3*pi/8, pi/8;    % область iii  
%         -pi/8, pi/8;      % область iv
%         -pi/8, pi/8;      % область v
%         -pi/8, 3*pi/8;    % область vi
%         -7*pi/8, 5*pi/8;  % область vii
%         -7*pi/8, 7*pi/8   % область viii
%     ];
%% Углы b1
    angles = [
        -7*pi/8, -3*pi/8; % область i
        -5*pi/8, -3*pi/8; % область ii
        -5*pi/8, -3*pi/8; % область iii
        -5*pi/8, -pi/8;   % область iv
         5*pi/8, pi/8;    % область v
         5*pi/8, 3*pi/8;  % область vi
         5*pi/8, 3*pi/8;  % область vii
         7*pi/8, 3*pi/8;  % область viii
        ];
%% Углы b2
%     angles = [
%         -5*pi/8, -7*pi/8; % область i
%         -5*pi/8, -7*pi/8; % область ii
%         -3*pi/8, -pi/8;   % область iii
%         -3*pi/8, -pi/8;   % область iv
%          3*pi/8,  pi/8;   % область v
%          3*pi/8,  pi/8;   % область vi
%          5*pi/8,  7*pi/8; % область vii
%          5*pi/8,  7*pi/8; % область viii
%         ];
%% Счёт и вывод таблицы
    fprintf('Region   | φ''1   | φ''0   | cos(φ''1-φ''0) | sin(φ''1-φ''0)\n');
    fprintf('--------------------------------------------------------\n');
    for region = 1:size(angles, 1)
        phi_1 = angles(region, 1);
        phi_0 = angles(region, 2);
        cos_diff = cos(phi_1) - cos(phi_0); 
        sin_diff = sin(phi_1) - sin(phi_0);
        fprintf('%6s | %5.2f | %5.2f | %10.4f | %11.4f\n', ...
                ['Region ' num2str(region)], phi_1, phi_0, cos_diff, sin_diff);
    end
end
