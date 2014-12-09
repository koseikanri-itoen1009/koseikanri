#include <stdio.h>
#include <stdlib.h>

/* �萔��}�N���͎g�킸�A�ׂ����� */

int main(int argc, char *argv[])
{
    int page_length;
    int upper_margin;
    int lower_margin;
    int prn_ch;

    if (argc != 4) {
       fprintf(stderr,"Usage : %s page_length upper_margin lower_margin > output\n",argv[0]);
       fprintf(stderr,"        1/360 �C���`�P��, �}�[�W���͎��ۂ̏㉺�̌��ԕ�\n");

       exit(1);
    } else {
       page_length = atoi(argv[1]);
       upper_margin = atoi(argv[2]);
       lower_margin = page_length-atoi(argv[3]);
       if (page_length <= 0)
       {
           fprintf(stderr,"page_length �p�����[�^�G���[\n");
           exit(1);
       }
       else if ((upper_margin >= page_length) || (upper_margin <= 0))
       {
           fprintf(stderr,"upper_margin �p�����[�^�G���[\n");
           exit(1);
       }
       else if ((lower_margin >= page_length) || (lower_margin <= 0))
       {
           fprintf(stderr,"lower_margin �p�����[�^�G���[\n");
           exit(1);
       }
    }

    /* �������͂������� */

    /* ������ */
    printf("\x1b@");

    /* ���j�b�g�ݒ� */
    printf("\x1b(U");
    putchar((int)(1));
    putchar((int)(0));

    putchar((int)(10)); /* 1/3600 �� 10�{ (�Œ�Ƃ���) */

    /* �y�[�W���ݒ� */
    printf("\x1b(C");
    putchar((int)(2));
    putchar((int)(0));

    prn_ch = page_length % 256;
    putchar(prn_ch);
    prn_ch = page_length / 256;
    putchar(prn_ch);

    /* �y�[�W�t�H�[�}�b�g�ݒ� */
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

    /* �S�p�����X�y�[�X�ʐݒ� */
    printf("\x1cS");

    putchar((int)(06));  /* ���X�y�[�X�� 6/180 �C���` */
    putchar((int)(06));  /* �E�X�y�[�X�� 6/180 �C���` */

    /* n/180�C���`������������ */
    /* printf("\x1bJ");*/
    
    /*putchar((int)('\x1c')); *//* 28/180 �C���`�̎����� */

}
