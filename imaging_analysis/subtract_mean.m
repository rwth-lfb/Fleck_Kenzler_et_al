function T  = subtract_mean(T, l, start, stop)

for i=1:l:length(T)

 B = mean( T( (i+start-1):(i+start-1+stop) ) );

 T(i:(i+l-1)) = T(i:(i+l-1)) - B;

end