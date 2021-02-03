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
    clearscreen.
    launch().
    control_loop_launch().
    circulurize().
    finish().
    print "".
    shutdown.
}

function launch {
    config:suppressautopilot off.
    sas off.
    rcs off.

    lock steering to north + r(ship_yaw, -1 * ship_pitch, ship_roll).
    lock throttle to throttle_value.

    stage.
    ag1 on.
    print "poggers".
}

function control_loop_launch {

    if landing_contition = "land" {
        print "midget porn is epic".
    }

    until apoapsis >= desired_orbit_height or landing_contition = "land" {
        control_conditions().
        wait 0.001.
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
        ag3 on.
        wait 5.
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
    set this_vessel to ship.

    set throttle_value to 0.
    stage.
    wait until stage:ready.

    if this_vessel = vessel("Landing Script") and not this_vessel = vessel("Launch Script") {
        set landing_contition to "land".
        return true.
    } else {
        return false.
    }
}

function circulurize {

}

function finish {
    set throttle_value to 0.
    ag4 on.
    lock steering to retrograde.
    wait 10.
    set throttle_value to 1.
    wait until periapsis <= 0.
}

function required_resources {
    return 300.
}

main().