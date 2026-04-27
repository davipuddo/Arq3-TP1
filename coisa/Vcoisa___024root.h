// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vcoisa.h for the primary calling header

#ifndef VERILATED_VCOISA___024ROOT_H_
#define VERILATED_VCOISA___024ROOT_H_  // guard

#include "verilated.h"


class Vcoisa__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vcoisa___024root final {
  public:

    // INTERNAL VARIABLES
    Vcoisa__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vcoisa___024root(Vcoisa__Syms* symsp, const char* namep);
    ~Vcoisa___024root();
    VL_UNCOPYABLE(Vcoisa___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
