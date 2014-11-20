CREATE OR REPLACE PACKAGE BODY XXCFO_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg2(body)
 * Description      : ���ʊ֐��i��v�j
 * MD.070           : MD070_IPO_CFO_001_���ʊ֐���`��
 * Version          : 1.00
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  chk_electric_book_item    P          �d�q���덀�ڃ`�F�b�N�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/31   1.00   SCSK T.Osawa     �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCCP_COMMON_PKG2';  -- �p�b�P�[�W��
--
  cv_msg_kbn_ccp         CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfo         CONSTANT VARCHAR2(5)   := 'XXCFO';
  -- ���b�Z�[�W
  cv_msg_ccp_10113       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10113';  -- DATE�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_ccp_10114       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';  -- NUMBER�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_cfo_10011       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';  -- �������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10018       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10018';  -- ���p������s�����b�Z�[�W
  cv_msg_cfo_10020       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10020';  -- �؎̂ăt���O�G���[���b�Z�[�W
  cv_msg_cfo_10021       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10021';  -- ���ڂ̒����ݒ�G���[���b�Z�[�W
  cv_msg_cfo_10022       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10022';  -- ���ڂ̒����i�����_�ȉ��j�ݒ�G���[���b�Z�[�W
  --�g�[�N��
  cv_tkn_value           CONSTANT VARCHAR2(10)  := 'VALUE';             -- �g�[�N����(VALUE)
  cv_tkn_item            CONSTANT VARCHAR2(10)  := 'ITEM';              -- �g�[�N����(ITEM)
  cv_tkn_key_data        CONSTANT VARCHAR2(10)  := 'KEY_DATA';          -- �g�[�N����(KEY_DATA)
  --
  cv_msg_cont            CONSTANT VARCHAR2(3)   := '.';  
--
  /**********************************************************************************
   * Function Name    : chk_electric_book_item
   * Description      : �d�q���덀�ڃ`�F�b�N�֐�
   ***********************************************************************************/
  PROCEDURE chk_electric_book_item(
      iv_item_name    IN  VARCHAR2 -- ���ږ���
    , iv_item_value   IN  VARCHAR2 -- ���ڂ̒l
    , in_item_len     IN  NUMBER   -- ���ڂ̒���
    , in_item_decimal IN  NUMBER   -- ���ڂ̒���(�����_�ȉ�)
    , iv_item_nullflg IN  VARCHAR2 -- �K�{�t���O
    , iv_item_attr    IN  VARCHAR2 -- ���ڑ���
    , iv_item_cutflg  IN  VARCHAR2 -- �؎̂ăt���O
    , ov_item_value   OUT VARCHAR2 -- ���ڂ̒l
    , ov_errbuf       OUT VARCHAR2 -- �G���[���b�Z�[�W
    , ov_retcode      OUT VARCHAR2 -- ���^�[���R�[�h
    , ov_errmsg       OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'chk_electric_book_item'; -- �v���O������
    -- �K�{�t���O
    cv_null_ok                CONSTANT VARCHAR2(7) := 'NULL_OK'; -- �C�Ӎ���
    cv_null_ng                CONSTANT VARCHAR2(7) := 'NULL_NG'; -- �K�{����
    -- ���ڑ���
    cv_attr_vc2               CONSTANT VARCHAR2(1) := '0';       -- VARCHAR2
    cv_attr_num               CONSTANT VARCHAR2(1) := '1';       -- NUMBER
    cv_attr_dat               CONSTANT VARCHAR2(1) := '2';       -- DATE
    cv_attr_cha               CONSTANT VARCHAR2(1) := '3';       -- CHAR
    -- �؎̂ăt���O
    cv_cut_ok                 CONSTANT VARCHAR2(2) := 'OK';      -- �؎̂�OK
    cv_cut_ng                 CONSTANT VARCHAR2(2) := 'NG';      -- �؎̂�NG
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_line_feed              VARCHAR2(1);     -- ���s�R�[�h
    lv_item_value             VARCHAR2(5000);  -- ���ڂ̒l�i�֐��Ăяo���p�j
    lv_item_attr              VARCHAR2(1);     -- ���ڑ����i�֐��Ăяo���p�j
    ln_number                 NUMBER;          -- �ϊ��p�iNUMBER�j
    ln_decimal_place          NUMBER;          -- �����_�ʒu�m�F�p
    ln_decimal                NUMBER;          -- �����_�ȉ��̒l�m�F�p
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_warn_expt         EXCEPTION;
    process_error_expt        EXCEPTION;
--
  BEGIN
    --==============================================================
    -- ������
    --==============================================================
    lv_errbuf     := NULL;
    lv_retcode    := xxccp_common_pkg.set_status_normal;
    lv_errmsg     := NULL;
    lv_line_feed  := CHR(10);
    lv_item_value := NULL;
    lv_item_attr  := NULL;
    ln_number     := NULL;
    ln_decimal    := NULL;
    --
    --==============================================================
    -- IN�p�����[�^�i�؎̂ăt���O�j�`�F�b�N
    --==============================================================
    IF (  ( iv_item_cutflg IS NOT NULL )
      AND ( iv_item_cutflg NOT IN ( cv_cut_ok, cv_cut_ng ) ) ) THEN
      lv_errbuf := cv_msg_cfo_10020;
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                           , cv_msg_cfo_10020
                                           , cv_tkn_value
                                           , iv_item_cutflg);
      RAISE process_warn_expt;
    END IF;
    --
    --==============================================================
    -- ���ڂ̒����A���ڂ̒����i�����_�ȉ��j�`�F�b�N
    --==============================================================
    -- ���ڂ̒�����NULL���A���ڑ�����DATE�ȊO�̏ꍇ
    IF (  ( in_item_len IS NULL )
      AND ( iv_item_attr <> cv_attr_dat ) ) THEN
      lv_errbuf := cv_msg_cfo_10021;
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                           , cv_msg_cfo_10021
                                           , cv_tkn_item
                                           , iv_item_name);
      RAISE process_warn_expt;
    -- ���ڂ̒����i�����_�ȉ��j��NULL���A���ڑ�����NUMBER�̏ꍇ
    ELSIF ( ( in_item_decimal IS NULL )
      AND   ( iv_item_attr = cv_attr_num ) ) THEN
      lv_errbuf := cv_msg_cfo_10022;
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                           , cv_msg_cfo_10022
                                           , cv_tkn_item
                                           , iv_item_name);
      RAISE process_warn_expt;
    -- ���ڂ̒�����NULL�łȂ��A���ڑ�����VARCHAR2�܂���CHAR�̏ꍇ
    ELSIF ( ( in_item_len IS NOT NULL )
      AND   ( iv_item_attr IN ( cv_attr_vc2, cv_attr_cha ) ) ) THEN
      -- ���ڑ�����CHAR�̏ꍇ
      IF ( iv_item_attr = cv_attr_cha ) THEN
        -- ���p�`�F�b�N�֐��ɂ�FALSE�̏ꍇ
        IF ( xxccp_common_pkg.chk_single_byte(iv_item_value) =  FALSE )  THEN
          lv_errbuf := cv_msg_cfo_10018;
          lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                               , cv_msg_cfo_10018
                                               , cv_tkn_item
                                               , iv_item_name);
          RAISE process_warn_expt;
        END IF;
      END IF;
      -- ���ڂ̒l�̃T�C�Y�����ڂ̒��������傫�����A�؎̂ăt���O��NG�̏ꍇ
      IF (  ( LENGTHB(iv_item_value) > in_item_len )
        AND ( iv_item_cutflg =  cv_cut_ng ) ) THEN
        lv_errbuf := cv_msg_cfo_10011;
        lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                             , cv_msg_cfo_10011
                                             , cv_tkn_key_data
                                             , NULL);
        RAISE process_warn_expt;
      END IF;
    -- ���ڂ̒�����NULL�łȂ��A���ڑ�����NUMBER�̏ꍇ
    ELSIF ( ( in_item_len IS NOT NULL )
      AND   ( iv_item_attr = cv_attr_num ) ) THEN
      -- ���ڂ̒l��NUMBER�^�ɕϊ��ł��Ȃ��ꍇ
      BEGIN
        ln_number := TO_NUMBER(iv_item_value);
      EXCEPTION 
        WHEN OTHERS THEN
          lv_errbuf := cv_msg_ccp_10114;
          lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_ccp
                                               , cv_msg_ccp_10114
                                               , cv_tkn_item
                                               , iv_item_name);
          RAISE process_warn_expt;
      END;
      -- ���ڂ̒����i�����_�ȉ��j��0�̏ꍇ
      IF ( in_item_decimal = 0 ) THEN
        -- ���ڂ̃T�C�Y�����ڂ̒��������傫���ꍇ
        IF ( LENGTHB(ABS(iv_item_value)) > in_item_len ) THEN
          lv_errbuf := cv_msg_cfo_10011;
          lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                               , cv_msg_cfo_10011
                                               , cv_tkn_key_data
                                               , NULL);
          RAISE process_warn_expt;
        END IF;
      -- ���ڂ̒����i�����_�ȉ��j��0�łȂ��ꍇ
      ELSE
        -- �����_�̈ʒu���擾
        ln_decimal_place := INSTRB(iv_item_value, cv_msg_cont);
        -- �����_������ꍇ
        IF (ln_decimal_place > 0) THEN
          -- ���ڂ̒l�̃T�C�Y�����ڂ̒��������傫���ꍇ�i�����_�̕��{�P�����l�Ŕ���j
          IF ( LENGTHB(ABS(iv_item_value)) > in_item_len + 1 ) THEN
            lv_errbuf := cv_msg_cfo_10011;
            lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                 , cv_msg_cfo_10011
                                                 , cv_tkn_key_data
                                                 , NULL);
            RAISE process_warn_expt;
          END IF;
        ELSE   
          -- ���ڂ̒l�̃T�C�Y�����ڂ̒��������傫���ꍇ
          IF ( LENGTHB(ABS(iv_item_value)) > in_item_len ) THEN
            lv_errbuf := cv_msg_cfo_10011;
            lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                 , cv_msg_cfo_10011
                                                 , cv_tkn_key_data
                                                 , NULL);
            RAISE process_warn_expt;
          END IF;
        END IF;  
        --
        -- �����_�����݂���ꍇ
        IF ( ln_decimal_place > 0 ) THEN
          -- ���ڂ̒l�̃T�C�Y��菬���_�܂ł̍��ڂ̒l�̃T�C�Y���������l�i�����_��艺�̒����j���擾
          ln_decimal := LENGTHB(iv_item_value) - INSTRB(iv_item_value, cv_msg_cont);
          -- �擾�l�����ڂ̒����i�����_�ȉ��j�����傫���ꍇ
          IF ( ln_decimal > in_item_decimal ) THEN
            lv_errbuf := cv_msg_cfo_10011;
            lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                 , cv_msg_cfo_10011
                                                 , cv_tkn_key_data
                                                 , NULL);
            RAISE process_warn_expt;
          END IF;
        END IF;
      END IF;
    END IF;
    --
    -- ���ڂ̒����ɍ��킹��
    --�����̏ꍇ
    IF ( iv_item_attr IN ( cv_attr_vc2, cv_attr_cha ) ) THEN
      lv_item_value := SUBSTRB(iv_item_value, 1, in_item_len);
    --���l�̏ꍇ
    ELSIF ( iv_item_attr = cv_attr_num ) THEN
      lv_item_value := ABS(iv_item_value);        --��Βl�œn��
    --��L�ȊO�̏ꍇ
    ELSE
      lv_item_value := iv_item_value;
    END IF;
    --
    -- ���ڑ����ύX�iCHAR��VARCHAR�j
    IF ( iv_item_attr = cv_attr_cha ) THEN
      lv_item_attr := cv_attr_vc2;
    ELSE
      lv_item_attr := iv_item_attr;
    END IF;
    --
    -- �A�b�v���[�h���ڃ`�F�b�N�֐��Ăяo��
    xxccp_common_pkg2.upload_item_check(
        iv_item_name    => iv_item_name      -- ���ږ��́i���ڂ̓��{�ꖼ�j  -- �K�{
      , iv_item_value   => lv_item_value     -- ���ڂ̒l                    -- �C��
      , in_item_len     => in_item_len       -- ���ڂ̒���                  -- �K�{
      , in_item_decimal => in_item_decimal   -- ���ڂ̒����i�����_�ȉ��j    -- �����t�K�{
      , iv_item_nullflg => iv_item_nullflg   -- �K�{�t���O�i��L�萔��ݒ�j-- �K�{
      , iv_item_attr    => lv_item_attr      -- ���ڑ����i��L�萔��ݒ�j  -- �K�{
      , ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    --
    IF (  ( lv_retcode <> xxccp_common_pkg.set_status_normal )
      AND ( lv_errmsg IS NOT NULL ) ) THEN
      RAISE  process_warn_expt;
    ELSIF ( ( lv_retcode <> xxccp_common_pkg.set_status_normal )
      AND   ( lv_errmsg IS NULL ) ) THEN
      RAISE  process_error_expt;
    END IF;
    -- ����I��
    -- ���l�̏ꍇ
    IF ( iv_item_attr = cv_attr_num ) THEN
      ov_item_value := iv_item_value;       --���͒l��߂�
    ELSE
      ov_item_value := lv_item_value;
    END IF;
    ov_retcode    := xxccp_common_pkg.set_status_normal;
    ov_errbuf     := NULL;
    ov_errmsg     := NULL;
    --
  EXCEPTION
    -- �x���I��
    WHEN process_warn_expt THEN
      ov_item_value := NULL;
      ov_retcode    := xxccp_common_pkg.set_status_warn;
      ov_errbuf     := lv_errbuf;
      ov_errmsg     := RTRIM( lv_errmsg, lv_line_feed );
    -- �ُ�I��
    WHEN process_error_expt THEN
      ov_item_value := NULL;
      ov_retcode    := xxccp_common_pkg.set_status_error;
      ov_errbuf     := cv_prg_name || SQLERRM;
      ov_errmsg     := NULL;
    -- �ُ�I��
    WHEN OTHERS THEN
      ov_item_value := NULL;
      ov_retcode    := xxccp_common_pkg.set_status_error;
      ov_errbuf     := cv_prg_name || SQLERRM;
      ov_errmsg     := NULL;
  END chk_electric_book_item;
--
END XXCFO_COMMON_PKG2;
/
