#include "main.h"

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <vector>

// =====================================================
// SIMPLE AUTON PLANNER (NO LEMLIB)
// =====================================================

pros::MotorGroup left_drive({-1, 2, -3}, pros::v5::MotorGears::blue);
pros::MotorGroup right_drive({4, -5, 6}, pros::v5::MotorGears::blue);

pros::Motor intake_left(7, pros::v5::MotorGears::blue);
pros::Motor intake_right(-8, pros::v5::MotorGears::blue);
pros::Motor outtake_left(9, pros::v5::MotorGears::blue);
pros::Motor outtake_right(-12, pros::v5::MotorGears::blue);

pros::Controller master(pros::E_CONTROLLER_MASTER);
pros::Imu imu(11);
pros::Gps gps(10);

// Optional: SD image (place at /usd/images/jerkbot.bmp)
namespace {
constexpr char kJerkbotPath[] = "/usd/images/jerkbot.bmp";
}

// =====================================================
// AUTON MODE SELECTION
// =====================================================

enum class AutonMode { GPS_MODE, BASIC_MODE };
static AutonMode g_auton_mode = AutonMode::GPS_MODE;

void update_auton_mode_from_controller() {
    if (master.get_digital(DIGITAL_A)) {
        g_auton_mode = AutonMode::GPS_MODE;
    } else if (master.get_digital(DIGITAL_B)) {
        g_auton_mode = AutonMode::BASIC_MODE;
    }
}

// =====================================================
// BMP DRAW (24-bit uncompressed)
// =====================================================
bool draw_bmp_from_sd(const char* path, int x, int y) {
    FILE* file = std::fopen(path, "rb");
    if (!file) return false;

    std::uint8_t header[54];
    if (std::fread(header, 1, sizeof(header), file) != sizeof(header)) {
        std::fclose(file);
        return false;
    }

    const std::uint32_t data_offset = *reinterpret_cast<std::uint32_t*>(&header[10]);
    const std::int32_t width = *reinterpret_cast<std::int32_t*>(&header[18]);
    const std::int32_t height = *reinterpret_cast<std::int32_t*>(&header[22]);
    const std::uint16_t bpp = *reinterpret_cast<std::uint16_t*>(&header[28]);
    const std::uint32_t compression = *reinterpret_cast<std::uint32_t*>(&header[30]);

    if (bpp != 24 || compression != 0 || width <= 0 || height == 0) {
        std::fclose(file);
        return false;
    }

    const std::int32_t abs_height = std::abs(height);
    const std::uint32_t row_size = ((bpp * width + 31) / 32) * 4;
    std::vector<std::uint8_t> row(row_size);

    std::fseek(file, static_cast<long>(data_offset), SEEK_SET);

    for (std::int32_t row_idx = 0; row_idx < abs_height; ++row_idx) {
        if (std::fread(row.data(), 1, row_size, file) != row_size) {
            break;
        }
        const std::int32_t draw_y = height > 0 ? (abs_height - 1 - row_idx) : row_idx;
        for (std::int32_t col = 0; col < width; ++col) {
            const std::size_t idx = static_cast<std::size_t>(col * 3);
            const std::uint8_t b = row[idx];
            const std::uint8_t g = row[idx + 1];
            const std::uint8_t r = row[idx + 2];
            const std::uint32_t color = (static_cast<std::uint32_t>(r) << 16) |
                                        (static_cast<std::uint32_t>(g) << 8) |
                                        static_cast<std::uint32_t>(b);
            pros::screen::set_pen(color);
            pros::screen::draw_pixel(x + col, y + draw_y);
        }
    }

    std::fclose(file);
    return true;
}

void draw_jerkbot() {
    draw_bmp_from_sd(kJerkbotPath, 0, 0);
}

// =====================================================
// SIMPLE HELPERS
// =====================================================

void stop_drive() {
    left_drive.brake();
    right_drive.brake();
}

void turn_to_heading(double target, int max_speed) {
    while (true) {
        double current = imu.get_heading();
        double error = target - current;

        if (error > 180) error -= 360;
        if (error < -180) error += 360;

        if (std::abs(error) < 2.0) break;

        double kp = 1.5;
        int speed = static_cast<int>(error * kp);

        if (speed > max_speed) speed = max_speed;
        if (speed < -max_speed) speed = -max_speed;

        left_drive.move(speed);
        right_drive.move(-speed);
        pros::delay(20);
    }
    stop_drive();
}

// =====================================================
// AUTON STEP SYSTEM (EASY TO EDIT)
// =====================================================

enum class StepType {
    DRIVE_MS,
    TURN_HEADING,
    WAIT_MS,
    INTAKE_ON,
    INTAKE_OFF,
    OUTTAKE_ON,
    OUTTAKE_OFF
};

struct Step {
    StepType type;
    int value1; // speed or heading or ms
    int value2; // duration for DRIVE_MS
};

// --- GPS MODE PLAN (EDIT THIS) ---
static Step gps_plan[] = {
    {StepType::DRIVE_MS, 60, 1200},
    {StepType::TURN_HEADING, 90, 0},
    {StepType::DRIVE_MS, -40, 500},
    {StepType::WAIT_MS, 250, 0},
};

// --- BASIC MODE PLAN (EDIT THIS) ---
static Step basic_plan[] = {
    {StepType::DRIVE_MS, 50, 1000},
    {StepType::TURN_HEADING, 45, 0},
    {StepType::DRIVE_MS, 50, 500},
};

void run_plan(const Step* plan, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i) {
        const Step& step = plan[i];
        switch (step.type) {
            case StepType::DRIVE_MS:
                left_drive.move(step.value1);
                right_drive.move(step.value1);
                pros::delay(step.value2);
                stop_drive();
                break;
            case StepType::TURN_HEADING:
                turn_to_heading(step.value1, 60);
                break;
            case StepType::WAIT_MS:
                pros::delay(step.value1);
                break;
            case StepType::INTAKE_ON:
                intake_left.move(127);
                intake_right.move(127);
                break;
            case StepType::INTAKE_OFF:
                intake_left.brake();
                intake_right.brake();
                break;
            case StepType::OUTTAKE_ON:
                outtake_left.move(127);
                outtake_right.move(127);
                break;
            case StepType::OUTTAKE_OFF:
                outtake_left.brake();
                outtake_right.brake();
                break;
        }
    }
}

// =====================================================
// SCREEN MENU (TOUCH UI)
// =====================================================

constexpr int kScreenW = 480;
constexpr int kScreenH = 240;

struct Rect {
    int x;
    int y;
    int w;
    int h;
};

bool hit_test(const Rect& r, int x, int y) {
    return x >= r.x && x <= (r.x + r.w) && y >= r.y && y <= (r.y + r.h);
}

const char* step_type_name(StepType type) {
    switch (type) {
        case StepType::DRIVE_MS: return "DRIVE_MS";
        case StepType::TURN_HEADING: return "TURN_HEADING";
        case StepType::WAIT_MS: return "WAIT_MS";
        case StepType::INTAKE_ON: return "INTAKE_ON";
        case StepType::INTAKE_OFF: return "INTAKE_OFF";
        case StepType::OUTTAKE_ON: return "OUTTAKE_ON";
        case StepType::OUTTAKE_OFF: return "OUTTAKE_OFF";
        default: return "UNKNOWN";
    }
}

StepType next_step_type(StepType type) {
    switch (type) {
        case StepType::DRIVE_MS: return StepType::TURN_HEADING;
        case StepType::TURN_HEADING: return StepType::WAIT_MS;
        case StepType::WAIT_MS: return StepType::INTAKE_ON;
        case StepType::INTAKE_ON: return StepType::INTAKE_OFF;
        case StepType::INTAKE_OFF: return StepType::OUTTAKE_ON;
        case StepType::OUTTAKE_ON: return StepType::OUTTAKE_OFF;
        case StepType::OUTTAKE_OFF: return StepType::DRIVE_MS;
        default: return StepType::DRIVE_MS;
    }
}

void draw_button(const Rect& r, const char* label, std::uint32_t color) {
    pros::screen::set_pen(color);
    pros::screen::draw_rect(r.x, r.y, r.x + r.w, r.y + r.h);
    pros::screen::print_at(r.x + 6, r.y + 18, label);
}

void draw_menu(AutonMode mode, int step_index, Step* plan, std::size_t count) {
    pros::screen::set_eraser(0x00000000);
    pros::screen::erase();

    const Rect gps_btn{10, 10, 140, 30};
    const Rect basic_btn{170, 10, 140, 30};
    const Rect save_btn{340, 10, 130, 30};

    draw_button(gps_btn, "GPS (A)", mode == AutonMode::GPS_MODE ? 0x0000FF00 : 0x00FFFFFF);
    draw_button(basic_btn, "BASIC (B)", mode == AutonMode::BASIC_MODE ? 0x0000FF00 : 0x00FFFFFF);
    draw_button(save_btn, "SAVE SD", 0x00FFFF00);

    const Rect prev_btn{10, 60, 70, 30};
    const Rect next_btn{90, 60, 70, 30};
    const Rect type_btn{170, 60, 140, 30};
    const Rect v1m_btn{320, 60, 50, 30};
    const Rect v1p_btn{380, 60, 50, 30};
    const Rect v2m_btn{320, 100, 50, 30};
    const Rect v2p_btn{380, 100, 50, 30};

    draw_button(prev_btn, "PREV", 0x00FFFFFF);
    draw_button(next_btn, "NEXT", 0x00FFFFFF);
    draw_button(type_btn, "TYPE", 0x00FFFFFF);
    draw_button(v1m_btn, "V1-", 0x00FFFFFF);
    draw_button(v1p_btn, "V1+", 0x00FFFFFF);
    draw_button(v2m_btn, "V2-", 0x00FFFFFF);
    draw_button(v2p_btn, "V2+", 0x00FFFFFF);

    if (step_index < 0) step_index = 0;
    if (step_index >= static_cast<int>(count)) step_index = static_cast<int>(count) - 1;

    const Step& step = plan[step_index];
    pros::screen::print_at(10, 150, "STEP: %d / %d", step_index + 1, static_cast<int>(count));
    pros::screen::print_at(10, 175, "TYPE: %s", step_type_name(step.type));
    pros::screen::print_at(10, 200, "V1: %d", step.value1);
    pros::screen::print_at(10, 225, "V2: %d", step.value2);
}

bool save_plans_to_sd() {
    FILE* file = std::fopen("/usd/auton_plans.txt", "w");
    if (!file) return false;

    std::fprintf(file, "[GPS]\\n");
    for (const auto& step : gps_plan) {
        std::fprintf(file, "%s,%d,%d\\n", step_type_name(step.type), step.value1, step.value2);
    }

    std::fprintf(file, "[BASIC]\\n");
    for (const auto& step : basic_plan) {
        std::fprintf(file, "%s,%d,%d\\n", step_type_name(step.type), step.value1, step.value2);
    }

    std::fclose(file);
    return true;
}

void menu_loop() {
    int step_index = 0;
    draw_menu(g_auton_mode, step_index,
              g_auton_mode == AutonMode::GPS_MODE ? gps_plan : basic_plan,
              g_auton_mode == AutonMode::GPS_MODE ? sizeof(gps_plan) / sizeof(gps_plan[0])
                                                  : sizeof(basic_plan) / sizeof(basic_plan[0]));

    while (true) {
        pros::screen_touch_status_s_t status = pros::screen::touch_status();
        if (status.touch_status == pros::E_TOUCH_RELEASED) {
            const int x = status.x;
            const int y = status.y;

            const Rect gps_btn{10, 10, 140, 30};
            const Rect basic_btn{170, 10, 140, 30};
            const Rect save_btn{340, 10, 130, 30};
            const Rect prev_btn{10, 60, 70, 30};
            const Rect next_btn{90, 60, 70, 30};
            const Rect type_btn{170, 60, 140, 30};
            const Rect v1m_btn{320, 60, 50, 30};
            const Rect v1p_btn{380, 60, 50, 30};
            const Rect v2m_btn{320, 100, 50, 30};
            const Rect v2p_btn{380, 100, 50, 30};

            if (hit_test(gps_btn, x, y)) g_auton_mode = AutonMode::GPS_MODE;
            if (hit_test(basic_btn, x, y)) g_auton_mode = AutonMode::BASIC_MODE;
            if (hit_test(save_btn, x, y)) save_plans_to_sd();

            Step* plan = g_auton_mode == AutonMode::GPS_MODE ? gps_plan : basic_plan;
            const int count = g_auton_mode == AutonMode::GPS_MODE
                                  ? static_cast<int>(sizeof(gps_plan) / sizeof(gps_plan[0]))
                                  : static_cast<int>(sizeof(basic_plan) / sizeof(basic_plan[0]));

            if (hit_test(prev_btn, x, y)) step_index = std::max(0, step_index - 1);
            if (hit_test(next_btn, x, y)) step_index = std::min(count - 1, step_index + 1);
            if (hit_test(type_btn, x, y)) plan[step_index].type = next_step_type(plan[step_index].type);
            if (hit_test(v1m_btn, x, y)) plan[step_index].value1 -= 5;
            if (hit_test(v1p_btn, x, y)) plan[step_index].value1 += 5;
            if (hit_test(v2m_btn, x, y)) plan[step_index].value2 -= 50;
            if (hit_test(v2p_btn, x, y)) plan[step_index].value2 += 50;

            draw_menu(g_auton_mode, step_index, plan, count);
        }

        pros::delay(50);
    }
}

// =====================================================
// PROS LIFECYCLE
// =====================================================

void initialize() {
    pros::lcd::initialize();
    imu.reset(true);
    while (imu.is_calibrating()) {
        pros::delay(10);
    }
    draw_jerkbot();
    static pros::Task menu_task([](void*) { menu_loop(); });
}

void autonomous() {
    update_auton_mode_from_controller();
    draw_jerkbot();

    if (g_auton_mode == AutonMode::GPS_MODE) {
        run_plan(gps_plan, sizeof(gps_plan) / sizeof(gps_plan[0]));
    } else {
        run_plan(basic_plan, sizeof(basic_plan) / sizeof(basic_plan[0]));
    }
}

void opcontrol() {
    while (true) {
        update_auton_mode_from_controller();

        int left_y = master.get_analog(ANALOG_LEFT_Y);
        int right_y = master.get_analog(ANALOG_RIGHT_Y);

        left_drive.move(left_y);
        right_drive.move(right_y);

        if (master.get_digital(DIGITAL_L1)) {
            intake_left.move(127);
            intake_right.move(127);
        } else if (master.get_digital(DIGITAL_L2)) {
            intake_left.move(-127);
            intake_right.move(-127);
        } else {
            intake_left.brake();
            intake_right.brake();
        }

        if (master.get_digital(DIGITAL_R1)) {
            outtake_left.move(127);
            outtake_right.move(127);
        } else if (master.get_digital(DIGITAL_R2)) {
            outtake_left.move(-127);
            outtake_right.move(-127);
        } else {
            outtake_left.brake();
            outtake_right.brake();
        }

        pros::delay(20);
    }
}
