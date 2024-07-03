function volume = sphere_intersection(x, y, rx, ry)

ry = ry.';
max_R = (rx + ry);
min_R = max(rx, ry) - min(rx, ry);

dist = pdist2(x, y, 'euclidean');

volume = pi * (rx + ry - dist).^2 .* (dist.^2 + 2 * dist .* (rx + ry) - 3 * (rx.^2 + ry.^2) + 6 * rx .* ry) ./ (12 * dist); 

min_vol = 4/3 * pi * min_R.^3;
volume(dist > max_R) = 0;
volume(dist < min_R) = min_vol(dist < min_R);

end

