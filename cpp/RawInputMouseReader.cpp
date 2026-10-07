#include <windows.h>
#include <iostream>
#include <iomanip>

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    if (uMsg == WM_INPUT) {
        UINT dwSize = 0;
        GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam), RID_INPUT, NULL, &dwSize, sizeof(RAWINPUTHEADER));

        if (dwSize == 0) {
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
        }

        std::unique_ptr<BYTE[]> buffer(new BYTE[dwSize]);
        RAWINPUT* raw = reinterpret_cast<RAWINPUT*>(buffer.get());

        if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam), RID_INPUT, raw, &dwSize, sizeof(RAWINPUTHEADER)) == dwSize) {
            if (raw->header.dwType == RIM_TYPEMOUSE) {
                const RAWMOUSE& mouse = raw->data.mouse;

                if (mouse.usFlags == MOUSE_MOVE_RELATIVE) {
                    LONG dx = mouse.lLastX;
                    LONG dy = mouse.lLastY;

                    std::cout << "dx=" << dx << " | dy=" << dy << "\n";
                }
            }
        }
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

int main() {
    const wchar_t* className = L"MouseInputClass";

    WNDCLASSEX wc = {};
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = className;

    if (!RegisterClassEx(&wc)) {
        std::cerr << "RegisterClassEx failed\n";
        return 1;
    }

    HWND hwnd = CreateWindowEx(
        0,
        className,
        L"Mouse Raw Input Test",
        0,
        CW_USEDEFAULT, CW_USEDEFAULT,
        400, 200,
        nullptr, nullptr,
        GetModuleHandle(nullptr),
        nullptr
    );

    if (!hwnd) {
        std::cerr << "CreateWindowEx failed\n";
        return 1;
    }

    RAWINPUTDEVICE rid[1];
    rid[0].usUsagePage = 0x01;
    rid[0].usUsage = 0x02;
    rid[0].dwFlags = 0;
    rid[0].hwndTarget = hwnd;

    if (RegisterRawInputDevices(rid, 1, sizeof(rid[0])) == FALSE) {
        std::cerr << "RegisterRawInputDevices failed\n";
        return 1;
    }

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

/*
    Observacao:
    Este e um exemplo minimo de leitura de mouse bruto no Windows usando Raw Input.
    Em um projeto real voce usaria isso para medir dx, registrar counts e ajustar
    o multiplicador antes do jogo receber o input.
*/
