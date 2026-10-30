require 'io/console'

W, H = 35, 15
# 壁(#)で埋めたマップを作り、ランダムウォーク(穴掘り)で床(.)を作る
map = Array.new(H) { Array.new(W, '#') }
cx, cy = W / 2, H / 2
250.times do
  map[cy][cx] = '.'
  dx, dy = [[1,0], [-1,0], [0,1], [0,-1]].sample
  cx = (cx + dx).clamp(1, W - 2)
  cy = (cy + dy).clamp(1, H - 2)
end

px, py = W / 2, H / 2               # プレイヤー座標
gx, gy = cx, cy                     # ゴール座標（穴掘りの終点）
map[gy][gx] = 'G'
coins = 5.times.map {               # コイン($)を床の上にランダム配置
  loop { x, y = rand(W), rand(H); break [x, y] if map[y][x] == '.' }
}
score = 0

print "\e[2J\e[?25l"
loop do
  # 画面描画（プレイヤーからの距離が4以内のマスだけ見える視界システム）
  print "\e[H Coins: #{score}/5 | WASD: Move, Q: Quit\n"
  H.times do |y|
    W.times do |x|
      dist = Math.hypot(px - x, py - y)
      if x == px && y == py
        print "\e[32m@\e[0m"        # プレイヤー（緑）
      elsif dist > 4.5
        print " "                   # 視界外は暗闇
      elsif coins.include?([x, y])
        print "\e[33m$\e[0m"        # コイン（黄色）
      elsif map[y][x] == 'G'
        print "\e[36mG\e[0m"        # ゴール（水色）
      else
        print map[y][x]
      end
    end
    puts
  end

  if px == gx && py == gy && score == 5
    puts "\e[?25hCongratulations! Dungeon Cleared!"
    break
  end

  # キー入力待ち（1文字入力されるまでピタッと止まる）
  key = STDIN.getch.downcase
  break if key == 'q'
  nx, ny = px, py
  nx -= 1 if key == 'a'; nx += 1 if key == 'd'
  ny -= 1 if key == 'w'; ny += 1 if key == 's'

  # 壁でなければ移動し、コインがあれば拾う
  if map[ny][nx] != '#'
    px, py = nx, ny
    score += 1 if coins.delete([px, py])
  end
end
print "\e[?25h"