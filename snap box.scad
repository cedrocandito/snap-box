/* [Part selection] */
// Select the part to be rendered: "box" or "lid".
render_part = "box"; // [box,lid]

/* [Box size] */
// Size of box inside, along the Y axis. Add 2 times shell_thickness to calculate the outer size.
length = 100;
// Size of box inside, along the X axis. Add 2 times shell_thickness to calculate the outer size.
width = 60;
// Size of box inside, along the Z axis Add 2 times shell_thickness to calculate the outer size.
height = 30;
// Height of the lid wall. Must be greater or equal than snap_band_width and less or equal than the height of the box.
lid_wall_height = 7;
// Overall thickness of the box.
shell_thickness = 2;
// Radius of the box corner bevels.
corner_radius = 1;

/* [Snap band] */

// Height of the snap band along the lid-to-box interface.
snap_band_width = 2.5;
// Thickness of the snap band along the lid-to-box interface.
snap_band_thickness = 0.2;
// Gap between box and lid.
gap = 0.15;

/* [Resolution] */
// Minimum size of a fragment.
$fs = 0.3;
// Minimum angle for a fragment (degrees).
$fa = 3;

// ------------------------------------------------------------

half_gap = gap / 2;
shell_half_thickness = shell_thickness / 2;
inner_size = [width, length, height];
outer_size = [width + 2*shell_thickness, length + 2*shell_thickness, height + 2*shell_thickness];
box_outer_size = outer_size - [0,0,shell_thickness];
lid_outer_size = [outer_size[0],outer_size[1],shell_thickness + lid_wall_height];
snap_band_y = lid_wall_height / 2;	// (relative to lid wall)
snap_band_r = (snap_band_thickness*snap_band_thickness + snap_band_width*snap_band_width/4) / (2*snap_band_thickness);
snap_band_center_offset = snap_band_r  - snap_band_thickness;

assert(lid_wall_height >= snap_band_width, "lid_wall_height must be greater or equal than snap_band_width");
assert(lid_wall_height <= height, "lid_wall_height must be less or equal than the height of the box");

if (render_part=="box")
{
	box();
}
else if (render_part=="lid")
{
	lid();
}
else
{
	assert(false,"No valid part selected");
}


module box()
{
	union()
	{
		difference()
		{
			// outer surface
			half_rounded_box(box_outer_size, corner_radius, bottom=true);
			
			// inner space
			translate([shell_thickness, shell_thickness, shell_thickness])
				translate([0,0,0.01])
					cube(inner_size);
			
			// indent
			translate([0,0,shell_thickness + height - lid_wall_height])
			{
				difference()
				{
					cube(outer_size);
					translate([shell_half_thickness+half_gap, shell_half_thickness+half_gap,0])
					union()
					{
						box_indent_size = outer_size - [shell_thickness+gap,shell_thickness+gap,0];
						cube(box_indent_size);
						
						// snap band
						translate([0,0,snap_band_y])
						{
							
							// left
							translate([snap_band_center_offset,0,0])
								rotate([-90,0,0])
									cylinder(r=snap_band_r, h=box_indent_size[1]);
							
							// right
							translate([box_indent_size[0] - snap_band_center_offset,0,0])
								rotate([-90,0,0])
									cylinder(r=snap_band_r, h=box_indent_size[1]);
							
							// front
							translate([0,snap_band_center_offset,0])
								rotate([0,90,0])
									cylinder(r=snap_band_r, h=box_indent_size[0]);
							
							
							// back
							translate([0,box_indent_size[1] - snap_band_center_offset,0])
								rotate([0,90,0])
									cylinder(r=snap_band_r, h=box_indent_size[0]);
						}
					}
				}
			}
		}
	}
}

module lid()
{
	difference()
	{
		// outer surface
		half_rounded_box(lid_outer_size, corner_radius, bottom=true);
		
		// inner space
		lid_indent_offset = shell_half_thickness - half_gap;
		lid_indent_size = outer_size - [shell_thickness-gap,shell_thickness-gap,0];
		
		intersection()
		{
			translate([lid_indent_offset, lid_indent_offset, shell_thickness])
			union()
			{
				
				translate([0,0,0.001])
					cube(lid_indent_size);
			
				// snap band
				translate([0,0,snap_band_y])
				{
					// left
					translate([snap_band_center_offset,0,0])
						rotate([-90,0,0])
							cylinder(r=snap_band_r, h=lid_indent_size[1]);
					
					// right
					translate([lid_indent_size[0] - snap_band_center_offset,0,0])
						rotate([-90,0,0])
							cylinder(r=snap_band_r, h=lid_indent_size[1]);
					
					// front
					translate([0,snap_band_center_offset,0])
						rotate([0,90,0])
							cylinder(r=snap_band_r, h=lid_indent_size[0]);
					
					
					// back
					translate([0,lid_indent_size[1] - snap_band_center_offset,0])
						rotate([0,90,0])
							cylinder(r=snap_band_r, h=lid_indent_size[0]);
				}
			}
			
			/* This intersections is needed to prevent the snap band cylinders
			to "carve" the floor. */
			translate([0,0,shell_thickness+0.001])
				cube(outer_size);
		}
	}
}

module half_sphere(r)
{
	intersection()
	{
		sphere(r);
		translate([0,0,r])
			cube([r*2, r*2, r*2], center=true);
	}
}

module half_rounded_box(size,r,bottom=false,center=false)
{
	translate([r,r,r])
		minkowski()
		{
			cube([size[0]-r*2, size[1]-r*2, size[2]-r],center);
			rotate(bottom?[180,0,0]:[0,0,0])
				half_sphere(r);
		}
}
