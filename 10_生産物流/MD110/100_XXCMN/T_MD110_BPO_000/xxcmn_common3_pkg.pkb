CREATE OR REPLACE PACKAGE BODY xxcmn_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxcmn_common3_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�3�i�⑫�����j.xls
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  blob_to_varchar2       P         BLOB�f�[�^�ϊ�
 *  upload_item_check      P         ���ڃ`�F�b�N
 *  delete_proc            P         �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/29   1.0   ohba             �V�K�쐬
 *  2008/01/30   1.0   nomura           ���ڃ`�F�b�N�ǉ�
 *  2008/02/01   1.0   nomura           �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜�ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common3_pkg'; -- �p�b�P�[�W��
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- ����
  gn_ret_error     CONSTANT NUMBER := 1; -- �G���[
--
  gv_cnst_msg_kbn                 CONSTANT VARCHAR2(5)   := 'XXINV';
  gv_cnst_com_kbn                 CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  gv_cnst_msg_com3_001  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ۯ��װ
  gv_cnst_msg_com3_002  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- �Ώۃf�[�^�Ȃ�
  -- ���ڃ`�F�b�N
  gv_cnst_msg_com3_para CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10010';  -- �p�����[�^�G���[
  gv_cnst_msg_com3_date CONSTANT VARCHAR2(15)  := 'APP-XXINV-10001';  -- DATE�^�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_com3_numb CONSTANT VARCHAR2(15)  := 'APP-XXINV-10002';  -- NUMBER�^�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_com3_size CONSTANT VARCHAR2(15)  := 'APP-XXINV-10007';  -- �T�C�Y�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_com3_null CONSTANT VARCHAR2(15)  := 'APP-XXINV-10061';  -- �K�{�`�F�b�N�G���[���b�Z�[�W
--
  gv_cnst_tkn_table               CONSTANT VARCHAR2(15)  := 'TABLE';
  gv_cnst_tkn_item                CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value               CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_file_id_name            CONSTANT VARCHAR2(7)   := 'FILE_ID';
  gv_cnst_tkn_para                CONSTANT VARCHAR2(9)   := 'PARAMETER';
  gv_cnst_xxinv_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                           := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
-- ���̓p�����[�^����
  gv_cnst_item_name       CONSTANT VARCHAR2(15)  := '���ږ���';
  gv_cnst_item_value      CONSTANT VARCHAR2(15)  := '���ڂ̒l';
  gv_cnst_item_len        CONSTANT VARCHAR2(15)  := '���ڂ̒���';
  gv_cnst_item_decimal    CONSTANT VARCHAR2(50)  := '���ڂ̒����i�����_�ȉ��j';
--
  gv_cnst_file_type       CONSTANT VARCHAR2(30)  := '�t�H�[�}�b�g�p�^�[��';
  gv_cnst_target_date     CONSTANT VARCHAR2(30)  := '�Ώۓ��t';
  gv_cnst_p_days          CONSTANT VARCHAR2(30)  := '�p�[�W�Ώۊ���';
--
  gv_cnst_item_null       CONSTANT VARCHAR2(15)  := '�K�{�t���O';
  gv_cnst_item_attr       CONSTANT VARCHAR2(15)  := '���ڑ���';
--
  gv_cnst_period          CONSTANT VARCHAR2(1)   := '.';        -- �s���I�h
  gv_cnst_err_msg_space   CONSTANT VARCHAR2(6)   := '      ';   -- �X�y�[�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE file_id_ttype IS TABLE OF  
    xxinv_mrp_file_ul_interface.file_id%TYPE INDEX BY BINARY_INTEGER;  -- �o�b�`ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : BLOB�f�[�^�ϊ�
   * Description      : blob_to_varchar2
   ***********************************************************************************/
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- �t�@�C���h�c
    ov_file_data OUT NOCOPY g_file_data_tbl, -- �ϊ���VARCHAR2�f�[�^
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'blob_to_varchar2'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    lv_line_feed                     VARCHAR2(1);                  -- ���s�R�[�h
    lb_src_lob                       BLOB;                         -- �ǂݍ��ݑΏ�BLOB
    lr_bufb                          RAW(32767);                   -- �i�[�o�b�t�@
    lv_str                           VARCHAR2(32767);              -- �L���X�g�ޔ�
    li_amt                           INTEGER;                      -- �ǂݎ��T�C�Y
    li_pos                           INTEGER;                      -- �ǂݎ��J�n�ʒu
    ln_index                         NUMBER;                       -- �s
    lb_index                         BOOLEAN;                      -- �s�쐬�p��
    ln_length                        NUMBER;                       -- �����ۊǗp
    ln_ieof                          NUMBER;                       -- EOF�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_data -- �t�@�C���f�[�^
    INTO   lb_src_lob
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ������
    ov_file_data.delete;
    lv_line_feed := CHR(13); -- ���s�R�[�h
    li_amt := 32000;         -- �ǂݎ��T�C�Y
    li_pos := 1;             -- �ǂݎ��J�n�ʒu
    ln_ieof := 0;            -- EOF�t���O
    ln_index := 0;           -- �s
    lb_index := TRUE;        -- �s�쐬�p��
--
    -- �o�b�t�@�擾
    DBMS_LOB.READ(lb_src_lob, --�ǂݍ��ݑΏ�BLOB
                  li_amt,     --�ǂݎ��T�C�Y
                  li_pos,     --�ǂݎ��J�n�ʒu
                  lr_bufb);   --�i�[�o�b�t�@
--
    -- VARCHAR2�ɕϊ�
    lv_str := UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
--
    -- ����o�b�t�@�v�Z
    li_pos := li_pos + li_amt;
    li_amt := 10000;
--
    -- ���s�R�[�h���ɕ���
    <<line_loop>>
    LOOP
--
      -- lv_str�����Ȃ��Ȃ�����A�ǉ��o�b�t�@�ǂݍ��݂��s��
      IF ((LENGTH(lv_str) <= 2000) AND (ln_ieof = 0)) THEN
        BEGIN
          -- �o�b�t�@�̓ǂݎ��
          DBMS_LOB.READ(lb_src_lob,--�ǂݍ��ݑΏ�BLOB
                        li_amt,    --�ǂݎ��T�C�Y
                        li_pos,    --�ǂݎ��J�n�ʒu
                        lr_bufb);  --�i�[�o�b�t�@
--
          -- VARCHAR2�ɕϊ�
          lv_str := lv_str || UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
--
          -- ����o�b�t�@�̎擾�ʒu�v�Z
          li_pos := li_pos + li_amt;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          ln_ieof := -1;
        END;
      END IF;
--
      -- �f�[�^�I��
      EXIT WHEN ((lb_index = FALSE) OR (lv_str IS NULL));
--
      -- �s�ԍ����J�E���g�A�b�v�i�����l�͂P�j
      ln_index := ln_index + 1;
--
      -- ���s�R�[�h�̈ʒu���擾
      ln_length := instr(lv_str,lv_line_feed);
--
      -- ���s�R�[�h�����̏ꍇ
      IF (ln_length = 0) THEN
        ln_length := LENGTH(lv_str);
        lb_index := FALSE;
      END IF;
--
      -- �P�s���̏���ۊ�
      IF (lb_index) THEN
        -- ���s�R�[�h�͂̂������߁Aln_length-1
        ov_file_data(ln_index) := SUBSTR(lv_str,1,ln_length - 1);
      ELSE
        ov_file_data(ln_index) := SUBSTR(lv_str,1,ln_length);
      END IF;
--
      --lv_str�͍���擾�����s�������i���s�R�[�hCRLF�͂̂������߁Aln_length + 2�j
      lv_str := SUBSTR(lv_str,ln_length + 2);
--
    END LOOP line_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_001,
                                            gv_cnst_tkn_table,
                                            gv_cnst_xxinv_mrp_file_ul_name);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_002,
                                            gv_cnst_tkn_item,
                                            gv_cnst_file_id_name,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END blob_to_varchar2;
--
  /**********************************************************************************
   * Procedure Name   : ���ڃ`�F�b�N
   * Description      : upload_item_check
   * 
   * �i�⑫�j
   *  �����͍��ځ�
   *  ���ږ��́i���ڂ̓��{�ꖼ�j    �F�K�{�F���ڂ̓��{�ꖼ�̂�ݒ�
   *  ���ڂ̒l                      �F�K�{�F���ڂ̒l��ݒ�
   *  ���ڂ̒���                    �F�C�ӁF���ڑ�����VARCHAR2  �̏ꍇ�A�ő包����ݒ�
   *                                        ���ڑ�����DATE      �̏ꍇ�ANULL��ݒ�
   *                                        ���ڑ�����NUMBER�Ō����w�肪����ꍇ�A�����_�ȉ����܂߂�������ݒ�
   *                                                                    �Ȃ��ꍇ�ANULL��ݒ�
   *  ���ڂ̒����i�����_�ȉ��j      �F�C�ӁF���ڑ�����NUMBER�ȊO�̏ꍇ�ANULL��ݒ�
   *                                        ���ڑ�����NUMBER�Ō����w�肪����ꍇ�A�����_�ȉ��̌�����ݒ�B
   *                                        �i�������̂ݎw��̏ꍇ��0��ݒ�j
   *                                                                    �Ȃ��ꍇ�ANULL��ݒ�
   *  �K�{�t���O�i��L�萔��ݒ�j  �F�K�{�F�K�{�t���O��ݒ�
   *  ���ڑ����i��L�萔��ݒ�j    �F�K�{�F���ڑ�����ݒ�
   *
   * �����^�[���R�[�h��
   * ov_retcode=gv_status_normal �̏ꍇ�F���ڃ`�F�b�N�̐���Ƃ���
   * ov_retcode=gv_status_warn   �̏ꍇ�F���ڃ`�F�b�N�ُ̈�I��
   * ov_retcode=gv_status_error  �̏ꍇ�F���ڃ`�F�b�N�̃V�X�e���G���[
   * 
   ***********************************************************************************/
  PROCEDURE upload_item_check(
    iv_item_name      IN          VARCHAR2,         -- ���ږ��́i���ڂ̓��{�ꖼ�j
    iv_item_value     IN          VARCHAR2,         -- ���ڂ̒l
    in_item_len       IN          NUMBER,           -- ���ڂ̒���
    in_item_decimal   IN          NUMBER,           -- ���ڂ̒����i�����_�ȉ��j
    in_item_nullflg   IN          VARCHAR2,         -- �K�{�t���O�i��L�萔��ݒ�j
    iv_item_attr      IN          VARCHAR2,         -- ���ڑ����i��L�萔��ݒ�j
    ov_errbuf         OUT NOCOPY  VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY  VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY  VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100)  := 'upload_item_check'; -- �v���O������
    cn_number_max_l               CONSTANT NUMBER         := 38;                  -- NUMBER�^�ő包��
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_line_feed                     VARCHAR2(1);                  -- ���s�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���ϐ� ***
    lv_err_message      VARCHAR2(32767);  -- �G���[���b�Z�[�W
    ln_period_col       NUMBER;           -- �s���I�h�ʒu
    ln_tonumber         NUMBER;           -- NUMBER�^�`�F�b�N�p
    ld_todate           DATE;             -- DATE�^�`�F�b�N�p
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ�������
    lv_err_message := NULL;     -- ���b�Z�[�W�̈揉����
    lv_line_feed := CHR(10);    -- ���s�R�[�h
--
    -- **************************************************
    -- *** �p�����[�^�`�F�b�N
    -- **************************************************
    -- �u���ږ��́v�`�F�b�N
    IF (iv_item_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_item_name,
                                            gv_cnst_tkn_value,
                                            iv_item_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�K�{�t���O�v�`�F�b�N
    IF ((in_item_nullflg IS NULL) OR (in_item_nullflg NOT IN (gv_null_ok, gv_null_ng)) )THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_item_null,
                                            gv_cnst_tkn_value,
                                            in_item_nullflg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u���ڑ����v�`�F�b�N
    IF ((iv_item_attr IS NULL) OR (iv_item_attr NOT IN (gv_attr_vc2, gv_attr_num, gv_attr_dat))) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_item_attr,
                                            gv_cnst_tkn_value,
                                            iv_item_attr);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ������VARCHAR2�̏ꍇ�A�u���ڂ̒����v�`�F�b�N 
    IF (iv_item_attr = gv_attr_vc2) THEN
      IF (in_item_len IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_com3_para,
                                              gv_cnst_tkn_para,
                                              gv_cnst_item_len,
                                              gv_cnst_tkn_value,
                                              iv_item_value);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ������NUMBER�̏ꍇ�A�u���ڂ̒����v�E�u���ڂ̒����i�����_�ȉ��j�v�`�F�b�N
    IF (iv_item_attr = gv_attr_num) THEN
--	
--    �u���ڂ̒����v�Ɓu���ڂ̒����i�����_�ȉ��j�v�̐������`�F�b�N
      IF (((in_item_len IS NULL) AND (in_item_decimal IS NULL)) 
        OR ((in_item_len IS NOT NULL) AND (in_item_decimal IS NOT NULL))) 
      THEN
        NULL;
      ELSE
        -- ���ڂ̒����v�E�u���ڂ̒����i�����_�ȉ��j�v�̒l������NULL�A����
        -- ���ڂ̒����v�E�u���ڂ̒����i�����_�ȉ��j�v�̒l������NOT NULL �łȂ��ꍇ�̓G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_com3_para,
                                              gv_cnst_tkn_para,
                                              gv_cnst_item_len,
                                              gv_cnst_tkn_value,
                                              in_item_len);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- **************************************************
    -- *** �K�{�`�F�b�N
    -- **************************************************
    -- �K�{���ڂ̏ꍇ
    IF (in_item_nullflg = gv_null_ng) THEN
      IF (iv_item_value IS NULL) THEN
        lv_err_message := lv_err_message
                          || gv_cnst_err_msg_space
                          || gv_cnst_err_msg_space
                          || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                      gv_cnst_msg_com3_null,
                                                      gv_cnst_tkn_item,
                                                      iv_item_name)
                          || lv_line_feed;
      END IF;
    END IF;
--
    --���ڂ̒l���ݒ肳��Ă���ꍇ
    IF (iv_item_value IS NOT NULL) THEN
      -- **************************************************
      -- *** VARCHAR2�^�i�t���[�j�`�F�b�N
      -- **************************************************
      IF (iv_item_attr = gv_attr_vc2) THEN
        -- �T�C�Y�`�F�b�N
        IF (LENGTHB(iv_item_value) > in_item_len) THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_size,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** �m�t�l�a�d�q�^�`�F�b�N
      -- **************************************************
      IF (iv_item_attr = gv_attr_num) THEN
        BEGIN
          -- TO_NUMBER�ł��Ȃ���΃G���[
          ln_tonumber := TO_NUMBER(iv_item_value);
--
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_numb,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
        END;
--
        -- �����w�肪�Ȃ��ꍇ
        IF in_item_len IS NULL THEN
          -- �s���I�h��������������38�����I�[�o�[�����ꍇ�G���[
          IF (LENGTHB(REPLACE(iv_item_value,gv_cnst_period,NULL))) > cn_number_max_l THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space 
                              || gv_cnst_err_msg_space
                              || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_size,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
          END IF;
        ELSE
          -- �s���I�h�̈ʒu���擾
          ln_period_col := INSTRB(iv_item_value, gv_cnst_period);
          -- �s���I�h�����̏ꍇ
          IF (ln_period_col = 0) THEN
            -- �������̌������I�[�o�[���Ă���΃G���[
            IF (LENGTHB(iv_item_value) > (in_item_len - in_item_decimal)) THEN
              lv_err_message := lv_err_message
                                || gv_cnst_err_msg_space 
                                || gv_cnst_err_msg_space
                                || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                            gv_cnst_msg_com3_size,
                                                            gv_cnst_tkn_item,
                                                            iv_item_name)
                                || lv_line_feed;
            END IF;
          -- �s���I�h�L��̏ꍇ
          --   �������������I�[�o�[���͏����_�ȉ��������I�[�o�[���Ă���΃G���[
          ELSIF ((ln_period_col -1 > (in_item_len - in_item_decimal))
            OR (LENGTHB(SUBSTRB(iv_item_value, ln_period_col + 1))) > in_item_decimal) THEN
              lv_err_message := lv_err_message
                                || gv_cnst_err_msg_space 
                                || gv_cnst_err_msg_space
                                || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                            gv_cnst_msg_com3_size,
                                                            gv_cnst_tkn_item,
                                                            iv_item_name)
                                || lv_line_feed;
          END IF;
--
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** �c�`�s�d�^�`�F�b�N
      -- **************************************************
      IF (iv_item_attr = gv_attr_dat) THEN
        ld_todate := FND_DATE.STRING_TO_DATE(iv_item_value, 'RR/MM/DD');
        IF (ld_todate IS NULL) THEN
          lv_err_message := lv_err_message
                            || gv_cnst_err_msg_space
                            || gv_cnst_err_msg_space
                            || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                        gv_cnst_msg_com3_date,
                                                        gv_cnst_tkn_item,
                                                        iv_item_name)
                            || lv_line_feed;
        END IF;
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** ���b�Z�[�W�̐��`
    -- **************************************************
    -- ���b�Z�[�W���o�^����Ă���ꍇ
    IF (lv_err_message IS NOT NULL) THEN
      -- �Ō�̉��s�R�[�h���폜��OUT�p�����[�^�ɐݒ�
      ov_errmsg := RTRIM(lv_err_message, lv_line_feed);
      -- ���[�j���O�Ƃ��ďI��
      ov_retcode := gv_status_warn;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upload_item_check;
--
  /**********************************************************************************
   * Procedure Name   : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜
   * Description      : delete_fileup_proc
   ***********************************************************************************/
  PROCEDURE delete_fileup_proc(
    iv_file_format IN         VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    id_now_date    IN         DATE,         --   �Ώۓ��t
    in_purge_days  IN         NUMBER,       --   �p�[�W�Ώۊ���
    ov_errbuf      OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_fileup_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_file_id_del_tab      file_id_ttype;     -- �o�b�`ID
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �p�����[�^�`�F�b�N
    -- **************************************************
    -- �u�t�H�[�}�b�g�p�^�[���v�`�F�b�N
    IF (iv_file_format IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_file_type,
                                            gv_cnst_tkn_value,
                                            iv_file_format);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �u�Ώۓ��t�v�`�F�b�N
    IF (id_now_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_target_date,
                                            gv_cnst_tkn_value,
                                            id_now_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �u�p�[�W�Ώۊ��ԁv�`�F�b�N
    IF (in_purge_days IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_p_days,
                                            gv_cnst_tkn_value,
                                            in_purge_days);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �Ώۃf�[�^�폜����
    -- **************************************************
    BEGIN
      -- FILE_ID�擾�����i���b�N�����j
      -- �����b(00:00:00)���l�����āA�p�[�W�Ώۊ��Ԃ��-1���������Ԃ�Ώۓ��t��������A�쐬���Ɣ�r���s���B
      SELECT xmf.file_id
      BULK COLLECT INTO lt_file_id_del_tab
      FROM   xxinv_mrp_file_ul_interface xmf
      WHERE  xmf.file_content_type  =  iv_file_format
      AND    xmf.creation_date      < (TRUNC(id_now_date) - (in_purge_days -1))
      FOR UPDATE OF xmf.file_id NOWAIT;
--
      -- �폜�����i�o���N�����j
      FORALL item_cnt IN 1 .. lt_file_id_del_tab.COUNT
        DELETE FROM xxinv_mrp_file_ul_interface xmf
        WHERE xmf.file_id = lt_file_id_del_tab(item_cnt);
--
    EXCEPTION
      WHEN check_lock_expt THEN
        NULL;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_fileup_proc;
--
END xxcmn_common3_pkg;
/
