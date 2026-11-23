## Como funciona

Emulador digital de una **planta de primer orden** (el equivalente de un RC pasivo),
hecho en silicio. En cada muestra calcula:

    y[n+1] = y[n] + (x[n] - y[n]) / 2^k        con k = 1..8

que corresponde a H(z) = a / (z - (1 - a)), con a = 2^-k, y a una constante de tiempo
tau = -Ts / ln(1 - 2^-k), aproximadamente 2^k muestras. Solo usa sumas y desplazamientos.

El chip genera su propio **escalon** (0 -> amplitud -> 0, cambia cada 4096 muestras), asi que
no necesita generador de funciones. La respuesta sale en 8 bits por `uo_out`.

## Como probarlo

1. Pon `clk` (por ejemplo 1 MHz) y haz reset.
2. `ui[2:0]` = K (tau = 2^(K+1) muestras). `ui[7:4]` = P: se muestrea cada 2^P ciclos de clk.
   Ejemplo: clk = 1 MHz y P = 8 -> Ts = 256 us.
3. `uio[1:0]` elige la amplitud del escalon: 63, 127, 191 o 255.
4. Modo manual: `ui[3] = 1` y `uio[2]` es el nivel del escalon.
5. Observa `uo_out[7:0]` con un DAC R-2R y un osciloscopio, o capturalo con la tarjeta de TT.
   `uio[7]` (escalon) y `uio[6]` (tick) sirven para sincronizar el osciloscopio.

## Hardware externo

Opcional: DAC R-2R de 8 bits en `uo_out` y osciloscopio.
