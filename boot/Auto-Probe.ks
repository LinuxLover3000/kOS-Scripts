wait until ship:unpacked.
clearscreen.

lock throttle to 1.0.
print "Launch in 3s".
wait 3.
stage.
print "Rocket Launched".

wait until stage:solidfuel = 0.
stage.
LOCK THROTTLE TO 1.

wait until apoapsis > 250000.
LOCK THROTTLE TO 0.5.

wait until apoapsis > 450000.
lock throttle to 0.1.

wait until apoapsis >= 500000.
LOCK THROTTLE TO 0.

stage.
stage.