function region = determineRegion(phaseAngle)
    % Нормализация угла фазы в диапазон [0, 2*pi)
    phaseAngle = mod(phaseAngle, 2*pi);

    % Определение границ регионов
    % Заметьте, что последняя граница 2*pi не включается, так как 0 и 2*pi эквивалентны
    region_bounds = [-3*pi/4, -pi/2, -pi/4, 0, pi/4, pi/2, 3*pi/4, pi];

    % Определение региона фазового угла
    region = find(phaseAngle >= region_bounds, 1, 'last');
    
    % Если угол фазы больше последней границы, то он принадлежит первому региону
    if phaseAngle >= region_bounds(end) || phaseAngle < region_bounds(1)
        region = 1;
    end
end
