import SwiftUI

struct PortMapView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Port Map")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)

                Card {
                    Text("Drive")
                        .font(.headline)
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
                        .font(.headline)
                        .foregroundColor(Theme.text)
                    row("Intake Left", value: $model.portMap.intakeLeft.value, reversed: $model.portMap.intakeLeft.reversed)
                    row("Intake Right", value: $model.portMap.intakeRight.value, reversed: $model.portMap.intakeRight.reversed)

                    HStack {
                        Text("IMU").foregroundColor(Theme.subtext)
                        Spacer()
                        Stepper("\(model.portMap.imu)", value: $model.portMap.imu, in: 1...21)
                    }
                    HStack {
                        Text("GPS").foregroundColor(Theme.subtext)
                        Spacer()
                        Stepper("\(model.portMap.gps)", value: $model.portMap.gps, in: 1...21)
                    }
                }

                Card {
                    Text("Apply")
                        .font(.headline)
                        .foregroundColor(Theme.text)
                    Text("Port changes are staged in-app. Use repository settings to commit/push when needed.")
                        .foregroundColor(Theme.subtext)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ name: String, value: Binding<Int>, reversed: Binding<Bool>) -> some View {
        HStack {
            Text(name).foregroundColor(Theme.subtext)
            Spacer()
            Toggle("Rev", isOn: reversed)
                .labelsHidden()
            Stepper("\(value.wrappedValue)", value: value, in: 1...21)
                .frame(width: 120)
        }
    }
}
