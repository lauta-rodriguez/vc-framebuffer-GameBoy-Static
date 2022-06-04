// Grupo:
// Nieto, Manuel
// Kurtz, Lara
// Rodriguez, Lautaro

.include "gameboy.s"

.globl main
main:

	// X0 contiene la direccion base del framebuffer
 	mov x20, x0	// Save framebuffer base address to x20	
	//---------------- CODE HERE ------------------------------------
	
	bl cleanFrameBuffer

	// Todo se calcula en función de las coordenadas del top-left
	// corner del borde de la pantalla (x1, x2) y las dimensiones
	// del borde (x3, x4) que es el cuadrado que incluye al display

	// Para aumentar el tamaño del gameboy modificar (x3, x4)
	// Se va a centrar todo en función de ese rectángulo

	// Para hacer el zoom in quitar el offset y cambiar (x3, x4)
	// a (640,480)

    //Inicializo los registros
    mov x1, xzr		// screen x coordinate
    mov x2, xzr		// screen y coordinate
 	mov x3, xzr		// 
    mov x4, xzr		// 
	mov x13, xzr	// temp
	mov x14, xzr	// temp

	// Parámetros del display border
	add x3, x3, 140		// width
	add x4, x4, 100		// height
    add x13, x13, SCREEN_WIDTH // framebuffer width
    add x14, x14, SCREEN_HEIGH // framebuffer height 

    // center border horizontally in the framebuffer
    sub x13, x13, x3      // substracts base width from framebuffer width 
    lsr x13, x13, 1       // divides it in half
    add x1, x1, x13       // move that amount of pixels right
   
    // center border vertically in the framebuffer
    sub x14, x14, x4      // substracts base height from framebuffer height 
    lsr x14, x14, 1       // divides it in half
    add x2, x2, x14       // move that amount of pixels right

	// Agrego un offset negativo de 10 pixeles a la dimensión 
	// vertical para que entre la animación del cartucho
	// smoothly move the gameboy upwards 10 pixels and thennn
	// zoom in 
	sub x2, x2, 10

	bl drawCartridge
    bl drawBase
	bl drawScreen
	bl drawButtons

infloop: b infloop
