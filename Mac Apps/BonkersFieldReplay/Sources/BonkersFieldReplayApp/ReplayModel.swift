import Foundation

struct LogSample: Identifiable {
    let id = UUID()
    let time: Double
    let axis1: Double
    let axis2: Double
    let axis3: Double
    let axis4: Double
    let action: String
}

struct Pose: Identifiable {
    let id = UUID()
    let t: Double
    let x: Double
    let y: Double
    let theta: Double
    let leftCmd: Double
    let rightCmd: Double
    let axis1: Double
    let axis2: Double
    let axis3: Double
    let axis4: Double
    let action: String
}

struct ReplaySettings {
    var fieldSizeIn: Double = 144.0
    var trackWidthIn: Double = 12.0
    var maxSpeedInPerS: Double = 60.0
    var dtFallback: Double = 0.02
}

struct ReplayEngine {
    static func parseLog(url: URL) throws -> [LogSample] {
        let raw = try String(contentsOf: url)
        let lines = raw.split(whereSeparator: \.isNewline)
        guard !lines.isEmpty else {
            return []
        }

        if lines[0].contains("time_s") {
            return parseCSV(lines: lines)
        }

        return parseEventLog(lines: lines)
    }

    private static func parseCSV(lines: [Substring]) -> [LogSample] {
        guard lines.count >= 2 else {
            return []
        }

        let headers = lines[0].split(separator: ",").map { String($0) }
        let indexMap = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($0.element, $0.offset) })

        func value(_ row: [Substring], _ key: String) -> String {
            guard let idx = indexMap[key], idx < row.count else { return "" }
            return String(row[idx])
        }

        var result: [LogSample] = []
        for line in lines.dropFirst() {
            let cols = line.split(separator: ",", omittingEmptySubsequences: false)
            let t = Double(value(cols, "time_s")) ?? 0.0
            let axis1 = Double(value(cols, "axis1")) ?? 0.0
            let axis2 = Double(value(cols, "axis2")) ?? 0.0
            let axis3 = Double(value(cols, "axis3")) ?? 0.0
            let axis4 = Double(value(cols, "axis4")) ?? 0.0
            let intake = value(cols, "intake_action")
            let outtake = value(cols, "outtake_action")
            let action = (intake.isEmpty && outtake.isEmpty) ? "" : "INTAKE:\(intake) OUT:\(outtake)"
            result.append(LogSample(time: t, axis1: axis1, axis2: axis2, axis3: axis3, axis4: axis4, action: action))
        }
        return result
    }

    private static func parseEventLog(lines: [Substring]) -> [LogSample] {
        var samples: [LogSample] = []
        var axis1: Double?
        var axis2: Double?
        var axis3: Double?
        var axis4: Double?
        var lastAction = ""
        var t = 0.0

        for line in lines {
            let text = line.trimmingCharacters(in: .whitespaces)
            guard let sep = text.firstIndex(of: ":") else { continue }
            let type = text[..<sep].trimmingCharacters(in: .whitespaces)
            let value = text[text.index(after: sep)...].trimmingCharacters(in: .whitespaces)

            if type == "AXIS1" {
                axis1 = Double(value) ?? 0.0
            } else if type == "AXIS2" {
                axis2 = Double(value) ?? 0.0
            } else if type == "AXIS3" {
                axis3 = Double(value) ?? 0.0
            } else if type == "AXIS4" {
                axis4 = Double(value) ?? 0.0
            } else {
                lastAction = "\(type) : \(value)"
            }

            if let a1 = axis1, let a2 = axis2, let a3 = axis3, let a4 = axis4 {
                samples.append(LogSample(time: t, axis1: a1, axis2: a2, axis3: a3, axis4: a4, action: lastAction))
                axis1 = nil
                axis2 = nil
                axis3 = nil
                axis4 = nil
                t += 0.02
            }
        }

        return samples
    }

    static func integrate(samples: [LogSample], settings: ReplaySettings) -> [Pose] {
        guard !samples.isEmpty else { return [] }

        var x = settings.fieldSizeIn / 2.0
        var y = settings.fieldSizeIn / 2.0
        var theta = 0.0

        var poses: [Pose] = []
        var lastT: Double? = nil

        for sample in samples {
            let t = sample.time
            let dt: Double
            if let last = lastT {
                let diff = t - last
                dt = diff > 0 ? diff : settings.dtFallback
            } else {
                dt = 0.0
            }

            let leftCmd = abs(sample.axis3) < 5 ? 0.0 : sample.axis3
            let rightCmd = abs(sample.axis2) < 5 ? 0.0 : sample.axis2

            let vL = (leftCmd / 100.0) * settings.maxSpeedInPerS
            let vR = (rightCmd / 100.0) * settings.maxSpeedInPerS
            let v = (vL + vR) / 2.0
            let omega = (vR - vL) / settings.trackWidthIn

            if dt > 0 {
                x += v * cos(theta) * dt
                y += v * sin(theta) * dt
                theta += omega * dt
            }

            poses.append(Pose(
                t: t,
                x: x,
                y: y,
                theta: theta,
                leftCmd: leftCmd,
                rightCmd: rightCmd,
                axis1: sample.axis1,
                axis2: sample.axis2,
                axis3: sample.axis3,
                axis4: sample.axis4,
                action: sample.action
            ))

            lastT = t
        }

        return poses
    }
}
