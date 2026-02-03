#include "main.h"
#include "lemlib/api.hpp"

// ======================================================
// Motors
// ======================================================

// Drivetrain motors
pros::MotorGroup left_motors({pros::Motor(1, pros::E_MOTOR_GEAR_BLUE, false),
                              pros::Motor(2, pros::E_MOTOR_GEAR_BLUE, true),
                              pros::Motor(3, pros::E_MOTOR_GEAR_BLUE, false)});
pros::MotorGroup right_motors({pros::Motor(4, pros::E_MOTOR_GEAR_BLUE, true),
                               pros::Motor(5, pros::E_MOTOR_GEAR_BLUE, false),
                               pros::Motor(6, pros::E_MOTOR_GEAR_BLUE, true)});

// Intake motors
pros::Motor intake_left(7, pros::E_MOTOR_GEAR_BLUE, false);
pros::Motor intake_right(8, pros::E_MOTOR_GEAR_BLUE, true);

// Outtake motor
pros::Motor outtake(9, pros::E_MOTOR_GEAR_BLUE, false);

// ======================================================
// Controller
// ======================================================
pros::Controller master(pros::E_CONTROLLER_MASTER);

namespace {
void gps_screen_task_fn(void*) {
    while (true) {
        const auto position = gps.get_position();
        pros::screen::print(TEXT_MEDIUM, 1, "GPS X: %.2f m", position.x);
        pros::screen::print(TEXT_MEDIUM, 2, "GPS Y: %.2f m", position.y);
        pros::screen::print(TEXT_MEDIUM, 3, "GPS H: %.2f deg", gps.get_heading() / 100.0);
        pros::delay(200);
    }
}
}

// ======================================================
// GPS Sensor
// ======================================================
pros::Gps gps(10, 0, 0); // Removed status flag

// ======================================================
// LemLib Setup
// ======================================================
lemlib::Drivetrain drivetrain(&left_motors, &right_motors, 12.75, 3.25, 450);
lemlib::OdomSensors sensors(nullptr, nullptr, nullptr, nullptr, &gps);

lemlib::ControllerSettings linearController(10, 0, 30, 0, 1, 500, 3);
lemlib::ControllerSettings angularController(8, 0, 40, 0, 1, 500, 3);

lemlib::Chassis chassis(&drivetrain, linearController, angularController, sensors);

// ======================================================
// Utility Functions
// ======================================================
void intake_on() {
    intake_left.move(127);
    intake_right.move(127);
}

void intake_reverse() {
    intake_left.move(-127);
    intake_right.move(-127);
}

void intake_off() {
    intake_left.brake();
    intake_right.brake();
}

void outtake_on() {
    outtake.move(127);
}

void outtake_off() {
    outtake.brake();
}

// ======================================================
// Initialization
// ======================================================
void initialize() {
    pros::lcd::initialize();
<<<<<<< Updated upstream
    pros::lcd::set_text(1, "LemLib Initialized");

    chassis.calibrate(); // GPS calibration
=======
    imu.reset(true); 
    static pros::Task gps_screen_task(gps_screen_task_fn, nullptr, "gps-screen");
>>>>>>> Stashed changes
}

// ======================================================
// Autonomous
// ======================================================
void autonomous() {
    chassis.setPose(0, 0, 0);
    chassis.moveToPoint(24, 0, 2000);
    intake_on();
    pros::delay(1500);
    intake_off();
    chassis.moveToPoint(36, 18, 2500);
    chassis.turnToHeading(90, 1000);
    outtake_on();
    pros::delay(1200);
    outtake_off();
    chassis.moveToPoint(0, 0, 3000);
    chassis.turnToHeading(0, 1000);
}

// ======================================================
// Operator Control
// ======================================================
void opcontrol() {
    while (true) {
        int forward = master.get_analog(ANALOG_LEFT_Y);
        int turn = master.get_analog(ANALOG_RIGHT_X);

        left_motors.move(forward - turn);
        right_motors.move(forward + turn);

        if (master.get_digital(DIGITAL_L1)) {
            intake_on();
        } else if (master.get_digital(DIGITAL_L2)) {
            intake_reverse();
        } else {
<<<<<<< Updated upstream
            intake_off();
=======
            intake_left.brake();
            intake_right.brake();
        }

        // --- OUTTAKE CONTROL (R1/R2) ---
        if (master.get_digital(DIGITAL_R1)) {
            outtake_left.move(127);
            outtake_right.move(127);
        } else if (master.get_digital(DIGITAL_R2)) {
            outtake_left.move(-127);
            outtake_right.move(-127);
        } else {
            outtake_left.brake();
            outtake_right.brake();
>>>>>>> Stashed changes
        }

        pros::delay(20);
    }
}
