function T  = delta_FF2(T, l, start, stop)

eps = 0.000000000001;

for i=1:l:length(T)

 B = mean( T( (i+start-1):(i+start-1+stop) ) ) + eps;

 T(i:(i+l-1)) = (T(i:(i+l-1)) - B) /B;

end