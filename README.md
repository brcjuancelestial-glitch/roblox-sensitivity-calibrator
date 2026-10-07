# Roblox Sensitivity Calibrator

Este repositório contém um protótipo educacional para a ideia de padronizar sensibilidade de câmera em Roblox.

Importante:
- Lua dentro do Roblox não consegue ler os `counts` brutos do mouse do Windows.
- Não é possível interceptar o input do mouse antes do Roblox receber o evento usando apenas Lua no ambiente do jogo.
- A parte "real" do projeto precisa de um programa externo em C++/WinAPI usando Raw Input.

Desta forma, este repositório separa a ideia em duas partes:

1. Prototipo em Lua para Roblox
   - simula a lógica de calibração
   - mede a rotação da câmera
   - calcula um fator de correção
   - aplica correção no movimento

2. Prova de conceito em C++ para Windows
   - lê eventos de mouse em nível de sistema via Raw Input
   - mede `dx`, `dy` e relativo movement
   - prepara o caminho para multiplicar os movimentos antes do jogo receber

## Estrutura

- `roblox/SensitivityCalibrationPrototype.lua` — LocalScript para testar a lógica de calibração em Roblox.
- `cpp/RawInputMouseReader.cpp` — exemplo em C++ para capturar mouse bruto no Windows.
- `README.md` — documentação do projeto.

## Como usar o protótipo em Roblox

1. Crie um `LocalScript` em `StarterPlayer > StarterPlayerScripts`.
2. Cole o conteúdo de `roblox/SensitivityCalibrationPrototype.lua`.
3. Pressione `C` para iniciar calibração.
4. Aguarde a rotação de 360°.
5. O script calcula o fator de correção e aplica a compensação sobre os movimentos.

## Limitação real

A lógica de alterar input antes do jogo receber é uma tarefa de nível do sistema operacional. Isso exige um processo externo, não um script de Roblox.

O projeto correto seria:

- `C++` + `WinAPI` + `Raw Input` para medir e alterar o mouse
- `Roblox` apenas para teste visual e validação da lógica da câmera

## O que esse protótipo demonstra

- referência de sensibilidade
- calculo do fator de correção
- giro de 360° para calibrar
- acumulador residual para preservar precisão decimal
- aplicação da correção em tempo real

## Observação

Esse código é um protótipo didático, não um bypass de proteção de jogo.
Ele serve para entender a matemática e a arquitetura da solução.
