import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Particles 2.0

import com.bbv.StreetLightSimulator 1.0

ApplicationWindow {
    title: qsTr("Street light simulator")
    id: gui
    objectName: "gui"
    visible: true
    property int defaultWidth: 1024
    width: defaultWidth
    height: 768
    property int dayLength: 60
    property double scalingFactor: (1.0*streetImage.paintedWidth)/defaultWidth
    property var car
    //onScalingFactorChanged: console.log("New scaling factor "+scalingFactor)
    Rectangle {
        objectName: "world"
        id: world
        anchors.fill: parent

        Image {
            id: streetImage
            anchors.fill: parent
            source: "strasse_tag"
            fillMode: Image.PreserveAspectFit
        }

        Image {
            opacity: 0
            id: streetImageNight
            anchors.fill: parent
            source: "strasse_nacht"
            fillMode: Image.PreserveAspectFit
            Behavior on opacity { NumberAnimation { duration: 3000 } }
        }

        Image{
            id: sign
            source: cppWarning.phrase === "" ? "sign_inactive" : "sign_active"
            width: 72*scalingFactor
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: streetImage.verticalCenter
            anchors.verticalCenterOffset: 120*scalingFactor
            anchors.horizontalCenter: streetImage.horizontalCenter
            //anchors.horizontalCenterOffset: 80*scalingFactor
            Label {
                anchors.fill: parent
                anchors.topMargin: 14*scalingFactor
                anchors.bottomMargin: 14*scalingFactor
                text: cppWarning.phrase
                color: "yellow"
                maximumLineCount: 6
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 2
                font.pixelSize: 20
            }
        }
        Image {
            id: lightsource
            anchors.fill: parent
            source: "light"
            opacity: cppLuminosity.scaled
            fillMode: Image.PreserveAspectFit
            z: 1
        }
        Image {
            id: sun
            source: "sun"
            objectName: "sun"
            visible: cppDay.daytime === DaySimulator.DAY
            anchors.horizontalCenter: streetImage.horizontalCenter
            anchors.verticalCenter: streetImage.verticalCenter
            fillMode: Image.PreserveAspectFit
            width: 60 * scalingFactor
            Behavior on anchors.horizontalCenterOffset  {NumberAnimation { duration: 1000 } }
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 1000 } }
        }
        NumberAnimation {
            id: animation
            duration: 1000
        }
        Image {
            id: moon
            source: "moon"
            objectName: "moon"
            fillMode: Image.PreserveAspectFit
            width: 60*scalingFactor
            visible: cppDay.daytime === DaySimulator.NIGHT
            anchors.verticalCenter: streetImage.verticalCenter
            anchors.horizontalCenter: streetImage.horizontalCenter
            Behavior on anchors.horizontalCenterOffset  {NumberAnimation { duration: 1000 } }
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 1000 } }
        }
        ParticleSystem {
            id: carParticles
            anchors.fill: streetImage
            ImageParticle {
                id: smokeParticle
                source: "smoke"
                groups: ["smoke"]
                rotationVariation: 180
            }
            Sprite {
                id: randomSprite
                frameDuration: 0
                name: "randomSprite"
                source: "car"
                frameY: 1
                frameX: 1
                frameWidth: 1
                frameHeight: 1
                frameCount: 1
                //How often one particular image shall travel over the display
                to: {"carSprite":70,"traktorSprite":28, "ufoSprite":2 }
            }

            Sprite {
                id: traktorSprite
                name: "traktorSprite"
                source: "car"
                frameY: 600
                frameX: 1*600
                frameWidth: 600
                frameHeight: 600
                frameCount: 1
                frameDuration: 20000
            }
            Sprite {
                id: carSprite
                name: "carSprite"
                source: "car"
                frameY: 0*600
                frameX: 0
                frameWidth: 600
                frameHeight: 600
                frameDuration: 20000
                frameCount: 1
            }
            Sprite {
                id: ufoSprite
                name: "ufoSprite"
                source: "car"
                frameY: 600
                frameX: 2*600
                frameWidth: 600
                frameHeight: 600
                frameCount: 1
                frameDuration: 20000
            }

            ImageParticle {
                id: car
                sprites: [randomSprite, carSprite, traktorSprite, ufoSprite ]
                groups: ["car"]
                colorVariation: 1
            }

            Emitter {
                id: carRight
                group: "car"
                property int carVelocity: 200*scalingFactor
                height: 1
                x: (gui.width-streetImage.paintedWidth)/2+streetImage.paintedWidth
                y: (gui.height-streetImage.paintedHeight)/2+streetImage.paintedHeight-250*scalingFactor
                //Just one car at a time on the screen
                emitRate: 1/(streetImage.paintedWidth/carVelocity)
                //maximumEmitted: 1
                lifeSpan: (streetImage.paintedWidth/carVelocity)*1000+1000
                velocity: PointDirection { x: -carRight.carVelocity}

                size: 300*scalingFactor

                //onEmitParticles is called repeatedly,
                //but the array will only have content if there is a new car
                onEmitParticles: {
                    for(var i=0; i<particles.length; i++)  {
                        var particle = particles[i]
                        world.newCar(particle)
                    }
                }
            }

            //simulate an uneven street, car bouncing up and down
            Wander {
                yVariance: 20*scalingFactor;
                pace: 1000;
                groups: ["car"]
            }
            TrailEmitter {
                id: smoke
                x: 150 * scalingFactor
                y: 110 * scalingFactor
                group: "smoke"
                follow: "car"
                emitRatePerParticle: 3
                lifeSpan: 1000
                velocity: PointDirection { y: -30*scalingFactor}
                sizeVariation: 10
            }

            ImageParticle {
                id: raindrop
                source: "raindrop"
                alphaVariation: 0.8
                rotation: -90
                autoRotation: true
            }
            Emitter {
                id: rainEmitter
                enabled: false
                x: (gui.width-streetImage.paintedWidth)/2-400*scalingFactor
                y: 0
                width: streetImage.paintedWidth+400*scalingFactor
                emitRate: 100
                lifeSpan: 10000
                size: 20*scalingFactor
                sizeVariation: 10*scalingFactor
                velocity: PointDirection { x: 100*scalingFactor; y: 150*scalingFactor; yVariation: 50*scalingFactor}
                acceleration: PointDirection {y: 150*scalingFactor; yVariation: 100*scalingFactor}
            }

            Connections {
                target: cppRain
                onRainChanged: {
                    if(cppRain.rain==true) {
                        rainStatus(true)
                    }
                    else {
                        rainStatus(false)
                    }
                }
            }
        }

        function calculateCelestialPositions() {
            var now = Math.floor(new Date().getTime() / 1000)
            var maxOffset = scalingFactor*defaultWidth/2
            var dayProgress = Math.min((now%dayLength)/(cppDay.nightStart%dayLength),1)
            var nightProgress = Math.max((now%dayLength-cppDay.nightStart%60)/(60-(cppDay.nightStart%dayLength)),0)
            //console.log("Day progress: "+dayProgress+ " Night progress: "+nightProgress)
            var sunX = (scalingFactor*defaultWidth+sun.width)*((dayProgress)-1/2)
            var sunY = scalingFactor*(-(Math.sin(dayProgress*Math.PI)*200)-150)
            var moonX = (defaultWidth*scalingFactor+moon.width)*((nightProgress)-1/2)
            var moonY = scalingFactor*(-(Math.sin(nightProgress*Math.PI)*200)-150)

            //force sun to the left when it invisible in the night
            if(cppDay.daytime === DaySimulator.NIGHT)
                sunX = -(maxOffset+sun.width/2)

            //console.log("sunX is now "+sunX+" moonX is now "+moonX)
            //console.log("Brightness is "+cppBrightness.scaled)
            sun.anchors.horizontalCenterOffset = sunX
            sun.anchors.verticalCenterOffset = sunY
            moon.anchors.horizontalCenterOffset = moonX
            moon.anchors.verticalCenterOffset = moonY

            //console.log("World width: "+gui.width+"Image width:"+streetImage.paintedWidth+"calc:"+(world.width-streetImage.paintedWidth)/2)
        }

        function calculateBrightness() {
            var brightness
            var maxOffset = scalingFactor*defaultWidth/2
            if(cppDay.daytime === DaySimulator.DAY)
                brightness = 1-Math.min(Math.abs(sun.anchors.horizontalCenterOffset/maxOffset),1)
            else
                brightness= 0.1*(1-Math.min(Math.abs(moon.anchors.horizontalCenterOffset/maxOffset),1))

            if(cppRain.rain === true)
                brightness *= 0.8

            cppBrightness.scaled = brightness
        }
        function updateCarProximity() {
            //Construct for multiple cars in an array:
            /*            var minProximity = 1
            for(var i=0; i<car.length; i++) {
                if(car[i].x)
                    console.log("This car: "+car[i].id)
                else
                    car.splice(i,i+1)
                var proximity =  Math.min(1,Math.max(-1,(car[i].x-(streetImage.paintedWidth/2))/(streetImage.paintedWidth/2)))

                if(Math.abs(proximity)<Math.abs(minProximity)) {
                    minProximity = proximity
                }
            }*/
            if(gui.car === undefined)
                return
            var proximity =  Math.min(1,Math.max(-1,(gui.car.x-(streetImage.paintedWidth/2))/(streetImage.paintedWidth/2)))
            cppProximity.scaled = proximity
            //console.log("Car is now at "+cppProximity.scaled)
        }

        function newCar(car) {
            gui.car = car
        }
        Connections {
            target: cppDay
            onDaytimeChanged: {
                if(cppDay.daytime === DaySimulator.DAY) {
                    streetImageNight.opacity = 0
                }
                else {
                    streetImageNight.opacity = 1
                }
            }
        }
    }

    Button {
        id: rainButton
        text: qsTr("Rain")
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10*scalingFactor
        onClicked: {
            rainEmitter.enabled ? rainStatus(false) : rainStatus(true);
        }
    }


    function rainStatus(status) {
        if(status===true) {
            rainEmitter.enabled = true;
            cppMoisture.scaled = 1.0
            rainButton.text = "Stop rain";
        }
        else {
            rainEmitter.enabled = false
            cppMoisture.scaled = 0.0
            rainButton.text = "Start rain"
        }
    }
}
