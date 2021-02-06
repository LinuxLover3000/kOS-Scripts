declare desired_orbit_height to 500000.
declare atmosphere_height to 50000.

declare ship_roll to 90.
declare ship_pitch to 0.
declare ship_yaw to 90.

declare throttle_value to 1.
declare max_speed to 2100.

declare landing_contition to "shid_fard".
declare iterated to false.

set this_vessel to ship.

function main {
    lock current_gravity to get_gravity(kerbin, kerbin:radius + alt:radar).
    print current_gravity.
    launch().
    control_loop_launch().
    circularize().
    finish().
}

function get_isp {
    parameter a_vessel.

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
    parameter a_vessel.
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
    parameter this_body.
    parameter radius.

    return constant:g * (this_body:mass / radius ^ 2) .
}

function get_velocity_at_apoapsis {
    parameter this_ship.
    parameter apoapsis_time.

    set m_time to timestamp(time:seconds + apoapsis_time).

    return velocityat(this_ship, m_time):orbit:mag.
}

function circularization_node {
    parameter gravity.
    parameter orbit_radius.

    set pi_squared to constant:pi ^ 2.
    set apoapsis_velocity to get_velocity_at_apoapsis(ship, ship:orbit:eta:apoapsis).

    set orbital_period to sqrt((4 * pi_squared * orbit_radius) / gravity).
    set orbital_circumference to (2 * constant:pi * orbit_radius).
    set orbit_velocity to (orbital_circumference / orbital_period).

    set deltav_for_node to orbit_velocity - apoapsis_velocity.

    return node(timespan(0, 0, 0, 0, eta:apoapsis), 0, 0, deltav_for_node).
}

function launch {

    config:suppressautopilot off.
    sas off.
    rcs off.
    clearscreen.

    lock steering to north + r(ship_yaw, -1 * ship_pitch, ship_roll).
    lock throttle to throttle_value.

    stage.
    toggle ag1.
    print "Launched".
}

function control_loop_launch {

    if landing_contition = "land" {
        print "Landing".
    }

    until apoapsis >= desired_orbit_height or landing_contition = "land" {
        control_conditions().
        wait 0.001.
        print get_gravity(kerbin, kerbin:radius + alt:radar).
    }
    set throttle_value to 0.
}

function control_conditions {
    if alt:radar <= atmosphere_height{
        set ship_pitch to 90 * (alt:radar / atmosphere_height).
        set throttle_value to ((max_speed - this_vessel:velocity:surface:mag) / max_speed).
    } else if not iterated {
        set throttle_value to 0.
        rcs on.
        set iterated to true.
    } else {
        set ship_pitch to 90.
        set throttle_value to 1.
    }

    if (this_vessel:maxthrust = 0 and throttle_value > 0) or stage:deltav:current <= (1.1 * required_resources) {
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
    parameter error_rate.
    parameter a_body.
    parameter thrust.

    local done is false.
    local starting_deltav is node:deltav:mag.
    local burn_time is get_burn_time(ship:mass, isp, a_body, node:orbit:apoapsis, thrust, node:deltav:mag).
    lock steering to node:burnvector.

    print "Burn Time: " + burn_time.

    wait until node:eta <= (burn_time / 2).

    set throttle_value to 1.

    until done {
        if node:deltav:mag <= starting_deltav * error_rate{
            unlock steering.
            set done to true.
        }
    }

    set throttle_value to 0.
    remove node.
}

function get_burn_time {
    parameter starting_mass.
    parameter ISP.
    parameter this_body.
    parameter orbit_radius.
    parameter stage_thrust.
    parameter burn_deltav.

    local gravity is get_gravity(this_body, this_body:radius + orbit_radius).
    local exhaust_velocity is isp * gravity.
    print gravity.

    local coefficient is (starting_mass * exhaust_velocity) / stage_thrust * 1000.
    local exponent is -1 * (burn_deltav / exhaust_velocity).
    local burn_length is coefficient * (1 - (constant:e ^ exponent)).

    return burn_length / 288.3947368.
}

function get_final_mass {
    parameter ship_mass.
    parameter deltav.
    parameter isp.
    parameter g.

    set exhaust_velocity to isp * g.

    return ship_mass * (constant:e ^ (( -1 * deltav) / exhaust_velocity) ).
}

function circularize {
    wait 5.
    set circular_orbit_node to circularization_node(get_gravity(kerbin, kerbin:radius + apoapsis) , apoapsis + kerbin:radius).
    add circular_orbit_node.
    execute_maneuver(get_isp(ship) , circular_orbit_node, 0.001, kerbin, get_max_thrust(ship, kerbin:radius + circular_orbit_node:orbit:apoapsis)).
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