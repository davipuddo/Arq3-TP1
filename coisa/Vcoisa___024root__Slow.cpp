// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcoisa.h for the primary calling header

#include "Vcoisa__pch.h"

void Vcoisa___024root___ctor_var_reset(Vcoisa___024root* vlSelf);

Vcoisa___024root::Vcoisa___024root(Vcoisa__Syms* symsp, const char* namep)
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vcoisa___024root___ctor_var_reset(this);
}

void Vcoisa___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vcoisa___024root::~Vcoisa___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
