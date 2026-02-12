#!/usr/bin/env python3
"""
Bonkers controller log -> field replay HTML.

Usage:
  python3 tools/bonkers_log_to_field.py /path/to/bonkers_log_XXXX.csv

Outputs:
  field_replay.html (in the same folder as the log unless --output is set)
"""

import argparse
import csv
import json
import math
import os

DEFAULT_FIELD_SIZE_IN = 144.0  # 12 ft VEX field
DEFAULT_TRACK_WIDTH_IN = 12.0
DEFAULT_MAX_SPEED_IN_PER_S = 60.0
DEFAULT_DT_S = 0.02


def _parse_float(value, default=None):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def load_rows(path):
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    if not rows:
        raise SystemExit("Log file has no rows.")
    return rows


def integrate(rows, field_size_in, track_width_in, max_speed_in_s):
    x = field_size_in / 2.0
    y = field_size_in / 2.0
    theta = 0.0

    poses = []
    last_t = None
    for i, row in enumerate(rows):
        t = _parse_float(row.get("time_s"), None)
        if t is None:
            t = 0.0 if last_t is None else last_t + DEFAULT_DT_S

        if last_t is None:
            dt = 0.0
        else:
            dt = t - last_t
            if dt <= 0:
                dt = DEFAULT_DT_S

        left_cmd = _parse_float(row.get("left_cmd"), 0.0)
        right_cmd = _parse_float(row.get("right_cmd"), 0.0)

        v_l = (left_cmd / 100.0) * max_speed_in_s
        v_r = (right_cmd / 100.0) * max_speed_in_s
        v = (v_l + v_r) / 2.0
        omega = (v_r - v_l) / track_width_in

        if dt > 0:
            x += v * math.cos(theta) * dt
            y += v * math.sin(theta) * dt
            theta += omega * dt

        poses.append(
            {
                "t": t,
                "x": x,
                "y": y,
                "theta": theta,
                "left_cmd": left_cmd,
                "right_cmd": right_cmd,
                "intake_action": row.get("intake_action", ""),
                "outtake_action": row.get("outtake_action", ""),
            }
        )

        last_t = t

    return poses


def build_html(poses, field_size_in, title):
    data_json = json.dumps(poses)
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>{title}</title>
  <style>
    :root {{
      --bg: #f4efe7;
      --panel: #fffaf2;
      --ink: #1b1b1b;
      --accent: #2f4f4f;
      --grid: #e2d7c6;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
      background: radial-gradient(circle at 20% 20%, #fff6e7 0%, #f4efe7 45%, #efe7db 100%);
      color: var(--ink);
      padding: 20px;
    }}
    .wrap {{
      max-width: 980px;
      margin: 0 auto;
      display: grid;
      grid-template-columns: 1fr;
      gap: 12px;
    }}
    .panel {{
      background: var(--panel);
      border: 2px solid #c7b8a4;
      border-radius: 12px;
      padding: 12px 14px;
    }}
    h1 {{
      font-size: 20px;
      margin: 0 0 6px 0;
      letter-spacing: 0.5px;
    }}
    .controls {{
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }}
    button {{
      background: var(--accent);
      color: #fff;
      border: none;
      padding: 8px 12px;
      border-radius: 8px;
      cursor: pointer;
      font-weight: 600;
    }}
    button.secondary {{
      background: #8f7f6b;
    }}
    input[type="range"] {{
      width: 220px;
    }}
    canvas {{
      width: 100%;
      height: auto;
      border: 2px solid #c7b8a4;
      border-radius: 12px;
      background: #fffdf7;
    }}
    .readout {{
      font-family: Menlo, Consolas, "Liberation Mono", monospace;
      font-size: 12px;
      white-space: pre;
    }}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="panel">
      <h1>{title}</h1>
      <div class="controls">
        <button id="play">Play</button>
        <button id="pause" class="secondary">Pause</button>
        <button id="reset" class="secondary">Reset</button>
        <label>Speed
          <select id="speed">
            <option value="0.5">0.5x</option>
            <option value="1" selected>1x</option>
            <option value="2">2x</option>
            <option value="4">4x</option>
          </select>
        </label>
        <input id="scrub" type="range" min="0" max="0" value="0" step="1" />
      </div>
    </div>

    <canvas id="field" width="800" height="800"></canvas>

    <div class="panel readout" id="readout">Loading...</div>
  </div>

  <script>
    const data = {data_json};
    const FIELD_SIZE = {field_size_in};
    const canvas = document.getElementById('field');
    const ctx = canvas.getContext('2d');
    const scale = canvas.width / FIELD_SIZE;

    const scrub = document.getElementById('scrub');
    const readout = document.getElementById('readout');
    const speedSelect = document.getElementById('speed');

    let idx = 0;
    let playing = false;
    let startTime = null;

    scrub.max = Math.max(0, data.length - 1);

    function fieldToCanvas(x, y) {{
      const cx = x * scale;
      const cy = canvas.height - y * scale;
      return [cx, cy];
    }}

    function drawGrid() {{
      ctx.save();
      ctx.strokeStyle = '#e2d7c6';
      ctx.lineWidth = 1;
      for (let i = 0; i <= FIELD_SIZE; i += 12) {{
        const [x0, y0] = fieldToCanvas(i, 0);
        const [x1, y1] = fieldToCanvas(i, FIELD_SIZE);
        ctx.beginPath();
        ctx.moveTo(x0, y0);
        ctx.lineTo(x1, y1);
        ctx.stroke();

        const [x2, y2] = fieldToCanvas(0, i);
        const [x3, y3] = fieldToCanvas(FIELD_SIZE, i);
        ctx.beginPath();
        ctx.moveTo(x2, y2);
        ctx.lineTo(x3, y3);
        ctx.stroke();
      }}
      ctx.restore();
    }}

    function drawPath(upTo) {{
      ctx.save();
      ctx.strokeStyle = '#2f4f4f';
      ctx.lineWidth = 2;
      ctx.beginPath();
      for (let i = 0; i <= upTo; i++) {{
        const [cx, cy] = fieldToCanvas(data[i].x, data[i].y);
        if (i === 0) {{
          ctx.moveTo(cx, cy);
        }} else {{
          ctx.lineTo(cx, cy);
        }}
      }}
      ctx.stroke();
      ctx.restore();
    }}

    function drawRobot(pose) {{
      const [cx, cy] = fieldToCanvas(pose.x, pose.y);
      const size = 10;
      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(-pose.theta);
      ctx.fillStyle = '#c23b22';
      ctx.fillRect(-size, -size, size * 2, size * 2);
      ctx.strokeStyle = '#111';
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(size * 1.4, 0);
      ctx.stroke();
      ctx.restore();
    }}

    function updateReadout(pose) {{
      readout.textContent =
        `t=${pose.t.toFixed(2)}s  x=${pose.x.toFixed(1)}in  y=${pose.y.toFixed(1)}in\n` +
        `left=${pose.left_cmd.toFixed(0)}  right=${pose.right_cmd.toFixed(0)}\n` +
        `intake=${pose.intake_action}  outtake=${pose.outtake_action}`;
    }}

    function draw(i) {{
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      drawGrid();
      drawPath(i);
      drawRobot(data[i]);
      updateReadout(data[i]);
      scrub.value = i;
    }}

    function animate(ts) {{
      if (!playing) {{
        startTime = null;
        return;
      }}

      if (startTime === null) {{
        startTime = ts - (data[idx].t * 1000);
      }}

      const speed = parseFloat(speedSelect.value || '1');
      const t = (ts - startTime) / 1000 * speed;

      while (idx < data.length - 1 && data[idx + 1].t <= t) {{
        idx += 1;
      }}

      draw(idx);

      if (idx < data.length - 1) {{
        requestAnimationFrame(animate);
      }} else {{
        playing = false;
      }}
    }}

    document.getElementById('play').addEventListener('click', () => {{
      if (!playing) {{
        playing = true;
        requestAnimationFrame(animate);
      }}
    }});

    document.getElementById('pause').addEventListener('click', () => {{
      playing = false;
    }});

    document.getElementById('reset').addEventListener('click', () => {{
      playing = false;
      idx = 0;
      draw(idx);
    }});

    scrub.addEventListener('input', (ev) => {{
      playing = false;
      idx = parseInt(ev.target.value, 10) || 0;
      draw(idx);
    }});

    draw(0);
  </script>
</body>
</html>
"""


def main():
    parser = argparse.ArgumentParser(description="Convert a Bonkers controller log to a field replay HTML.")
    parser.add_argument("log", help="Path to bonkers_log_XXXX.csv")
    parser.add_argument("--output", help="Output HTML path")
    parser.add_argument("--field-size", type=float, default=DEFAULT_FIELD_SIZE_IN)
    parser.add_argument("--track-width", type=float, default=DEFAULT_TRACK_WIDTH_IN)
    parser.add_argument("--max-speed", type=float, default=DEFAULT_MAX_SPEED_IN_PER_S)
    args = parser.parse_args()

    rows = load_rows(args.log)
    poses = integrate(rows, args.field_size, args.track_width, args.max_speed)

    title = os.path.basename(args.log)
    html = build_html(poses, args.field_size, f"Bonkers Field Replay - {title}")

    if args.output:
        out_path = args.output
    else:
        out_path = os.path.join(os.path.dirname(args.log), "field_replay.html")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
