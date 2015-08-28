(defun c:testarch ()
					;Define the function

					;***************************************************************************
					;	how to write subroutines - do not put c: on subroutines
					;	creating/using/accessing/printing arrays
					;       drawing polylines with lines and arches
					;       creating entities
					;	explode pieces
					;	making tables
					;       sheets
					;	erase everything
					;       save to customer file number



					;Save system variables

  (setq oldsnap (getvar "osmode"))
					;Save snap settings

  (setq oldblipmode (getvar "blipmode"))
					;Save blipmode setting

					;***************************************************************************

					;Switch OFF system variables

  (setvar "osmode" 0)
					;Switch off SNAP

  (setvar "blipmode" 0)
					;Switch off BLIMPMODE

					;**************************************************************************
					; User inputs

					; ArchString - type of arch "sb", "fl", "fr" (sunburst, fan left, fan right)
					; FrameHeight - height of side frame (can be zero)
					; FrameWidth - width of base
                                        ; HubString - type of hub -- "a" or "p" (arch or profile)
					; TotalHeight - total height of shutter

					; Buried user inputs

					; Allowance - space allowed between hub and louvers and between frame and louvers (in)
					; HubRatio - fraction of base covered by hub (Note: This value may be adjusted upward by the program
					;            to accomodate pin spacing
					; LouverThickness - thickness of louver board stock (in)
					; MaxBoardWidth - maximum width of louvers (limited by board stock) (in)
					; MinPinSpacing - minimum center-to-center spacing of pins on hub (in)
					; PinDepth - hole depth for louver and frame joinery pins (in)
					; TrimWidth - width of trim (in)

					; Program constants

					; a1Dist - distance between ArchCenter and Midpointp9p10
					; a2Dist - distance between HubCenter and Midpoint p9p10
					; ArchCenter - point locating the center of the circle shared by the ArchTopOutside, ArchTopInside, and ArchLouverTop
					; ArchHeight - calculated as difference between TotalHeight and FrameHeight
					; ArchLouverTop - point locating the top of the arch formed by the louvers
					; ArchTopOutside - point locating the top of the arch on the outside trim
					; ArchTopInside - point locating the top of the arch on the inside trim
					; BaseChordHeight - vertical distance between inside of base to chord that runs to outside of arch
					; FirstHalf - value used for sb arches to determine when to flip overlap to other side
					; FrameHeightMinimum - calculated for semi-circular arches
					; HalfHubBaseLength - half of the distance covered by the bottom of the hub(in)
					; HubRadius - radius of hub circle (in)
					; HubTop - point at top of hub
					; InsideChordLength - chord length determined by inside radius arch
					; InsideRadius - radius of arc defined by inside of arch trim (in)
					; iNumberofLouvers - number of louvers (integer)
					; LouverBottom - top of arch defined by hub side of louvers
					; LouverChordHeight - vertical distance between bottom of lourvers and chord that runs to outside of arch
					; LouverLength - maximum louver length (in)
					; LouverOverlap - same as LouverThickness (45 degree overlap) (in)
					; LouverRadius - radius of arc defined by outside of louvers (in)
					; MaxLouverAngle - maximum allowable angle for louvers for given MaxBoardWidth (radians)
					; MaxLouverWidth - surface width of louvers (MaxBoardWidth - LouverOverlap) (in)
					; MidPointp1p2 - point midway between p1 and p2
					; MidPointp3p4 - point midway between p3 and p4
					; MidPointp5p6 - point midway between p5 and p6
					; MidPointp9p10 - point midway between p9 and p10
					; MidPointp11p12 - point midway between p11 and p12
					; OutsideRadius - radius of arc defined by outside of arch trim (in)
					; p1 - insertion point, lower left-hand corner of outer base
					; p2 - lower right-hand corner of outer base 
					; p3 - right-hand corner of outer vertical side frame
					; p4 - left-hand corner of outer vertical side frame
					; p5 - lower left-hand corner of inner base
					; p6 - lower right-hand corner of inner base
					; p7 - right-hand corner of inner vertical side frame
					; p8 - left-hand corner of inner verical side frame
					; p9 - lower left-hand corner of louvers
					; p10 - lower right-hand corner of louvers
					; p11 - right-hand corner of louvers at right-hand corner of vertical side frame
					; p12 - left-hand corner of louvers at left-hand corner of vertical side frame
					; p13 - left-hand point where hub contacts line between p9 and p10
					; p14 - right-hand point where hub contancts line between p9 and p10
					; p15 - left hand point where hub contacts base
					; p16 - right hand point where hub contacts base
					; p17 - left-hand point where louvers stop next to hub just above base
					; p18 - right-hand point where louvers stop next to hub just above base
					; PinCheck - minimum distance between pins into hub (in), used to adjust HubRatio
					; xNumberofLouvers - number of louvers (real)

					; Program variables

					; a - parameter for quadratic equation
					; a1DistOverlap - distance between ArchCenter and MidpointOverlap
					; a2DistOverlap - distance between HubCenter and MidpointOverlap
					; b - parameter for quadratic equation
					; bAngle - angle used to solve Law of Cosine for louver angle with quadratic equation (opposite side B)
					; bPinAngle - angle used to solve Law of Cosine for pin angle with quadratic equation (opposite side B)
					; c - parameter for quadratic equation
					; deltaIntercept = offset from intercept for overlap line
					; HubChordLength - length of chord along bottom of hub
					; intercept - y intercept of louver line (used to determine overlap line, which is parallel to louver line)
					; LouverAngle - angle between each louver, determined by louver surface in LouverLayer (does not include overlap)
					; LouverChordLength - chord length determined by louver arch, used to locate points along bottom of louver section
					; MidpointOverlap - point at which overlap line crosses vertical midline of hub
					; n - counter for louver number, counted from lower right
					; theta - used for angle calculations (radians)
					; p100 - central point used to spec holes for joinery pins
					; p101 - end of hole for pins
					; p102 - end of hole for pins (mates with p101)
					; p1PinInside - insertion point for pin hole in hub side of louver
					; p1PinOutside - insertion point for pin hole in trim for louver
					; p2PinInside - endpoint for pin hole in hub side of louver
					; p2PinOutside - end point for pin hole in trim for louver
					; p3Last - previous value of p3PinInside, used to calculate spacing between pins on hub
					; p3PinInside - insertion point for pin hole into hub
					; p3PinOutside - insertion point for pin hole into end of louver
					; p4PinInside - endpoiint for pin hole into hub
					; p4PinOutside - endpoint for pin hole into end of louver
					; pAngle - angle for each louver
					; pInside - inside point (hub side) of louver line
					; pInsideOverlap - inside point (hub side) of overlap line
					; pOutsideOverlap - outside point (arch side) of overlap line
					; pLength - length used to located inside and outside point of louvers, overlap lines, etc.
					; pOutside - outside point of louver line
					; pOutsideOverlap - outside point of overlap line
					; pPinAngle - angle of pins measured from MidPointp9p10 and horizontal
					; pPinLength - length from MidPointp9p10 to edge of hub, used to locate pin insertion points (p3PinInside)
					; root - root of quadratic equation
					; slope - slope of louver line (used to determine overlap line, which is parallel to louver line)
					; str1 - string used to relay messages through alert command
					; str2 - string used to relay messages through alert command
					; str3 - string used to relay messages through alert command
					; str4 - string used to relay messages through alert command


					;**************************************************************************

					;Get user inputs

  (setq ArchString (getstring "\nEnter type of arch (sb, fl, fr): "))
  (while (and (/= ArchString "sb")
	      (/= ArchString "fl")
	      (/= ArchString "fr")
	 )
    (alert
      "Enter the type of arch: \nsb  - Sunburst\nfl - Fan Left\nfr - Fan Right"
    )
    (setq ArchString (getstring "\nEnter type of arch (sb, fl, fr): "))
  )

  (setq
    FrameWidth	       (getreal "\nOutside width of frame opening (in): ")
					;Get the outside width of the frame in inches

    TotalHeight	       (getreal "\nTotal height of frame opening (in): ")
					;Get total height of frame opening

    FrameHeight	       (getreal "\nOutside height of side frame (in): ")
					;Get height of side frame

    FrameHeightMinimum (max 0.0 (- TotalHeight (/ FrameWidth 2.0)))
  )
  
  (while (or (< FrameHeight FrameHeightMinimum)
	     (>= FrameHeight TotalHeight)
	 )
    (cond
      ((< FrameHeight FrameHeightMinimum)
       (setq str1 (rtos FrameHeightMinimum 2 2))
       (alert
	 (strcat "Frame height must be at least " str1 " inches.")
       )
       (setq FrameHeight
	      (getreal "\nOutside height of side frame (in): ")
       )
      )
    )
					;Get height of side frame again
    (cond
      ((>= FrameHeight TotalHeight)
       (alert
	 "The FrameHeight must be less than the TotalHeight.  Please re-enter the values."
       )
       (setq
	 TotalHeight (getreal "\nTotal height of frame opening (in): ")
	 FrameHeight (getreal "\nOutside height of side frame (in): ")
					;Get height of side frame
					;Get total height of frame opening
       )
      )
    )
  )
  (setq
    ArchHeight
     (- TotalHeight FrameHeight)
					;Calculate the outside height of the arch in inches

    TrimWidth 2.0
					;(in), constant

    Allowance (/ 1.0 16.0)
					;(in), allowance between louvers and frame/hub, constant

    MaxBoardWidth
     4.0
					;(in), constant

    LouverThickness
     (/ 5.0 16.0)
					;(in), constant
    LouverOverlap
     LouverThickness

    MaxLouverWidth
     (- MaxBoardWidth LouverOverlap)
					;(in), constant

    PinDepth 0.5
					;depth of holes drilled for pins (in), constant

    MinPinSpacing
     0.5
					; spacing between center of pins (in), constant

    HubRatio 0.20
					;HubRatio
					;(getreal "\n HubRatio (fraction): ")
					;Get HubRatio

					;fraction of frame width used for hub, adjusted upward if pin spacing is too close
  )
					;***************************************************************************

					; Define the layers

  (_makelayer "BaseLayer" 1 "Continuous" 40)
  (_makelayer "BasePinLayer" 232 "Continuous" 40)
  (_makelayer "FrameLayer" 2 "Continuous" 40)
  (_makelayer "FramePinLayer" 41 "Continuous" 40)
  (_makelayer "ArchLayer" 6 "Continuous" 40)
  (_makelayer "ArchPinLayer" 212 "Continuous" 40)
  (_makelayer "HubLayer" 3 "Continuous" 40)
  (_makelayer "HubPinLayer" 82 "Continuous" 40)
  (_makelayer "LouverLayer" 5 "Continuous" 40)
  (_makelayer "LouverPinLayer" 152 "Continuous" 40)
  (_makelayer "LouverOverlapLayer" 141 "Continuous" 40)
					; (_makelayer "DebugLayer" 32 "Continuous" 40)


					;***************************************************************************

					;Determine points for the rectangular portion of the frame

  (setq
    p1		  (getpoint "\nReference corner (lower left): ")
					;insertion point	
    p2		  (polar p1 0.0 FrameWidth)
					;Bottom outside points (counter-clockwise)


    MidPointp1p2  (polar p2 PI (* FrameWidth 0.5))
    OutsideRadius (/ (+	(expt (distance MidPointp1P2 p2) 2.0)
			(expt ArchHeight 2.0)
		     )
		     (* ArchHeight 2.0)
		  )
    InsideRadius  (- OutsideRadius TrimWidth)
    LouverRadius  (- InsideRadius Allowance)

  )
  (cond
    ((>= FrameHeight TrimWidth)
					;There is some FrameHeight portion to the interior design
     (setq
       p3	      (polar p2 (* PI 0.5) FrameHeight)
       p4	      (polar p3 PI FrameWidth)
       MidPointp3p4   (polar p3 PI (* FrameWidth 0.5))
					;Top outside points (counter-clockwise)

       p5	      (polar p1 (* PI 0.25) (* TrimWidth (sqrt 2.0)))
       p6	      (polar p5 0.0 (- FrameWidth (* TrimWidth 2.0)))
       MidPointp5p6   (polar p6 PI (* (distance p5 p6) 0.5))
					;Bottom inside points (counter-clockwise), analogous to p1 and p2

       p9	      (polar p1
			     (* PI 0.25)
			     (* (+ TrimWidth Allowance) (sqrt 2.0))
		      )
       p10	      (polar p9
			     0.0
			     (- Framewidth (* (+ TrimWidth Allowance) 2.0))
		      )
       MidPointp9p10  (polar p10 PI (* (distance p9 p10) 0.5))
					;Bottom points of louvers (counter-clockwise), analogous to p1 and p2

       ArchTopOutside (polar MidPointp3p4 (* PI 0.5) ArchHeight)
       ArchTopInside  (polar ArchTopOutside (* PI 1.5) TrimWidth)
       ArchLouverTop  (polar ArchTopOutside
			     (* PI 1.5)
			     (+ TrimWidth Allowance)
		      )
					;Locate arch tops

       ArchCenter     (polar ArchTopOutSide (* PI 1.5) OutsideRadius)
					;Center of Arch Radius (same for both Inside and Outside)
     )

     (cond

       ((< ArchHeight (/ FrameWidth 2.0))
	(setq
	  theta	(atan (/ (sqrt (- (expt InsideRadius 2.0)
				  (expt (distance MidPointp5p6 p6) 2.0)
			       )
			 )
			 (distance MidPointp5p6 p6)
		      )
		)
	  p7	(polar ArchCenter theta InsideRadius)
	  p8	(polar ArchCenter (- PI theta) InsideRadius)
					;Top inside points (counter-clockwise), analogous to p3 and p4
	  theta	(atan (/ (sqrt (- (expt LouverRadius 2.0)
				  (expt (distance MidPointp9p10 p10) 2.0)
			       )
			 )
			 (distance MidPointp9p10 p10)
		      )
		)
	  p11	(polar ArchCenter theta LouverRadius)
	  p12	(polar ArchCenter (- Pi theta) LouverRadius)
					;Top louver points (counter-clockwise), analogous to p3 and p4
	)
       )
       (T
	(setq
	  p7  (polar p3 PI TrimWidth)
	  p8  (polar p4 0.0 TrimWidth)
					;Top inside points (counter-clockwise), analogous to p3 and p4
	  p11 (polar p3 PI (+ TrimWidth Allowance))
	  p12 (polar p4 0.0 (+ TrimWidth Allowance))
					;Top louver points (counter-clockwise), analogous to p3 and p4
	)
       )
     )

     (setvar 'clayer "BaseLayer")
     (command "Line" p1 p2 p6 p5 "c")
     (setvar 'clayer "FrameLayer")
     (command
       "Line" p4 p1 p5 p8 "c" "Line" p3	p2 p6 p7 "c")

					;Draw the lower frame
     (setq
       theta (angle p7 p3)
       p100  (polar p7 theta (/ (distance p3 p7) 3.0))
       p101  (polar p100 (+ theta (* PI 0.50)) PinDepth)
       p102  (polar p100 (+ theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p7 theta (* (/ (distance p3 p7) 3.0) 2.0))
       p101 (polar p100 (+ theta (* PI 0.50)) PinDepth)
       p102 (polar p100 (+ theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p102 "")
					;Pins between RightFrame and Arch
     (setq
       theta (angle p8 p4)
       p100  (polar p8 theta (/ (distance p4 p8) 3.0))
       p101  (polar p100 (- theta (* PI 0.50)) PinDepth)
       p102  (polar p100 (- theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p8 theta (* (/ (distance p4 p8) 3.0) 2.0))
       p101 (polar p100 (- theta (* PI 0.50)) PinDepth)
       p102 (polar p100 (- theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p1 (* PI 0.25) (/ (distance p1 p5) 3.0))
       p101 (polar p100 (* PI 0.75) PinDepth)
       p102 (polar p100 (* PI 0.75) (- 0.0 PinDepth))
     )
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p1 (* PI 0.25) (* (/ (distance p1 p5) 3.0) 2.0))
       p101 (polar p100 (* PI 0.75) PinDepth)
       p102 (polar p100 (* PI 0.75) (- 0.0 PinDepth))
     )
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")
					;Pins between LeftFrame and Base
     (setq
       p100 (polar p2 (* PI 0.75) (/ (distance p2 p6) 3.0))
       p101 (polar p100 (* PI 0.25) PinDepth)
       p102 (polar p100 (* PI 0.25) (- 0.0 PinDepth))
     )
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p2 (* PI 0.75) (* (/ (distance p2 p6) 3.0) 2.0))
       p101 (polar p100 (* PI 0.25) PinDepth)
       p102 (polar p100 (* PI 0.25) (- 0.0 PinDepth))
     )
     (setvar 'clayer "FramePinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")
					;Pins between RightFrame and Base
    )
    (T
     (setq
       p3		 p2
       p4		 p1
       MidPointp3p4	 MidPointp1p2
       ArchTopOutside	 (polar MidPointp3p4 (* PI 0.5) ArchHeight)
       ArchTopInside	 (polar ArchTopOutside (* PI 1.5) TrimWidth)
       ArchLouverTop	 (polar	ArchTopOutside
				(* PI 1.5)
				(+ TrimWidth Allowance)
			 )
       ArchCenter	 (polar ArchTopOutSide (* PI 1.5) OutsideRadius)
       BaseChordHeight	 (- TrimWidth FrameHeight)
       LouverChordHeight (- (+ TrimWidth Allowance) FrameHeight)
       MidPointp5p6	 (polar MidPointp3p4 (* PI 0.5) BaseChordHeight)
       MidPointp9p10	 (polar MidPointp5p6 (* PI 0.5) Allowance)
       InsideChordLength (sqrt
			   (- (expt InsideRadius 2.0)
			      (expt
				(+ (distance MidPointp3p4 ArchCenter)
				   BaseChordHeight
				)
				2.0
			      )
			   )
			 )
       LouverChordLength (sqrt
			   (- (expt LouverRadius 2.0)
			      (expt
				(+ (distance MidPointp3p4 ArchCenter)
				   LouverChordHeight
				)
				2.0
			      )
			   )
			 )
       p5		 (polar MidPointp5p6 PI InsideChordLength)
       P6		 (polar MidPointp5p6 0.0 InsideChordLength)
       p7		 p6
       p8		 p5
       p9		 (polar MidPointp9p10 PI LouverChordLength)
       p10		 (polar MidPointp9p10 0.0 LouverChordLength)
       p11		 p10
       p12		 p9
       theta		 (angle p1 p5)
     )

     (setvar 'clayer "BaseLayer")
     (command "Line" p1 p2 p6 p5 "c")

     (setq
       p100 (polar p1 theta (/ (distance p1 p5) 3.0))
       p101 (polar p100 (+ theta (* PI 0.50)) PinDepth)
       p102 (polar p100 (+ theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100  (polar p1 theta (* (/ (distance p1 p5) 3.0) 2.0))
       p101  (polar p100 (+ theta (* PI 0.50)) PinDepth)
       p102  (polar p100 (+ theta (* PI 0.50)) (- 0.0 PinDepth))
       theta (angle p2 p6)
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p2 theta (/ (distance p2 p6) 3.0))
       p101 (polar p100 (- theta (* PI 0.50)) PinDepth)
       p102 (polar p100 (- theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")

     (setq
       p100 (polar p2 theta (* (/ (distance p2 p6) 3.0) 2.0))
       p101 (polar p100 (- theta (* PI 0.50)) PinDepth)
       p102 (polar p100 (- theta (* PI 0.50)) (- 0.0 PinDepth))
     )
     (setvar 'clayer "ArchPinLayer")
     (command "Line" p100 p101 "")
     (setvar 'clayer "BasePinLayer")
     (command "Line" p100 p102 "")
					;Pins between Base and Arch
    )
  )

					;***************************************************************************

					;Draw the arcs

  (setvar 'clayer "ArchLayer")
  (command
    "Arc"    p3	      ArchTopOutside	p4	 "Line"	  p4
    p8	     ""	      "Arc"    p8	ArchTopInside	  p7
    "Line"   p7	      p3       ""
   )
  (setvar 'clayer "LouverLayer")
  (command "Arc" p11 ArchLouverTop p12)
					;***************************************************************************

					;Calculate iNumberofLouvers and LouverAngle

  (cond
    ((>= (distance MidPointp9p10 ArchLouverTop)
	 (distance MidPointp9p10 p12)
     )
     (setq LouverLength (distance MidPointp9p10 ArchLouverTop))
    )					; taller frames
    (T
     (setq LouverLength (distance MidPointp9p10 p11))
    )					; sqatter frames 
  )

  (setq
    MaxLouverAngle   (*	(atan (/ (* MaxLouverWidth 0.5) LouverLength))
			2.0
		     )
    xNumberofLouvers (/ PI MaxLouverAngle)
    iNumberofLouvers (fix xNumberofLouvers)
  )

  (if (> xNumberofLouvers (float iNumberofLouvers))
    (setq
      iNumberofLouvers (+ 1 iNumberofLouvers)
      xNumberofLouvers (float iNumberofLouvers)
    )
  )
  (if (and (= ArchString "sb") (= (rem iNumberofLouvers 2) 1))
    (setq
      iNumberofLouvers (+ 1 iNumberofLouvers)
      xNumberofLouvers (float iNumberofLouvers)
    )
  )
  (if (= ArchString "sb")
    (setq FirstHalf (/ iNumberofLouvers 2))
  )
  (setq
    LouverAngle	   (/ PI xNumberofLouvers)
    MidPointp11p12 (polar p11 PI (* (distance p11 p12) 0.5))
    
    HubRadius	   (* LouverRadius HubRatio)
    a1Dist	   (distance ArchCenter MidPointp9p10)
    HalfHubBaseLength (* (distance p9 p10) (* HubRatio 0.5))
    p14		   (polar MidPointp9p10 0.0 HalfHubBaseLength)
  )

					;***************************************************************************

                                        ; Get hub type
  (setq HubString (getstring "\nEnter type of hub (a, p): "))
  (while (and (/= HubString "a")
	      (/= HubString "p")
	 )
    (alert
      "Enter the type of hub: \np  - Profile\na - Arch"
    )
    (setq HubString (getstring "\nEnter type of hub (a, p): "))
  )
  
  
  (cond
    ((= HubString "a")
     (setq
       HubTop	   (polar MidPointp9p10
			  (* PI 0.5)
			  (* (distance MidPointp11p12 ArchLouverTop) HubRatio)
		   )
       p20 p14
     )
    )
    ((= Hubstring "p")
     (setq
       HubTop (polar Midpointp9p10 (* PI 0.5) (* (distance MidPointp9p10 ArchLouverTop) HubRatio))
       p20 (polar p14 (* PI 0.5) (* (distance p9 p12) HubRatio))
     )
    )
  )
  (setq     
    HubCenter	   (polar HubTop (* PI 1.5) HubRadius)
    a2Dist	   (distance HubCenter MidPointp9p10)
    BaseMidPoint MidPointp9p10
    FramePoint p20
    BaseSidePoint p14
    CenterPoint HubCenter
    Radius HubRadius
    aDist a2Dist
  )
  					;Check hub for sizing
  (cond					
    ((= (rem iNumberofLouvers 2) 0)	; even number of louvers
     (setq
       pPinAngle (- (/ PI 2.0) (/ LouverAngle 2.0))
       PointAngle pPinAngle
     )
     (PointFinder)
     (setq
       p3PinInside Point
       PinCheck	   (* (- (* PI 0.5) (angle HubCenter p3PinInside))
		      HubRadius
		      2.0
	   	   )
     )
    )					
    (T					; odd number of louvers
     (setq
       pPinAngle (- (/ PI 2.0) LouverAngle)
       PointAngle pPinAngle
     )
     (PointFinder)
     (setq
       p3PinInside Point
       PinCheck	   (* (- (* PI 0.5) (angle HubCenter p3PinInside))
		      HubRadius
		   )
     )	
    )
  )
  (cond
    ((< PinCheck MinPinSpacing)
     (setq
       HubRatio (* HubRatio (/ MinPinSpacing PinCheck))
       HubTop	(polar	MidPointp9p10
			(* PI 0.5)
			(* (distance MidPointp11p12 ArchLouverTop) HubRatio)
		 )
       HubRadius (* LouverRadius HubRatio)
       HubCenter (polar HubTop (* PI 1.5) HubRadius)
       a2Dist	 (distance HubCenter MidPointp9p10)
       str1
		 (rtos HubRatio 2 3)
       str2
		 (rtos MinPinSpacing 2 3)
     )
     (alert (strcat "Hub ratio changed to " str1 " to keep pin spacing at " str2 " in."))
    )
  )
  
					;***************************************************************************

					;Spec out hub

  (setq
    HalfHubBaseLength (* (distance p9 p10) (* HubRatio 0.5))
    p13		      (polar MidPointp9p10 PI HalfHubBaseLength)
    p14		      (polar MidPointp9p10 0.0 HalfHubBaseLength)
    LouverBottom      (polar HubTop (* PI 0.5) Allowance)
  )

  (cond
					; Hub is a half circle, so Allowance distance is covered by a rectangle.
    ((and (= ArchHeight (/ FrameWidth 2.0)) (= HubString "a"))
     (setq
					; points where Hub contacts the base
       p15 (polar p13 (* PI 1.5) Allowance)
       p16 (polar p14 (* PI 1.5) Allowance)
					; points where Louvers stop at base of Hub
       p17 (polar p13 PI Allowance)
       p18 (polar p14 0.0 Allowance)
     )

					; Outline the Hub
     (setvar 'clayer "HubLayer")
     (command
       "Line" p15 p13 "" "Arc" p13 HubTop p14 "Line" p14 p16 p15 "")

					; Outline the Louver boundary around the Hub
     (setvar 'clayer "LouverLayer")
     (command
       "Line" p12 p9 p17 "" "Arc" p17 LouverBottom p18 "Line" p18 p10
       p11 "")
    )

					; Hub is less than a half circle, so Allowance distance is covered by continuing the circle.
    ((= HubString "a")
     (setq
       HubChordLength	 (sqrt
			   (- (expt HubRadius 2.0)
			      (expt (distance MidPointp5p6 HubCenter) 2.0)
			   )
			 )

					; points where Hub contacts the base
       p15		 (polar MidPointp5p6 PI HubChordLength)
       p16		 (polar MidPointp5p6 0.0 HubChordLength)

       LouverChordLength (sqrt
			   (- (expt (+ HubRadius Allowance) 2.0)
			      (expt (distance MidPointp9p10 HubCenter)
				    2.0
			      )
			   )
			 )

					; points where Louvers stop at base of Hub
       p17		 (polar MidPointp9p10 PI LouverChordLength)
       p18		 (polar MidPointp9p10 0.0 LouverChordLength)
       p21 p17
       p22 p18
     )

					; Outline the Hub
     (setvar 'clayer "HubLayer")
     (command
       "Arc" p15 HubTop	p16 "Line" p16 p15 "")

					; Outline the Louver boundary around the Hub
     (setvar 'clayer "LouverLayer")
     (command
       "Line" p12 p9 p17 "" "Arc" p17 LouverBottom p18 "Line" p18 p10
       p11 "")
    )
    (T
     
     (setq
					; points where Hub contacts the base
       p15 (polar p13 (* PI 1.5) Allowance)
       p16 (polar p14 (* PI 1.5) Allowance)
					; points where Louvers stop at base of Hub
       p17 (polar p13 PI Allowance)
       p18 (polar p14 0.0 Allowance)
     
	                                        ; corner points of Hub

       p19 (polar p13 (* PI 0.5) (* (distance p9 p12) HubRatio))
       p20 (polar p14 (* PI 0.5) (* (distance p9 p12) HubRatio))
		                                ; corner points of louvers at Hub corners
       theta (angle MidPointp9p10 p20)
       tanTheta (/ (sin theta) (cos theta))
       p21 (polar p17 (* Pi 0.5) (* (+ HalfHubBaseLength Allowance) tanTheta))
       p22 (polar p18 (* Pi 0.5) (* (+ HalfHubBaseLength Allowance) tanTheta)) 
     )
					; Outline the Hub
     (setvar 'clayer "HubLayer")
     (command
       "Arc" p19 HubTop	p20 "Line" p20 p16 p15 p19 "")
					; Outline the Louver boundary around the Hub
     (setvar 'clayer "LouverLayer")
     (command
       "Line" p12 p9 p17 p21 "" "Arc" p21 LouverBottom p22 "Line" p22 p18 p10 p11 "")
    )
  )

					;Pins between Hub and Base (3 of them)
  (setq
    p100 (polar p15 0.0 (/ (distance p15 p16) 4.0))
    p101 (polar p100 (* PI 0.50) PinDepth)
    p102 (polar p100 (* PI 1.50) PinDepth)
  )
  (setvar 'clayer "HubPinLayer")
  (command "Line" p100 p101 "")
  (setvar 'clayer "BasePinLayer")
  (command "Line" p100 p102 "")

  (setq
    p100 (polar p15 0.0 (* (/ (distance p15 p16) 4.0) 2.0))
    p101 (polar p100 (* PI 0.50) PinDepth)
    p102 (polar p100 (* PI 1.50) PinDepth)
  )
  (setvar 'clayer "HubPinLayer")
  (command "Line" p100 p101 "")
  (setvar 'clayer "BasePinLayer")
  (command "Line" p100 p102 "")

  (setq
    p100 (polar p15 0.0 (* (/ (distance p15 p16) 4.0) 3.0))
    p101 (polar p100 (* PI 0.50) PinDepth)
    p102 (polar p100 (* PI 1.50) PinDepth)
  )
  (setvar 'clayer "HubPinLayer")
  (command "Line" p100 p101 "")
  (setvar 'clayer "BasePinLayer")
  (command "Line" p100 p102 "")
  
					;***************************************************************************
					;Big loop to spec out each louver, pins, and overlap

  (setq n 1)
  (while (<= n iNumberofLouvers)

					;Spec out louvers
					;Find outside point of louvers (against arch and frames)
    (setq
      pAngle (* LouverAngle n)
      PointAngle pAngle
      BaseMidPoint MidPointp9p10
      FramePoint p11
      BaseSidePoint p10
      CenterPoint ArchCenter
      Radius LouverRadius
      aDist a1Dist
    )
    (PointFinder)
    (setq pOutside Point)
       					;****************************************************************************

					;Find hubside point of louvers
    (setq
      FramePoint p22
      BaseSidePoint p18
      CenterPoint HubCenter
      Radius (+ HubRadius Allowance)
      aDist a2Dist
    )
    (PointFinder)
    (setq pInside Point)       
					;Don't double draw final side of louvers
    (cond
      ((< n iNumberofLouvers)
       (setvar 'clayer "LouverLayer")
       (command "Line" pInside pOutside "")
      )
    )
					;****************************************************************************

					;Draw line for overlap parallel to top louver edge

    (cond
					;Any situation where louver boundary line is not vertical
      ((/= pAngle (/ PI 2.0))
       (setq
	 slope	   (/ (- (cadr pOutside) (cadr pInside))
		      (- (car pOutside) (car pInside))
		   )
	 intercept (- (cadr pOutside) (* slope (car pOutside)))
       )
       (cond
	 ((= ArchString "fl")
	  (setq	deltaIntercept
		 (/ LouverOverlap (sin (- (* PI 0.5) pAngle)))
	  )
	 )
	 ((= ArchString "fr")
	  (setq	deltaIntercept
		 (- 0.0
		    (/ LouverOverlap
		       (sin (- (* PI 0.5) pAngle))
		    )
		 )
	  )
	 )
	 ((and (= ArchString "sb") (< n FirstHalf))
	  (setq	deltaIntercept
		 (- 0.0
		    (/ LouverOverlap
		       (sin (- (* PI 0.5) pAngle))
		    )
		 )
	  )
	 )
	 ((and (= ArchString "sb") (> n FirstHalf))
	  (setq	deltaIntercept
		 (/ LouverOverlap (sin (- (* PI 0.5) pAngle)))
	  )
	 )
       )
       (setq
	 MidPointOverlap (polar MidPointp9p10 (* PI 0.5) deltaIntercept)
	 a1DistOverlap	 (distance ArchCenter MidPointOverlap)
	 a2DistOverlap	 (distance HubCenter MidPointOverlap)
       )
      )
    )

    (cond
					;Louver boundary line is vertical, can only happen once with even number of louvers
      ((= pAngle (/ PI 2.0))
       (cond
	 ((= ArchString "fl")
	  (setq
	    bAngle	    (+ (/ PI 2.0)
			       (atan (/	LouverOverlap
					(sqrt (- (expt LouverRadius 2.0)
						 (expt LouverOverlap 2.0)
					      )
					)
				     )
			       )
			    )
	    pOutsideOverlap (polar ArchCenter bAngle LouverRadius)
	  )
	 )
	 ((= ArchString "fr")
	  (setq
	    bAngle	    (- (/ PI 2.0)
			       (atan (/	LouverOverlap
					(sqrt (- (expt LouverRadius 2.0)
						 (expt LouverOverlap 2.0)
					      )
					)
				     )
			       )
			    )
	    pOutsideOverlap (polar ArchCenter bAngle LouverRadius)
	  )
	 )
       )
      )
      (T
       (setq
	 BaseMidPoint MidPointOverlap
         FramePoint p11
         BaseSidePoint (polar MidPointOverlap 0.0 (distance MidPointp9p10 p10))
         CenterPoint ArchCenter
         Radius LouverRadius
         aDist a1DistOverlap
       )
       (PointFinder)
       (setq pOutsideOverlap Point)
      )
    )
					;Find hubside point of overlap

    (cond
					;Louver boundary line is vertical, can only happen once with even number of louvers
      ((= pAngle (/ PI 2.0))
       (cond
	 ((= ArchString "fl")
	  (setq
	    bAngle	   (+ (/ PI 2.0)
			      (atan (/ LouverOverlap
				       (sqrt (-	(expt HubRadius 2.0)
						(expt LouverOverlap 2.0)
					     )
				       )
				    )
			      )
			   )
	    pInsideOverlap (polar HubCenter bAngle HubRadius)
	  )
	 )
	 ((= ArchString "fr")
	  (setq
	    bAngle	   (- (/ PI 2.0)
			      (atan (/ LouverOverlap
				       (sqrt (-	(expt HubRadius 2.0)
						(expt LouverOverlap 2.0)
					     )
				       )
				    )
			      )
			   )
	    pInsideOverlap (polar HubCenter bAngle HubRadius)
	  )
	 )
       )
      )

      (T
       (setq
	 BaseMidPoint MidPointOverlap
         FramePoint p22
         BaseSidePoint (polar MidPointOverlap 0.0 (distance MidPointp9p10 p14))
         CenterPoint HubCenter
         Radius (+ HubRadius Allowance)
         aDist a2DistOverlap
       )
       (PointFinder)
       (setq pInsideOverlap Point)
      )
    )

    (cond
      ((= n iNumberofLouvers)
      )
      ((and (= ArchString "sb") (= n FirstHalf))
      )
      (T
       (setvar 'clayer "LouverOverlapLayer")
       (command "Line" pInsideOverlap pOutsideOverlap "")
      )
    )

					;****************************************************************************


					; Repeat calculations for pins

    (setq
      pPinAngle (- pAngle (/ LouverAngle 2.0))
      PointAngle pPinAngle
      BaseMidPoint MidPointp9p10
      FramePoint p7
      BaseSidePoint p6
      CenterPoint ArchCenter
      Radius (+ LouverRadius Allowance)
      aDist a1Dist
    )
    (PointFinder)
    (setq
      p1PinOutside Point
      p2PinOutside (polar p1PinOutside pPinAngle PinDepth)
      FramePoint p11
      BaseSidePoint p10
      Radius LouverRadius
    )
    (PointFinder)
    (setq
      p3PinOutside Point
      p4PinOutside (polar p3PinOutside pPinAngle (- 0.0 PinDepth))
      FramePoint p22
      BaseSidePoint p18
      CenterPoint HubCenter
      Radius (+ HubRadius Allowance)
      aDist a2Dist
    )
    (PointFinder)
    (setq
      p1PinInside Point
      p2PinInside (polar p1PinInside pPinAngle PinDepth)
      FramePoint p20
      BaseSidePoint p14
      Radius HubRadius
    )
    (PointFinder)
    (setq
      p3PinInside Point
      p4PinInside (polar p3PinInside pPinAngle (- 0.0 PinDepth))
    )
					;Find hubside point of pins

    (setvar 'clayer "FramePinLayer")
    (command "Line" p1PinOutside p2PinOutside "")
    (setvar 'clayer "LouverPinLayer")
    (command
      "Line"	    p3PinOutside  p4PinOutside	""
      "Line"	    p1PinInside	  p2PinInside	""
     )
    (setvar 'clayer "HubPinLayer")
    (command "Line" p3PinInside p4PinInside "")
					;(cond
					;  ((> n 1)
					;   (setq
					;	 PinDistance (*	HubRadius
					;			(- (angle p3PinInside HubCenter) (angle p3Last HubCenter))
					;		     )
					;	 str1	     (itoa (- n 1))
					;	 str2	     (itoa n)
					;	 str3	     (rtos PinDistance 2 5)
					;	 str4	     (rtos HubRatio 2 5)
					;       )
					;       (alert
					;	 (strcat "PinDistance between "		   str1
					;		 " and "	  str2		   " is "
					;		 str3		  ". \nHubRatio is "
					;		 str4
					;		)
					;       )
					;      )
					;    )

					;   (setq p3Last p3PinInside)
    (setq n (+ 1 n))
  )
					;***************************************************************************

					;Reset system variables

  (setvar "osmode" oldsnap)
					;Reset SNAP

  (setvar "blipmode" oldblipmode)
  :Reset
  BLIPMODE

					;***************************************************************************

  (princ)
					;finish cleanly

)					;end of testarch

					;***************************************************************************


(princ)					;load cleanly

					;***************************************************************************
(defun _makelayer (name color ltype lnwt)
  (
   (lambda (_function)
     (_function
       (list
	 (cons 0 "LAYER")
	 (cons 100 "AcDbSymbolTableRecord")
	 (cons 100 "AcDbLayerTableRecord")
	 (cons 2 name)
	 (cons 70 0)
	 (cons 62 color)
	 (cons 6 ltype)
	 (cons 370 lnwt)
       )
     )
   )
    (if	(tblsearch "LAYER" name)
      (lambda (data)
	(entmod (cons (cons -1 (tblobjname "LAYER" name)) data))
      )
      entmakex
    )
  )
)
(princ)					;load cleanly

(defun quadratic ()
  (setq	root (/	(+ (- 0.0 b) (sqrt (- (expt b 2.0) (* 4.0 a c))))
		(* 2.0 a)
	     )
  )
)

(defun PointFinder ()
  (cond
					; Lengths determined by frame
    ((<	(abs (sin PointAngle))
	(sin (angle BaseMidPoint FramePoint))
     )
     (setq
       PointLength
	(/ (distance BaseMidPoint BaseSidePoint)
	   (abs (cos PointAngle))
	)
     )
    )

					; Lengths determined by arch.  Arch center coincides with Louver baseline (perfect half circle arches).
    ((= (cadr CenterPoint) (cadr BaseMidPoint))
     (setq PointLength Radius)
    )

					; Lengths determined by arch.  Arch center lies above the Louver baseline (taller arches).
    ((> (cadr CenterPoint) (cadr BaseMidPoint))
     (setq
       bAngle (abs (- (/ PI 2.0) PointAngle))
       a      1.0
       b      (- 0.0 (* 2.0 aDist (cos bAngle)))
       c      (- (expt aDist 2.0) (expt Radius 2.0))
     )
     (quadratic)
     (setq PointLength root)
    )

					; Lengths determined by arch.  Arch center lies below the Louver baseline (squatter arches).
    (T
     (setq
       bAngle (abs (+ (/ PI 2.0) PointAngle))
       a      1.0
       b      (- 0.0 (* 2.0 aDist (cos bAngle)))
       c      (- (expt aDist 2.0) (expt Radius 2.0))
     )
     (quadratic)
     (setq PointLength root)
    )
  )
  (setq Point (polar BaseMidPoint PointAngle PointLength))
)