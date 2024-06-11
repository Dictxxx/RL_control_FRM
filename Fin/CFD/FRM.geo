// Gmsh project created on Tue Oct 18 12:39:43 2022
SetFactory("OpenCASCADE");

// = DefineNumber[ 0.70710678, Name "Parameters" ]; = 0.70710678;
sqrt2 = 1.414213562373095;
b = 1.0;
ratio1 = 0.625;
ratio2 = 3.6;

r = b*ratio1;
a = r/sqrt2;

nx1 = 10;  //+
nx2 = 6;  //+
nx3 = nx1;  //+
ny1 = nx1;  //+
ny2 = nx2;  //+
nb  = 8;  //+

Rx1 = 0.8;
Rb  = 0.7;

// the size of computational Domain 
L  = b * ratio2;
Lout = L;
Lsym = L; 

// origin
Point(1) = {0, 0, 0, 1.0};


// cylinder 1
Point(2) = {-b, -b, 0, 1.0};

Point(3) = {-b+a, -b+a, 0, 1.0};
Point(4) = {-b+a, -b-a, 0, 1.0};
Point(5) = {-b-a, -b-a, 0, 1.0};
Point(6) = {-b-a,  -b+a, 0, 1.0};

Point(7) = {-b+b, -b-b, 0, 1.0};
Point(8) = {-b-b, -b-b, 0, 1.0};
Point(9) = {-b-b, -b+b, 0, 1.0};

Circle(1) = {3, 2, 4};
Circle(2) = {4, 2, 5};
Circle(3) = {5, 2, 6};
Circle(4) = {6, 2, 3};


// cylinder 2
Point(10) = {-b, b, 0, 1.0};

Point(11) = {-b+a, b+a, 0, 1.0};
Point(12) = {-b+a, b-a, 0, 1.0};
Point(13) = {-b-a, b-a, 0, 1.0};
Point(14) = {-b-a, b+a, 0, 1.0};

Point(15) = {-b+b, b+b, 0, 1.0};
Point(16) = {-b-b, b+b, 0, 1.0};

Circle(5) = {11, 10, 12};
Circle(6) = {12, 10, 13};
Circle(7) = {13, 10, 14};
Circle(8) = {14, 10, 11};


// cylinder 3
Point(17) = {b, b, 0, 1.0};

Point(18) = {b+a, b+a, 0, 1.0};
Point(19) = {b+a, b-a, 0, 1.0};
Point(20) = {b-a, b-a, 0, 1.0};
Point(21) = {b-a, b+a, 0, 1.0};

Point(22) = {b+b, b+b, 0, 1.0};
Point(23) = {b+b, b-b, 0, 1.0};

Circle(9) = {18, 17, 19};
Circle(10) = {19, 17, 20};
Circle(11) = {20, 17, 21};
Circle(12) = {21, 17, 18};


// cylinder 4
Point(24) = {b, -b, 0, 1.0};

Point(25) = {b+a, -b+a, 0, 1.0};
Point(26) = {b+a, -b-a, 0, 1.0};
Point(27) = {b-a, -b-a, 0, 1.0};
Point(28) = {b-a, -b+a, 0, 1.0};

Point(29) = {b+b, -b-b, 0, 1.0};

Circle(13) = {25, 24, 26};
Circle(14) = {26, 24, 27};
Circle(15) = {27, 24, 28};
Circle(16) = {28, 24, 25};


// physical boundaries
Point(30) = {-L, Lsym, 0, 1.0};
Point(31) = {-b-b, Lsym, 0, 1.0};
Point(32) = {-b+b, Lsym, 0, 1.0};
Point(33) = {b+b, Lsym, 0, 1.0};
Point(34) = {Lout, Lsym, 0, 1.0};

Point(35) = {-L, b+b, 0, 1.0};
Point(36) = {Lout, b+b, 0, 1.0};

Point(37) = {-L, -b+b, 0, 1.0};
Point(38) = {Lout, -b+b, 0, 1.0};

Point(39) = {-L, -b-b, 0, 1.0};
Point(40) = {Lout, -b-b, 0, 1.0};

Point(41) = {-L, -Lsym, 0, 1.0};
Point(42) = {-b-b, -Lsym, 0, 1.0};
Point(43) = {-b+b, -Lsym, 0, 1.0};
Point(44) = {b+b, -Lsym, 0, 1.0};
Point(45) = {Lout, -Lsym, 0, 1.0};


// horizontal 
Line(17) = {30, 31};
Line(18) = {31, 32};
Line(19) = {32, 33};
Line(20) = {33, 34};

Line(21) = {35, 16};
Line(22) = {16, 15};
Line(23) = {15, 22};
Line(24) = {22, 36};

Line(25) = {37, 9};
Line(26) = {9, 1};
Line(27) = {1, 23};
Line(28) = {23, 38};

Line(29) = {39, 8};
Line(30) = {8, 7};
Line(31) = {7, 29};
Line(32) = {29, 40};

Line(33) = {41, 42};
Line(34) = {42, 43};
Line(35) = {43, 44};
Line(36) = {44, 45};


// vertical
Line(37) = {30, 35};
Line(38) = {35, 37};
Line(39) = {37, 39};
Line(40) = {39, 41};

Line(41) = {31, 16};
Line(42) = {16, 9};
Line(43) = {9, 8};
Line(44) = {8, 42};

Line(45) = {32, 15};
Line(46) = {15, 1};
Line(47) = {1, 7};
Line(48) = {7, 43};

Line(49) = {33, 22};
Line(50) = {22, 23};
Line(51) = {23, 29};
Line(52) = {29, 44};

Line(53) = {34, 36};
Line(54) = {36, 38};
Line(55) = {38, 40};
Line(56) = {40, 45};


// diagonal
Line(57) = {1, 3};
Line(58) = {7, 4};
Line(59) = {8, 5};
Line(60) = {9, 6};

Line(61) = {15, 11};
Line(62) = {1, 12};
Line(63) = {9, 13};
Line(64) = {16, 14};

Line(65) = {22, 18};
Line(66) = {23, 19};
Line(67) = {1, 20};
Line(68) = {15, 21};

Line(69) = {23, 25};
Line(70) = {29, 26};
Line(71) = {7, 27};
Line(72) = {1, 28};


// surfaces
Line Loop(1) = {17, 41, -21, -37}; Plane Surface(1) = {1};
Line Loop(2) = {18, 45, -22, -41}; Plane Surface(2) = {2};
Line Loop(3) = {19, 49, -23, -45}; Plane Surface(3) = {3};
Line Loop(4) = {20, 53, -24, -49}; Plane Surface(4) = {4};
Line Loop(5) = {21, 42, -25, -38}; Plane Surface(5) = {5};
Line Loop(6) = {22, 61, -8, -64}; Plane Surface(6) = {6};
Line Loop(7) = {46, 62, -5, -61}; Plane Surface(7) = {7};
Line Loop(8) = {26, 62, 6, -63};  Plane Surface(8) = {8};
Line Loop(9) = {42, 63, 7, -64};  Plane Surface(9) = {9};
Line Loop(10) = {23, 65, -12, -68}; Plane Surface(10) = {10};
Line Loop(11) = {50, 66, -9, -65}; Plane Surface(11) = {11};
Line Loop(12) = {27, 66, 10, -67}; Plane Surface(12) = {12};
Line Loop(13) = {46, 67, 11, -68}; Plane Surface(13) = {13};
Line Loop(14) = {24, 54, -28, -50}; Plane Surface(14) = {14};
Line Loop(15) = {25, 43, -29, -39}; Plane Surface(15) = {15};
Line Loop(16) = {26, 57, -4, -60}; Plane Surface(16) = {16};
Line Loop(17) = {47, 58, -1, -57}; Plane Surface(17) = {17};
Line Loop(18) = {30, 58, 2, -59};  Plane Surface(18) = {18};
Line Loop(19) = {43, 59, 3, -60};  Plane Surface(19) = {19};
Line Loop(20) = {27, 69, -16, -72}; Plane Surface(20) = {20};
Line Loop(21) = {51, 70, -13, -69}; Plane Surface(21) = {21};
Line Loop(22) = {31, 70, 14, -71}; Plane Surface(22) = {22};
Line Loop(23) = {47, 71, 15, -72}; Plane Surface(23) = {23};
Line Loop(24) = {28, 55, -32, -51}; Plane Surface(24) = {24};
Line Loop(25) = {29, 44, -33, -40}; Plane Surface(25) = {25};
Line Loop(26) = {30, 48, -34, -44}; Plane Surface(26) = {26};
Line Loop(27) = {31, 52, -35, -48}; Plane Surface(27) = {27};
Line Loop(28) = {32, 56, -36, -52}; Plane Surface(28) = {28};

Recombine Surface {1, 2, 3, 4, 
		   5, 6, 7, 8, 9, 13, 10, 11, 12, 14, 
		   15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 
		   25, 26, 27, 28};




// meshing
Transfinite Line {37, 41, 45, 49, 53} = ny1 Using Progression Rx1;
Transfinite Line {17, 21, 25, 29, 33} = nx1 Using Progression Rx1;
Transfinite Line {40, 44, 48, 52, 56} = ny1 Using Progression 1/Rx1;

Transfinite Line {38, 42, 7, 5, 46, 11, 9, 50, 54} = ny2 Using Progression 1;
Transfinite Line {39, 43, 3, 1, 47, 15, 13, 51, 55} = ny2 Using Progression 1;

Transfinite Line {18, 22, 8, 6, 26, 4, 2, 30, 34} = nx2 Using Progression 1;
Transfinite Line {19, 23, 12, 10, 27, 16, 14, 31, 35} = nx2 Using Progression 1; 
Transfinite Line {20, 24, 28, 32, 36} = nx3 Using Progression 1/Rx1;
Transfinite Line {57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72} = nb Using Progression Rb;

Transfinite Surface {1, 2, 3, 4, 
		   5, 6, 7, 8, 9, 13, 10, 11, 12, 14, 
		   15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 
		   25, 26, 27, 28};


// physical groups
Physical Line("wall1") = {1, 2, 3, 4};
Physical Line("wall2") = {5, 6, 7, 8};
Physical Line("wall3") = {9, 10, 11, 12};
Physical Line("wall4") = {13, 14, 15, 16};
Physical Line("inlet") = {37,38, 39, 40};
Physical Line("outlet") = {53, 54, 55, 56};
Physical Line("sym") = {17, 18, 19, 20, 33, 34, 35, 36};
Physical Surface("fluid") = {1, 2, 3, 4,
			     5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 
			     15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
			     25, 26, 27, 28};
















