CREATE OR REPLACE PACKAGE BODY xxinv530002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530002c(body)
 * Description      : HHT�I���f�[�^IF�v���O����
 * MD.050/070       : �I��Issue1.0(T_MD050_BPO_530)
 *                  : �I��Issue1.0(T_MD050_BPO_53B)
 * Version          : 1.5
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  fnc_check_num               ���l�`�F�b�N���܂��B
 *  proc_del_table_data_batch   �f�[�^�폜����(B-6)
 *  proc_ins_table_batch        �ꊇ�o�^����(B-5)
 *  proc_upd_table_batch        �ꊇ�X�V����(B-4)
 *  fnc_get_data_dump           �f�[�^�_���v���쐬���܂��B
 *  proc_put_dump_msg           �f�[�^�_���v�ꊇ�o�͏���(B-4)
 *  proc_check                  �Ó����`�F�b�N(B-3)
 *  get_ins_data                �Ώۃf�[�^�擾(B-2)
 *  proc_del_table_data         �f�[�^�p�[�W����(B-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/03    1.0   T.Endou          �V�K�쐬
 *  2008/05/02    1.1   M.Inamine        �C��(�yBPO_530_�I���z�C���˗����� No2�̑Ή�)
 *                      M.Inamine        �C��(MD.050_530�̕s��ɂ��ĂQ.txt�̑Ή�)
 *  2008/05/07    1.2   T.Endou          �C��(MD.050_530�̕s��ɂ��ĂS.txt�̑Ή�)
 *                      T.Endou          �C��(MD.050_530�̕s��ɂ��ĂT.txt�̑Ή�)
 *  2008/05/08    1.3   T.Endou          �C��(���b�g�Ǘ����Ȃ��ꍇ��NULL)
 *  2008/05/09    1.4   M.Inamine        �C��(2008/05/08 03 �s��Ή��F���t�����̌��)
 *  2008/12/06    1.5   T.Miyata         �C��(�{�ԏ�Q#510�Ή��F���t�͕ϊ����Ĕ�r)
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  global_user_expt       EXCEPTION;        -- ���[�U�[�ɂĒ�`��������O
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxinv530002c'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn                CONSTANT VARCHAR2(100) := 'XXCMN';
  gv_xxinv                CONSTANT VARCHAR2(100) := 'XXINV';
  -- YES/NO
  gv_y                    CONSTANT VARCHAR2(1) := 'Y';
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  -- YES/NO
  gn_y                    CONSTANT NUMBER := 1;
  gn_n                    CONSTANT NUMBER := 0;
--
  gn_ret_nomal            CONSTANT NUMBER := 0; -- ����
  gn_ret_error            CONSTANT NUMBER := 1; -- �G���[
--
  -- WHO����
  gn_user_id              CONSTANT NUMBER := FND_GLOBAL.USER_ID;
  gd_sysdate              CONSTANT DATE   := SYSDATE;
  gn_last_update_login    CONSTANT NUMBER := FND_GLOBAL.LOGIN_ID;
  gn_request_id           CONSTANT NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
  gn_program_appl_id      CONSTANT NUMBER := FND_GLOBAL.PROG_APPL_ID;
  gn_program_id           CONSTANT NUMBER := FND_GLOBAL.CONC_PROGRAM_ID;
--
  -- ���i�敪
  gv_goods_classe_reaf    CONSTANT VARCHAR2(1)  := '1';   -- ���i�敪�F1(���[�t)
  gv_goods_classe_drink   CONSTANT VARCHAR2(1)  := '2';   -- ���i�敪�F2(�h�����N)
  -- ���i�敪
  gv_item_class_products  CONSTANT VARCHAR2(1)  := '5';   -- �i�ڋ敪�F5(���i)
--
  gv_date                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';--2008/05/02
  gv_blank                CONSTANT VARCHAR2(2)  := '�@';
  gn_zero                 CONSTANT NUMBER       := 0;
  gn_one                  CONSTANT NUMBER       := 1;
  gv_zero                 CONSTANT VARCHAR2(1) := '0';
--
  gv_profile_name         CONSTANT VARCHAR2(16) := '�I���폜�Ώۓ��t';
  gv_inv_hht_name         CONSTANT VARCHAR2(21) := 'HHT�I�����[�N�e�[�u��';
  gv_inv_result_name      CONSTANT VARCHAR2(21) := '�I�����ʃe�[�u��';
  gv_opm_item_name        CONSTANT VARCHAR2(21) := 'OPM�i�ڃ}�X�^';
  gv_opm_lot_name         CONSTANT VARCHAR2(21) := 'OPM���b�g�}�X�^';
  gv_invent_whse_name     CONSTANT VARCHAR2(21) := 'OPM�q�Ƀ}�X�^';
  gv_report_post_name     CONSTANT VARCHAR2(21) := '���Ə��}�X�^';
--
  gv_item_col             CONSTANT VARCHAR2(4)  := '�i��';
  gv_inv_whse_code_col    CONSTANT VARCHAR2(8)  := '�I���q��';
  gv_report_post_code_col CONSTANT VARCHAR2(8)  := '�񍐕���';
  gv_lot_no_col           CONSTANT VARCHAR2(8)  := '���b�gNo';
  gv_maker_date_col       CONSTANT VARCHAR2(8)  := '������';
  gv_limit_date_col       CONSTANT VARCHAR2(8)  := '�ܖ�����';
  gv_proper_mark_col      CONSTANT VARCHAR2(8)  := '�ŗL�L��';
  gv_case_amt_col         CONSTANT VARCHAR2(10) := '�I���P�[�X';
  gv_content_col          CONSTANT VARCHAR2(4)  := '����';
  gv_loose_amt_col        CONSTANT VARCHAR2(8)  := '�I���o��';
--
-- 2008/12/06 T.Miyata Add Start
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
-- 2008/12/06 T.Miyata Add End
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- HHT�I�����[�N���R�[�h
  TYPE gtbl_hht_work IS RECORD (
    invent_hht_if_id   xxinv_stc_inventory_hht_work.invent_hht_if_id%TYPE
   ,report_post_code   xxinv_stc_inventory_hht_work.report_post_code%TYPE
   ,invent_date        xxinv_stc_inventory_hht_work.invent_date%TYPE
   ,invent_whse_code   xxinv_stc_inventory_hht_work.invent_whse_code%TYPE
   ,invent_seq         xxinv_stc_inventory_hht_work.invent_seq%TYPE
   ,item_code          xxinv_stc_inventory_hht_work.item_code%TYPE
   ,lot_no             xxinv_stc_inventory_hht_work.lot_no%TYPE
   ,maker_date         xxinv_stc_inventory_hht_work.maker_date%TYPE
   ,limit_date         xxinv_stc_inventory_hht_work.limit_date%TYPE
   ,proper_mark        xxinv_stc_inventory_hht_work.proper_mark%TYPE
   ,case_amt           xxinv_stc_inventory_hht_work.case_amt%TYPE
   ,content            xxinv_stc_inventory_hht_work.content%TYPE
   ,loose_amt          xxinv_stc_inventory_hht_work.loose_amt%TYPE
   ,location           xxinv_stc_inventory_hht_work.location%TYPE
   ,rack_no1           xxinv_stc_inventory_hht_work.rack_no1%TYPE
   ,rack_no2           xxinv_stc_inventory_hht_work.rack_no2%TYPE
   ,rack_no3           xxinv_stc_inventory_hht_work.rack_no3%TYPE
   ,b_invent_seq       xxinv_stc_inventory_hht_work.invent_seq%TYPE  -- ���i�d���`�F�b�N�p
   ,c_invent_seq       xxinv_stc_inventory_hht_work.invent_seq%TYPE  -- ���i�ȊO�d���`�F�b�N�p
   ,rowid_work         ROWID
   ,err_msg            VARCHAR2(5000)                                -- �G���[���b�Z�[�W
   ,b3_item_id         xxcmn_item_mst_v.item_id%TYPE                 -- b3_�i��ID
   ,b3_lot_ctl         xxcmn_item_mst_v.lot_ctl%TYPE                 -- b3_���b�g�Ǘ��敪
   ,b3_num_of_cases    xxcmn_item_mst_v.num_of_cases%TYPE            -- b3_�P�[�X����
   ,b3_item_class_code xxcmn_item_categories4_v.item_class_code%TYPE -- b3_�i�ڋ敪
   ,b3_prod_class_code xxcmn_item_categories4_v.prod_class_code%TYPE -- b3_���i�敪
   ,b3_lot_id          NUMBER                                        -- b3_���b�gID
   ,b3_lot_no          xxinv_stc_inventory_hht_work.lot_no%TYPE      -- b3_���b�gNO
   ,b3_maker_date      VARCHAR2(240)                                 -- b3_�����N����
   ,b3_proper_mark     VARCHAR2(240)                                 -- b3_�ŗL�L��
   ,b3_limit_date      VARCHAR2(240));                               -- b3_�ܖ�����
  --
  TYPE gtbl_hht_work_type IS TABLE OF gtbl_hht_work INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gtbl_data       gtbl_hht_work_type; -- ���f�[�^
  gtbl_normal     gtbl_hht_work_type; -- ����f�[�^
  gtbl_error      gtbl_hht_work_type; -- �G���[�f�[�^
  gtbl_reserve    gtbl_hht_work_type; -- �ۗ��f�[�^
  gtbl_normal_ins gtbl_hht_work_type; -- ����f�[�^�}��
--
  CURSOR gcur_xxinv_stc_inv_hht_work
  IS
    SELECT xsihw.ROWID
    FROM   xxinv_stc_inventory_hht_work xsihw
    FOR UPDATE NOWAIT;
--
-- 2008/12/07 T.MIYATA ADD START #510
--
  /**********************************************************************************
   * Function Name    : fnc_check_date
   * Description      : ���t�`�F�b�N���s���܂��B
   ***********************************************************************************/
  FUNCTION fnc_check_date(
    iv_date IN VARCHAR2
    ) RETURN VARCHAR2
  IS
  BEGIN
--
    RETURN to_char(to_date(iv_date, gc_char_d_format), gc_char_d_format);
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN null;
  END fnc_check_date;
--
-- 2008/12/07 T.MIYATA ADD END #510
--
  /**********************************************************************************
   * Function Name    : fnc_check_num
   * Description      : ���l�`�F�b�N���܂��B
   ***********************************************************************************/
  FUNCTION fnc_check_num(
    iv_check_num IN VARCHAR2,
    iv_format    IN VARCHAR2
    ) RETURN BOOLEAN
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_check_num'; -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    ln_num NUMBER;
--
  BEGIN
--
    ln_num := TO_NUMBER(iv_check_num,iv_format);
    RETURN(TRUE);
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN(FALSE);
  END fnc_check_num;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_table_data_batch
   * Description      : �f�[�^�폜����(B-6)
   ***********************************************************************************/
  PROCEDURE proc_del_table_data_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_table_data_batch'; -- �v���O������
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
    ln_count_err NUMBER DEFAULT 0;
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ROWID PL/SQL�\�^
    TYPE ltbl_hht_work_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    ltbl_hht_work_rowid ltbl_hht_work_rowid_type;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ltbl_hht_work_rowid.DELETE; -- ������
    -- ����f�[�^ROWID
    <<normal_loop>>
    FOR ln_count IN 1..gtbl_normal.COUNT LOOP
      ltbl_hht_work_rowid(ln_count) := gtbl_normal(ln_count).rowid_work;
      ln_count_err := ln_count;
    END LOOP normal_loop;
--
    -- �G���[�f�[�^ROWID
    <<error_loop>>
    FOR ln_count IN 1..gtbl_error.COUNT LOOP
      ln_count_err := ln_count_err + 1;
      ltbl_hht_work_rowid(ln_count_err) := gtbl_error(ln_count).rowid_work;
    END LOOP error_loop;
--
    -- ===============================
    -- HHT�I�����[�N�e�[�u���폜
    -- ===============================
    FORALL ln_count IN 1..ltbl_hht_work_rowid.COUNT
      DELETE xxinv_stc_inventory_hht_work xsihw
      WHERE  ROWID = ltbl_hht_work_rowid(ln_count);
--
    -- ���b�N�擾�J�[�\��CLOSE
    CLOSE gcur_xxinv_stc_inv_hht_work;
--
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
  END proc_del_table_data_batch;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_table_batch
   * Description      : �ꊇ�o�^����(B-5)
   ***********************************************************************************/
  PROCEDURE proc_ins_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_table_batch'; -- �v���O������
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
    ln_val     NUMBER;  -- �I������ID�̘A��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- �I�����ʃe�[�u���^�C�v
    TYPE ltbl_xsir_type IS TABLE OF xxinv_stc_inventory_result%ROWTYPE INDEX BY BINARY_INTEGER;
    ltbl_xsir ltbl_xsir_type;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �ꊇ�o�^����
    -- ===============================
    <<normal_ins_loop>>
    FOR ln_cnt_loop IN 1 .. gtbl_normal_ins.COUNT LOOP
      -- �I������ID�̘A�Ԏ擾
      SELECT xxinv_stc_invt_rslt_s1.NEXTVAL
      INTO   ln_val
      FROM   dual;
      -- �I������ID
      ltbl_xsir(ln_cnt_loop).invent_result_id := ln_val;
      -- �񍐕���
      ltbl_xsir(ln_cnt_loop).report_post_code := gtbl_normal_ins(ln_cnt_loop).report_post_code;
      -- �I����
      ltbl_xsir(ln_cnt_loop).invent_date      := gtbl_normal_ins(ln_cnt_loop).invent_date;
      -- �I���q��
      ltbl_xsir(ln_cnt_loop).invent_whse_code := gtbl_normal_ins(ln_cnt_loop).invent_whse_code;
      -- �I���A��
      ltbl_xsir(ln_cnt_loop).invent_seq       := gtbl_normal_ins(ln_cnt_loop).invent_seq;
      -- �i��ID
      ltbl_xsir(ln_cnt_loop).item_id          := gtbl_normal_ins(ln_cnt_loop).b3_item_id;
      -- �i��
      ltbl_xsir(ln_cnt_loop).item_code        := gtbl_normal_ins(ln_cnt_loop).item_code;
      -- ���b�gID
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- ���i
          ltbl_xsir(ln_cnt_loop).lot_id := gtbl_normal_ins(ln_cnt_loop).b3_lot_id;
        ELSE
          -- ���i�ȊO
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ���b�g�Ǘ�
              ltbl_xsir(ln_cnt_loop).lot_id := gtbl_normal_ins(ln_cnt_loop).b3_lot_id;
            ELSE
              -- ���b�g�Ǘ��ΏۊO
              ltbl_xsir(ln_cnt_loop).lot_id := NULL;
          END CASE;
      END CASE;
      -- ���b�gNo
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- ���i
          ltbl_xsir(ln_cnt_loop).lot_no := gtbl_normal_ins(ln_cnt_loop).b3_lot_no;
        ELSE
          -- ���i�ȊO
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ���b�g�Ǘ�
              ltbl_xsir(ln_cnt_loop).lot_no := gtbl_normal_ins(ln_cnt_loop).lot_no;
            ELSE
              -- ���b�g�Ǘ��ΏۊO
              ltbl_xsir(ln_cnt_loop).lot_no := NULL;
          END CASE;
      END CASE;
      -- ������
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- ���i
          ltbl_xsir(ln_cnt_loop).maker_date := gtbl_normal_ins(ln_cnt_loop).maker_date;
        ELSE
          -- ���i�ȊO
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ���b�g�Ǘ�
              ltbl_xsir(ln_cnt_loop).maker_date := gtbl_normal_ins(ln_cnt_loop).b3_maker_date;
            ELSE
              -- ���b�g�Ǘ��ΏۊO
              ltbl_xsir(ln_cnt_loop).maker_date := NULL;
           END CASE;
      END CASE;
      -- �ܖ�����
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- ���i
          ltbl_xsir(ln_cnt_loop).limit_date := gtbl_normal_ins(ln_cnt_loop).limit_date;
        ELSE
          -- ���i�ȊO
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ���b�g�Ǘ�
              ltbl_xsir(ln_cnt_loop).limit_date := gtbl_normal_ins(ln_cnt_loop).b3_limit_date;
            ELSE
              -- ���b�g�Ǘ��ΏۊO
              ltbl_xsir(ln_cnt_loop).limit_date := NULL;
          END CASE;
      END CASE;
      -- �ŗL�L��
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- ���i
          ltbl_xsir(ln_cnt_loop).proper_mark := gtbl_normal_ins(ln_cnt_loop).proper_mark;
        ELSE
          -- ���i�ȊO
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ���b�g�Ǘ�
              ltbl_xsir(ln_cnt_loop).proper_mark := gtbl_normal_ins(ln_cnt_loop).b3_proper_mark;
            ELSE
              -- ���b�g�Ǘ��ΏۊO
              ltbl_xsir(ln_cnt_loop).proper_mark := NULL;
          END CASE;
      END CASE;
      -- �I���P�[�X��
      ltbl_xsir(ln_cnt_loop).case_amt         := gtbl_normal_ins(ln_cnt_loop).case_amt;
      -- ����
      ltbl_xsir(ln_cnt_loop).content          := gtbl_normal_ins(ln_cnt_loop).content;
      -- �I���o��
      ltbl_xsir(ln_cnt_loop).loose_amt        := gtbl_normal_ins(ln_cnt_loop).loose_amt;
      -- ���P�[�V����
      ltbl_xsir(ln_cnt_loop).location         := gtbl_normal_ins(ln_cnt_loop).location;
      -- ���b�NNo�P
      ltbl_xsir(ln_cnt_loop).rack_no1         := gtbl_normal_ins(ln_cnt_loop).rack_no1;
      -- ���b�NNo�Q
      ltbl_xsir(ln_cnt_loop).rack_no2         := gtbl_normal_ins(ln_cnt_loop).rack_no2;
      -- ���b�NNo�R
      ltbl_xsir(ln_cnt_loop).rack_no3         := gtbl_normal_ins(ln_cnt_loop).rack_no3;
-- 2008/12/06 T.Miyata Add Start �{�ԏ�Q#510 ���t���������킹�邽�߁A��xTO_DATE����B
        -- ������
        IF (ltbl_xsir(ln_cnt_loop).maker_date <> '0') THEN
          ltbl_xsir(ln_cnt_loop).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_cnt_loop).maker_date, gc_char_d_format), gc_char_d_format);
        END IF;
--
        -- �ܖ�����
        IF (ltbl_xsir(ln_cnt_loop).limit_date <> '0') THEN
          ltbl_xsir(ln_cnt_loop).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_cnt_loop).limit_date, gc_char_d_format), gc_char_d_format);
        END IF;
-- 2008/12/06 T.Miyata Add End
      -- WHO���
      ltbl_xsir(ln_cnt_loop).created_by             := gn_user_id;
      ltbl_xsir(ln_cnt_loop).creation_date          := gd_sysdate;
      ltbl_xsir(ln_cnt_loop).last_updated_by        := gn_user_id;
      ltbl_xsir(ln_cnt_loop).last_update_date       := gd_sysdate;
      ltbl_xsir(ln_cnt_loop).last_update_login      := gn_user_id;
      ltbl_xsir(ln_cnt_loop).request_id             := gn_request_id;
      ltbl_xsir(ln_cnt_loop).program_application_id := gn_program_appl_id;
      ltbl_xsir(ln_cnt_loop).program_id             := gn_program_id;
      ltbl_xsir(ln_cnt_loop).program_update_date    := gd_sysdate;
    END LOOP normal_ins_loop;
--
    -- ===============================
    -- �I�����ʃe�[�u���ꊇ�X�V
    -- ===============================
    FORALL ln_cnt_loop in 1..ltbl_xsir.COUNT
      INSERT INTO xxinv_stc_inventory_result VALUES ltbl_xsir(ln_cnt_loop);
--
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
  END proc_ins_table_batch;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_table_batch
   * Description      : �ꊇ�X�V����(B-4)
   ***********************************************************************************/
  PROCEDURE proc_upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_table_batch'; -- �v���O������
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
    ln_upd_cnt    NUMBER DEFAULT 0; -- �X�V�����J�E���g
    ln_ins_cnt    NUMBER DEFAULT 0; -- �}�������J�E���g
    lr_rowid      ROWID;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �I�����ʃe�[�u��(�i�ڋ敪�����i)
    CURSOR lcur_xxinv_stc_inv_res_pt(
      itbl_hht_work gtbl_hht_work)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
      WHERE  xsir.invent_seq       = itbl_hht_work.invent_seq       -- �I���A��
      AND    xsir.invent_whse_code = itbl_hht_work.invent_whse_code -- �I���q��
      AND    xsir.report_post_code = itbl_hht_work.report_post_code -- �񍐕���
      AND    xsir.item_code        = itbl_hht_work.item_code        -- �i��
      AND    xsir.invent_date      = itbl_hht_work.invent_date      -- �I����
-- 2008/12/06 T.Miyata Add Start
--      AND    xsir.maker_date       = itbl_hht_work.maker_date       -- ������
--      AND    xsir.limit_date       = itbl_hht_work.limit_date       -- �ܖ�����
      AND    fnc_check_date(xsir.maker_date) = fnc_check_date(itbl_hht_work.maker_date) -- ������
--test      AND    fnc_check_date(xsir.limit_date) = fnc_check_date(itbl_hht_work.limit_date)  -- �ܖ�����
-- 2008/12/06 T.Miyata Add End
      AND    xsir.proper_mark      = itbl_hht_work.proper_mark      -- �ŗL�L��
      FOR UPDATE NOWAIT;
--
    -- �I�����ʃe�[�u��(�i�ڋ敪�����i�ȊO ���� ���b�g�Ǘ��Ώ�)
    CURSOR lcur_xxinv_stc_inv_res_npt_lot(
      itbl_hht_work gtbl_hht_work)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
      WHERE  xsir.invent_seq       = itbl_hht_work.invent_seq       -- �I���A��
      AND    xsir.invent_whse_code = itbl_hht_work.invent_whse_code -- �I���q��
      AND    xsir.report_post_code = itbl_hht_work.report_post_code -- �񍐕���
      AND    xsir.item_code        = itbl_hht_work.item_code        -- �i��
      AND    xsir.invent_date      = itbl_hht_work.invent_date      -- �I����
      AND    xsir.lot_id           = itbl_hht_work.b3_lot_id        -- ���b�gID
      FOR UPDATE NOWAIT;
--
    -- �I�����ʃe�[�u��(�i�ڋ敪�����i�ȊO ���� ���b�g�Ǘ��ΏۊO)
    CURSOR lcur_xxinv_stc_inv_res_npt(
      itbl_hht_work gtbl_hht_work)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
      WHERE  xsir.invent_seq       = itbl_hht_work.invent_seq       -- �I���A��
      AND    xsir.invent_whse_code = itbl_hht_work.invent_whse_code -- �I���q��
      AND    xsir.report_post_code = itbl_hht_work.report_post_code -- �񍐕���
      AND    xsir.item_code        = itbl_hht_work.item_code        -- �i��
      AND    xsir.invent_date      = itbl_hht_work.invent_date      -- �I����
      FOR UPDATE NOWAIT;
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �P�����ƍX�V���� �����b�N���P���P�ʂł����o���Ȃ����߁AFORALL�͎g���܂���B
    -- ===============================
    <<upd_table_batch_loop>>
    FOR ln_cnt_loop IN 1 .. gtbl_normal.COUNT LOOP
--
      lr_rowid := NULL;
-- 2008/12/06 T.Miyata Add Start �{�ԏ�Q#510 ���t���������킹�邽�߁A��xTO_DATE����B
      -- ������
      IF (gtbl_normal(ln_cnt_loop).maker_date <> '0') THEN
        gtbl_normal(ln_cnt_loop).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(gtbl_normal(ln_cnt_loop).maker_date, gc_char_d_format), gc_char_d_format);
      END IF;
--
      -- �ܖ�����
      IF (gtbl_normal(ln_cnt_loop).limit_date <> '0') THEN
        gtbl_normal(ln_cnt_loop).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(gtbl_normal(ln_cnt_loop).limit_date, gc_char_d_format), gc_char_d_format);
      END IF;
-- 2008/12/06 T.Miyata Add End
      BEGIN
        IF (gtbl_normal(ln_cnt_loop).b3_item_class_code = gv_item_class_products) THEN
          -- �i�ڋ敪�����i
          OPEN  lcur_xxinv_stc_inv_res_pt(
            gtbl_normal(ln_cnt_loop));        -- ���b�N�擾�J�[�\��OPEN
--
          FETCH lcur_xxinv_stc_inv_res_pt INTO lr_rowid;
--
          IF (lcur_xxinv_stc_inv_res_pt%NOTFOUND) THEN
            ln_ins_cnt := gtbl_normal_ins.COUNT + 1;
            gtbl_normal_ins(ln_ins_cnt) := gtbl_normal(ln_cnt_loop); -- ����f�[�^�}��
          ELSE
            ln_upd_cnt := ln_upd_cnt + 1;
            UPDATE xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
            SET    xsir.case_amt               = gtbl_normal(ln_cnt_loop).case_amt  -- �I���P�[�X��
                  ,xsir.content                = gtbl_normal(ln_cnt_loop).content   -- ����
                  ,xsir.loose_amt              = gtbl_normal(ln_cnt_loop).loose_amt -- �I���o��
                  ,xsir.location               = gtbl_normal(ln_cnt_loop).location  -- ���P�[�V����
                  ,xsir.rack_no1               = gtbl_normal(ln_cnt_loop).rack_no1  -- ���b�NNo�P
                  ,xsir.rack_no2               = gtbl_normal(ln_cnt_loop).rack_no2  -- ���b�NNo�Q
                  ,xsir.rack_no3               = gtbl_normal(ln_cnt_loop).rack_no3  -- ���b�NNo�R
                   -- WHO�J����
                  ,xsir.last_updated_by        = gn_user_id
                  ,xsir.last_update_date       = gd_sysdate
                  ,xsir.last_update_login      = gn_user_id
                  ,xsir.request_id             = gn_request_id
                  ,xsir.program_application_id = gn_program_appl_id
                  ,xsir.program_id             = gn_program_id
                  ,xsir.program_update_date    = gd_sysdate
            WHERE  xsir.ROWID = lr_rowid;
          END IF;
--
          CLOSE lcur_xxinv_stc_inv_res_pt; -- ���b�N�擾�J�[�\��CLOSE
--
        ELSE
          -- �i�ڋ敪�����i�ȊO
          IF (gtbl_normal(ln_cnt_loop).b3_lot_ctl = gn_y) THEN
            -- ���b�g�Ǘ��Ώ�
            OPEN  lcur_xxinv_stc_inv_res_npt_lot(
              gtbl_normal(ln_cnt_loop));        -- ���b�N�擾�J�[�\��OPEN
--
            FETCH lcur_xxinv_stc_inv_res_npt_lot INTO lr_rowid;
--
            IF (lcur_xxinv_stc_inv_res_npt_lot%NOTFOUND) THEN
              ln_ins_cnt := gtbl_normal_ins.COUNT + 1;
              gtbl_normal_ins(ln_ins_cnt) := gtbl_normal(ln_cnt_loop); -- ����f�[�^�}��
            ELSE
              ln_upd_cnt := ln_upd_cnt + 1;
              UPDATE xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
              SET
                 xsir.case_amt               = gtbl_normal(ln_cnt_loop).case_amt  -- �I���P�[�X��
                ,xsir.content                = gtbl_normal(ln_cnt_loop).content   -- ����
                ,xsir.loose_amt              = gtbl_normal(ln_cnt_loop).loose_amt -- �I���o��
                ,xsir.location               = gtbl_normal(ln_cnt_loop).location  -- ���P�[�V����
                ,xsir.rack_no1               = gtbl_normal(ln_cnt_loop).rack_no1  -- ���b�NNo�P
                ,xsir.rack_no2               = gtbl_normal(ln_cnt_loop).rack_no2  -- ���b�NNo�Q
                ,xsir.rack_no3               = gtbl_normal(ln_cnt_loop).rack_no3  -- ���b�NNo�R
                 -- WHO�J����
                ,xsir.last_updated_by        = gn_user_id
                ,xsir.last_update_date       = gd_sysdate
                ,xsir.last_update_login      = gn_user_id
                ,xsir.request_id             = gn_request_id
                ,xsir.program_application_id = gn_program_appl_id
                ,xsir.program_id             = gn_program_id
                ,xsir.program_update_date    = gd_sysdate
              WHERE xsir.ROWID = lr_rowid;
            END IF;
--
            CLOSE lcur_xxinv_stc_inv_res_npt_lot; -- ���b�N�擾�J�[�\��CLOSE
--
          ELSE
            -- ���b�g�Ǘ��ΏۊO
            OPEN  lcur_xxinv_stc_inv_res_npt(
              gtbl_normal(ln_cnt_loop));        -- ���b�N�擾�J�[�\��OPEN
--
            FETCH lcur_xxinv_stc_inv_res_npt INTO lr_rowid;
--
            IF (lcur_xxinv_stc_inv_res_npt%NOTFOUND) THEN
              ln_ins_cnt := gtbl_normal_ins.COUNT + 1;
              gtbl_normal_ins(ln_ins_cnt) := gtbl_normal(ln_cnt_loop); -- ����f�[�^�}��
            ELSE
              ln_upd_cnt := ln_upd_cnt + 1;
              UPDATE xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
              SET
                 xsir.case_amt               = gtbl_normal(ln_cnt_loop).case_amt  -- �I���P�[�X��
                ,xsir.content                = gtbl_normal(ln_cnt_loop).content   -- ����
                ,xsir.loose_amt              = gtbl_normal(ln_cnt_loop).loose_amt -- �I���o��
                ,xsir.location               = gtbl_normal(ln_cnt_loop).location  -- ���P�[�V����
                ,xsir.rack_no1               = gtbl_normal(ln_cnt_loop).rack_no1  -- ���b�NNo�P
                ,xsir.rack_no2               = gtbl_normal(ln_cnt_loop).rack_no2  -- ���b�NNo�Q
                ,xsir.rack_no3               = gtbl_normal(ln_cnt_loop).rack_no3  -- ���b�NNo�R
                 -- WHO�J����
                ,xsir.last_updated_by        = gn_user_id
                ,xsir.last_update_date       = gd_sysdate
                ,xsir.last_update_login      = gn_user_id
                ,xsir.request_id             = gn_request_id
                ,xsir.program_application_id = gn_program_appl_id
                ,xsir.program_id             = gn_program_id
                ,xsir.program_update_date    = gd_sysdate
              WHERE xsir.ROWID = lr_rowid;
            END IF;
--
            CLOSE lcur_xxinv_stc_inv_res_npt; -- ���b�N�擾�J�[�\��CLOSE
--
          END IF;
--
        END IF;
--
      EXCEPTION
        WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
          -- �J�[�\����CLOSE(���i)
          IF (lcur_xxinv_stc_inv_res_pt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_res_pt;
          END IF;
          -- �J�[�\����CLOSE(���i�ȊO ���b�g�Ώ�)
          IF (lcur_xxinv_stc_inv_res_npt_lot%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_res_npt_lot;
          END IF;
          -- �J�[�\����CLOSE(���i�ȊO ���b�g�ΏۊO)
          IF (lcur_xxinv_stc_inv_res_npt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_res_npt;
          END IF;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                         gv_xxcmn
                        ,'APP-XXCMN-10019'
                        ,'TABLE'
                        ,gv_inv_result_name
                        ),1,5000);
          RAISE global_user_expt;
      END;
--
    END LOOP upd_table_batch_loop;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
  END proc_upd_table_batch;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_data_dump
   * Description      : �f�[�^�_���v���쐬���܂��B
   ***********************************************************************************/
  FUNCTION fnc_get_data_dump(
    itbl__hht_work IN gtbl_hht_work -- �f�[�^�_���v�����R�[�h
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_data_dump'; -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_dump VARCHAR2(2000);
--
  BEGIN
--
    -- ===============================
    -- �f�[�^�_���v�쐬
    -- ===============================
    lv_dump :=
      itbl__hht_work.invent_hht_if_id || gv_msg_comma || -- HHT�I��IF_ID
      itbl__hht_work.report_post_code || gv_msg_comma || -- �񍐕���
      itbl__hht_work.invent_date      || gv_msg_comma || -- �I����
      itbl__hht_work.invent_whse_code || gv_msg_comma || -- �I���q��
      itbl__hht_work.invent_seq       || gv_msg_comma || -- �I���A��
      itbl__hht_work.item_code        || gv_msg_comma || -- �i��
      itbl__hht_work.lot_no           || gv_msg_comma || -- ���b�gNo.
      itbl__hht_work.maker_date       || gv_msg_comma || -- ������
      itbl__hht_work.limit_date       || gv_msg_comma || -- �ܖ�����
      itbl__hht_work.proper_mark      || gv_msg_comma || -- �ŗL�L��
      itbl__hht_work.case_amt         || gv_msg_comma || -- �I���P�[�X��
      itbl__hht_work.content          || gv_msg_comma || -- ����
      itbl__hht_work.loose_amt        || gv_msg_comma || -- �I���o��
      itbl__hht_work.location         || gv_msg_comma || -- ���P�[�V����
      itbl__hht_work.rack_no1         || gv_msg_comma || -- ���b�NNo�P
      itbl__hht_work.rack_no2         || gv_msg_comma || -- ���b�NNo�Q
      itbl__hht_work.rack_no3;                           -- ���b�NNo�R
--
    RETURN(lv_dump) ;
--
  END fnc_get_data_dump;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���(B-4)
   ***********************************************************************************/
  PROCEDURE proc_put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_dump_msg'; -- �v���O������
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
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�ꊇ�o��
    -- ===============================
    IF ((gtbl_error.COUNT > 0)
      OR (gtbl_reserve.COUNT > 0)) THEN
--
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
      -- �G���[�f�[�^�i���o���j
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                   gv_xxcmn
                  ,'APP-XXCMN-00006'
                  ),1,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
      -- �G���[�f�[�^�_���v
      <<error_dump_loop>>
      FOR ln_cnt_loop IN 1 .. gtbl_error.COUNT LOOP
        -- �_���v�o��
        lv_msg := fnc_get_data_dump(gtbl_error(ln_cnt_loop));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
        -- �G���[���b�Z�[�W�o��
        lv_msg := gtbl_error(ln_cnt_loop).err_msg;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
      END LOOP error_dump_loop;
--
      -- �ۗ��f�[�^�_���v
      <<reserve_dump_loop>>
      FOR ln_cnt_loop IN 1 .. gtbl_reserve.COUNT LOOP
        -- �_���v�o��
        lv_msg := fnc_get_data_dump(gtbl_reserve(ln_cnt_loop));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
        -- �G���[���b�Z�[�W�o��
        lv_msg := gtbl_reserve(ln_cnt_loop).err_msg;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
      END LOOP reserve_dump_loop;
--
    END IF;
--
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
  END proc_put_dump_msg;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_check
   * Description      : �Ó����`�F�b�N(B-3)
   ***********************************************************************************/
  PROCEDURE proc_check(
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check'; -- �v���O������
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
    cv_case_amt_format CONSTANT VARCHAR2(10) := '999999999D';  -- �I���P�[�X���A���l�t�H�[�}�b�g
--
    -- *** ���[�J���ϐ� ***
--
    ln_item_id         xxcmn_item_mst_v.item_id%TYPE;                 -- �i��ID
    ln_lot_ctl         xxcmn_item_mst_v.lot_ctl%TYPE;                 -- ���b�g�Ǘ��敪
    lv_num_of_cases    xxcmn_item_mst_v.num_of_cases%TYPE;            -- �P�[�X����
    lv_item_class_code xxcmn_item_categories4_v.item_class_code%TYPE; -- �i�ڋ敪
    lv_prod_class_code xxcmn_item_categories4_v.prod_class_code%TYPE; -- ���i�敪
    ln_lot_id          NUMBER;        -- ���b�gID
    ln_lot_no          NUMBER;        -- ���b�gNO
    lv_maker_date      VARCHAR2(240); -- �����N����
    lv_proper_mark     VARCHAR2(240); -- �ŗL�L��
    lv_limit_date      VARCHAR2(240); -- �ܖ�����
    lv_errbuf_work     VARCHAR2(5000);
--
    lb_err_flag        BOOLEAN DEFAULT FALSE; -- �G���[�t���O
    lb_warn_flag       BOOLEAN DEFAULT FALSE; -- �ۗ��t���O
--
    ln_normal_cnt      NUMBER DEFAULT 0;
    ln_error_cnt       NUMBER DEFAULT 0;
    ln_reserve_cnt     NUMBER DEFAULT 0;
--
    ln_whse_cnt        NUMBER DEFAULT 0;
    ln_location_cnt    NUMBER DEFAULT 0;
    ln_ret             NUMBER DEFAULT 0;
    --2008/05/02
    ld_maker_date      DATE  DEFAULT NULL;--�������`�F�b�N�p
    ld_limit_date      DATE  DEFAULT NULL;--�ܖ������`�F�b�N�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    <<check_loop>>
    FOR ln_cnt_loop IN 1..gtbl_data.COUNT LOOP
      -- ������
      ln_lot_id      := NULL;  -- ���b�gID
      ln_lot_no      := NULL;  -- ���b�gNO
      lv_maker_date  := NULL;  -- �����N����
      lv_proper_mark := NULL;  -- �ŗL�L��
      lv_limit_date  := NULL;  -- �ܖ�����
      lb_err_flag    := FALSE; -- �G���[�t���O
      lb_warn_flag   := FALSE; -- �ۗ��t���O
      -- ==============================================================
      -- �i�ڃ}�X�^�`�F�b�N
      -- ==============================================================
      BEGIN
        SELECT
          ximv.item_id          AS item_id         -- �i��ID
         ,ximv.lot_ctl          AS lot_ctl         -- ���b�g�Ǘ��敪
         ,ximv.num_of_cases     AS num_of_cases    -- �P�[�X����
         ,xic4v.item_class_code AS item_class_code -- �i�ڋ敪
         ,xic4v.prod_class_code AS prod_class_code -- ���i�敪
        INTO
          ln_item_id
         ,ln_lot_ctl
         ,lv_num_of_cases
         ,lv_item_class_code
         ,lv_prod_class_code
        FROM   xxcmn_item_mst_v         ximv
              ,xxcmn_item_categories4_v xic4v
        WHERE  ximv.item_no  = gtbl_data(ln_cnt_loop).item_code
        AND    xic4v.item_id = ximv.item_id;
      EXCEPTION
        -- �f�[�^���Ȃ��ꍇ�͌x��(�G���[)
        WHEN NO_DATA_FOUND THEN
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10102',
                              iv_token_name1  => 'TABLE',
                              iv_token_value1 => gv_opm_item_name,
                              iv_token_name2  => 'OBJECT',
                              iv_token_value2 =>
                                gv_item_col || gv_msg_part || gtbl_data(ln_cnt_loop).item_code);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
          lb_err_flag := TRUE;
      END;
      -- �擾���ڂ�ێ����܂��B
      gtbl_data(ln_cnt_loop).b3_item_id         := ln_item_id;         -- b3_�i��ID
      gtbl_data(ln_cnt_loop).b3_lot_ctl         := ln_lot_ctl;         -- b3_���b�g�Ǘ��敪
      gtbl_data(ln_cnt_loop).b3_num_of_cases    := lv_num_of_cases;    -- b3_�P�[�X����
      gtbl_data(ln_cnt_loop).b3_item_class_code := lv_item_class_code; -- b3_�i�ڋ敪
      gtbl_data(ln_cnt_loop).b3_prod_class_code := lv_prod_class_code; -- b3_���i�敪
--
      -- ==============================================================
      -- �d���`�F�b�N
      -- ==============================================================
      IF (lv_item_class_code = gv_item_class_products) THEN
        -- �i�ڋ敪�����i
        IF (gtbl_data(ln_cnt_loop).b_invent_seq IS NOT NULL) THEN
          -- �I���A�ԁE�I���q�ɁE�񍐕����E�i�ځE�������E�ܖ������E�ŗL�L���ŏd���L��(�G���[)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10101');
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
          lb_err_flag := TRUE;
        END IF;
      ELSE
        -- �i�ڋ敪�����i�ȊO
        IF (gtbl_data(ln_cnt_loop).c_invent_seq IS NOT NULL) THEN
          -- �I���A�ԁE�I���q�ɁE�񍐕����E�i�ځE���b�gNo�E�I�����ŏd���L��(�G���[)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10101');
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
          lb_err_flag := TRUE;
        END IF;
      END IF;
  --
      -- ==============================================================
      -- �I���q�Ƀ}�X�^�`�F�b�N
      -- ==============================================================
      SELECT COUNT(xilv.whse_code) AS whse_cnt
      INTO ln_whse_cnt
      FROM xxcmn_item_locations_v xilv
      WHERE xilv.whse_code = gtbl_data(ln_cnt_loop).invent_whse_code;
--
      IF (ln_whse_cnt = 0) THEN
        -- ���o�^�̏ꍇ�G���[(�G���[)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10102',
                            iv_token_name1  => 'TABLE',
                            iv_token_value1 => gv_invent_whse_name,
                            iv_token_name2  => 'OBJECT',
                            iv_token_value2 => gv_inv_whse_code_col
                              || gv_msg_part || gtbl_data(ln_cnt_loop).invent_whse_code);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- �񍐕����}�X�^�`�F�b�N
      -- ==============================================================
      SELECT COUNT(xlv.location_code) AS location_cnt
      INTO ln_location_cnt
      FROM xxcmn_locations_v xlv
      WHERE xlv.location_code = gtbl_data(ln_cnt_loop).report_post_code;
--
      IF (ln_location_cnt = 0) THEN
        -- ���o�^�̏ꍇ�G���[(�G���[)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10102',
                            iv_token_name1  => 'TABLE',
                            iv_token_value1 => gv_report_post_name,
                            iv_token_name2  => 'OBJECT',
                            iv_token_value2 => gv_report_post_code_col
                              || gv_msg_part || gtbl_data(ln_cnt_loop).report_post_code);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- ���b�gNo�}�X�^�`�F�b�N
      -- ==============================================================
      IF (lv_item_class_code != gv_item_class_products) THEN
        -- �i�ڋ敪�����i�ȊO
        IF (ln_lot_ctl = gn_y) THEN
          -- ���b�g�Ǘ��Ώ�
          IF (gtbl_data(ln_cnt_loop).lot_no = 0) THEN
            -- 0�̏ꍇ�G���[(�G���[)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_lot_no_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          -- --------------------------------------------------------------
          -- OPM���b�g�}�X�^���݃`�F�b�N
          -- --------------------------------------------------------------
          BEGIN
            SELECT
              ilm.lot_id     AS lot_id     -- ���b�gID
             ,ilm.attribute1 AS attribute1 -- �����N����
             ,ilm.attribute2 AS attribute2 -- �ŗL�L��
             ,ilm.attribute3 AS attribute3 -- �ܖ�����
            INTO
              ln_lot_id
             ,lv_maker_date
             ,lv_proper_mark
             ,lv_limit_date
            FROM   ic_lots_mst ilm
            WHERE  ilm.lot_no  = gtbl_data(ln_cnt_loop).lot_no
            AND    ilm.item_id = ln_item_id
            AND    ROWNUM      = 1;
          EXCEPTION
            -- �f�[�^���Ȃ��ꍇ�͌x��(�ۗ�)
            WHEN NO_DATA_FOUND THEN
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10108',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_lot_no_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).lot_no ||
                                    gv_msg_comma ||
                                    gv_item_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).item_code);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
              lb_warn_flag := TRUE;
          END;
          -- �擾���ڂ�ێ����܂��B
          gtbl_data(ln_cnt_loop).b3_lot_id      := NVL(ln_lot_id,gn_zero); -- b3_���b�gID
          gtbl_data(ln_cnt_loop).b3_maker_date  := lv_maker_date;  -- b3_�����N����
          gtbl_data(ln_cnt_loop).b3_proper_mark := lv_proper_mark; -- b3_�ŗL�L��
          gtbl_data(ln_cnt_loop).b3_limit_date  := lv_limit_date;  -- b3_�ܖ�����
        ELSE
          -- ���b�g�Ǘ��ΏۊO
          IF (gtbl_data(ln_cnt_loop).lot_no != 0) THEN
            -- 0�ȊO�̏ꍇ�G���[(�G���[)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10103',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_lot_no_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
        END IF;
      END IF;
--
      -- ==============================================================
      -- �������A�ܖ������A�ŗL�L��
      -- ==============================================================
      IF (lv_item_class_code = gv_item_class_products) THEN
        -- �i�ڋ敪�����i
        IF (lv_prod_class_code = gv_goods_classe_drink) THEN
          -- ���i�敪���h�����N
          -- a
          IF (gtbl_data(ln_cnt_loop).maker_date = gv_zero) THEN
            -- �������A0�̏ꍇ�G���[
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_maker_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          IF (gtbl_data(ln_cnt_loop).limit_date = gv_zero) THEN
            -- �ܖ������A0�̏ꍇ�G���[
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_limit_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          IF (gtbl_data(ln_cnt_loop).proper_mark = gv_zero) THEN
            -- �ŗL�L���A0�̏ꍇ�G���[
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_proper_mark_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          -- �������̓��t�`���`�F�b�N(yyyy/mm/dd)
          ld_maker_date :=  FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).maker_date, gv_date);
          IF  (ld_maker_date IS NULL) THEN
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10105',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_maker_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
           -- �ܖ������̓��t�`���`�F�b�N(yyyy/mm/dd)
          ld_limit_date :=  FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).limit_date, gv_date);
          IF  (ld_limit_date IS NULL) THEN
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10105',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_limit_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          -- c
          -- --------------------------------------------------------------
          -- OPM���b�g�}�X�^���݃`�F�b�N
          -- --------------------------------------------------------------
          BEGIN
            SELECT
              ilm.lot_id     AS lot_id     -- ���b�gID
             ,ilm.lot_no     AS lot_no     -- ���b�gNO
             ,ilm.attribute3 AS attribute3 -- �ܖ�����
            INTO
              ln_lot_id
             ,ln_lot_no
             ,lv_limit_date
            FROM   ic_lots_mst ilm
            WHERE  ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gv_date) || ''--������2008/05/02
            AND    ilm.attribute2 = gtbl_data(ln_cnt_loop).proper_mark
            AND    ilm.item_id    = ln_item_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- OPM���b�g�}�X�^�ɖ��o�^(�ۗ�)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10108',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_maker_date_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).maker_date ||
                                    gv_msg_comma ||
                                    gv_proper_mark_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).proper_mark);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
              lb_warn_flag := TRUE;
            WHEN TOO_MANY_ROWS THEN
              -- OPM���b�g�}�X�^�ɕ����o�^(�ۗ�)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10109',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_maker_date_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).maker_date ||
                                    gv_msg_comma ||
                                    gv_proper_mark_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).proper_mark);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
              lb_warn_flag := TRUE;
          END;
          -- �擾���ڂ�ێ����܂��B
          gtbl_data(ln_cnt_loop).b3_lot_id      := NVL(ln_lot_id,gn_zero); -- b3_���b�gID
          gtbl_data(ln_cnt_loop).b3_lot_no      := ln_lot_no;              -- b3_���b�gNO
          gtbl_data(ln_cnt_loop).b3_limit_date  := lv_limit_date;          -- b3_�ܖ�����
--
          -- �ܖ������̈�v�`�F�b�N
          IF (lv_limit_date IS NOT NULL) THEN
            IF (FND_DATE.STRING_TO_DATE(lv_limit_date, gv_date) != ld_limit_date) THEN
              -- �ܖ������̕s��v(�ۗ�)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10110',
                                  iv_token_name1  => 'OBEJCT',
                                  iv_token_value1 => gv_limit_date_col,
                                  iv_token_name2  => 'CONTENT',
                                  iv_token_value2 => gv_limit_date_col ||
                                    gv_msg_part || lv_limit_date);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
              lb_warn_flag := TRUE;
            END IF;
          END IF;
        ELSE
          -- ���i�敪�F���[�t
          -- a
          IF (gtbl_data(ln_cnt_loop).limit_date = gv_zero) THEN
            -- �ܖ������A0�̏ꍇ�G���[(�G���[)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_limit_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          IF (gtbl_data(ln_cnt_loop).proper_mark = gv_zero) THEN
            -- �ŗL�L���A0�̏ꍇ�G���[(�G���[)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_proper_mark_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          -- b
          -- �ܖ������̓��t�`���`�F�b�N(yyyy/mm/dd)
          ld_limit_date :=  FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).limit_date, gv_date);
          IF  (ld_limit_date IS NULL) THEN
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxcmn,
                                iv_name         => 'APP-XXCMN-10012',
                                iv_token_name1  => 'ITEM',
                                iv_token_value1 => gv_limit_date_col,
                                iv_token_name2  => 'VALUE',
                                iv_token_value2 => gtbl_data(ln_cnt_loop).limit_date);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
          -- �������̓��t�`���ϊ�(yyyy/mm/dd)
          ld_maker_date := FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).maker_date, gv_date);
          -- c
          -- --------------------------------------------------------------
          -- OPM���b�g�}�X�^���݃`�F�b�N
          -- --------------------------------------------------------------
          BEGIN
            SELECT
              ilm.lot_id     AS lot_id     -- ���b�gID
             ,ilm.lot_no     AS lot_no     -- ���b�gNO
             ,ilm.attribute3 AS attribute3 -- �ܖ�����
            INTO
              ln_lot_id
             ,ln_lot_no
             ,lv_limit_date
            FROM   ic_lots_mst ilm
            WHERE  ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gv_date) || ''--������2008/05/02
            AND    ilm.attribute2 = gtbl_data(ln_cnt_loop).proper_mark
            AND    ilm.item_id    = ln_item_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- --------------------------------------------------------------
              -- OPM���b�g�}�X�^���݃`�F�b�N
              -- --------------------------------------------------------------
              BEGIN
                SELECT
                  ilm.lot_id     AS lot_id     -- ���b�gID
                 ,ilm.lot_no     AS lot_no     -- ���b�gNO
                 ,ilm.attribute1 AS attribute1 -- �����N����
                INTO
                  ln_lot_id
                 ,ln_lot_no
                 ,lv_maker_date
                FROM   ic_lots_mst ilm
                WHERE  ilm.attribute2 = gtbl_data(ln_cnt_loop).proper_mark
                AND    ilm.attribute3 = ''
                                     || TO_CHAR(ld_limit_date, gv_date) || ''--�ܖ�����2008/05/02
                AND    ilm.item_id    = ln_item_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- OPM���b�g�}�X�^�ɖ��o�^(�ۗ�)
                  lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                      iv_application  => gv_xxinv,
                                      iv_name         => 'APP-XXINV-10108',
                                      iv_token_name1  => 'OBJECT',
                                      iv_token_value1 =>
                                        gv_proper_mark_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).proper_mark ||
                                        gv_msg_comma ||
                                        gv_limit_date_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).limit_date);
                  ln_reserve_cnt := gtbl_reserve.COUNT + 1;
                  gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
                  gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
                  lb_warn_flag := TRUE;
                WHEN TOO_MANY_ROWS THEN
                  -- OPM���b�g�}�X�^�ɕ����o�^(�ۗ�)
                  lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                      iv_application  => gv_xxinv,
                                      iv_name         => 'APP-XXINV-10109',
                                      iv_token_name1  => 'OBJECT',
                                      iv_token_value1 =>
                                        gv_proper_mark_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).proper_mark ||
                                        gv_msg_comma ||
                                        gv_limit_date_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).limit_date);
                  ln_reserve_cnt := gtbl_reserve.COUNT + 1;
                  gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
                  gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
                  lb_warn_flag := TRUE;
              END;
--
            WHEN TOO_MANY_ROWS THEN
              -- OPM���b�g�}�X�^�ɕ����o�^(�ۗ�)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10109',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_maker_date_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).maker_date ||
                                    gv_msg_comma ||
                                    gv_proper_mark_col ||
                                    gv_msg_part || gtbl_data(ln_cnt_loop).proper_mark);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
              lb_warn_flag := TRUE;
          END;
          -- �擾���ڂ�ێ����܂��B
          gtbl_data(ln_cnt_loop).b3_lot_id     := NVL(ln_lot_id,gn_zero); -- b3_���b�gID
          gtbl_data(ln_cnt_loop).b3_lot_no     := ln_lot_no;     -- b3_���b�gNO
          gtbl_data(ln_cnt_loop).b3_limit_date := lv_limit_date; -- b3_�ܖ�����
          -- �ܖ������̈�v�`�F�b�N
          IF (lv_limit_date IS NOT NULL) THEN
            IF (FND_DATE.STRING_TO_DATE(lv_limit_date, gv_date) != ld_limit_date) THEN
              -- �ܖ������̕s��v(�ۗ�)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10110',
                                  iv_token_name1  => 'OBEJCT',
                                  iv_token_value1 => gv_limit_date_col,
                                  iv_token_name2  => 'CONTENT',
                                  iv_token_value2 => gv_limit_date_col ||
                                    gv_msg_part || lv_limit_date);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
              lb_warn_flag := TRUE;
            END IF;
          END IF;
        END IF;
--
      ELSE
        -- �i�ڋ敪�����i�ȊO
        IF (gtbl_data(ln_cnt_loop).maker_date != gv_zero) THEN
          -- �������A0�ȊO�̏ꍇ�G���[(�G���[)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_maker_date_col);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
          lb_err_flag := TRUE;
        END IF;
        IF (gtbl_data(ln_cnt_loop).limit_date != gv_zero) THEN
          -- ��������A0�ȊO�̏ꍇ�G���[(�G���[)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
          lb_err_flag := TRUE;
        END IF;
        IF (gtbl_data(ln_cnt_loop).proper_mark != gv_zero) THEN
          -- �ŗL�L���A0�ȊO�̏ꍇ�G���[(�G���[)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
          lb_err_flag := TRUE;
        END IF;
--
      END IF;
--
      -- ==============================================================
      -- �I���P�[�X���l�`�F�b�N
      -- ==============================================================
      IF (gtbl_data(ln_cnt_loop).case_amt < gn_zero) THEN
        -- �I���P�[�X�A0�����̏ꍇ�G���[(�G���[)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10106',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_case_amt_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
        lb_err_flag := TRUE;
      END IF;
--
      IF (
          fnc_check_num(
            iv_check_num => gtbl_data(ln_cnt_loop).case_amt
           ,iv_format    => cv_case_amt_format) = FALSE
         ) THEN
        -- �I���P�[�X�A���l�ϊ��G���[(�G���[)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10107',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_case_amt_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- �I���o�����l�`�F�b�N
      -- ==============================================================
      IF (gtbl_data(ln_cnt_loop).loose_amt < gn_zero) THEN
        -- �I���o���A0�����̏ꍇ�G���[(�G���[)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10106',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_loose_amt_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- �����l�`�F�b�N
      -- ==============================================================
      IF (gtbl_data(ln_cnt_loop).content < gn_zero) THEN
        -- �����A0�����̏ꍇ�G���[(�G���[)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10106',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_content_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
        lb_err_flag := TRUE;
      ELSE
        IF (lv_item_class_code = gv_item_class_products) AND
           (lv_prod_class_code = gv_goods_classe_drink) THEN
          -- �i�ڋ敪�����i�� ���� ���i�敪���h�����N
          IF (lv_num_of_cases != gtbl_data(ln_cnt_loop).content) THEN
            -- �����̕s��v(�G���[)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10110',
                                iv_token_name1  => 'OBEJCT',
                                iv_token_value1 => gv_content_col,
                                iv_token_name2  => 'CONTENT',
                                iv_token_value2 => gv_content_col ||
                                  gv_msg_part || gtbl_data(ln_cnt_loop).content);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- ���̓f�[�^�ޔ�
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- �G���[���b�Z�[�W�Z�b�g
            lb_err_flag := TRUE;
          END IF;
        END IF;
--
      END IF;
--
      -- ����f�[�^�̃Z�b�g
      IF ((lb_err_flag = FALSE)
        AND (lb_warn_flag = FALSE)) THEN
        -- �G���[�Ȃ��̏ꍇ
        ln_normal_cnt := gtbl_normal.COUNT + 1;
        gtbl_normal(ln_normal_cnt) := gtbl_data(ln_cnt_loop);
      ELSIF (lb_err_flag = TRUE) THEN -- �G���[�t���O(�G���[�D��)
        -- �G���[�����J�E���g
        gn_error_cnt  := gn_error_cnt + 1;
        -- �G���[���A�x���Z�b�g
        ov_retcode := gv_status_warn;
      ELSIF (lb_warn_flag = TRUE) THEN-- �ۗ��t���O
        -- �ۗ������J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
        -- �G���[���A�x���Z�b�g
        ov_retcode := gv_status_warn;
      END IF;
--
    END LOOP check_loop;
    -- ����
    gn_normal_cnt := gtbl_normal.COUNT;                 -- ���팏��
--
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
  END proc_check;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_ins_data
   * Description      : �Ώۃf�[�^�擾(B-2)
   ***********************************************************************************/
  PROCEDURE proc_get_ins_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_ins_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================
    -- �Ώۃf�[�^���b�N
    -- =============================
    BEGIN
      -- ���b�N�擾�J�[�\��OPEN
      OPEN gcur_xxinv_stc_inv_hht_work;
    EXCEPTION
      WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
        -- �J�[�\����CLOSE
        IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
          CLOSE gcur_xxinv_stc_inv_hht_work;
        END IF;
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                       iv_application  => gv_xxcmn,
                       iv_name         => 'APP-XXCMN-10019',
                       iv_token_name1  => 'TABLE',
                       iv_token_value1 => gv_inv_hht_name),1,5000);
        RAISE global_user_expt;
    END;
--
    -- =============================
    -- �Ώۃf�[�^�擾
    -- =============================
    gtbl_data.DELETE;
    BEGIN
      SELECT
        xsihw.invent_hht_if_id AS invent_hht_if_id
       ,xsihw.report_post_code AS report_post_code
       ,xsihw.invent_date      AS invent_date
       ,xsihw.invent_whse_code AS invent_whse_code
       ,xsihw.invent_seq       AS invent_seq
       ,xsihw.item_code        AS item_code
       ,xsihw.lot_no           AS lot_no
-- 2008/12/06 T.Miyata Update Start
--       ,xsihw.maker_date       AS maker_date
--       ,xsihw.limit_date       AS limit_date
       ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.maker_date, gc_char_d_format), gc_char_d_format)       AS maker_date
       ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.limit_date, gc_char_d_format), gc_char_d_format)       AS limit_date
-- 2008/12/06 T.Miyata Update End
       ,xsihw.proper_mark      AS proper_mark
       ,xsihw.case_amt         AS case_amt
       ,xsihw.content          AS content
       ,xsihw.loose_amt        AS loose_amt
       ,xsihw.location         AS location
       ,xsihw.rack_no1         AS rack_no1
       ,xsihw.rack_no2         AS rack_no2
       ,xsihw.rack_no3         AS rack_no3
       ,xsihw_b.invent_seq     AS b_invent_seq       -- ���i�d���`�F�b�N�p
       ,xsihw_c.invent_seq     AS c_invent_seq       -- ���i�ȊO�d���`�F�b�N�p
       ,xsihw.ROWID            AS rowid_work
       ,''                     AS err_msg            -- �G���[���b�Z�[�W
       ,gn_zero                AS b3_item_id         -- b3_�i��ID
       ,NULL                   AS b3_lot_ctl         -- b3_���b�g�Ǘ��敪
       ,NULL                   AS b3_num_of_cases    -- b3_�P�[�X����
       ,NULL                   AS b3_item_class_code -- b3_�i�ڋ敪
       ,NULL                   AS b3_prod_class_code -- b3_���i�敪
       ,gn_zero                AS b3_lot_id          -- b3_���b�gID
       ,NULL                   AS b3_lot_no          -- b3_���b�gNO
       ,NULL                   AS b3_maker_date      -- b3_�����N����
       ,NULL                   AS b3_proper_mark     -- b3_�ŗL�L��
       ,NULL                   AS b3_limit_date      -- b3_�ܖ�����
      BULK COLLECT INTO gtbl_data
      FROM
        -- HHT�I�����[�N�e�[�u��
        xxinv_stc_inventory_hht_work xsihw
        -- HHT�I�����[�N�e�[�u�� ���i�d���`�F�b�N�p
       ,(
        SELECT
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
-- 2008/12/06 T.Miyata Update Start
--         ,xsihw.maker_date
--         ,xsihw.limit_date
         ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.maker_date, gc_char_d_format), gc_char_d_format)       AS maker_date
         ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.limit_date, gc_char_d_format), gc_char_d_format)       AS limit_date
-- 2008/12/06 T.Miyata Update End
         ,xsihw.proper_mark
         ,xsihw.invent_date --2008/05/02
        FROM xxinv_stc_inventory_hht_work xsihw
        GROUP BY
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
         ,xsihw.maker_date
         ,xsihw.limit_date
         ,xsihw.proper_mark
         ,xsihw.invent_date --2008/05/02
        HAVING COUNT(xsihw.invent_seq) > 1
        ) xsihw_b,
        -- HHT�I�����[�N�e�[�u�� ���i�ȊO�d���`�F�b�N�p
        (
        SELECT
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
         ,xsihw.lot_no
         ,xsihw.invent_date
        FROM xxinv_stc_inventory_hht_work xsihw
        GROUP BY
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
         ,xsihw.lot_no
         ,xsihw.invent_date
        HAVING COUNT(xsihw.invent_seq) > 1
        ) xsihw_c
      WHERE
      -- HHT�I�����[�N�e�[�u�� ���i�d���`�F�b�N�p
          xsihw.invent_seq       = xsihw_b.invent_seq(+)
      AND xsihw.invent_whse_code = xsihw_b.invent_whse_code(+)
      AND xsihw.report_post_code = xsihw_b.report_post_code(+)
      AND xsihw.item_code        = xsihw_b.item_code(+)
      AND xsihw.maker_date       = xsihw_b.maker_date(+)
      AND xsihw.limit_date       = xsihw_b.limit_date(+)
      AND xsihw.proper_mark      = xsihw_b.proper_mark(+)
      AND xsihw.invent_date      = xsihw_b.invent_date(+) --2008/05/02
      -- HHT�I�����[�N�e�[�u�� ���i�ȊO�d���`�F�b�N�p
      AND xsihw.invent_seq       = xsihw_c.invent_seq(+)
      AND xsihw.invent_whse_code = xsihw_c.invent_whse_code(+)
      AND xsihw.report_post_code = xsihw_c.report_post_code(+)
      AND xsihw.item_code        = xsihw_c.item_code(+)
      AND xsihw.lot_no           = xsihw_c.lot_no(+)
      AND xsihw.invent_date      = xsihw_c.invent_date(+)
      ORDER BY
        xsihw.invent_seq
       ,xsihw.invent_whse_code
       ,xsihw.report_post_code
       ,xsihw.item_code
       ,xsihw.maker_date
       ,xsihw.limit_date
       ,xsihw.proper_mark
       ,xsihw.lot_no
       ,xsihw.invent_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    -- �Ώی���
    gn_target_cnt := gtbl_data.COUNT;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_get_ins_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_table_data
   * Description      : �f�[�^�p�[�W����(B-1)
   ***********************************************************************************/
  PROCEDURE proc_del_table_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_table_data'; -- �v���O������
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
    cv_inv_del_date   CONSTANT VARCHAR2(100) := 'XXINV_INVENTORY_PURGE_TERM'; -- �I���폜�Ώۓ��t
--
    -- *** ���[�J���ϐ� ***
    lv_inv_del_date   FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
    ld_del_date       DATE;
    lr_rowid          ROWID;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- HHT�I�����[�N�e�[�u���J�[�\��
    CURSOR xxinv_stc_inv_hht_work_lcur(
      cd_del_date DATE -- �폜���t
      )
    IS
      SELECT xsihw.ROWID
      FROM   xxinv_stc_inventory_hht_work xsihw
      WHERE  xsihw.creation_date < cd_del_date
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE ltbl_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    ltbl_rowid ltbl_rowid_type;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �v���t�@�C���I�v�V�����擾
    -- ==============================================================
    -- �v���t�@�C�����i�I���폜�Ώۓ��t�j
    lv_inv_del_date := FND_PROFILE.VALUE(cv_inv_del_date);
    -- �v���t�@�C���ɖ��o�^
    IF (lv_inv_del_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,'APP-XXCMN-10002'
                    ,'NG_PROFILE'
                    ,gv_profile_name),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- HHT�I�����[�N�e�[�u���̍폜
    -- ==============================================================
    BEGIN
      -- �폜���t�̍쐬
      ld_del_date := (TRUNC(SYSDATE) - TO_NUMBER(lv_inv_del_date));
--
      --  ���b�N�擾�J�[�\��OPEN
      OPEN xxinv_stc_inv_hht_work_lcur(
        cd_del_date => ld_del_date);
--
      <<fetch_loop>>
      LOOP
        FETCH xxinv_stc_inv_hht_work_lcur INTO lr_rowid;
        EXIT WHEN xxinv_stc_inv_hht_work_lcur%NOTFOUND;
        -- �폜�Ώ�ROWID�̃Z�b�g
        ltbl_rowid(ltbl_rowid.COUNT + 1) := lr_rowid;
      END LOOP fetch_loop;
--
      -- �ꊇ�폜����
      FORALL ln_cnt_loop in 1..ltbl_rowid.COUNT
        DELETE xxinv_stc_inventory_hht_work xsihw
        WHERE  xsihw.ROWID = ltbl_rowid(ln_cnt_loop);
--
      -- ���b�N�擾�J�[�\����CLOSE
      CLOSE xxinv_stc_inv_hht_work_lcur;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
        -- �J�[�\����CLOSE
        IF (xxinv_stc_inv_hht_work_lcur%ISOPEN) THEN
          CLOSE xxinv_stc_inv_hht_work_lcur;
        END IF;
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                       gv_xxcmn
                      ,'APP-XXCMN-10019'
                      ,'TABLE'
                      ,gv_inv_hht_name
                      ),1,5000);
        RAISE global_user_expt;
      WHEN OTHERS THEN
        -- �J�[�\����CLOSE
        IF (xxinv_stc_inv_hht_work_lcur%ISOPEN) THEN
          CLOSE xxinv_stc_inv_hht_work_lcur;
        END IF;
        RAISE global_user_expt;
--
    END;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
  END proc_del_table_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
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
    lb_check_warn BOOLEAN DEFAULT FALSE; -- �G���[�`�F�b�N���x���ێ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gtbl_data.DELETE;       -- ���f�[�^
    gtbl_normal.DELETE;     -- ����f�[�^
    gtbl_error.DELETE;      -- �G���[�f�[�^
    gtbl_reserve.DELETE;    -- �ۗ��f�[�^
    gtbl_normal_ins.DELETE; -- ����f�[�^�}��
--
    -- ===============================
    -- B-1.�f�[�^�p�[�W����
    -- ===============================
    proc_del_table_data(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-2.�Ώۃf�[�^�擾
    -- ===============================
    proc_get_ins_data(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-3.�Ó����`�F�b�N
    -- ===============================
    proc_check(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      -- �G���[�`�F�b�N���x����ێ�
      lb_check_warn := TRUE;
    END IF;
--
    -- ===============================
    -- B-3.�G���[�_���v�ꊇ�o��
    -- ===============================
    proc_put_dump_msg(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-4.�I�����ʍX�V����
    -- ===============================
    proc_upd_table_batch(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-5.�I�����ʓo�^����
    -- ===============================
    proc_ins_table_batch(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-6.�Ώۃf�[�^�폜
    -- ===============================
    proc_del_table_data_batch(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (lb_check_warn) THEN
      -- �G���[�`�F�b�N���x����߂��܂��B
      ov_retcode := gv_status_warn;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
        CLOSE gcur_xxinv_stc_inv_hht_work;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
        CLOSE gcur_xxinv_stc_inv_hht_work;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
        CLOSE gcur_xxinv_stc_inv_hht_work;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := FND_GLOBAL.USER_NAME;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = FND_GLOBAL.PROG_APPL_ID
    AND    fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      gn_normal_cnt := 0; -- ���������̏�����
    END IF;
    -- ==================================
    -- D-15.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�ۗ������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv530002c;
/
