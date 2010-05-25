import Qt 4.7
import Qt.widgets 4.7
import Plasma 0.1 as Plasma

QGraphicsWidget {
    id: root;

    signal backClicked

    property string subjectText: ""
    property string bodyText: ""
    property string toText: ""

    Plasma.Frame {
        id: frame
        anchors.left: parent.left
        anchors.right: parent.right
        frameShadow : "Raised"

        layout: QGraphicsGridLayout {
            id : lay

            Plasma.PushButton {
                QGraphicsGridLayout.row : 0
                QGraphicsGridLayout.column : 0
                QGraphicsGridLayout.columnMaximumWidth : 30
                text: "Back"
                onClicked: {
                    root.backClicked()
                }
            }


            Plasma.PushButton {
                id: fromButton
                QGraphicsGridLayout.row : 0
                QGraphicsGridLayout.column : 1
                text: "John"
            }

            Plasma.LineEdit {
                minimumSize.height : fromButton.size.height
                QGraphicsGridLayout.row : 0
                QGraphicsGridLayout.column : 2
                QGraphicsGridLayout.columnSpan : 2
                //QGraphicsGridLayout.alignment : QGraphicsGridLayout.Center
                text: root.subjectText
            }



            Plasma.PushButton {
                id: toButton
                QGraphicsGridLayout.row : 1
                QGraphicsGridLayout.column : 1
                text: "To:"
            }
            Plasma.LineEdit {
                minimumSize.height : toButton.size.height
                QGraphicsGridLayout.row : 1
                QGraphicsGridLayout.column : 2
                QGraphicsGridLayout.columnStretchFactor : 3
                text: root.toText
            }
            Plasma.PushButton {
                QGraphicsGridLayout.row : 1
                QGraphicsGridLayout.column : 3
                text: "Send"
            }
        }
    }


    Plasma.WebView {
        id : text
        anchors.left: parent.left
        anchors.leftMargin: 60
        anchors.right: parent.right
        anchors.top : frame.bottom
        anchors.bottom : parent.bottom
        width : parent.width - 60
        dragToScroll : true
        html: root.bodyText
    }


    Plasma.PushButton {
        id : buttonA
        anchors.left: parent.left
        anchors.top: parent.bottom
        text: "A"
        rotation : -90
    }
    Plasma.PushButton {
        id : buttonActions
        anchors.left: parent.left
        anchors.bottom: buttonA.top
        anchors.bottomMargin : 25
        text: "Actions"
        rotation : -90
    }
}