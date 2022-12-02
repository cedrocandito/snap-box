/* [Part selection] */
// Select the part to be rendered: "box", "lid" or "both".
render_part = "both"; // [box,lid,both]

/* [Box size] */
// Size of box inside, along the Y axis. Add 2 times shell_thickness to calculate the outer size.
length = 100;
// Size of box inside, along the X axis. Add 2 times shell_thickness to calculate the outer size.
width = 60;
// Size of box inside, along the Z axis. Add 2 times shell_thickness to calculate the outer size.
height = 30;
// Height of the lid wall. Must be greater or equal than snap_band_width and less or equal than the height of the box.
lid_wall_height = 12;
// Overall thickness of the box.
shell_thickness = 2.2;

/* [Options] */

// Radius of the box corner bevels. Don't make it too large or the snap band will punch a hole through the corners.
corner_radius = 1;
// Don't fix the snap band wall at the corners, make four "flaps" instead; the lid will snap easily.
snappy_flaps = true;
// Only used when snappy_flaps = true: size of the snappy flaps holes.
snappy_flaps_gap_size = 1.0;
// Add a slot of this width in the front and back walls to help grabbing cards in the box. If 0 no slot will be cut. Note that for this to be aesthetically pleasing lid_wall_height should be equal to height.
cards_handling_slot_size = 0;
// Internal dividers along the x axis; it is a list of percentages of the box's width. If the total is less than 100% the remaining space will be added on the right of the last divider . For example you can specify [15,15,25] to get 4 spaces of 15%, 15%, 25% and 45% of the box's width.
dividers_x = [];
// Internal dividers along the y axis; see dividers_x for a description.
dividers_y = [];
// Thickness of the dividers (ignored if both dividers_x and dividers_y are empty).
dividers_thickness = 0.8;
// Distance between box and lid when render_part = "both" (ignored if only one part is selected for rendering).
box_and_lid_distance = 3;

/* [Snap band] */

// Height of the snap band along the lid-to-box interface.
snap_band_width = 2.5;
// Thickness of the snap band along the lid-to-box interface.
snap_band_thickness = 0.6;
// Position of the snap band: top, bottom or middle of the lid wall.
snap_band_position = "top"; // [top,middle,bottom]
// Distance between the snaop band and the top or bottom (depending on snap_band_position) edge of the lid wall. Ignored if snap_band_position is "middle".
snap_band_offset = 3;
// Percentage of length/width to cover with the snap band. Lower values make the lid stronger and allow a thinner shell thickness, higher values make the box more... well, "snappy".
snap_band_percentage = 50; // [1:100]
// How much smaller the snap band ridge radius is than the groove radius.
snap_band_ridge_difference_radius = 0.1;
// How much longer the snap band groove is than the ridge.
snap_band_ridge_difference_length = 4;
// Gap between box and lid.
gap = 0.1;

/* [Resolution] */
// Minimum size of a fragment.
$fs = 0.2;
// Minimum angle for a fragment (degrees).
$fa = 3;

// ------------------------------------------------------------

half_gap = gap / 2;
shell_half_thickness = shell_thickness / 2;
inner_size = [width, length, height];
outer_size = [width + 2*shell_thickness, length + 2*shell_thickness, height + 2*shell_thickness];
box_outer_size = outer_size - [0,0,shell_thickness];
lid_outer_size = [outer_size[0],outer_size[1],shell_thickness + lid_wall_height];
snap_band_y = snap_band_position=="bottom"
	? snap_band_offset
	: snap_band_position == "top"
		? lid_wall_height - snap_band_offset
		: snap_band_position=="middle"
			? lid_wall_height / 2
			: undef;
assert(is_num(snap_band_y),"snap_band_position must be one of 'top', 'bottom', 'middle'");
snap_band_r = (snap_band_thickness*snap_band_thickness + snap_band_width*snap_band_width/4) / (2*snap_band_thickness);
snap_band_center_offset = snap_band_r - snap_band_thickness;

assert(lid_wall_height >= snap_band_width, "lid_wall_height must be greater or equal than snap_band_width");
assert(lid_wall_height <= height, "lid_wall_height must be less or equal than the height of the box");
assert(snap_band_offset >= 0,"snap_band_offset must be greater or equal than zero");

if (render_part=="box")
{
	box();
}
else if (render_part=="lid")
{
	lid();
}
else if (render_part=="both")
{
	union()
	{
		box();
		translate([box_outer_size[0] + box_and_lid_distance, 0, 0])
			lid();
	}
}
else
{
	assert(false,"No valid part selected");
}


module box()
{
	box_indent_size = outer_size - [shell_thickness+gap,shell_thickness+gap,0];
	
	difference()
	{
		union()
		{
			// (outer box - inner space - indent)
			difference()
			{
				// outer surface
				half_rounded_box(box_outer_size, corner_radius, bottom=true);
				
				// inner space
				translate([shell_thickness, shell_thickness, shell_thickness])
					cube(inner_size + [0,0,0.01]);
				
				// indent
				// snap band + (larger cube - smaller cube)
				translate([-0.01,-0.01,shell_thickness + height - lid_wall_height])
				{
					union()
					{
						translate([shell_half_thickness+half_gap, shell_half_thickness+half_gap,0])
						{
							// snap band

							box_snap_band_length = min(box_indent_size[1]*snap_band_percentage/100+snap_band_ridge_difference_length,box_indent_size[1]);
							box_snap_band_width = min(box_indent_size[0]*snap_band_percentage/100+snap_band_ridge_difference_length,box_indent_size[0]);
							
							translate([0,0,snap_band_y])
							{
								// left
								translate([-snap_band_center_offset,box_indent_size[1]/2,0])
									rotate([-90,0,0])
										cylinder(r=snap_band_r, h=box_snap_band_length, center=true);
								
								// right
								translate([box_indent_size[0] + snap_band_center_offset,box_indent_size[1]/2,0])
									rotate([-90,0,0])
										cylinder(r=snap_band_r, h=box_snap_band_length, center=true);
								
								// front
								translate([box_indent_size[0]/2,-snap_band_center_offset,0])
									rotate([0,90,0])
										cylinder(r=snap_band_r, h=box_snap_band_width, center=true);
								
								// back
								translate([box_indent_size[0]/2,box_indent_size[1] + snap_band_center_offset,0])
									rotate([0,90,0])
										cylinder(r=snap_band_r, h=box_snap_band_width, center=true);
							}
						}
						
						difference()
						{
							cube(outer_size+[0.02,0.02,0.02]);
							translate([shell_half_thickness+half_gap, shell_half_thickness+half_gap,0])
								cube(box_indent_size);
						}
					}
				}
			}
			
			// dividers
			translate([shell_thickness, shell_thickness, shell_thickness])
			{
				// x axis
				if (is_list(dividers_x) && len(dividers_x)>0)
				{
					for (i=[0:len(dividers_x)-1])
					{
						percent_sum = sum_up_to_index_n(dividers_x,i);
						assert(percent_sum < 100,"The sum of dividers_x must be less than 100");
						offset = percent_sum*width/100;
						translate([offset,0,0])
						{
							cube([dividers_thickness,length,height]);
						}
					}
				}
				
				// y axis
				if (is_list(dividers_y) && len(dividers_y)>0)
				{
					for (i=[0:len(dividers_y)-1])
					{
						percent_sum = sum_up_to_index_n(dividers_y,i);
						assert(percent_sum < 100,"The sum of dividers_y must be less than 100");
						offset = percent_sum*length/100;
						translate([0,offset,0])
						{
							cube([width,dividers_thickness,height]);
						}
					}
				}
			}
		}
	
		// snappy flaps separator holes
		if (snappy_flaps)
		{
			flap_holes_size = [shell_thickness + snappy_flaps_gap_size, shell_thickness + snappy_flaps_gap_size, lid_wall_height + 0.01];
			
			// corners
			translate([0,0,shell_thickness + height - lid_wall_height])
			{
				// front left
				cube(flap_holes_size);
				
				// front right
				translate([outer_size[0]-flap_holes_size[0],0,0])
					cube(flap_holes_size);
				
				// back left
				translate([0,outer_size[1]-flap_holes_size[1],0])
					cube(flap_holes_size);
				
				// back righe
				translate([outer_size[0]-flap_holes_size[0],outer_size[1]-flap_holes_size[1],0])
					cube(flap_holes_size);
			}
			
			// gap between shell and dividers
			translate([0,0,shell_thickness + height - lid_wall_height])
			{
				// front
				translate([shell_thickness, shell_thickness, 0])
					cube([inner_size[0], snappy_flaps_gap_size, lid_wall_height + 0.01]);
				
				// back
			  translate([shell_thickness, outer_size[1]-shell_thickness-snappy_flaps_gap_size, 0])
					cube([inner_size[0], snappy_flaps_gap_size, lid_wall_height + 0.01]);
				
				// left
				translate([shell_thickness, shell_thickness, 0])
					cube([snappy_flaps_gap_size, inner_size[1], lid_wall_height + 0.01]);
				
				// right
				translate([outer_size[0]-shell_thickness-snappy_flaps_gap_size, shell_thickness, 0])
					cube([snappy_flaps_gap_size, inner_size[1], lid_wall_height + 0.01]);
			}
		}
	
		// card handling slot
		if (cards_handling_slot_size > 0)
		{
			// front
			translate([(outer_size[0]-cards_handling_slot_size)/2,-0.01,shell_thickness])
			{
				cube([cards_handling_slot_size,shell_thickness+0.02,inner_size[2]+0.01]);
			}
			
			// back
			translate([(outer_size[0]-cards_handling_slot_size)/2,outer_size[1] - shell_thickness - 0.01,shell_thickness])
			{
				cube([cards_handling_slot_size,shell_thickness+0.02,inner_size[2]+0.01]);
			}
		}
		
	} // end of root difference()
} // end of module

module lid()
{
	// (outer cube - (inner space - snap bands))
	difference()
	{
		// outer surface
		half_rounded_box(lid_outer_size, corner_radius, bottom=true);
		
		lid_indent_offset = shell_half_thickness - half_gap;
		lid_indent_size = outer_size - [shell_thickness-gap,shell_thickness-gap,0];
		
		translate([lid_indent_offset, lid_indent_offset, shell_thickness])
		{
			difference()
			{
				// inner space
				cube(lid_indent_size);
			
				// snap band
				lid_snap_band_length = lid_indent_size[1]*snap_band_percentage/100;
				lid_snap_band_width = lid_indent_size[0]*snap_band_percentage/100;
				snap_band_ridge_r = snap_band_r - snap_band_ridge_difference_radius;
				
				translate([0,0,snap_band_y])
				{
					// left
					translate([-snap_band_center_offset,lid_indent_size[1]/2,0])
						rotate([-90,0,0])
							cylinder(r=snap_band_ridge_r, h=lid_snap_band_length, center=true);
					
					// right
					translate([lid_indent_size[0] + snap_band_center_offset,lid_indent_size[1]/2,0])
						rotate([-90,0,0])
							cylinder(r=snap_band_ridge_r, h=lid_snap_band_length, center=true);
					
					// front
					translate([lid_indent_size[0]/2,-snap_band_center_offset,0])
						rotate([0,90,0])
							cylinder(r=snap_band_ridge_r, h=lid_snap_band_width, center=true);
					
					
					// back
					translate([lid_indent_size[0]/2,lid_indent_size[1] + snap_band_center_offset,0])
						rotate([0,90,0])
							cylinder(r=snap_band_ridge_r, h=lid_snap_band_width, center=true);
				}
			}
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

/* Return the sum of the elements of the list up to index n. */
function sum_up_to_index_n(list, n) = n>=0 ? list[n] + sum_up_to_index_n(list,n-1) : 0;
