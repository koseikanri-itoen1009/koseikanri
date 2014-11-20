CREATE OR REPLACE PACKAGE BODY XXCFO_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFO_COMMON_PKG(body)
 * Description      : ���ʊ֐��i��v�j
 * MD.050           : �Ȃ�
 * Version          : 1.00
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  get_special_info_item     F    VAR    �Y�t��񍀖ڒl�����擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-05   1.00   SCS �R���D        �V�K�쐬
 *  2008-03-25   1.01   SCS Kayahara      �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
--
  /**********************************************************************************
   * Function Name    : get_special_info_item
   * Description      : �Y�t��񍀖ڒl�����擾
   ***********************************************************************************/
  FUNCTION get_special_info_item(
     il_long_text              IN          LONG         -- ��������
    ,iv_serach_char            IN          VARCHAR2     -- ����������
                                )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'XXCFO_COMMON_PKG.get_special_info_item'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_long_text_len             NUMBER := 0;            -- ���������̒���
    ln_start_serach_char         NUMBER := 0;            -- �����Ώە�����J�n�ʒu
    ln_remainder_cnt             NUMBER := 0;            -- �c������
    ln_chr10                     NUMBER := 0;            -- �c������̉��s�R�[�h�ʒu
    ln_serach_char_len           NUMBER := 0;            -- �����Ώە�����̒���
    ln_remainder_char_len        NUMBER := 0;            -- �c������̒���
    ln_set_value_len             NUMBER := 0;            -- �ݒ�l�̒���
    lv_remainder_char            LONG;                   -- �c������
    lv_special_info_item         VARCHAR2(5000) := NULL; -- ���ʏ�񍀖�
--
  BEGIN
--
    -- ���������̒����̎擾
    ln_long_text_len   := LENGTHB(il_long_text);
--
    -- �����Ώە�����J�n�ʒu
    ln_start_serach_char := INSTRB(il_long_text,iv_serach_char);
--
    IF (  ln_start_serach_char != 0
      AND ln_start_serach_char IS NOT NULL)
    THEN
      -- �c�������̎擾
      ln_remainder_cnt  := ln_long_text_len - ln_start_serach_char + 1;
--
      -- �����Ώە�����̒����̎擾
      ln_serach_char_len := LENGTHB(iv_serach_char);
--
      -- �c������̎擾
      lv_remainder_char := SUBSTRB(il_long_text, ln_start_serach_char, ln_remainder_cnt);
--
      -- �c������̉��s�R�[�h�ʒu�̎擾
      ln_chr10 := INSTRB(lv_remainder_char,CHR(10));
--
      IF (ln_chr10 = 0) THEN
        -- �c������̒����̎擾
        ln_remainder_char_len := LENGTHB(lv_remainder_char);
--
        -- �ݒ�l�̒����̎擾
        ln_set_value_len := ln_remainder_char_len - ln_serach_char_len;
--
        -- ���ʏ�񍀖ڂ̎擾
        lv_special_info_item := SUBSTRB(lv_remainder_char, ln_serach_char_len + 1, ln_set_value_len);
--
      ELSE
        -- ���ʏ�񍀖ڂ̎擾
        lv_special_info_item := SUBSTRB(lv_remainder_char, ln_serach_char_len + 1, ln_chr10 - ln_serach_char_len - 1);
--
      END IF;
--
    END IF;
--
    RETURN lv_special_info_item;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_special_info_item;
--
END XXCFO_COMMON_PKG;
/