clearscreen.
declare desired_orbit_height to 500000.

config:suppressautopilot off.
sas off.
lock throttle to 1.0.

print "Launch in 3s".
wait 3.
stage.
print "Rocket Launched".

wait until stage:solidfuel = 0.
stage.
print eta:apoapsis.

lock throttle to 1.
wait until apoapsis >= desired_orbit_height/2.

lock throttle to 0.5.
wait until apoapsis >= desired_orbit_height/1.1.

lock throttle to 0.1.
wait until apoapsis >= desired_orbit_height.

print "orbit completed" + eta:apoapsis.
lock throttle to 0.

wait until alt:radar > 70000.
stage.
wait 5.
stage.
wait 5.
rcs on.
toggle ag1.

if apoapsis < desired_orbit_height - 1000 {
    lock steering to prograde.
    lock throttle to 0.1.
    wait until apoapsis >= desired_orbit_height.
    lock throttle to 0.
}

if apoapsis > desired_orbit_height + 1000 {
    lock steering to retrograde.
    lock throttle to 0.1.
    wait until apoapsis <= desired_orbit_height.
    lock throttle to 0.
}

lock steering to north.
wait until (eta:apoapsis) - 30.
lock steering to prograde.
wait until eta:apoapsis = 12.
print "Circularizing".

lock throttle to 1.
wait until periapsis >= desired_orbit_height/2.

lock throttle to 0.5.
wait until periapsis >= desired_orbit_height/1.1.

lock throttle to 1.1.
wait until periapsis >= desired_orbit_height.

LOCK THROTTLE TO 0.