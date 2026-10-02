#!/bin/bash

DO_PATH="../code-samples/DO"
FAILED=0

echo "=== Интеграционные тесты для DO ==="
echo ""

# Тест 1: без аргументов (ожидаем код -1)
echo "Тест 1: запуск без аргументов"
$DO_PATH > /dev/null 2>&1
if [ $? -eq 255 ]; then
    echo "  PASS: вернул -1 как и ожидалось"
else
    echo "  FAIL: ожидался код -1, получен $?"
    FAILED=1
fi

# Тест 2: аргумент 1 (Learning to Linux)
echo "Тест 2: аргумент '1'"
RESULT=$($DO_PATH 1)
if [ "$RESULT" = "Learning to Linux" ]; then
    echo "  PASS: вывод совпадает"
else
    echo "  FAIL: ожидалось 'Learning to Linux', получено '$RESULT'"
    FAILED=1
fi

# Тест 3: аргумент 2 (Learning to work with Network)
echo "Тест 3: аргумент '2'"
RESULT=$($DO_PATH 2)
if [ "$RESULT" = "Learning to work with Network" ]; then
    echo "  PASS: вывод совпадает"
else
    echo "  FAIL: ожидалось 'Learning to work with Network', получено '$RESULT'"
    FAILED=1
fi

# Тест 4: аргумент 3 (Learning to Monitoring)
echo "Тест 4: аргумент '3'"
RESULT=$($DO_PATH 3)
if [ "$RESULT" = "Learning to Monitoring" ]; then
    echo "  PASS: вывод совпадает"
else
    echo "  FAIL: ожидалось 'Learning to Monitoring', получено '$RESULT'"
    FAILED=1
fi

# Тест 5: аргумент 4 (Learning to extra Monitoring)
echo "Тест 5: аргумент '4'"
RESULT=$($DO_PATH 4)
if [ "$RESULT" = "Learning to extra Monitoring" ]; then
    echo "  PASS: вывод совпадает"
else
    echo "  FAIL: ожидалось 'Learning to extra Monitoring', получено '$RESULT'"
    FAILED=1
fi

# Тест 6: аргумент 5 (Learning to Docker)
echo "Тест 6: аргумент '5'"
RESULT=$($DO_PATH 5)
if [ "$RESULT" = "Learning to Docker" ]; then
    echo "  PASS: вывод совпадает"
else
    echo "  FAIL: ожидалось 'Learning to Docker', получено '$RESULT'"
    FAILED=1
fi

# Тест 7: аргумент 6 (Learning to CI/CD)
echo "Тест 7: аргумент '6'"
RESULT=$($DO_PATH 6)
if [ "$RESULT" = "Learning to CI/CD" ]; then
    echo "  PASS: вывод совпадает"
else
    echo "  FAIL: ожидалось 'Learning to CI/CD', получено '$RESULT'"
    FAILED=1
fi

# Тест 8: неверный аргумент (ожидаем код -2)
echo "Тест 8: аргумент '99'"
$DO_PATH 99 > /dev/null 2>&1
if [ $? -eq 254 ]; then
    echo "  PASS: вернул -2 как и ожидалось"
else
    echo "  FAIL: ожидался код -2, получен $?"
    FAILED=1
fi

# Тест 9: несколько аргументов
echo "Тест 9: несколько аргументов '1 2 3'"
$DO_PATH 1 2 3 > /dev/null 2>&1
if [ $? -eq 255 ]; then
    echo "  PASS: вернул -1 как и ожидалось"
else
    echo "  FAIL: ожидался код -1, получен $?"
    FAILED=1
fi

# #  Тест 10: аргумент '7'
# echo "Тест 10: аргумент '7'"
# RESULT=$($DO_PATH 6)
# if [ "$RESULT" = "Hello World" ]; then
#     echo "  PASS: вывод совпадает"
# else
#     echo "  FAIL: ожидалось 'Hello World', получено '$RESULT'"
#     FAILED=1
# fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== ИТОГ: ВСЕ ИНТЕГРАЦИОННЫЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО ==="
    exit 0
else
    echo "=== ИТОГ: ИНТЕГРАЦИОННЫЕ ТЕСТЫ ПРОВАЛИЛИСЬ ==="
    exit 1
fi
