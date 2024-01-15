/*
    Summary:    Communications package file
*/

package com;
    typedef struct packed { logic [3:0] red, green, blue; } color;

    typedef enum int unsigned {NONE, EVEN, ODD, MARK, SPACE} parity;
endpackage
