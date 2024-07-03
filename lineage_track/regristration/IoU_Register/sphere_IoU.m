function IoU = sphere_IoU(x, y, rx, ry)

volume1 = 4 / 3 * pi * rx.^3;
volume2 = 4 / 3 * pi * ry.^3;
intersection = sphere_intersection(x, y, rx, ry);

IoU = intersection ./ (volume1 + volume2.' - intersection);

end

