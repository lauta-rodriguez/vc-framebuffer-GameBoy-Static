.ifndef utils_s
.equ utils_s, 0

.include "data.s"

// la valores en base a los que se calcula el tamaño de las 
// figuras es arbitrario. Se eligieron en función de como queda
// el resultado (imagen) final

cleanFrameBuffer:
    //------------------
    sub sp, sp, 16
    stur x0, [sp,8]
    stur lr, [sp,0]
    //------------------

    movz x10, 0x3B, lsl 16
    movk x10, 0x3E45, lsl 00
    mov x2, SCREEN_HEIGH
    
    loopCFB0:
    mov x1, SCREEN_WIDTH
    loopCFB1:
    stur w10, [x0]
    add x0, x0, #4
    sub x1, x1, #1
    cbnz x1, loopCFB1
    sub x2,x2,#1							// substract row from counter
    cbnz x2, loopCFB0	

    //------------------
    ldur x0, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 16
    ret
    //------------------    

paintPixel:
    //------------------
    // do pixel in the given (x,y) coordinates
    // x -> x1 
    // y -> x2 
    // colour -> x10
    ///////////////////////////////////////////

    sub sp, sp, 24
    stur x8, [sp,16]
    stur x9, [sp,8]
    stur lr, [sp,0]
    //------------------

    // no se queja si es más chico
    cmp x1, SCREEN_WIDTH
    b.ge end
    cmp x2, SCREEN_HEIGH
    b.ge end

    // calculate the initial address 
    // address = fb_base_address + 4 * [x + (y * 640)]
    mov x8, SCREEN_WIDTH
    mul x9, x2, x8
    add x9, x9, x1
    lsl x9, x9, 2
    add x9, x9, x0

    stur w10, [x9]

    //------------------

    end:
    ldur x8, [sp,16]
    ldur x9, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 24
    ret
    //------------------

paintRectangle:
    //------------------
    //  x10 -> color 
    //  x1 -> x coord
    //  x2 -> y coord
    //  x3 -> base
    //  x4 -> height

    sub sp, sp, 64      // reserve memory in the stack
    stur x10,[sp,56]    // save parameters, temp registers and return pointer in the stack
    stur x8, [sp,48]    
    stur x9, [sp,40]
    stur x1, [sp,32]
    stur x2, [sp,24]
    stur x3, [sp,16]
    stur x4, [sp,8]
    stur lr, [sp]
    //------------------

    mov x9, x4                              // saves height in the temp register x9

    loop1:
        cbz x9, loop1End                    // if height==0 or finished painting the rectangle, exits
        cmp x2, SCREEN_HEIGH                // y_coord - SCREEN_HEIGH ≥ 0 ?
        b.ge loop1End                       // we exceeded the boundaries of the framebuffer, exits
        ldur x1, [sp, 32]
        mov x8, x3                         // saves base in the temp register x9     
        loop0:
            cbz x8, loop0End               // finished painting an horizontal line, exits
            cmp x1, SCREEN_WIDTH           
            b.ge loop0End                  //  we exceeded the boundaries of the framebuffer, exits
            bl paintPixel
            add x1,x1,1
            sub x8,x8,1
            b loop0
        loop0End:
        add x2, x2, 1
        sub x9, x9, 1
        b loop1
    loop1End:

    //------------------
    ldur x10,[sp,56]
    ldur x8,[sp,48]
    ldur x9,[sp,40]
    ldur x1, [sp,32]
    ldur x2, [sp,24]
    ldur x3, [sp,16]
    ldur x4, [sp,8]
    ldur lr, [sp]
    add sp, sp, 64
    br lr
    //------------------

paintTriangle:
    //------------------
    // Paramétros de entrada:
    // x1  --> x coordinate
    // x2  --> y coordinate
    // x5  --> triangle height
    //------------
    // Otras variables:
    // x12 --> registro auxiliar para la heigth
    // x15 --> base en cada iteracion
    // x16 --> controla la base en cada iteración

    sub sp, sp, 48      // reserve memory in the stack
    stur x1,[sp,40]    // save parameters, temp registers and return pointer in the stack
    stur x2, [sp,32]
    stur x5, [sp,24]
    stur x15, [sp,16]
    stur x13, [sp,8]
    stur lr, [sp,0]
    //------------------

    //dividir la altura por 2
    //determinar el vértice más alto como el punto que
    //está exactamente altura/2 pixeles sobre la coordenada
    //del punto medio

    add x16, xzr, xzr
    add x15, xzr, xzr
    sub x15, x15, #1  // x13 empieza en -1 -> valores impares
   
    //  Calculo del vértice más alto a partir del punto medio
        // lsr x13, x5, 1 // divide la altura por 2
    // a la coordenada del punto medio le resto la 
    // mitad de la altura
    // sub x13, x2, x13 
    mov x13, x1
   
   //tengo que guardar el valor de x15 cada vez
   // si no siempre oscila entre ser 0 y 1
    triangle_height:
        cbz x5, end_triangle // x5 -> triangle height
        add x15, x15, #2  // la base crece simétricamente
        mov x16, x15
    //  modificar el pixel de inicio para la línea horizontal
        triangle_base:
    //  pintar la línea horizontal necesaria
            cbz x16, end_base
            bl paintPixel
            add x1, x1, 1 // MUEVE UN PIXEL A LA DERECHA
            sub x16, x16, #1 //un pixel menos que pintar
            b triangle_base
        
    // ESTA PINTANDO SIEMPRE UN SOLO PIXEL

        end_base:
            sub x5, x5, #1 // capaz vaya al final de base
            sub x13, x13, #1  // x coordinate
    //      NUEVAS coordenadas para paintpixel
            mov x1, x13
            add x2, x2, #1 // BAJA UN PIXEL
            b triangle_height

        
    end_triangle:

    //------------------
    ldur x1,[sp,40]    // save parameters, temp registers and return pointer in the stack
    ldur x2, [sp,32]
    ldur x5, [sp,24]
    ldur x15, [sp,16]
    ldur x13, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 48      // give back memory to the stack
    br lr 
    //------------------

ifPixelInCirclePaintIT:
    ///////////////////////////////////////////
    //  This procedure checks if the point
    //  (x1,x2) belongs to the circle and
    //  paints it if it does
    //  
    //  parameters:
    //  x10 → colour 
    //  (x1,x2) → current pixel
    //  (x4,x5) → center of the circle
    //  x3 -> r
    ///////////////////////////////////////////
    
    // "(x1-x4)² + (x2-x5)² ≤ x3²" is true if  "(x1,x2) ∈ Circle"

    sub sp, sp, 72
    stur x15,[sp,64]
    stur x14,[sp,56]
    stur x13,[sp,48]
    stur x5, [sp,40]
    stur x4, [sp,32]
    stur x3, [sp,24]
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp]

    mul x15,x3,x3    //r²

    sub x13, x1, x4
    mul x13, x13, x13  // (x1-x4)²

    sub x14, x2, x5 
    mul x14, x14, x14  // (x2-x5)²
    
    add x13, x13, x14  // (x1-x4)² + (x2-x5)²
    cmp x13, x15

    b.gt endPiC

    // paints the pixel (x1,x2)
    bl paintPixel

    endPiC: 
    ldur x15,[sp,64]
    ldur x14,[sp,56]
    ldur x13,[sp,48]
    ldur x5, [sp,40]
    ldur x4, [sp,32]
    ldur x3, [sp,24]
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp]
    add sp, sp, 72
    br lr

paintCircle:
    ///////////////////////////////////////////
    //  circle of radius r, centered in (x0,y0)
    //  x10 -> colour 
    //  x3 -> r
    //  (x4,x5) -> (x0,y0)
    ///////////////////////////////////////////

    sub sp, sp, 88
    stur x10,[sp,80]    // colour 
    stur x9, [sp,72]    // square heigth 
    stur x8, [sp,64]    // square base 
    stur x7, [sp,56]    // temp for x1 
    stur x6, [sp,48]    // diameter
    stur x5, [sp,40]    // y0
    stur x4, [sp,32]    // x0
    stur x3, [sp,24]    // radius
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp]       // return pointer

    // calculate the side length of the minimum square that contains the circle 
    add x6, x3, x3
    
    subs x1, x4, x3
    b.lt setx1_0
    b skip_x1
    setx1_0: 
        add x1, xzr, xzr
    skip_x1:
        subs x2, x5, x3   // (x1,x2) apunto al primer pixel del cuadrado que contiene al circulo
        b.lt setx2_0
        b skip_x2
    setx2_0: 
        add x2, xzr, xzr
    skip_x2:

    mov x7, x1
    mov x9, x6
    loopPC1:
        cbz x9, endLoopPC1
        cmp x2, SCREEN_HEIGH
        b.ge endLoopPC1
        mov x1, x7
        mov x8, x6
        loopPC0:
            cbz x8, endLoopPC0
            cmp x1, SCREEN_WIDTH
            b.ge endLoopPC0
            bl ifPixelInCirclePaintIT
            add x1, x1, 1
            sub x8, x8, 1
            b loopPC0

    endLoopPC0:
        add x2, x2, 1
        sub x9, x9, 1
        b loopPC1
    
    endLoopPC1:
    ldur x10,[sp,80]
    ldur x9, [sp,72]
    ldur x8, [sp,64]
    ldur x7, [sp,56]
    ldur x6, [sp,48] 
    ldur x5, [sp,40]
    ldur x4, [sp,32]    
    ldur x3, [sp,24]   
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp]
    add sp, sp, 88
    ret

paintRoundedRectangle:
    //------------------
    sub sp, sp, 104      
    stur x1, [sp,96]        // starting x coordinate
    stur x2, [sp,88]        // starting y coordinate
    stur x3, [sp,80]        // width
    stur x4, [sp,72]        // height
    stur x5, [sp,64]    
    stur x6, [sp,56]    
    stur x7, [sp,48]    
    stur x8, [sp,40]        // determines how pronounced is the corner's curve
    stur x9, [sp,32]
    stur x10,[sp,24]     
    stur x11,[sp,16]
    stur x12,[sp,8]
    stur lr, [sp,0]
    //------------------

    // a bigger x8 makes the corner's curve less pronounced

    // Initializes registers
    mov x5, xzr
    mov x6, xzr
    mov x9, xzr

    // RECTANGLE SIZE
    //calculates corner's side
    udiv x8, x4, x8     
    add x8, x8, x9      // radius of the circle that shapes the corner
    add x9, x8, x8      // x9 contains the diameter

    mov x11, x3         // saves original base width temporarily

    add x1, x1, x8      // moves radius pixels right
    sub x3, x3, x9      // substracts diameter from the base width 
    mov x7, x3          // horizontal distance between two center points

    bl paintRectangle   // paints horizontal rectangle

    add x2, x2, x8      // moves radius pixels down

    mov x6, x1          // temp: paintCircle expects x coordinate at x4
    mov x5, x2          // paintCircle expects y coordinate at x5

    sub x1, x1, x8      // moves radius pixels left
    mov x3, x11         // restores base width
    sub x4, x4, x9      // substracts diameter pixels from the height
    mov x12, x4         // vertical distance between two center points

    bl paintRectangle   // paints vertical rectangle

    // CORNERS
    mov x3, x8          // x3 now contains the radius
    mov x4, x6          // x4 contains the x coordinate for the center point of the circle
    bl paintCircle      // paints top-left corner
    
    add x4, x4, x7      // x7 contains the horizontal distance between two central points
    bl paintCircle      // paints top-right corner

    add x5, x5, x12     // x12 contains the vertical distance between two central points
    bl paintCircle      // paints bottom-right corner

    sub x4, x4, x7
    bl paintCircle      // paints bottom-left corner

    //------------------
    ldur x1, [sp,96]    
    ldur x2, [sp,88]    
    ldur x3, [sp,80]    
    ldur x4, [sp,72]    
    ldur x5, [sp,64]    
    ldur x6, [sp,56]    
    ldur x7, [sp,48]    
    ldur x8, [sp,40]
    ldur x9, [sp,32]
    ldur x10,[sp,24]    
    ldur x11,[sp,16]
    ldur x12,[sp,8]
    ldur lr, [sp,0]
    add sp, sp, 104     // free memory in the stack
    br lr
    //------------------


.endif
