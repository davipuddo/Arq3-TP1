// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VCOISA__SYMS_H_
#define VERILATED_VCOISA__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vcoisa.h"

// INCLUDE MODULE CLASSES
#include "Vcoisa___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vcoisa__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vcoisa* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vcoisa___024root               TOP;

    // CONSTRUCTORS
    Vcoisa__Syms(VerilatedContext* contextp, const char* namep, Vcoisa* modelp);
    ~Vcoisa__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
