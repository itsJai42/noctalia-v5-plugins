import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null

  property var lights: []
  property var rooms: []

  function getLights() {
    return lights
  }

  function setLightOnState(id, state) {
    const command = ["openhue", "set", "light"]
    command.push(id)
    command.push(state ? "--on" : "--off")

    // Only update command field if it's different from last one
    if (setter.command !== command) {
      setter.command = command
    }

    setter.running = true
  }

  function setLightBrightness(id, value) {
    const command = ["openhue", "set", "light"]
    command.push(id)
    command.push("--brightness", String(Math.round(value)))

    // Only update command field if it's different from last one
    if (setter.command !== command) {
      setter.command = command
    }

    setter.running = true
  }

  function setRoomOnState(id, state) {
    const command = ["openhue", "set", "room"]
    command.push(id)
    command.push(state ? "--on" : "--off")

    // Only update command field if it's different from last one
    if (setter.command !== command) {
      setter.command = command
    }

    setter.running = true
  }

  function setRoomBrightness(id, value) {
    const command = ["openhue", "set", "room"]
    command.push(id)
    command.push("--on", "--brightness", String(Math.round(value)))

    // Only update command field if it's different from last one
    if (setter.command !== command) {
      setter.command = command
    }

    setter.running = true
  }

  function refresh() {
    if (!getLights.running) {
      getLights.running = true
    }
    if (!getRooms.running) {
      getRooms.running = true
    }
  }

  Process {
    id: getLights
    command: ["openhue", "get", "lights", "--json"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        let data = [];
        for (const light of JSON.parse(text)) {
          data.push({
            id: light.HueData.id,
            name: light.HueData.metadata.name,
            brightness: light.HueData.dimming ? light.HueData.dimming.brightness : 0,
            dimmable: !!light.HueData.dimming,
            on: light.HueData.on.on
          });
        }
        root.lights = data;
      }
    }
  }

  Process {
    id: getRooms
    command: ["openhue", "get", "rooms", "--json"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        let data = [];
        for (const room of JSON.parse(text)) {
          const devices = room.Devices || [];
          const lightsInRoom = devices.filter(d => d.Light !== null);
          const anyOn = lightsInRoom.some(d => d.Light.HueData.on.on);
          let avgBrightness = 0;
          const dimmableLights = lightsInRoom.filter(d => d.Light.HueData.dimming);
          if (dimmableLights.length > 0) {
            const total = dimmableLights.reduce((sum, d) => sum + d.Light.HueData.dimming.brightness, 0);
            avgBrightness = total / dimmableLights.length;
          }
          data.push({
            id: room.Id,
            name: room.Name,
            brightness: avgBrightness,
            on: anyOn
          });
        }
        root.rooms = data;
      }
    }
  }

  Process {
    id: setter
    running: false
    onStarted: {
      console.log("Running setter command: ", command)
    }
    onExited: {
      refresh()
    }
  }

  Component.onCompleted: {
    refresh()
  }
}
