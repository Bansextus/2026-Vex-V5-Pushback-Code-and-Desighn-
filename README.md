README — 2026 VEX V5 Pushback Code & Design

Overview
The repository includes PROS projects which manage driving functionality and auton planning and controller logging operations and companions desktop applications which enable users to view field logs during log replay.

Projects

1) The Tahera Sequence (driver + auton)
- Driver control + touchscreen UI.
- The system loads autonomous operation from the current save slot.
- The system functions through these controls:
  - A enables GPS drive (default off)
  - B disables GPS drive
  - Y enables 6‑wheel drive (default on)
  - X disables 6‑wheel drive
  - The D- pad enables driving with GPS- heading assist when GPS drive functions are active.

2) Auton Planner (touch UI + recording + slots)
- The touch interface provides users with editing capabilities for their step sequences.
- The system records tank drive movements to create automated driving steps.
- The system includes three save slots which users can access through S1 and S2 and S3 buttons.
- Users can maintain their slot selection through auton_slot.txt file.

3) Basic Bonkers (controller logger)
- The system records all controller input events to SD storage.
- The data format uses TYPE : ACTION structure.
- Users can save their work by tapping the brain screen.

Desktop Apps

Mac — Bonkers Field Replay
- The system builds the application by executing the command ./build_app.sh.
- The build process produces the output file dist/BonkersFieldReplay.app.
- The application supports opening both .txt and .csv log files.

Windows — Bonkers Field Replay
- The system builds an EXE file through the command .\build_windows.ps1.
- The system builds an installer package in MSI format through the command .\build_installer.ps1.

Save Slots (Auton Planner + Tahera)
The system creates SD files which include:
- auton_plans_slot1.txt
- auton_plans_slot2.txt
- auton_plans_slot3.txt
- auton_slot.txt (stores current slot number 1–3)

Typical Slots
- The Tahera Sequence occupies slot 1.
- Auton Planner occupies slot 2.
- Image Selector occupies slot 3.
- Basic Bonkers occupies slot 4.

Ports (Default Wiring)
- The system uses ports 1 and 2 and 3 for left drive movement.
- The system uses ports 4 and 5 and 6 for right drive movement.
- The system uses ports 7 and 8 for intake operations.
- The system uses ports 9 and 12 for outtake operations.
- The system uses port 11 for IMU operation.
- The system uses port 10 for GPS operation.

Image Conversion
The system requires users to execute tools/convert_images_to_bmp.sh for image conversion which transforms SD images into 480x240 BMP format.

Troubleshooting
The user needs to reconnect USB or enter the serial port path when PROS upload fails to detect the V5 device.
