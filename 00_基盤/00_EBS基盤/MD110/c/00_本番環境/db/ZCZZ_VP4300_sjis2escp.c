#include <stdio.h>
#include <stdlib.h>

#define is_sjis(c)	(((c)>=0x81)&&((c)<=0x9F)||((c)>=0xE0)&&((c)<=0xFC))

const unsigned char KI[2] = {0x1C,0x26}; /* ESC/P KANJI_IN  */
const unsigned char KO[2] = {0x1C,0x2E}; /* ESC/P KANJI_OUT */


/*********************************************/
/* ２バイト Shift JIS を JIS7 に変換する関数 */
/*********************************************/
char *sjis_to_jis(unsigned char sjis[2])
{
    static unsigned char jis[2];

    jis[0] = sjis[0];
    jis[1] = sjis[1];

    /* 外字領域(ユーザ登録領域) */
    if ((jis[0]>=0xF0) && (jis[0]<=0xF9))
    {
        /* 伊藤園登録外字(全角波線) */
        if ((jis[0]==0xF1) && (jis[1]==0x40))
        {
            jis[0] = 0x21;
            jis[1] = 0x41;
            return jis;
        }
        /* 黒塗り四角 */
        else
        {
            jis[0] = 0x22;
            jis[1] = 0x23;
            return jis;
        }
    }
    /* 外字領域(エプソンプリンタ非対応領域) */
    else if (jis[0]>=0xFA)
    {
        /* ローマ数字 (i,ii,iii,.v...x) */
        if ((jis[1]>=0x40) && (jis[1]<=0x49))
        {
            jis[0] = 0x2D;
            jis[1] = jis[1] + 0x05;
            return jis;
        }
        /* ローマ数字 (I,II,III,.V...X) */
        else if ((jis[1]>=0x4A) && (jis[1]<=0x53))
        {
            jis[0] = 0x2D;
            jis[1] = jis[1] - 0x15;
            return jis;
        }
        /* (株) */
        else if (jis[1]==0x58)
        {
            jis[0] = 0x2D;
            jis[1] = 0x6A;
            return jis;
        }
        /* No. */
        else if (jis[1]==0x59)
        {
            jis[0] = 0x2D;
            jis[1] = 0x62;
            return jis;
        }
        /* Tel */
        else if (jis[1]==0x5A)
        {
            jis[0] = 0x2D;
            jis[1] = 0x64;
            return jis;
        }
        /* 白抜き四角 */
        else
        {
            jis[0] = 0x22;
            jis[1] = 0x22;
            return jis;
        }
    }
    /* エプソンプリンタ対応部分(計算式による対応) */
    else
    {
        if (jis[0]<=0x9F)
        {
            jis[0] = jis[0] - 0x71;
        }
        else
        {
            jis[0] = jis[0] - 0xB1;
        }
        jis[0] = jis[0]*2 + 1;

        if (jis[1]>=0x7F)
        {
            jis[1] = jis[1] - 0x01;
        }
    
        if (jis[1]>=0x9E)
        {
            jis[0] = jis[0] + 0x01;
            jis[1] = jis[1] - 0x7D;
        }
        else
        {
            jis[1] = jis[1] - 0x1F;
        }
    }
    return jis;
}

int main(int argc, char *argv[])
{
   unsigned int c;
   unsigned char sjis[2];
   unsigned int kin_flag = 0;

   while ((c=getchar()) != EOF)
   {
       if is_sjis(c)
       {
          sjis[0]=c;
          if ((c=getchar()) == EOF)
          {
              break;
          }
          sjis[1]=c;
          if (kin_flag == 0)
          {
              printf("%s",KI);
              kin_flag = -1;
          }
          printf("%s",sjis_to_jis(sjis));
       }
       else
       {
          if (kin_flag == -1)
          {
              printf("%s",KO);
              kin_flag = 0;
          }
          putchar(c);
       }
   }
}
