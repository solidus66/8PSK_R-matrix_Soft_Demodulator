function region = determineRegion(phaseAngle)
    % нормализация угла фазы в диапазон [-pi, pi)
    phaseAngle = mod(phaseAngle + pi, 2*pi) - pi;

    % определение границ для всех восьми областей
    region_bounds = [-pi, -3*pi/4, -pi/2, -pi/4, 0, pi/4, pi/2, 3*pi/4];

    % определение области фазового угла
    region = find(phaseAngle >= region_bounds, 1, 'last');
    if isempty(region)
        region = 1;
    end
end