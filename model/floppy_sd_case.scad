// Floppy Disk SD Card Case
// 3.5"-Diskette als duenne, stabile Aufbewahrungsbox fuer 2 SD- und
// 6 microSD-Karten (2 Teile: Tray + schlichter Deckel, ohne Beschriftung).
// Die Kontur ist an eine echte 3,5"-Diskette angelehnt (abgeschraegte
// Ecke, Schreibschutz- und Sensor-Aussparung an der Einschubkante).
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

// Echte 3,5"-Disketten haben an der Einschubkante (unten) zwei kleine
// Aussparungen: den Schreibschutz-Schieber (links, hier zugleich als
// Fingergriff zum Oeffnen genutzt) und das kleinere Sensorloch (rechts,
// rein dekorativ). Beide sind Teil der Kontur, nicht der Bauteiltiefe -
// die Box wird dadurch nicht dicker.
wp_notch_w      = 9;    // Breite Schreibschutz-Aussparung
wp_notch_d      = 6;    // Tiefe Schreibschutz-Aussparung
wp_notch_x      = -outer_w / 2 + 13;  // Position von der Mitte aus
sensor_notch_w  = 5;    // Breite Sensorloch-Aussparung
sensor_notch_d  = 3.5;  // Tiefe Sensorloch-Aussparung
sensor_notch_x  = outer_w / 2 - 13;   // Position von der Mitte aus

/* [Wandstaerken - moeglichst duenn, aber stabil] */
wall         = 1.6;   // Aussenwand des Trays
floor_t      = 1.6;   // Bodenstaerke
skirt_h      = 2.2;   // Hoehe des Rands, in den der Deckel greift
lid_t        = 1.6;   // Deckelstaerke

/* [SD-Kartenfaecher] */
sd_w         = 24;    // SD-Karten-Breite
sd_l         = 32;    // SD-Karten-Laenge
sd_t         = 2.1;   // SD-Karten-Dicke
sd_clearance = 1.0;   // Spiel pro Fach (XY)
sd_count     = 2;     // Anzahl SD-Faecher (nebeneinander)

/* [microSD-Kartenfaecher] */
micro_w         = 11;    // microSD-Breite
micro_l         = 15;    // microSD-Laenge
micro_t         = 1.0;   // microSD-Dicke
micro_clearance = 1.2;   // Spiel pro Fach (XY)
micro_cols      = 3;     // Spalten
micro_rows      = 2;     // Reihen (macht 6 Faecher)

/* [Faecher allgemein] */
divider      = 1.6;   // Stegbreite zwischen den Faechern
group_gap    = 6;     // Abstand zwischen SD-Reihe und microSD-Raster
protrusion   = 0.4;   // wie weit die duennste Karte oben uebersteht (zum Greifen)

/* [Passung Deckel] */
fit_clearance = 0.25;  // Spiel zwischen Deckel-Steg und Trayrand
skirt_wall    = 1.4;   // Wandstaerke des Deckelstegs
skirt_len     = skirt_h - 0.4; // wie tief der Steg in den Tray eintaucht

// ---------------------------------------------------------------------
// Abgeleitete Werte
pocket_sd_w = sd_l + sd_clearance;
pocket_sd_d = sd_w + sd_clearance;
// Taschentiefe = Kartendicke minus gewuenschtem Ueberstand (nicht duenner als 0.6mm Restboden)
pocket_sd_depth    = max(sd_t - protrusion, 0.6);
pocket_micro_depth = max(micro_t - protrusion, 0.5);
plate_h  = max(pocket_sd_depth, pocket_micro_depth); // Dicke der Fachplatte ab dem Boden
base_h   = floor_t + plate_h + skirt_h;

pocket_micro_w = micro_l + micro_clearance;
pocket_micro_d = micro_w + micro_clearance;

sd_group_w    = sd_count * pocket_sd_w + (sd_count + 1) * divider;
sd_group_d    = pocket_sd_d + 2 * divider;
micro_group_w = micro_cols * pocket_micro_w + (micro_cols + 1) * divider;
micro_group_d = micro_rows * pocket_micro_d + (micro_rows + 1) * divider;

content_d = sd_group_d + group_gap + micro_group_d;
sd_group_cy    = content_d / 2 - sd_group_d / 2;
micro_group_cy = sd_group_cy - sd_group_d / 2 - group_gap - micro_group_d / 2;

// Randaussparung: von aussen in die Kontur geschnittene, abgerundete
// Nut (fuer Schreibschutz-Schieber / Sensorloch an der Einschubkante).
module edge_notch(cx, w, d, r = 1.2) {
    translate([cx, -outer_d / 2 - 1 + (d + 1) / 2])
        offset(r = r) offset(delta = -r) square([w, d + 1], center = true);
}

// 2D-Grundriss der Diskette: abgerundetes Rechteck mit einer
// abgeschraegten Ecke oben links (Schreibschutz-/Orientierungsecke)
// sowie den beiden Aussparungen an der unteren Einschubkante.
module floppy_shape(w = outer_w, d = outer_d, r = corner_r, n = notch) {
    difference() {
        offset(r = r) offset(delta = -r) square([w, d], center = true);
        translate([-w / 2, d / 2])
            polygon([[0, 0], [n, 0], [0, -n]]);
        edge_notch(wp_notch_x, wp_notch_w, wp_notch_d, 2.5);
        edge_notch(sensor_notch_x, sensor_notch_w, sensor_notch_d, 1);
    }
}

// Rechteckiges Fach mit leicht abgerundeten Ecken (leichteres Einlegen).
module pocket(w, d, r = 1.2) {
    offset(r = r) offset(delta = -r) square([w, d], center = true);
}

// Ein Block aus cols x rows gleich grossen Faechern, zentriert um (0, cy).
module pocket_block(cols, rows, pw, pd, cy) {
    grid_w = cols * pw + (cols + 1) * divider;
    grid_d = rows * pd + (rows + 1) * divider;
    for (c = [0 : cols - 1])
        for (r = [0 : rows - 1]) {
            x = -grid_w / 2 + divider + pw / 2 + c * (pw + divider);
            y = cy - grid_d / 2 + divider + pd / 2 + r * (pd + divider);
            translate([x, y]) pocket(pw, pd);
        }
}

module sd_pockets() {
    pocket_block(sd_count, 1, pocket_sd_w, pocket_sd_d, sd_group_cy);
}

module micro_pockets() {
    pocket_block(micro_cols, micro_rows, pocket_micro_w, pocket_micro_d, micro_group_cy);
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
            // Fachplatte, zunaechst massiv (Taschen werden unten abgezogen)
            translate([0, 0, floor_t])
                linear_extrude(height = plate_h)
                    offset(delta = -wall) floppy_shape();
        }
        // SD-Taschen: volle Plattentiefe (bis auf den Boden)
        translate([0, 0, floor_t + plate_h - pocket_sd_depth])
            linear_extrude(height = pocket_sd_depth + 0.1)
                sd_pockets();
        // microSD-Taschen: flacher, duennere Karten liegen naeher an der Oberflaeche
        translate([0, 0, floor_t + plate_h - pocket_micro_depth])
            linear_extrude(height = pocket_micro_depth + 0.1)
                micro_pockets();
    }
}

module lid() {
    union() {
        // Deckplatte (schlicht, ohne Beschriftung)
        linear_extrude(height = lid_t) floppy_shape();
        // Steg, der in den Tray-Rand fasst
        translate([0, 0, -skirt_len])
            linear_extrude(height = skirt_len)
                difference() {
                    offset(delta = -wall - fit_clearance) floppy_shape();
                    offset(delta = -wall - fit_clearance - skirt_wall) floppy_shape();
                }
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
