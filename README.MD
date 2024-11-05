# Meine Kundenkarten

Diese App ist entstanden, da sich immer mehr Kundenkarten in immer mehr Apps der jeweiligen Anbieter angesammelt haben und jede Anbieter App dann gleich teilweise 100 bis 300 MB belegt. Daher hatte ich StoCard genutzt um alle Karten in einer App zu haben und auch Karten die nur als physische Karte existieren in einer App zu haben. Nur: weshalb muss eine App für Kundenkarten wie StoCard selbst wiederum installiert mit Daten mehr als 250 MB Platz belegen?

Deshalb ist die App "Meine Kundenkarten" entstanden, bei der wir die Karten die wir innerhalb der Familie haben in einer kleinen, nur knapp über 1 MB großen App verwalten können und inlusive der App Daten (also ca 20 gespeicherten Kundenkarten) ist die App ingesamt nur knapp über 2 MB groß.

## Was kann die App

Für den gleichen iCloud Account werden die gespeicherten Daten über die iCloud synchronisiert. Um mit anderen Familienmitgliedern die Daten zu teilen, können entweder alle Karten oder eine einzelne Karte geteilt werden. Dazu werden die Kartendaten als Text in JSON Form ausgegeben und können per Nachrichten oder über eine geteilte Notiz geteilt und in der App importiert werden. Beim Import kann man wählen ob die neuen Daten einfach hinzugefügt werden, auch Karten mit der gleichen ID überschrieben werden oder ob man vor dem Import alle bestehenden Karten löschen will. Für den Import gilt eine Karte nur dann als gleiche Karte, wenn diese Karte selbst wiederum zuvor exportiert wurde, da der eindeutige Schlüssel eine zufällig generierte intere ID ist.

Kundenkarten können entweder per Kamera fotografiert werden oder aus einem Bild aus der Fotos App importiert werden.

Zu jeder Karte kann die Geoposition gespeichert werden und wenn man die App dann an diesem Ort neu startet, wird die Karte direkt aus der Liste der Karten geöffnet.

Pro Karte kann jeweils die Kartenfarbe und die Textfarbe gewählt werden. Für die von uns benutzen Firmen sind verschiedene Farbwerte direkt schon per Auswahl hinterlegt. Die Reihenfolge der Karten lässt sich durch Drag und Drop einer Karte in der Liste beliebig verändern.

Die Karten können biometrisch geschützt werden, dass die Barcodes erst angezeigt werden können, nachdem man sich zB per Face ID erfolgreich angemeldet hat.

Die Daten können entweder über das "Speichern" Menü manuell gespeichert werden oder indem die App in den Hintergrund gelegt wird, werden die Daten ebenfalls automatisch gespeichert. Bedeutet allerdings: erfasst man neue Daten und speichert nicht manuell, wechselt in den App Drawer und schießt dann die App direkt App, dann wurden die Änderungen nicht gespeichert da die App noch nicht in den Hintergrundmodus gewechselt war.

## Technischer Hintergrund

Swift ist in der Lage eigentlich jeden Barcode über das von Apple bereitgestellt Framework der Kamera zu scannen und sowohl den Barcodetyp als auch den Barcodeinhalt zurück zu melden. Die Herausforderung für diese App lag dann aber darin, diesen Barcode auch wieder darzustellen. Denn Apple bietet mit Swift nur bestimmte Barcodetypen an, aber vor allem der am meisten vorkommende Barcode vom Typ EAN-128 oer EAN-13 können nicht von Apple direkt erstellt werden.

Diese Barcodes werden dadurch erstellt, das unsichtbar für den Anwender im Hintergrund über WebKit die App sozusagen selbst einen Safari öffnet und dann mit Hilfe einer JavaScript Bibliothek (barcode.js) die Barcodes als Bild darstellt. Aus diesem unsichtbaren Safari wird dann das Bild kopiert und per base64 codiert damit es als Text direkt abgespeichert werden kann. Aus diesem Grund gibt es wenn man die Kartendaten exportiert oft einen langen merkwürdigen Text: dies ist das Barcode Bild als base64 encodierter Text.

## Notwendige Anpassungen
Die App kann mit dem vorhandenen Code aus Github direkt 1:1 verwendet werden.

## App Screenshots

### Kartenübersicht
![Kartenübersicht](https://ios.dbweb.info/wp-content/uploads/2024/11/karten1-scaled.jpg)

### Kartenanzeige
![Kartenanzeige](https://ios.dbweb.info/wp-content/uploads/2024/11/karten2-scaled.jpg)

### Karte bearbeiten
![Karte pflegen](https://ios.dbweb.info/wp-content/uploads/2024/11/karten3-scaled.jpg)

### Einstellungen
![Einstellungen](https://ios.dbweb.info/wp-content/uploads/2024/11/karten4-scaled.jpg)
