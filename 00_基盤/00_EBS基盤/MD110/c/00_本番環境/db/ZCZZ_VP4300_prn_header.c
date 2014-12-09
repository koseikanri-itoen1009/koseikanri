#include <stdio.h>
#include <stdlib.h>

/* 定数やマクロは使わず、べた書き */

int main(int argc, char *argv[])
{
    int page_length;
    int upper_margin;
    int lower_margin;
    int prn_ch;

    if (argc != 4) {
       fprintf(stderr,"Usage : %s page_length upper_margin lower_margin > output\n",argv[0]);
       fprintf(stderr,"        1/360 インチ単位, マージンは実際の上下の隙間分\n");

       exit(1);
    } else {
       page_length = atoi(argv[1]);
       upper_margin = atoi(argv[2]);
       lower_margin = page_length-atoi(argv[3]);
       if (page_length <= 0)
       {
           fprintf(stderr,"page_length パラメータエラー\n");
           exit(1);
       }
       else if ((upper_margin >= page_length) || (upper_margin <= 0))
       {
           fprintf(stderr,"upper_margin パラメータエラー\n");
           exit(1);
       }
       else if ((lower_margin >= page_length) || (lower_margin <= 0))
       {
           fprintf(stderr,"lower_margin パラメータエラー\n");
           exit(1);
       }
    }

    /* 実処理はここから */

    /* 初期化 */
    printf("\x1b@");

    /* ユニット設定 */
    printf("\x1b(U");
    putchar((int)(1));
    putchar((int)(0));

    putchar((int)(10)); /* 1/3600 の 10倍 (固定とする) */

    /* ページ長設定 */
    printf("\x1b(C");
    putchar((int)(2));
    putchar((int)(0));

    prn_ch = page_length % 256;
    putchar(prn_ch);
    prn_ch = page_length / 256;
    putchar(prn_ch);

    /* ページフォーマット設定 */
    printf("\x1b(c");
    putchar((int)(4));
    putchar((int)(0));

    prn_ch = upper_margin % 256;
    putchar(prn_ch);
    prn_ch = upper_margin / 256;
    putchar(prn_ch);

    prn_ch = lower_margin % 256;
    putchar(prn_ch);
    prn_ch = lower_margin / 256;
    putchar(prn_ch);

    /* 全角文字スペース量設定 */
    printf("\x1cS");

    putchar((int)(06));  /* 左スペースは 6/180 インチ */
    putchar((int)(06));  /* 右スペースも 6/180 インチ */

    /* n/180インチ順方向紙送り */
    /* printf("\x1bJ");*/
    
    /*putchar((int)('\x1c')); *//* 28/180 インチの紙送り */

}
