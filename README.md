# 📘 Trabalho Prático — Arquitetura de Computadores

Este repositório contém a implementação e o relatório de um projeto acadêmico voltado ao estudo de **arquitetura de processadores**, com foco em um processador baseado na arquitetura **RISC-V** com pipeline de cinco estágios.

## 🎯 Objetivo

O objetivo deste trabalho é explorar, na prática, conceitos fundamentais de execução de instruções em processadores modernos, especialmente:

* Execução em **pipeline**
* Controle de fluxo com instruções de desvio (branch)
* Tratamento de dependências entre instruções (**hazards**)

A proposta consiste em evoluir um modelo simplificado de processador, adicionando mecanismos que garantam a execução correta e eficiente de programas.

## ⚙️ O que foi desenvolvido

O trabalho foi dividido em três etapas principais:

### 1. Controle de Fluxo

Implementação de instruções de desvio condicional (branch), permitindo alterar o fluxo de execução de programas.

### 2. Execução de Programa de Teste

Execução e ajuste de um programa em assembly, evidenciando problemas causados por dependências entre instruções.

### 3. Tratamento de Hazards

Implementação de mecanismos que permitem ao processador lidar automaticamente com conflitos e dependências, garantindo a execução correta sem intervenção manual no código.

## 👥 Autores

* Antônio Drumond Cota de Souza
* Davi Ferreira Puddo
* Gabriel Valedo Batista Silva
* Mateus Henrique Medeiros Diniz
* Raquel de Parde Motta

## 📄 Relatório

O relatório completo do trabalho está disponível neste repositório e descreve o processo de desenvolvimento, as decisões tomadas e os conceitos envolvidos.
