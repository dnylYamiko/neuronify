import QtQuick 2.0
import "paths"
import "hud"

Entity {
    id: sensorRoot
    objectName: "touchSensor"
    fileName: "TouchSensor.qml"

    property int cells: 5
    property int _oldCells: 0
    property var dropFunction
    property var actualCells: []

    width: cells * 100
    height: 100

    controls: Component {
        SensorControls {
            id: sensorControls
            sensor: sensorRoot
            onDeleteClicked: {
                simulatorRoot.deleteSensor(sensor)
            }
        }
    }

    Component.onCompleted: {
        dropFunction = simulator.createConnectionToPoint
        resetCells()
    }

    function resetCells() {
        for(var i = 0; i < actualCells.length; i++) {
            var cell = actualCells[i]
            for(var j in cell.connections) {
                var connection = cell.connections[j]
                connection.destroy()
            }
            cell.destroy()
        }
        actualCells.length = 0
        for(var i = 0; i < cells; i++) {
            var cell = simulator.createEntity("TouchSensorCell.qml", {cellIndex: i, sensor: sensorRoot})
            cell.parent = cellRow
            actualCells.push(cell)
        }
    }

    onStep: {
        for(var i in actualCells) {
            var cell = actualCells[i]
            cell.step(dt)
        }
    }

    function cellAt(index) {
        var cell = actualCells[index]
        if(!cell) {
            console.warn("WARNING: No cell at index " + index)
        }
        return cell
    }

    onCellsChanged: {
        resetCells()
    }

    MouseArea {
        anchors.fill: cellRow

        function desenseAll() {
            for(var i in actualCells) {
                var item = actualCells[i]
                item.sensing = false
            }
        }

        function senseObject(mouse) {
            desenseAll()
            var index = parseInt(mouse.x / 100)
            var item = actualCells[index]
            if(item) {
                item.sensing = true
            }
        }

        onPressed: {
            senseObject(mouse)
        }

        onPositionChanged: {
            senseObject(mouse)
        }

        onReleased: {
            desenseAll()
        }

        onExited: {
            desenseAll()
        }
    }

    Row {
        id: cellRow

    }

    Rectangle {
        anchors {
            horizontalCenter: parent.left
            verticalCenter: parent.top
        }
        width: parent.height / 3
        height: width
        radius: width / 2
        color: "#c6dbef"
        border.width: width * 0.1
        border.color: "#f7fbff"

        Image {
            anchors.fill: parent
            anchors.margins: parent.width * 0.1
            source: "images/transform-move.png"
            smooth: true
            antialiasing: true
        }

        MouseArea {
            anchors.fill: parent
            drag.target: sensorRoot
            onPressed: {
                sensorRoot.dragging = true
                dragStarted()
            }

            onClicked: {
                sensorRoot.clicked(sensorRoot, mouse)
            }

            onReleased: {
                sensorRoot.dragging = false
            }
        }
    }
}
