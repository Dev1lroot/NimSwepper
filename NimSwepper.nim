import os, terminal, random, wxkb, math, times, truecolors

type
    BlockStatus = enum
        OPEN, CLOSED, MARKED
    GameStyle = enum
        EARTH, MARS, MOON, JUPITER
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
    Game = object
        x: int
        y: int
        w: int
        h: int
        matrix: seq[Block]
        level: int
        start: float
        bombs: int
        player: Player
        style: GameStyle

# Отвечает за вывод времени (сверху)
proc timeRenderer(game: Game) =
    setCursorPos(game.x, 1)
    stdout.write("Время: " & $floor(cpuTime() - game.start) )

# Отвечает за вывод игрока (решетки)
proc playerRenderer(game: var Game, player: var Player) =
    setCursorPos(game.x + player.x, game.y + player.y)
    stdout.write("\x1b[38;2;255;255;255m#\x1b[0m")

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

# Заполняем матрицу
proc generateLevel(game: var Game) =

    # Обнуляем матрицу
    game.matrix = @[]

    # Заполняем матрицу бомбами
    for x in 0..game.w:
        for y in 0..game.h:
            var b: Block
            b.status = CLOSED
            b.value = (if rand(10) == 10: "*" else: "-")
            b.x = x
            b.y = y
            b.surfaceDecoration = ["V","v","l","i","_","-"," ","w","W",".",","][rand(10)]
            b.cavernDecoration  = ["^","-","l","_"," ","\\","/"][rand(6)]
            game.matrix.add b

    # Заполняем матрицу цифрами вокруг бомб
    for i in 0..game.matrix.len-1:
        if game.matrix[i].value != "*":
            var bombsNearby = game.matrix.countBombs(game.matrix[i].x, game.matrix[i].y);
            if bombsNearby > 0: game.matrix[i].value = $(bombsNearby)

# Рендерим выбранный блок
proc renderBlock(game: var Game, b: Block) =
    setCursorPos(game.x + b.x, game.y + b.y)
    
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

        if game.style == EARTH:

            setBackgroundColor(0,color,0)
            if b.status == MARKED:
                setForegroundColor(255,0,0)
                stdout.write("X\x1b[0m")
            else:
                var surfaceColor = 80 + rand(128)
                setForegroundColor(0,surfaceColor,0)
                stdout.write(b.surfaceDecoration & "\x1b[0m")

        if game.style == MOON:

            #color = color div 3

            setBackgroundColor(color,color,color)
            if b.status == MARKED:
                setForegroundColor(255,0,0)
                stdout.write("X\x1b[0m")
            else:
                var surfaceColor = 80 + rand(128)
                setForegroundColor(surfaceColor,surfaceColor,surfaceColor)
                stdout.write(b.surfaceDecoration & "\x1b[0m")

        if game.style == MARS:

            #color = color div 3

            setBackgroundColor(color+48,30,0)
            if b.status == MARKED:
                setForegroundColor(0,255,0)
                stdout.write("X\x1b[0m")
            else:
                var surfaceColor = 80 + rand(128)
                setForegroundColor(surfaceColor,20,0)
                stdout.write(b.surfaceDecoration & "\x1b[0m")
        
        if game.style == JUPITER: # W.I.P

            var red   = 90
            var green = (toInt(sin(toFloat(b.y))*5)*5) + 70
            var blue = (toInt(sin(toFloat(b.y))*5)*5) + 30

            setBackgroundColor(red,green,blue)
            if b.status == MARKED:
                setForegroundColor(0,0,255)
                stdout.write("X\x1b[0m")
            else:
                setForegroundColor(red+rand(32),green+rand(32),blue)
                stdout.write(b.surfaceDecoration & "\x1b[0m")

# Отрисовка всей карты
proc renderMap(game: var Game) =
    for item in game.matrix:
        game.renderBlock(item)

# Пересоздаем игру
proc reload(game: var Game) =
    game.generateLevel()
    game.start = cpuTime()
    game.renderMap()
    game.playerRenderer(game.player)

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

# Получить все бомбы
proc getBombs(game: Game): seq[Block] =
    var output: seq[Block]
    for b in game.matrix:
        if b.value == "*":
            output.add(b)
    return output

# Подсчитать количество открытых блоков
proc countOpenBlocks(matrix: seq[Block]): int =
    var count = 0
    for b in matrix:
        if b.status == OPEN: count += 1
    return count

# Взрыв бомбы
proc detonateBlock(game: var Game, bomb: Block) =

    # Если обьект бомба
    if bomb.value == "*":

        # Открываем текущую бомбу
        var thebomb = game.matrix.getBlock(bomb.x,bomb.y)
        thebomb.status = OPEN
        game.matrix.updateBlock(thebomb)
        game.renderBlock(thebomb)

        sleep(200)

        # Плавно активируем все бимбы в радиусе
        for radius in 1..20:

            sleep(100)

            # Получаем область вокруг блока
            var blocks = game.matrix.getNearbyBlocks(bomb.x, bomb.y, radius)
        
            # Открываем все бомбы
            for b in blocks:
                var b = b
                # Если это неоткрытая бомба
                if b.status != OPEN and b.value == "*":
                    b.status = OPEN
                    game.matrix.updateBlock(b)
                    game.renderBlock(b)

        sleep(200)

        # Плавно уничтожаем все блоки вокруг бомб
        for radius in 1..game.w:

            sleep(5)

            # Получаем область вокруг блока
            var blocks = game.matrix.getNearbyBlocks(bomb.x, bomb.y, radius)
        
            # Открываем все блоки
            for b in blocks:
                if b.status != OPEN or b.value != "-":
                    var o = b
                    o.status = OPEN
                    o.value  = "-"
                    game.matrix.updateBlock(o)
                    game.renderBlock(o)

        # # Активируем бомбы в большем радиусе
        # var big = game.matrix.getNearbyBlocks(bomb.x, bomb.y, 4)

        # # Взрываем все блоки рядом
        # for b in big:
        #     if b.status != OPEN and b.value == "*":
        #         var tb = b
        #         tb.status = OPEN
        #         game.matrix.updateBlock(tb)
        
        # for b in big:
        #     if b.status == OPEN and b.value == "*":
        #         game.detonateBlock(b)
        game.level = 1;
        game.reload();

# Открыть блок
proc openBlock(game: var Game, x: int, y: int) =
    
    var b = game.matrix.getBlock(x, y)
    
    # Если блок закрыт
    if b.status == CLOSED:

        # Открываем блок
        b.status = OPEN
        game.matrix.setBlock(x,y,b)

        # Если блок был пустым то рекурсивно открываем все вокруг
        if b.value == "-":

            # Получаем область вокруг блока
            var blocks = game.matrix.getNearbyBlocks(x, y, 1)
            
            # Проходимся по блокам вокруг
            for b in blocks:
                # Если блок закрытый
                if b.status == CLOSED or b.status == MARKED:
                    game.openBlock(b.x,b.y)
                    game.renderBlock(game.matrix.getBlock(b.x, b.y))
        
        # Если блок это бомба
        if b.value == "*":
            game.detonateBlock(b);

proc drawFrame(x1,y1,x2,y2: int) = 

    # Рисуем верхнюю линию
    setCursorPos(x1,y1)
    for x in x1..x2:
        stdout.write("\x1b[38;2;0;0;255m═\x1b[0m")

    # Рисуем нижнюю линию
    setCursorPos(x1,y2)
    for x in x1..x2:
        stdout.write("\x1b[38;2;0;0;255m═\x1b[0m")

    # Рисуем левую линию
    for y in y1..y2:
        setCursorPos(x1,y)
        stdout.write("\x1b[38;2;0;0;255m║\x1b[0m")

    # Рисуем правую линию
    for y in y1..y2:
        setCursorPos(x2,y)
        stdout.write("\x1b[38;2;0;0;255m║\x1b[0m")

    # Расставляем углы
    setCursorPos(x1,y1)
    stdout.write("\x1b[38;2;0;0;255m╔\x1b[0m")
    setCursorPos(x2,y1)
    stdout.write("\x1b[38;2;0;0;255m╗\x1b[0m")
    setCursorPos(x1,y2)
    stdout.write("\x1b[38;2;0;0;255m╚\x1b[0m")
    setCursorPos(x2,y2)
    stdout.write("\x1b[38;2;0;0;255m╝\x1b[0m")

# Отвечает за вывод инфы (снизу)
proc infoRenderer(game: var Game) =
    setCursorPos(game.x, game.h + game.y + 2)
    stdout.write("Открыто: " & $game.matrix.countOpenBlocks() & " из " & $game.matrix.len & " Бомб: " & $game.getBombs().len & " Уровень: " & $game.level & "  ")

# Контроллер управления игроком
proc playerHandler(game: var Game, player: var Player) =
    while true:
        var ch = wxkb.detect()
        
        # Открыть клетку через Enter || Space
        if ch == 32 or ch == 13:
            game.openBlock(game.player.x, game.player.y)

        # Маркировать клетку на X
        if ch == 120:
            game.matrix.checkBlock(game.player.x, game.player.y)

        # Рендерим блок, скорее всего мы с него уходим или активируем его
        if ch != -1:
            var b = game.matrix.getBlock(game.player.x, game.player.y)
            game.renderBlock(b)

        # Управление WASD
        if ch == 119: game.player.y -= 1
        if ch == 115: game.player.y += 1
        if ch == 97:  game.player.x -= 1
        if ch == 100: game.player.x += 1
        
        # Ограничиваем игрока в пределах карты
        if game.player.x > game.w: game.player.x = 0
        if game.player.y > game.h: game.player.y = 0
        if 0 > game.player.x: game.player.x = game.w
        if 0 > game.player.y: game.player.y = game.h

        # Если челикс чето сделал то ререндерим инфу
        if ch != -1:
            # Рендерим инфу
            game.infoRenderer()

            # Рендерим игрока
            game.playerRenderer(game.player)

            # Проверяем переход на следующий уровень (если остались ток бомбы)
            if game.matrix.len - game.matrix.countOpenBlocks() == game.getBombs().len:
                # Переходим на второй уровень
                game.level += 1
                game.reload()
        
        # Время рендерим всегда
        game.timeRenderer()

# Создаем игровую зону
var game = Game(
    x: 2,
    y: 3,
    w: terminalWidth() - 4,
    h: terminalHeight() - 6,
    level: 1,
    bombs: 30,
    start: cpuTime(),
    style: [EARTH,MARS,JUPITER,MOON][0]
)
game.generateLevel()

# Создаем игрока и кидаем его в центр поля
game.player.x = game.w div 2
game.player.y = game.h div 2

# Рисуем все
eraseScreen()
enableTrueColors()

drawFrame(game.x-1, game.y-1, game.x + game.w + 1, game.y + game.h + 1)

game.renderMap();

# Пререндер персонажа и его запуск
game.playerRenderer(game.player)
game.playerHandler(game.player)