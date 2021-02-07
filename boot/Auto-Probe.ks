global current_condition is "null".
global current_body is "kerbin".

global max_speed is 2100.
global desired_orbit_height is 500000.
global atmosphere_height is 50000.
global inclanation is 90.
global ship_pitch is 0.
global throttle_value is 1.

global g0 is 9.80665.
global error_rate is 0.0001.

function main {

    lock current_gravity to get_gravity(kerbin, kerbin:radius + alt:radar).
    print current_gravity.
    launch().
    control_loop_launch().
    circularize().
    finish().
}

function get_isp {
    local iterating is 0.
    local isp is 0.

    list engines in ship_engines.
    for engines in ship_engines{
        if engines:ignition {
            set isp to isp + engines:isp.
            set iterating to iterating +1.
        }
    }

    return isp / iterating.
}

function get_max_thrust {
    parameter thrust_altitude.

    local thrust is 0.

    list engines in ship_engines.
    for engines in ship_engines{
        if engines:ignition {
            set thrust to thrust + engines:maxthrustat(thrust_altitude).
        }
    }

    return thrust.
}

function get_gravity {
    parameter current_body.
    parameter radius.

    return constant:g * (current_body:mass / radius ^ 2) .
}

function get_velocity_at_apoapsis {
    parameter this_ship.
    parameter apoapsis_time.

    local m_time is timestamp(time:seconds + apoapsis_time).

    return velocityat(this_ship, m_time):orbit:mag.
}

function circularization_node {
    parameter gravity.
    parameter orbit_radius.

    local pi_squared is constant:pi ^ 2.
    local apoapsis_velocity is get_velocity_at_apoapsis(ship, ship:orbit:eta:apoapsis).

    local orbital_period is sqrt((4 * pi_squared * orbit_radius) / gravity).
    local orbital_circumference is (2 * constant:pi * orbit_radius).
    local orbit_velocity is (orbital_circumference / orbital_period).

    local deltav_for_node is orbit_velocity - apoapsis_velocity.

    return node(timespan(0, 0, 0, 0, eta:apoapsis), 0, 0, deltav_for_node).
}

function launch {
    config:suppressautopilot off.
    sas off.
    rcs off.
    clearscreen.

    lock steering to heading(inclanation, ship_pitch).
    lock throttle to throttle_value.

    stage.
    toggle ag1.
    print "Launched".
}

function control_loop_launch {
    local wait_time is 0.001.

    if current_condition = "land" {
        print "Landing".
    }

    until ship:apoapsis >= desired_orbit_height or current_condition = "land" {
        control_conditions().
        wait wait_time.
    }
    set throttle_value to 0.
}

function control_conditions {
    if alt:radar <= atmosphere_height{
        set ship_pitch to (alt:radar / atmosphere_height).
        set throttle_value to ((max_speed - ship:velocity:surface:mag) / max_speed).
    } else if not iterated {
        set throttle_value to 0.
        rcs on.
        set iterated to true.
    } else {
        set ship_pitch to 90.
        set throttle_value to 1.
    }

    if (ship:maxthrust = 0 and throttle_value > 0) or stage:deltav:current <= (1.1 * required_resources()) {
        if stage_function() {
            print "breaking".
        } else {
            print "Out of fuel or engine failure".
        }
    }
}

function stage_function {
    set throttle_value to 0.
    wait 1.
    ag3 on.
    ag2 on.
    stage.
    wait until stage:ready.
    set this_vessel to ship.

    //if this_vessel:partsdubbed("Landing Script"):exist  and not this_vessel:partsdubbed("Launch Script"):exist {
        //set landing_contition to "land".
        //return true.
    //} else {
        //return false.
    //}
}

function execute_maneuver {
    parameter isp.
    parameter node.
    parameter a_body.

    local done is false.
    local starting_deltav is node:deltav:mag.
    local burn_time is get_burn_time(ship:mass, get_isp(ship), node:deltav:mag).
    lock steering to node:burnvector.

    print "Burn Time: " + burn_time.

    wait until node:eta <= (burn_time / 2).

    set throttle_value to 1.

    wait burn_length.

    set throttle_value to 0.
    remove node.
}

function get_burn_time {
    parameter starting_mass.
    parameter ISP.
    parameter burn_deltav.

    local exhaust_velocity is ISP * g0.

    local mf is starting_mass / constant:e ^ (burn_deltav / exhaust_velocity).
    local fuel_flow is ship:availablethrust / exhaust_velocity.
    local burn_length is (starting_mass - mf) / fuel_flow.

    return burn_length.
}

function circularize {
    wait 5.
    set circular_orbit_node to circularization_node(get_gravity(kerbin, kerbin:radius + apoapsis) , apoapsis + kerbin:radius).
    add circular_orbit_node.
    execute_maneuver(get_isp(ship) , circular_orbit_node, kerbin).
}

function finish {
    set throttle_value to 0.
    wait 100.
    ag4 on.
    lock steering to retrograde.
    wait until steering = retrograde.
    set throttle_value to 1.
    wait until periapsis <= 0.
    set throttle_value to 0.
    print "  ".
    print "circularized and finishing.".
    shutdown.
}

function required_resources {
    return 300.
}

main().