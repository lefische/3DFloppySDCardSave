// Floppy Disk SD Card Case
// 3.5"-Diskette als Aufbewahrungsbox fuer SD-Karten (2 Teile: Tray + Deckel).
// Rendern in OpenSCAD, "part" unten waehlen, dann als STL exportieren.

$fn = 64;

/* [Ausgabe] */
// "base" = Unterteil, "lid" = Deckel, "both" = beide nebeneinander (Vorschau/Druck)
part = "both"; // [base, lid, both]

/* [Aussenform] */
outer_w   = 90;   // Breite (X)
outer_d   = 94;   // Tiefe (Y)
corner_r  = 3;    // Eckenradius
notch     = 14;   // Groesse der abgeschraegten Diskettenecke (oben links)

/* [Wandstaerken] */
wall        = 2.2;   // Aussenwand des Trays
floor_t     = 2;     // Bodenstaerke
pocket_depth = 3.5;  // Tiefe der Kartenfaecher
skirt_h     = 4;     // Hoehe des Rands, in den der Deckel greift
lid_t       = 2.2;   // Deckelstaerke

/* [Kartenfaecher] */
card_w    = 24;    // SD-Karten-Breite
card_l    = 32;    // SD-Karten-Laenge
clearance = 1.2;   // Spiel pro Fach
divider   = 2.2;   // Stegbreite zwischen den Faechern
cols      = 2;      // Spalten
rows      = 3;      // Reihen

/* [Passung Deckel] */
fit_clearance = 0.3;  // Spiel zwischen Deckel-Steg und Trayrand
skirt_wall    = 1.6;  // Wandstaerke des Deckelstegs
skirt_len     = skirt_h - 0.6; // wie tief der Steg in den Tray eintaucht

/* [Beschriftung] */
label_text = "SD BACKUP";
label_size = 8;

// ---------------------------------------------------------------------
// Abgeleitete Werte
base_h = floor_t + pocket_depth + skirt_h;
pocket_w = card_l + clearance;
pocket_d = card_w + clearance;

// 2D-Grundriss der Diskette: abgerundetes Rechteck mit einer
// abgeschraegten Ecke oben links (Schreibschutz-/Orientierungsecke).
module floppy_shape(w = outer_w, d = outer_d, r = corner_r, n = notch) {
    difference() {
        offset(r = r) offset(delta = -r) square([w, d], center = true);
        translate([-w / 2, d / 2])
            polygon([[0, 0], [n, 0], [0, -n]]);
    }
}

// Rechteckiges Fach mit leicht abgerundeten Ecken (leichteres Einlegen).
module pocket(w, d, r = 1.5) {
    offset(r = r) offset(delta = -r) square([w, d], center = true);
}

// Fach-Raster, zentriert im Innenraum des Trays.
module pocket_grid() {
    grid_w = cols * pocket_w + (cols + 1) * divider;
    grid_d = rows * pocket_d + (rows + 1) * divider;
    for (c = [0 : cols - 1])
        for (r = [0 : rows - 1]) {
            x = -grid_w / 2 + divider + pocket_w / 2 + c * (pocket_w + divider);
            y = -grid_d / 2 + divider + pocket_d / 2 + r * (pocket_d + divider);
            translate([x, y]) pocket(pocket_w, pocket_d);
        }
}

// Kleine Kerbe an der Vorderkante, um den Deckel mit dem Fingernagel
// abheben zu koennen.
module finger_notch(depth_extra = 0) {
    translate([0, -outer_d / 2, -0.1])
        cylinder(h = base_h + 0.2 + depth_extra, r = 6);
}

module base_tray() {
    difference() {
        union() {
            // Aussenwand, volle Hoehe
            linear_extrude(height = base_h)
                difference() {
                    floppy_shape();
                    offset(delta = -wall) floppy_shape();
                }
            // Boden
            linear_extrude(height = floor_t)
                floppy_shape();
            // Fachplatte mit Ausschnitten
            translate([0, 0, floor_t])
                linear_extrude(height = pocket_depth)
                    difference() {
                        offset(delta = -wall) floppy_shape();
                        pocket_grid();
                    }
        }
        finger_notch();
    }
}

label_recess_depth = 0.5;  // Tiefe der Etikettenvertiefung
label_text_h       = 0.4;  // wie weit die Schrift darin hervorsteht (< label_recess_depth)

module lid() {
    union() {
        difference() {
            union() {
                // Deckplatte
                linear_extrude(height = lid_t) floppy_shape();
                // Steg, der in den Tray-Rand fasst
                translate([0, 0, -skirt_len])
                    linear_extrude(height = skirt_len)
                        difference() {
                            offset(delta = -wall - fit_clearance) floppy_shape();
                            offset(delta = -wall - fit_clearance - skirt_wall) floppy_shape();
                        }
            }
            // dekorativer "Schutzschieber" oben (angelehnt an das Diskettenvorbild)
            translate([outer_w / 4, outer_d / 4 - 4, lid_t - 0.6])
                linear_extrude(height = 0.8)
                    offset(r = 1.5) offset(delta = -1.5)
                        square([outer_w * 0.34, outer_d * 0.22], center = true);
            // Etiketten-Vertiefung
            translate([0, -outer_d * 0.08, lid_t - label_recess_depth])
                linear_extrude(height = label_recess_depth + 0.1)
                    offset(r = 2) offset(delta = -2)
                        square([outer_w * 0.68, outer_d * 0.34], center = true);
            // Kerbe passend zum Tray
            finger_notch(1);
        }
        // Beschriftung: erhaben im Boden der Etikettenvertiefung
        if (label_text != "")
            translate([0, -outer_d * 0.08, lid_t - label_recess_depth])
                linear_extrude(height = label_text_h)
                    text(label_text, size = label_size, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

// Beide Teile werden liegend im druckfertigen Layout ausgegeben
// (Deckel um 180 Grad gedreht: Steg zeigt nach oben, keine Ueberhaenge).
if (part == "base") {
    base_tray();
} else if (part == "lid") {
    rotate([180, 0, 0]) lid();
} else {
    translate([-outer_w / 2 - 6, 0, 0]) base_tray();
    translate([outer_w / 2 + 6, 0, 0]) rotate([180, 0, 0]) lid();
}
