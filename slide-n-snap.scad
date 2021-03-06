/*
This work is lincensed by Benjamin E Morgan under a Creative Commons Attribution 4.0 International License
http://creativecommons.org/licenses/by/4.0/

Original Source: https://github.com/benjamin-edward-morgan/openscad-slide-n-snap

Use these openSCAD modules to attach two FDM 3D printed parts together securely without requiring additional hardware.  The two parts, male and female, slide and snap together. They can attach so that separating them is difficult.

The female part's living spring and latch snaps and locks the male part in place when they are assembled. The female part is modeled in negative space and must be subtracted from one of the parts you wish to assemble. The male part of the connection is modeled in positive space and is added with the other part you are assembling. It is important to print the parts in their given orientations to maximize the tensile strength of the connection.

Usage:

//Copy slide-n-snap.scad to the same directory where your openSCAD files are and use an include statement:
include<slide-n-snap.scad>;

//Subtract the slide_n_snap_female_clip_negative from one part. For example:
difference() {
  your_module(...);
  slide_n_snap_female_clip_negative(t=1.75,w=5.25,g=0.25,j=0.5,l=7,h=1,s=0.8,a=7,c=20);
}

//Also union the slide_n_snap male_clip from another part. For example:
union() {
  your_other_module(...);
  slide_n_snap_male_clip(t=1.75,w=5.25,l=7)
}
*/

/* Variable Definitions:
t - Width of smallest part of male clip. Larger values make a stronger connection
w - Width of largest part of male clip. w > t+2*g
l - Length of male clip part. l >= w
g - Gap between faces inside the clip. Decrease if assembly is too loose, increase if the parts are too tight to assemble. This value depends on the tolerance of the 3D printer used.
j - Gap around edge of living spring. Generally this will equal 2*g. If the edge of the living spring prints fused together then increase this value. This value depends on the tolerance of the 3D printer used. 2*g <= j <= 3*j
h - Length of the base of the latch. 1 or 2 mm is probably all that is needed when printing "right-side-up" for the latch to adhere to the print bed. h > 0
s - Thickness of living spring. Generally should be around 3 or 4 layers thick for FDM. In the "right-side-up" configuration the living spring is formed with a bridge between the latch and the base of the channel. In the "upside-down" configuration the living spring is formed directly on the print bed and the latch is built up over it.
a - Length of living spring. a <= l
c - Extra length of channel. This is how much extra channel to add in front of the female part of the clip. This length depends entirely on the placement of the female clip negative and the body it is removed from. Make this long enough that the channel goes all the way to the edge of your part. c > 0
epsilon - A small value by which some values are fudged to overcome floating point errors. The default is 0.001 to make the real-time rendered view slightly less glitchy and to overcome small numerical errors in geometry used with this library.

The following profiles worked well with the aurthor's printer, but your mileage may vary. Use these values as a starting point. The larger profiles are also slightly looser to accomodate less precise printers. 

//small:  (t=1.75,w=5.25,l=7,g=0.3,j=0.6,h=1,s=1,a=7)
//medium: (t=2.0,w=6.5,l=8.5,g=0.35,j=0.7,h=1.2,s=1,a=8.5)
//large:  (t=2.75,w=8,l=10,g=0.4,j=0.8,h=2,s=1.5,a=10)
*/

/*******************************************/
/**Useful functions for using slide-n-snap**/
/*******************************************/
//Overall height from xy plane to top of living spring. The part from which the female clip is subctracted must be at least this height.
function slide_n_snap_clip_height(t,w,s) = w/2-t/2+s;

//The total width of the inner channel along the x-axis at its widest point. The width (along the z axis, centered at zero) of the part from which the female clip is subtracted should be sufficiently wider than this value to make a rigid connection.
function slide_n_snap_channel_width(w,g) = g*(1+sqrt(2))*2+w;

//Overall length of the entire female clip part, including the latch and gap in front of the living spring. The length (along the negative y axis, starting from about 2g) should be larger than this value.
function slide_n_snap_female_length(w,t,g,j,h,l,s) = w/2-t/2+s+h+g+j+l;

/*****************************/
/**Main slide-n-snap modules**/
/*****************************/
/*
Model of the positive space for the male clip. It should be printed in this orientation for maximum overall tensile strength when printed an FDM printer. This part takes advantage of the fact that FDM printed parts are generally more susceptible to break under strain between layers in a plane parallel to the x-y plane. The body of the part you wish to add the male clip too should be on the -y side of the zx plane near the origin.
*/
//slide_n_snap_male_clip(t=1.75,w=5.25,l=7);
module slide_n_snap_male_clip(t,w,l) {
    color("blue")
    linear_extrude(height=l)
    slide_n_snap_male_clip_profile(t=t,w=w);
}

/*
Models negative space for the female clip. This includes the channel, living spring, and latch. It should be subtacted from the body of the part you with to attach. The body of you wish to subtract the famale clip from should lie on top of the xy plane and be at least as tick as slide_n_snap_clip_height(...). If your part is siginficantly thicker, the cavity may lie entirely within the part, making the living spring very difficult to access once assembled. In the case, separating the two assembled parts will be more difficult.
*/
//slide_n_snap_female_clip_negative(t=1.75,w=5.25,g=0.25,j=0.5,l=7,h=1,s=0.8,a=7,c=20);
module slide_n_snap_female_clip_negative(t,w,g,j,l,h,s,a,c,epsilon=0.001,incl_cavity=true) {
    difference()
    {
        union() {
            color("deeppink")
            translate([0,g,0])
            rotate([90,0,0])
            linear_extrude(height=l+g+w/2-t/2+s+h+c)
            slide_n_snap_clip_female_negative_profile(t=t,w=w,g=g,epsilon=epsilon);

            //this cube negative subtracts out an area for the latch
            oprt = (1+sqrt(2));
            color("lightcoral")
            translate([
                -(w+2*g*oprt)/2,
                -w/2+t/2-s-h-g-l-j,
                -epsilon
            ])
            cube(size=[
                w+2*g*oprt,
                w/2-t/2+s+h+g+j,
                w/2-t/2+epsilon]
            );

            color("red")
            translate([0,0,w/2-t/2-epsilon])
            linear_extrude(height=s+2*epsilon)
            slide_n_snap_spring_negative_profile(t=t,w=w,g=g,j=j,l=l,s=s,h=h,a=a);

            if(incl_cavity) {
                color("salmon")
                slide_n_snap_living_spring_cavity(t=t,w=w,g=g,j=j,l=l,s=s,h=h,a=a,epsilon=epsilon);
            }
        }

        color("hotpink")
        translate([0,-l-g,0])
        slide_n_snap_latch(t=t,w=w,g=g,j=j,h=h,s=s,epsilon=epsilon);
    }
}

/*
An upside down version of the female clip negative. It also assumes that the body is is differenced from lies above the xy plane. The thickness of the other body should *exatly* slide_n_snap_clip_height(...) or should otherwise leave room for the male clip to be attached. The cavity is excluded in the case, since it lies entirely below the xy plane. The living spring is accessible after the parts are assmebled. They can be separated more easily because the living spring can be pryed upward to release the male clip part.
*/
//slide_n_snap_upside_down_female_clip_negative(t=1.75,w=5.25,g=0.25,j=0.5,l=7,h=1,s=0.8,a=7,c=20);
module slide_n_snap_upside_down_female_clip_negative(t,w,g,j,l,h,s,a,c,epsilon=0.01) {

    translate([0,0,slide_n_snap_clip_height(t=t,w=w,s=s)])
    mirror([0,0,1])
    slide_n_snap_female_clip_negative(t=t,w=w,g=g,j=j,l=l,h=h,s=s,a=a,c=c,epsilon=epsilon,incl_cavity=false);
}

/******************************************************************/
/**Internal Modules used by the slide-n-snap parts are below here**/
/******************************************************************/
/*
The latch at the end of the living spring and locks the male clip part in place once assembled. The latch is angled on one side so that inserting the male clip part causes it and the living spring to deflect upward.
*/
//slide_n_snap_latch(t=2,w=5,g=0.25,j=0.5,h=0.5,s=0.8);
module slide_n_snap_latch(t,w,g,j,h,s,epsilon=0.001) {
    rotate([90,0,-90])
    linear_extrude(height=w+2*g*(1+sqrt(2))-2*j,center=true)
    polygon(points=[
        [-epsilon,-2*epsilon],
        [-epsilon,w/2-t/2+s+2*epsilon],
        [w/2-t/2+s+h+epsilon,w/2-t/2+s+2*epsilon],
        [h-epsilon,-2*epsilon]
    ]);
}

/*
This 2D profile removes 3 edges around the living spring, leaving 1 edge attached where the spring is connected to the rest of the body. It also leaves space for the latch.
*/
//slide_n_snap_spring_negative_profile(t=1.75,w=5.25,g=0.25,j=0.5,l=7,s=0.8,h=1,a=6);
module slide_n_snap_spring_negative_profile(t,w,g,j,l,s,h,a) {
    oprt = (1+sqrt(2));

    x1 = -w/2-g*oprt;
    x2 = x1+j;
    x3 = -x2;
    x4 = -x1;

    y1 = 0;
    y2 = w/2-t/2+s+2*g+h;
    y3 = a+w/2-t/2+s+h+2*g+j;

    translate([0,-y3-l+a+g])
    polygon(points=[
        [x1,y1],
        [x1,y3],
        [x2,y3],
        [x2,y2],
        [x3,y2],
        [x3,y3],
        [x4,y3],
        [x4,y1]
    ]);
}

/*
A box-shaped 3D negative positioned over the living spring. This cavity leaves room over the living spring so it has room to move and enforces the thickness of the living spring when the slide_n_snap_female_clip_negative is removed from a thicker body
*/
//slide_n_snap_living_spring_cavity(t=1.75,w=5.25,g=0.25,j=0.5,l=7,s=0.8,h=1,a=6);
module slide_n_snap_living_spring_cavity(t,w,g,j,l,s,h,a,epsilon=0.0001) {
    y3 = a+w/2-t/2+s+h+2*g+j;
    translate([
        -w/2-g*(1+sqrt(2)),
        -y3-l+a+g,
        slide_n_snap_clip_height(t,w,s)+epsilon
    ])
    cube(size=[
        slide_n_snap_channel_width(w,g),
        y3,
        w/2-t/2+g
    ]);
}

/*
A 2D profile of negative space for the female clip part.
*/
//slide_n_snap_clip_female_negative_profile(t=1.75,w=5.25,g=0.25);
module slide_n_snap_clip_female_negative_profile(t,w,g,epsilon=0.001) {
   goprt = g*(1+sqrt(2));
   color("pink")
   polygon(points=[
       [-w/2-goprt,w/2-t/2],
       [w/2+goprt,w/2-t/2],
       [t/2+goprt-epsilon,-epsilon],
       [-t/2-goprt+epsilon,-epsilon]
   ]);
}

/*
A 2D profile of male clip part.
*/
//slide_n_snap_male_clip_profile(t=1.75,w=5.25);
module slide_n_snap_male_clip_profile(t,w) {
   color("blue")
   polygon(points=[
       [t/2,0],[w/2,0],
       [w/2,-t/2],
       [0,-t/2],
       [-w/2,-t/2],
       [-w/2,0],[-t/2,0],
       [-w/2,w/2-t/2],
       [w/2,w/2-t/2]
    ]);
}
