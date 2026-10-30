require 'io/console'

W, H = 20, 12
# 地形データ（表示アイコン、消費SAN値、名称）
TERRAINS = {
  plain:   { icon: "🟩", cost: 2,  name: "草原" },
  forest:  { icon: "🌲", cost: 5,  name: "密林" },
  swamp:   { icon: "🟫", cost: 9,  name: "泥沼" },
  mountain:{ icon: "⛰️", cost: 15, name: "険しい山" },
  port:    { icon: "⚓", cost: 0,  name: "開拓港(拠点)" },
  village: { icon: "🏕️", cost: 0,  name: "原住民の集落" }
}

# マップ生成（距離に応じて危険な地形が増える＆奥地に集落を配置）
map = Array.new(H) do |y|
  Array.new(W) do |x|
    r = rand(100)
    r < 50 ? :plain : (r < 75 ? :forest : (r < 90 ? :swamp : :mountain))
  end
end
map[1][1] = :port
[[6, 3], [4, 9], [13, 4], [17, 9], [18, 2]].each { |vx, vy| map[vy][vx] = :village }

# プレイヤー初期状態
px, py = 1, 1
san, max_san = 100, 100
cash = 500
cargo = { "医療品" => 0, "鉄の農具" => 0, "嗜好品" => 0 }
BASE_PRICES = { "医療品" => 50, "鉄の農具" => 120, "嗜好品" => 300 }
visited = Array.new(H) { Array.new(W, false) }
msg = "開拓港(⚓)で物資を仕入れ、未開の集落(🏕️)へ届けて交易しよう！"

# 交易画面（拠点からの距離 dist が遠い集落ほど買取価格が跳ね上がる！）
def open_trade(place_type, dist, cash, san, max_san, cargo)
  cursor = 0
  keys = BASE_PRICES.keys
  # 港なら1.0倍（定価）、集落なら距離に応じて 1.4倍 〜 3.5倍以上で売れる！
  mult = (place_type == :port) ? 1.0 : (1.2 + dist * 0.12).round(2)

  loop do
    print "\e[H\e[2J==========================================================\n"
    title = (place_type == :port) ? "⚓ 開拓港（仕入れ・休息）" : "🏕️ 奥地の集落（距離:#{dist.to_i} / 買取倍率: \e[31mx#{mult}\e[0m）"
    puts " 【#{title}】 所持金: \e[33m$#{cash}\e[0m | SAN値: \e[36m#{san}/#{max_san}\e[0m"
    puts "=========================================================="
    keys.each_with_index do |k, i|
      mark = (i == cursor) ? "👉" : "  "
      price = (BASE_PRICES[k] * mult).to_i
      puts " #{mark} #{k.ljust(6)} | 取引価格: $%-5d | 所持数: %d個" % [price, cargo[k]]
    end
    puts "----------------------------------------------------------"
    puts " [W/S] 選択  [D] 買う  [A] 売る  [R] 宿で休む($50でSAN全快)"
    puts " [Space / Enter] 交易を終えてマップに戻る"

    k = STDIN.getch.downcase
    item = keys[cursor]
    price = (BASE_PRICES[item] * mult).to_i

    case k
    when 'w' then cursor = (cursor - 1) % keys.size
    when 's' then cursor = (cursor + 1) % keys.size
    when 'd'
      if cash >= price
        cash -= price; cargo[item] += 1
      end
    when 'a'
      if cargo[item] > 0
        cash += price; cargo[item] -= 1
      end
    when 'r'
      if cash >= 50 && san < max_san
        cash -= 50; san = max_san
      end
    when ' ', "\r", "\n" then break
    end
  end
  [cash, san]
end

print "\e[2J\e[?25l"
loop do
  # 周囲2マスの視界を開く
  (-2..2).each do |dy|
    (-2..2).each do |dx|
      ny, nx = py + dy, px + dx
      visited[ny][nx] = true if ny.between?(0, H-1) && nx.between?(0, W-1) && Math.hypot(dx, dy) <= 2.3
    end
  end

  # マップ描画
  print "\e[H==========================================================\n"
  puts " 💰 所持金: \e[33m$%-6d\e[0m | 🧠 SAN値(正気度): \e[36m%3d / %3d\e[0m\e[K" % [cash, san, max_san]
  puts " 📦 積荷: 医療品(#{cargo['医療品']}) 農具(#{cargo['鉄の農具']}) 嗜好品(#{cargo['嗜好品']})\e[K"
  puts "=========================================================="
  H.times do |y|
    print " "
    W.times do |x|
      if x == px && y == py
        print "🤠"
      elsif visited[y][x]
        print TERRAINS[map[y][x]][:icon]
      else
        print "🌫️" # 未踏の霧
      end
    end
    puts "\e[K"
  end
  puts "----------------------------------------------------------"
  puts " 💬 #{msg}\e[K"
  puts " [WASD] 移動  [Space] 拠点/集落で交易する  [Q] 終了\e[K"

  if san <= 0
    puts "\n\e[31m【発狂・遭難】正気度を失い、調査隊は未開の森へ消えた… (GAME OVER)\e[0m\e[?25h"
    break
  end

  key = STDIN.getch.downcase
  break if key == 'q'

  if key == ' ' && [:port, :village].include?(map[py][px])
    dist = Math.hypot(px - 1, py - 1)
    cash, san = open_trade(map[py][px], dist, cash, san, max_san, cargo)
    print "\e[2J"
    msg = "交易を終えた。次の目的地を目指そう。"
    next
  end

  nx, ny = px, py
  nx -= 1 if key == 'a'; nx += 1 if key == 'd'
  ny -= 1 if key == 'w'; ny += 1 if key == 's'

  if nx.between?(0, W-1) && ny.between?(0, H-1) && [nx, ny] != [px, py]
    px, py = nx, ny
    t = TERRAINS[map[py][px]]
    san -= t[:cost]
    msg = "#{t[:name]}を進んだ (SAN値 -#{t[:cost]})。"
    msg += " \e[32m[Spaceキーで交易可能！]\e[0m" if [:port, :village].include?(map[py][px])
  end
end
print "\e[?25h"