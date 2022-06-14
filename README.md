# Generate LTSM Neural networks based on strokes from the Apple Pencil

This is a minimal demo of a simple drawing tool supporting the Apple Pencil in iOS Safari. The Apple Pencil support comes courtesy of [Pressure.js](https://pressurejs.com/) and all drawing is done using [p5.js](https://p5js.org).

Online demo: https://draw.neurohub.io

docker run -d -p 1880:1880/tcp -p 1880:1880/udp -v ./flow_data:/data nodered/node-red:latest
