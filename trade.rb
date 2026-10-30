require 'io/console'

# 商品データ（名前、基準価格、現在の価格、所持数、取得単価の合計用）
ITEMS = [
  { name: "1. 穀物  ", base: 100,  price: 100,  owned: 0, cost: 0 },
  { name: "2. 鉄鉱石 ", base: 500,  price: 500,  owned: 0, cost: 0 },
  { name: "3. 香辛料 ", base: 2000, price: 2000, owned: 0, cost: 0 },
  { name: "4. 魔導結晶", base: 8000, price: 8000, owned: 0, cost: 0 }
]

cash = 3000
day = 1
max_days = 30
cursor = 0
news = "市場は平穏だ。まずは安いものを仕入れよう。"

# 次の商談（相場変動とランダムイベント）を生成する関数
def next_deal(items)
  news = "特に大きなニュースはない。通常の相場変動だ。"
  # まず全商品を基準価格の 70% 〜 130% でランダム変動させる
  items.each { |it| it[:price] = (it[:base] * rand(0.7..1.3)).to_i }

  # 60%の確率で「暴落（割引）」か「高騰」の特別商談が発生！
  if rand < 0.6
    target = items.sample
    if rand < 0.5
      target[:price] = (target[:base] * rand(0.2..0.45)).to_i
      news = "\e[36m【大暴落】#{target[:name].strip}が豊作・過剰在庫で投げ売り中！（買い時！）\e[0m"
    else
      target[:price] = (target[:base] * rand(2.0..3.8)).to_i
      news = "\e[31m【超高騰】#{target[:name].strip}が深刻な品薄！貴族が言い値で買い漁っている！\e[0m"
    end
  end
  news
end

print "\e[2J\e[?25l"

loop do
  # 総資産の計算（所持金 ＋ 手持ち商品の現在価値）
  total_asset = cash + ITEMS.sum { |it| it[:price] * it[:owned] }

  # --- トレード画面の描画 ---
  print "\e[H============================================================\n"
  print " 商談 #{day} / #{max_days} 日目 | 所持金: \e[33m$#{cash}\e[0m (総資産評価: $#{total_asset})\n"
  print "============================================================\n"
  print " 【今回の商談状況】 #{news}\e[K\n\n"
  print "    商品名       現在価格  (基準比)     所持数   平均取得単価\n"
  print "------------------------------------------------------------\n"

  ITEMS.each_with_index do |it, idx|
    mark = (idx == cursor) ? "\e[32m=>\e[0m" : "  "
    ratio = (it[:price].to_f / it[:base] * 100).to_i
    # 基準より安ければ水色（お得）、高ければ赤色（売り時）にする
    color = ratio <= 60 ? "\e[36m" : (ratio >= 160 ? "\e[31m" : "\e[0m")
    avg_cost = it[:owned] > 0 ? "$#{it[:cost] / it[:owned]}" : "---"

    printf(" %s %s  %s$%-7d (%3d%%)\e[0m     %-6d   %-8s\e[K\n",
           mark, it[:name], color, it[:price], ratio, it[:owned], avg_cost)
  end

  print "------------------------------------------------------------\n"
  print " [W/S] 商品選択  [D] 1個買う  [A] 1個売る\n"
  print " [E] 買えるだけ全力買い(MAX)  [Q] 全力売却(ALL)\n"
  print " [Space / Enter] 決済して次の商談へ進む  [X] ゲーム終了\n"

  break if day > max_days

  # --- キー入力と取引処理 ---
  key = STDIN.getch.downcase
  item = ITEMS[cursor]

  case key
  when 'w' then cursor = (cursor - 1) % ITEMS.size
  when 's' then cursor = (cursor + 1) % ITEMS.size
  when 'd' # 1個買う
    if cash >= item[:price]
      cash -= item[:price]
      item[:owned] += 1
      item[:cost] += item[:price]
    end
  when 'e' # 全力買い（複利で一気に増やす用！）
    count = cash / item[:price]
    if count > 0
      cash -= item[:price] * count
      item[:owned] += count
      item[:cost] += item[:price] * count
    end
  when 'a' # 1個売る
    if item[:owned] > 0
      item[:cost] -= item[:cost] / item[:owned]
      cash += item[:price]
      item[:owned] -= 1
    end
  when 'q' # 全力売り
    if item[:owned] > 0
      cash += item[:price] * item[:owned]
      item[:owned] = 0
      item[:cost] = 0
    end
  when ' ', "\r", "\n" # 決済して次の商談へ
    day += 1
    news = next_deal(ITEMS) if day <= max_days
  when 'x'
    break
  end
end

print "\e[?25h\n============================================================\n"
puts " 30日間の取引終了！ 最終所持金: $#{cash}"
puts "============================================================"