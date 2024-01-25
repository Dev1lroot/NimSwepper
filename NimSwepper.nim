import os, terminal, random, sequtils, parseutils, wxkb, math

type
    BlockStatus = enum
        OPEN, CLOSED, MARKED
    Block = object
        value: string
        status: BlockStatus
        x: int
        y: int
        surfaceDecoration: string 
        cavernDecoration: string
    Player = object
        x: int 
        y: int
        state: int

# Получить 9 клеток вокруг
proc getNearbyBlocks(matrix: var seq[Block], x: int, y: int, radius: int = 1): seq[Block] =
    var output: seq[Block]
    for item in matrix:
        if item.x >= x-radius and x+radius >= item.x:
            if item.y >= y-radius and y+radius >= item.y:
                output.add item
    return output

# Функция подсчета бомб
proc countBombs(matrix: var seq[Block], x: int, y: int): int =
    var bombs = 0;
    var blocks = matrix.getNearbyBlocks(x, y, 1)
    for item in blocks:
        if item.value == $"*": bombs = bombs + 1
    return bombs

# Функция для определения ввода мышью
proc getCursorPos(): tuple [x,y: int] =
    if isatty(stdout):
        stdout.write("\\E[6n")
    var
        x, y: int = 0
        c = getch()
    c = getch()
    c = getch()
    while c != ';':
        y = y*10 + (int(c) - int('0'))
        c = getch()
    while c != ';':
        x = x*10 + (int(c) - int('0'))
        c = getch()
    return (x,y)

# Задаем блок по координатам
proc setBlock(matrix: var seq[Block], x: int ,y: int, b: Block) =
    for i in 0..matrix.len-1:
        if matrix[i].x == x and matrix[i].y == y: matrix[i] = b

# Обновляем блок
proc updateBlock(matrix: var seq[Block], b: Block) =
    for i in 0..matrix.len-1:
        if matrix[i].x == b.x and matrix[i].y == b.y: matrix[i] = b

# Получаем блок по координатам
proc getBlock(matrix: seq[Block], x: int ,y: int): Block =
    for item in matrix:
        if item.x == x and item.y == y: return item

# Поставить метку на блоке
proc checkBlock(matrix: var seq[Block], x: int, y: int) =
    var b = matrix.getBlock(x, y)
    if b.status == CLOSED:
        b.status = MARKED
        matrix.updateBlock(b)
    elif b.status == MARKED:
        b.status = CLOSED
        matrix.updateBlock(b)

# Рендерим выбранный блок
proc renderBlock(b: Block) =
    setCursorPos(b.x, b.y)
    
    if b.status == OPEN:
        var prefix = "\x1b[0m";
        var symbol = b.value;

        if b.value == "1": prefix = "\x1b[38;2;0;255;0m"
        if b.value == "2": prefix = "\x1b[38;2;255;216;0m"
        if b.value == "3": prefix = "\x1b[38;2;255;106;0m"
        if b.value == "4": prefix = "\x1b[38;2;255;0;0m"
        if b.value == "5": prefix = "\x1b[38;2;178;0;255m"
        if b.value == "6": prefix = "\x1b[38;2;0;0;255m"
        if b.value == "*": prefix = "\x1b[38;2;255;0;0m"
        if b.value == "-": prefix = "\x1b[38;2;32;32;32m"
        if b.value == "-": symbol = b.cavernDecoration

        stdout.write(prefix & symbol & "\x1b[0m")

    else:

        var color = 48
        if b.x / 2 == floor(b.x / 2) and b.y / 2 == floor(b.y / 2): color += 32
        if b.x / 2 != floor(b.x / 2) and b.y / 2 != floor(b.y / 2): color += 32
        
        if b.status == MARKED:
            stdout.write("\x1b[48;2;0;" & $color & ";0m\x1b[38;2;255;0;0mX\x1b[0m")
        else:
            var surfaceColor = 80 + rand(128)
            stdout.write("\x1b[48;2;0;" & $color & ";0m\x1b[38;2;0;" & $surfaceColor & ";0m" & b.surfaceDecoration & "\x1b[0m")

# Подсчитать количество открытых блоков
proc countOpenBlocks(matrix: seq[Block]): int =
    var count = 0
    for b in matrix:
        if b.status == OPEN: count += 1
    return count

# Взрыв бомбы
proc detonate(matrix: var seq[Block], bomb: Block) =

    # Если обьект бомба
    if bomb.value == "*":

        # Открываем текущую бомбу
        var thebomb = matrix.getBlock(bomb.x,bomb.y)
        thebomb.status = OPEN
        matrix.updateBlock(thebomb)
        thebomb.renderBlock()

        sleep(200)

        # Получаем область вокруг блока
        var blocks = matrix.getNearbyBlocks(bomb.x, bomb.y, 2)
        
        # Взрываем все блоки рядом
        for b in blocks:
            var o = b
            o.status = OPEN
            o.value = "-"
            matrix.updateBlock(o)
            o.renderBlock()

        # Активируем бомбы в большем радиусе
        var big = matrix.getNearbyBlocks(bomb.x, bomb.y, 4)

        # Взрываем все блоки рядом
        for b in big:
            if b.status != OPEN and b.value == "*":
                sleep(100)
                matrix.detonate(b)

# Открыть блок
proc openBlock(matrix: var seq[Block], x: int, y: int) =
    
    var b = matrix.getBlock(x, y)
    
    # Если блок закрыт
    if b.status == CLOSED:

        # Открываем блок
        b.status = OPEN
        matrix.setBlock(x,y,b)

        # Если блок был пустым то рекурсивно открываем все вокруг
        if b.value == "-":

            # Получаем область вокруг блока
            var blocks = matrix.getNearbyBlocks(x, y, 1)
            
            # Проходимся по блокам вокруг
            for b in blocks:
                # Если блок закрытый
                if b.status == CLOSED or b.status == MARKED:
                    matrix.openBlock(b.x,b.y)
                    renderBlock(matrix.getBlock(b.x, b.y))
        
        # Если блок это бомба
        if b.value == "*":
            matrix.detonate(b);

# Заполняем матрицу
proc fill(matrix: var seq[Block], width: int, height: int) =

    # Заполняем матрицу бомбами
    for x in 0..width:
        for y in 0..height:
            var b: Block
            b.status = CLOSED
            b.value = (if rand(10) == 10: "*" else: "-")
            b.x = x
            b.y = y
            b.surfaceDecoration = ["V","v","l","i","_","-"," ","w","W",".",","][rand(10)]
            b.cavernDecoration  = ["^","-","l","_"," ","\\","/"][rand(6)]
            matrix.add b

    # Заполняем матрицу цифрами вокруг бомб
    for i in 0..matrix.len-1:
        if matrix[i].value != "*":
            var bombsNearby = matrix.countBombs(matrix[i].x, matrix[i].y);
            if bombsNearby > 0: matrix[i].value = $(bombsNearby)


# Создаем игровую зону
var width = terminalWidth() - 1
var height = terminalHeight() - 2
var matrix: seq[Block]
matrix.fill(width, height)

# Создаем игрока и кидаем его в центр поля
var player: Player
player.x = width div 2
player.y = height div 2

# Рисуем все
eraseScreen()
enableTrueColors()

for item in matrix:
    renderBlock(item)


# Пререндер персонажа
setCursorPos(player.x, player.y)
stdout.write("\x1b[38;2;255;255;255m#\x1b[0m")

while true:
    var ch = wxkb.detect()
    
    # Открыть клетку через Enter || Space
    if ch == 32 or ch == 13:
        matrix.openBlock(player.x, player.y)

    # Маркировать клетку на X
    if ch == 120:
        matrix.checkBlock(player.x, player.y)

    # Рендерим блок, скорее всего мы с него уходим или активируем его
    if ch != -1:
        var b = matrix.getBlock(player.x, player.y)
        b.renderBlock()

    # Управление WASD
    if ch == 119: player.y -= 1
    if ch == 115: player.y += 1
    if ch == 97:  player.x -= 1
    if ch == 100: player.x += 1
    
    # Ограничиваем игрока в пределах карты
    if player.x > width: player.x = 0
    if player.y > height: player.y = 0
    if 0 > player.x: player.x = width
    if 0 > player.y: player.y = height

    if ch != -1:
        setCursorPos(0, height + 1)
        stdout.write("Открыто: " & $matrix.countOpenBlocks() & " из " & $matrix.len & " Бомб: " & " Клавиши: WASD/Enter/Space/X Нажато: " & $ch & "     ")
        setCursorPos(player.x, player.y)
        stdout.write("\x1b[38;2;255;255;255m#\x1b[0m")