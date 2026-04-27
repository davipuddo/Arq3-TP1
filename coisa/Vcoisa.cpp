// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vcoisa__pch.h"

//============================================================
// Constructors

Vcoisa::Vcoisa(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vcoisa__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vcoisa::Vcoisa(const char* _vcname__)
    : Vcoisa(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vcoisa::~Vcoisa() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vcoisa___024root___eval_debug_assertions(Vcoisa___024root* vlSelf);
#endif  // VL_DEBUG
void Vcoisa___024root___eval_static(Vcoisa___024root* vlSelf);
void Vcoisa___024root___eval_initial(Vcoisa___024root* vlSelf);
void Vcoisa___024root___eval_settle(Vcoisa___024root* vlSelf);
void Vcoisa___024root___eval(Vcoisa___024root* vlSelf);

void Vcoisa::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vcoisa::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vcoisa___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vcoisa___024root___eval_static(&(vlSymsp->TOP));
        Vcoisa___024root___eval_initial(&(vlSymsp->TOP));
        Vcoisa___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vcoisa___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vcoisa::eventsPending() { return false; }

uint64_t Vcoisa::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vcoisa::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vcoisa___024root___eval_final(Vcoisa___024root* vlSelf);

VL_ATTR_COLD void Vcoisa::final() {
    Vcoisa___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vcoisa::hierName() const { return vlSymsp->name(); }
const char* Vcoisa::modelName() const { return "Vcoisa"; }
unsigned Vcoisa::threads() const { return 1; }
void Vcoisa::prepareClone() const { contextp()->prepareClone(); }
void Vcoisa::atClone() const {
    contextp()->threadPoolpOnClone();
}
