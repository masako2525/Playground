#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

#define W 40
#define H 20

// Linuxのターミナルを「エンターキーなしで即座に入力を受け取る」モードにする関数
int kbhit(void) {
    struct termios oldt, newt;
    int ch, oldf;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);
    if (ch != EOF) { ungetc(ch, stdin); return 1; }
    return 0;
}

int main() {
    float bx = W / 2, by = H / 2;   // ボールの座標
    float vx = 0.8, vy = -0.5;      // ボールの速度ベクトル
    int px = W / 2 - 3, pw = 7;     // パドルのX座標と幅
    int bricks[5][W] = {0};         // ブロックの配列 (1=あり, 0=なし)
    int score = 0;

    // ブロックを配置
    for (int y = 1; y < 4; y++)
        for (int x = 4; x < W - 4; x++) bricks[y][x] = 1;

    printf("\033[2J\033[?25l"); // 画面クリア ＆ カーソル非表示

    while (1) {
        // 1. 入力処理 (Aで左、Dで右、Qで終了)
        if (kbhit()) {
            char c = getchar();
            if (c == 'a' && px > 1) px -= 2;
            if (c == 'd' && px + pw < W - 1) px += 2;
            if (c == 'q') break;
        }

        // 2. 物理・当たり判定の更新
        bx += vx; by += vy;
        if (bx <= 1 || bx >= W - 2) vx = -vx; // 左右の壁で反射
        if (by <= 1) vy = -vy;                // 天井で反射

        // パドルとの当たり判定
        if ((int)by == H - 2 && (int)bx >= px && (int)bx <= px + pw) {
            vy = -vy;
            // パドルの端に当たるほど横の角度がつく仕組み
            vx = ((bx - (px + pw / 2.0)) / (pw / 2.0)) * 1.2;
        }

        // ブロックとの当たり判定
        if ((int)by < 5 && bricks[(int)by][(int)bx]) {
            bricks[(int)by][(int)bx] = 0;
            vy = -vy;
            score += 10;
        }

        if (by >= H - 1) break; // 床に落ちたらゲームオーバー

        // 3. 画面描画 (\033[H でカーソルを左上に戻して上書き)
        printf("\033[HScore: %d  (Move: A / D, Quit: Q)\n", score);
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                if (y == 0 || x == 0 || x == W - 1) printf("#");
                else if (y == (int)by && x == (int)bx) printf("O");
                else if (y == H - 2 && x >= px && x < px + pw) printf("=");
                else if (y < 5 && bricks[y][x]) printf("@");
                else printf(" ");
            }
            printf("\n");
        }
        usleep(40000); // 40ミリ秒待機 (フレームレート調整)
    }

    printf("\033[?25hGame Over! Final Score: %d\n", score); // カーソルを戻す
    return 0;
}