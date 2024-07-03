

function [A] = RandomRotationMatrix(seed)

q = randrot();
A = quat2rotm(q);

