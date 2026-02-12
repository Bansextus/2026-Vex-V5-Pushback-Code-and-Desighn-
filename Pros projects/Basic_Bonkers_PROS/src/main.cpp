#include "main.h"

#include <cstdio>
#include <string>
#include <vector>

namespace {
constexpr int kLogIntervalMs = 20;
constexpr int kBufferLimit = 25;
constexpr int kDisplayIntervalMs = 100;
constexpr int kHistoryStartLine = 3;
constexpr int kHistoryLines = 5;
constexpr const char* kLogDir = "/usd/";
constexpr const char* kLogPrefix = "bonkers_log_";

std::string make_log_path() {
    char path[128];
    std::snprintf(path, sizeof(path), "%s%s%u.txt", kLogDir, kLogPrefix, pros::millis());
    return std::string(path);
}

FILE* open_log_file(std::string* out_path) {
    if (out_path == nullptr) {
        return nullptr;
    }

    *out_path = make_log_path();
    FILE* file = std::fopen(out_path->c_str(), "w");
    if (!file) {
        return nullptr;
    }

    std::fflush(file);

    return file;
}

void display_line(std::int16_t line, const char* text) {
    pros::lcd::set_text(line, text);
    pros::screen::print(TEXT_MEDIUM, line + 1, "%s", text);
}

void log_event(FILE* file,
               std::vector<std::string>& buffer,
               const char* event,
               const char* value) {
    if (!file || !event || !value) {
        return;
    }

    char row[96];
    const int written = std::snprintf(row, sizeof(row), "%s : %s\n", event, value);
    if (written > 0) {
        buffer.emplace_back(row, static_cast<std::size_t>(written));
    }
}

void flush_buffer(FILE* file, std::vector<std::string>& buffer) {
    if (!file || buffer.empty()) {
        return;
    }

    for (const auto& line : buffer) {
        std::fwrite(line.data(), 1, line.size(), file);
    }
    std::fflush(file);
    buffer.clear();
}
}

// ======================================================
// PROS Required Hooks
// ======================================================
void initialize() {
    pros::lcd::initialize();
    pros::screen::set_eraser(0x00000000);
    pros::screen::set_pen(0x00FFFFFF);
    pros::screen::erase();
    display_line(0, "Basic Bonkers Logger");
}

void disabled() {}

void competition_initialize() {}

void autonomous() {}

void opcontrol() {
    pros::Controller master(pros::E_CONTROLLER_MASTER);

    std::string log_path;
    FILE* log_file = open_log_file(&log_path);

    display_line(1, "Tap screen to save");
    display_line(2, log_file ? log_path.c_str() : "No SD card");
    for (int i = 0; i < kHistoryLines; ++i) {
        display_line(kHistoryStartLine + i, "");
    }

    const std::uint32_t start_ms = pros::millis();
    std::uint32_t last_display_ms = start_ms;
    std::vector<std::string> buffer;
    buffer.reserve(kBufferLimit);
    std::vector<std::string> history;
    history.reserve(kHistoryLines);

    int last_btnL1 = -1;
    int last_btnL2 = -1;
    int last_btnR1 = -1;
    int last_btnR2 = -1;
    int last_btnA = -1;
    int last_btnB = -1;
    int last_btnX = -1;
    int last_btnY = -1;
    int last_btnUp = -1;
    int last_btnDown = -1;
    int last_btnLeft = -1;
    int last_btnRight = -1;
    std::int32_t last_press_count = -1;
    auto add_history = [&](const std::string& entry) {
        if (history.size() >= kHistoryLines) {
            return;
        }
        history.push_back(entry);
        display_line(kHistoryStartLine + static_cast<int>(history.size()) - 1, entry.c_str());
    };

    while (true) {
        const int axis1 = master.get_analog(pros::E_CONTROLLER_ANALOG_RIGHT_X);
        const int axis2 = master.get_analog(pros::E_CONTROLLER_ANALOG_RIGHT_Y);
        const int axis3 = master.get_analog(pros::E_CONTROLLER_ANALOG_LEFT_Y);
        const int axis4 = master.get_analog(pros::E_CONTROLLER_ANALOG_LEFT_X);

        const int btnL1 = master.get_digital(pros::E_CONTROLLER_DIGITAL_L1);
        const int btnL2 = master.get_digital(pros::E_CONTROLLER_DIGITAL_L2);
        const int btnR1 = master.get_digital(pros::E_CONTROLLER_DIGITAL_R1);
        const int btnR2 = master.get_digital(pros::E_CONTROLLER_DIGITAL_R2);
        const int btnA = master.get_digital(pros::E_CONTROLLER_DIGITAL_A);
        const int btnB = master.get_digital(pros::E_CONTROLLER_DIGITAL_B);
        const int btnX = master.get_digital(pros::E_CONTROLLER_DIGITAL_X);
        const int btnY = master.get_digital(pros::E_CONTROLLER_DIGITAL_Y);
        const int btnUp = master.get_digital(pros::E_CONTROLLER_DIGITAL_UP);
        const int btnDown = master.get_digital(pros::E_CONTROLLER_DIGITAL_DOWN);
        const int btnLeft = master.get_digital(pros::E_CONTROLLER_DIGITAL_LEFT);
        const int btnRight = master.get_digital(pros::E_CONTROLLER_DIGITAL_RIGHT);

        if (log_file) {
            char axis_buf[8];
            std::snprintf(axis_buf, sizeof(axis_buf), "%d", axis1);
            log_event(log_file, buffer, "AXIS1", axis_buf);
            std::snprintf(axis_buf, sizeof(axis_buf), "%d", axis2);
            log_event(log_file, buffer, "AXIS2", axis_buf);
            std::snprintf(axis_buf, sizeof(axis_buf), "%d", axis3);
            log_event(log_file, buffer, "AXIS3", axis_buf);
            std::snprintf(axis_buf, sizeof(axis_buf), "%d", axis4);
            log_event(log_file, buffer, "AXIS4", axis_buf);

            if (btnL1 && last_btnL1 != 1) {
                log_event(log_file, buffer, "BTN_L1", "INTAKE_IN");
                add_history("BTN_L1 : INTAKE_IN");
            }
            if (btnL2 && last_btnL2 != 1) {
                log_event(log_file, buffer, "BTN_L2", "INTAKE_OUT");
                add_history("BTN_L2 : INTAKE_OUT");
            }
            if (btnR1 && last_btnR1 != 1) {
                log_event(log_file, buffer, "BTN_R1", "OUTTAKE_OUT");
                add_history("BTN_R1 : OUTTAKE_OUT");
            }
            if (btnR2 && last_btnR2 != 1) {
                log_event(log_file, buffer, "BTN_R2", "OUTTAKE_IN");
                add_history("BTN_R2 : OUTTAKE_IN");
            }
            if (btnA && last_btnA != 1) {
                log_event(log_file, buffer, "BTN_A", "NO_ACTION");
                add_history("BTN_A : NO_ACTION");
            }
            if (btnB && last_btnB != 1) {
                log_event(log_file, buffer, "BTN_B", "NO_ACTION");
                add_history("BTN_B : NO_ACTION");
            }
            if (btnX && last_btnX != 1) {
                log_event(log_file, buffer, "BTN_X", "NO_ACTION");
                add_history("BTN_X : NO_ACTION");
            }
            if (btnY && last_btnY != 1) {
                log_event(log_file, buffer, "BTN_Y", "NO_ACTION");
                add_history("BTN_Y : NO_ACTION");
            }
            if (btnUp && last_btnUp != 1) {
                log_event(log_file, buffer, "BTN_UP", "NO_ACTION");
                add_history("BTN_UP : NO_ACTION");
            }
            if (btnDown && last_btnDown != 1) {
                log_event(log_file, buffer, "BTN_DOWN", "NO_ACTION");
                add_history("BTN_DOWN : NO_ACTION");
            }
            if (btnLeft && last_btnLeft != 1) {
                log_event(log_file, buffer, "BTN_LEFT", "NO_ACTION");
                add_history("BTN_LEFT : NO_ACTION");
            }
            if (btnRight && last_btnRight != 1) {
                log_event(log_file, buffer, "BTN_RIGHT", "NO_ACTION");
                add_history("BTN_RIGHT : NO_ACTION");
            }

            if (buffer.size() >= kBufferLimit) {
                flush_buffer(log_file, buffer);
            }
        }

        last_btnL1 = btnL1;
        last_btnL2 = btnL2;
        last_btnR1 = btnR1;
        last_btnR2 = btnR2;
        last_btnA = btnA;
        last_btnB = btnB;
        last_btnX = btnX;
        last_btnY = btnY;
        last_btnUp = btnUp;
        last_btnDown = btnDown;
        last_btnLeft = btnLeft;
        last_btnRight = btnRight;

        const std::uint32_t now_ms = pros::millis();
        if (now_ms - last_display_ms >= kDisplayIntervalMs) {
            display_line(0, log_file ? "BB Logger SD OK" : "BB Logger SD NO");
            last_display_ms = now_ms;
        }

        const auto touch = pros::screen::touch_status();
        if (touch.press_count != last_press_count && touch.touch_status == pros::E_TOUCH_PRESSED) {
            last_press_count = touch.press_count;
            if (log_file) {
                log_event(log_file, buffer, "SCREEN_TAP", "SAVE");
            }
            break;
        }

        pros::delay(kLogIntervalMs);
    }

    if (log_file) {
        flush_buffer(log_file, buffer);
        std::fclose(log_file);
    }

    pros::lcd::set_text(4, "Logging stopped");

    while (true) {
        pros::delay(100);
    }
}
