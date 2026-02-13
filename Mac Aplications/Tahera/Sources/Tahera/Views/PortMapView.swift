import SwiftUI
import AppKit

struct PortMapView: View {
    @EnvironmentObject var model: TaheraModel
    private let legendColumns = [GridItem(.adaptive(minimum: 170), spacing: 10)]
    // Calibrated for the bundled v5_brain.png asset (265x190).
    private let topPortX: [CGFloat] = [0.162, 0.225, 0.289, 0.351, 0.414, 0.508, 0.571, 0.634, 0.697, 0.760]
    private let bottomPortX: [CGFloat] = [0.162, 0.225, 0.289, 0.351, 0.414, 0.508, 0.571, 0.634, 0.697, 0.760]
    private let topPortY: CGFloat = 0.086
    private let bottomPortY: CGFloat = 0.922

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PanelTitle(text: "Port Map", icon: "slider.horizontal.3")

                Card {
                    Text("V5 Brain Map")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                    if let image = loadBrainImage() {
                        brainOverlay(for: image)
                    } else {
                        Text("Add v5_brain.png to Tahera resources to display the brain map.")
                            .foregroundColor(Theme.subtext)
                            .font(.system(size: 16, weight: .medium))
                    }
                }

                Card {
                    Text("Live Port Legend")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                    LazyVGrid(columns: legendColumns, spacing: 10) {
                        ForEach(assignments) { assignment in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(assignment.color)
                                    .frame(width: 11, height: 11)
                                Text(assignment.short)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.text)
                                Text("P\(assignment.port) \(assignment.title)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.subtext)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.black.opacity(0.2))
                            )
                        }
                    }
                }

                Card {
                    Text("Drive")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                    row("Left Outer 1", value: $model.portMap.leftOuter1.value, reversed: $model.portMap.leftOuter1.reversed)
                    row("Left Outer 2", value: $model.portMap.leftOuter2.value, reversed: $model.portMap.leftOuter2.reversed)
                    row("Left Middle", value: $model.portMap.leftMiddle.value, reversed: $model.portMap.leftMiddle.reversed)
                    row("Right Outer 1", value: $model.portMap.rightOuter1.value, reversed: $model.portMap.rightOuter1.reversed)
                    row("Right Outer 2", value: $model.portMap.rightOuter2.value, reversed: $model.portMap.rightOuter2.reversed)
                    row("Right Middle", value: $model.portMap.rightMiddle.value, reversed: $model.portMap.rightMiddle.reversed)
                }

                Card {
                    Text("Intake / Sensors")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                    row("Intake Left", value: $model.portMap.intakeLeft.value, reversed: $model.portMap.intakeLeft.reversed)
                    row("Intake Right", value: $model.portMap.intakeRight.value, reversed: $model.portMap.intakeRight.reversed)

                    HStack {
                        Text("IMU").foregroundColor(Theme.subtext)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Stepper("\(model.portMap.imu)", value: $model.portMap.imu, in: 1...21)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    HStack {
                        Text("GPS").foregroundColor(Theme.subtext)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Stepper("\(model.portMap.gps)", value: $model.portMap.gps, in: 1...21)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }

                Card {
                    Text("Apply")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                    Text("Port changes are staged in-app. Use repository settings to commit/push when needed.")
                        .foregroundColor(Theme.subtext)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ name: String, value: Binding<Int>, reversed: Binding<Bool>) -> some View {
        HStack {
            Text(name)
                .foregroundColor(Theme.subtext)
                .font(.system(size: 16, weight: .medium))
            Spacer()
            Toggle("Rev", isOn: reversed)
                .labelsHidden()
            Stepper("\(value.wrappedValue)", value: value, in: 1...21)
                .frame(width: 120)
                .font(.system(size: 15, weight: .semibold))
        }
    }

    private func loadBrainImage() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "v5_brain", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private func brainOverlay(for image: NSImage) -> some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()

            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    ForEach(1...20, id: \.self) { port in
                        let anchor = socketPoint(for: port, in: size)
                        Text("\(port)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.text.opacity(0.9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.black.opacity(0.35))
                            )
                            .position(anchor)
                    }

                    ForEach(assignmentsByPort.keys.sorted(), id: \.self) { port in
                        if let portAssignments = assignmentsByPort[port] {
                            ForEach(Array(portAssignments.enumerated()), id: \.element.id) { index, assignment in
                                assignmentMarker(
                                    assignment: assignment,
                                    index: index,
                                    groupCount: portAssignments.count,
                                    anchor: socketPoint(for: port, in: size),
                                    canvasSize: size
                                )
                            }
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .aspectRatio(max(image.size.width / max(image.size.height, 1), 0.1), contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func assignmentMarker(
        assignment: PortAssignment,
        index: Int,
        groupCount: Int,
        anchor: CGPoint,
        canvasSize: CGSize
    ) -> some View {
        let centerOffset = CGFloat(index) - CGFloat(groupCount - 1) / 2.0
        let horizontalSpread = centerOffset * max(48, canvasSize.width * 0.095)
        let isTopRow = assignment.port <= 10
        let verticalOffset = max(34, canvasSize.height * 0.11)
        let badgePoint = CGPoint(
            x: anchor.x + horizontalSpread,
            y: anchor.y + (isTopRow ? verticalOffset : -verticalOffset)
        )
        let connectorY = badgePoint.y + (isTopRow ? -14 : 14)

        Path { path in
            path.move(to: anchor)
            path.addLine(to: CGPoint(x: badgePoint.x, y: connectorY))
        }
        .stroke(assignment.color.opacity(0.95), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))

        Circle()
            .fill(assignment.color)
            .frame(width: 8, height: 8)
            .position(anchor)

        HStack(spacing: 6) {
            Text(assignment.short)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)
            Text("P\(assignment.port)")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.text.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(assignment.color.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: assignment.color.opacity(0.45), radius: 8, x: 0, y: 3)
        .position(badgePoint)
    }

    private func socketPoint(for port: Int, in size: CGSize) -> CGPoint {
        let clampedPort = min(max(port, 1), 20)
        let index = (clampedPort - 1) % 10
        let isTop = clampedPort <= 10
        let xRatio = (isTop ? topPortX : bottomPortX)[index]
        let yRatio = isTop ? topPortY : bottomPortY
        let x = size.width * xRatio
        let y = size.height * yRatio
        return CGPoint(x: x, y: y)
    }

    private var assignmentsByPort: [Int: [PortAssignment]] {
        Dictionary(grouping: assignments, by: \.port)
    }

    private var assignments: [PortAssignment] {
        [
            PortAssignment(id: "L1", short: "L1", title: "Left Outer 1", port: model.portMap.leftOuter1.value, color: Color(hex: 0x40DCC6)),
            PortAssignment(id: "L2", short: "L2", title: "Left Outer 2", port: model.portMap.leftOuter2.value, color: Color(hex: 0x57C8FF)),
            PortAssignment(id: "LM", short: "LM", title: "Left Middle", port: model.portMap.leftMiddle.value, color: Color(hex: 0x7CD8FF)),
            PortAssignment(id: "R1", short: "R1", title: "Right Outer 1", port: model.portMap.rightOuter1.value, color: Color(hex: 0x7BFF9E)),
            PortAssignment(id: "R2", short: "R2", title: "Right Outer 2", port: model.portMap.rightOuter2.value, color: Color(hex: 0x9BFF83)),
            PortAssignment(id: "RM", short: "RM", title: "Right Middle", port: model.portMap.rightMiddle.value, color: Color(hex: 0xC5FF7A)),
            PortAssignment(id: "IN", short: "IN", title: "Intake Left", port: model.portMap.intakeLeft.value, color: Color(hex: 0xFFCA6F)),
            PortAssignment(id: "OUT", short: "OUT", title: "Intake Right", port: model.portMap.intakeRight.value, color: Color(hex: 0xFFA76A)),
            PortAssignment(id: "IMU", short: "IMU", title: "Inertial Sensor", port: model.portMap.imu, color: Color(hex: 0xD4C2FF)),
            PortAssignment(id: "GPS", short: "GPS", title: "GPS Sensor", port: model.portMap.gps, color: Color(hex: 0xFFC1EA))
        ]
    }
}

private struct PortAssignment: Identifiable {
    let id: String
    let short: String
    let title: String
    let port: Int
    let color: Color
}
