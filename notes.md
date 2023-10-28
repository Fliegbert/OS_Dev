# Die meisten BIOS Interrupts erwarten einen Real Mode Segment Wert in DS daher funktionieren die meisten nicht

# Im Real Mode werden Adressen mit segment * 16 + offset berechnet

- Aufgaben
	- MakeFile für build erstellen
	- mbr file aufräumen/anpassen
	- TODO: disk.inc
	- anschließend muss disk read funktionabel gemacht werden
	- gdb debugging hinzufügen wenn möglich
	- TODO: print.inc
	- Bios info gathering starten
