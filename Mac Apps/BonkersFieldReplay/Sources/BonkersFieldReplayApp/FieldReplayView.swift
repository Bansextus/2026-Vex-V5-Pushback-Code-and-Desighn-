import SwiftUI

struct FieldReplayView: View {
    let poses: [Pose]
    let fieldSizeIn: Double
    let index: Int

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let scale = size / fieldSizeIn

            Canvas { context, _ in
                let origin = CGPoint(x: 0, y: 0)
                let rect = CGRect(origin: origin, size: CGSize(width: size, height: size))

                context.fill(Path(rect), with: .color(Color(red: 1.0, green: 0.99, blue: 0.96)))

                var grid = Path()
                let spacing: Double = 12.0
                let step = spacing * scale
                var i: Double = 0
                while i <= size + 0.1 {
                    grid.move(to: CGPoint(x: i, y: 0))
                    grid.addLine(to: CGPoint(x: i, y: size))
                    grid.move(to: CGPoint(x: 0, y: i))
                    grid.addLine(to: CGPoint(x: size, y: i))
                    i += step
                }
                context.stroke(grid, with: .color(Color(red: 0.89, green: 0.84, blue: 0.78)), lineWidth: 1)

                guard !poses.isEmpty else { return }
                let idx = max(0, min(index, poses.count - 1))

                var path = Path()
                for (pIndex, pose) in poses.enumerated() {
                    let px = pose.x * scale
                    let py = (fieldSizeIn - pose.y) * scale
                    let point = CGPoint(x: px, y: py)
                    if pIndex == 0 {
                        path.move(to: point)
                    } else if pIndex <= idx {
                        path.addLine(to: point)
                    }
                }
                context.stroke(path, with: .color(Color(red: 0.2, green: 0.31, blue: 0.31)), lineWidth: 2)

                let pose = poses[idx]
                let rx = pose.x * scale
                let ry = (fieldSizeIn - pose.y) * scale
                let robotSize: Double = 12.0
                var robot = Path()
                robot.addRect(CGRect(x: -robotSize, y: -robotSize, width: robotSize * 2, height: robotSize * 2))

                context.saveGState()
                context.translateBy(x: rx, y: ry)
                context.rotate(by: Angle(radians: -pose.theta))
                context.fill(robot, with: .color(Color(red: 0.77, green: 0.22, blue: 0.13)))

                var heading = Path()
                heading.move(to: .zero)
                heading.addLine(to: CGPoint(x: robotSize * 1.4, y: 0))
                context.stroke(heading, with: .color(.black), lineWidth: 2)
                context.restoreGState()

                context.stroke(Path(rect), with: .color(Color(red: 0.78, green: 0.7, blue: 0.63)), lineWidth: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color(red: 1.0, green: 0.99, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.78, green: 0.7, blue: 0.63), lineWidth: 2)
        )
        .padding(.horizontal, 8)
    }
}
