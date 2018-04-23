create or replace PACKAGE BODY xxinv530001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv5300001(body)
 * Description      : �I�����ʃC���^�[�t�F�[�X
 * MD.050           : �I��(T_MD050_BPO_530)
 * MD.070           : ���ʃC���^�[�t�F�[�X(T_MD070_BPO_53A)
 * Version          : 1.14
 *
 * Program List
 *  ----------------------------------------------------------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------------------------------------------------------------------
 *  proc_put_dump_msg               P         �f�[�^�_���v�ꊇ�o�͏���            (A-4-5)
 *  proc_get_data_dump              P         �f�[�^�_���v�擾����                (A-4-4)
 *  proc_duplication_chk            P         �d���f�[�^�`�F�b�N                  (A-4-3)
 *  proc_del_table_data             P         �Ώۃf�[�^�폜                      (A-7)
 *  proc_ins_table_batch            P         �I�����ʓo�^����                    (A-6)
 *  proc_upd_table_batch            P         �I�����ʍX�V����                    (A-5)
 *  proc_master_data_chk            P         �Ó����`�F�b�N                      (A-4)
 *  proc_get_lock                   P         �ΏۃC���^�[�t�F�[�X�f�[�^�擾      (A-3)
 *  proc_del_inventory_if           P         �f�[�^�p�[�W����                    (A-2)
 *  proc_check_param                P         �p�����[�^�`�F�b�N                  (A-1)
 *  submain                         P         ���C�������v���V�[�W��
 *  main                            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * -----------------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * -----------------------------------------------------------------------------------
 *  2008/03/14    1.0   M.Inamine        �V�K�쐬
 *  2008/05/02    1.1   M.Inamine        �C��(�yBPO_530_�I���z�C���˗����� No2�̑Ή�)
 *                                           (�yBPO_530_�I���z�C���˗����� No4�̑Ή�)
 *  2008/05/07    1.2   M.Inamine        �C��(20080507_03 No5�̑Ή��A���b�g���͋󔒂��o��)
 *  2008/05/08    1.3   M.Inamine        �C��(�d�l�ύX�Ή��A���b�g�Ǘ��O�̏ꍇ���b�gID��NULL��)
 *  2008/05/09    1.4   M.Inamine        �C��(2008/05/08 03 �s��Ή��F���t�����̌��)
 *  2008/05/20    1.4   T.Ikehara        �C��(�s�ID6�Ή��F�o�̓��b�Z�[�W�̌��)
 *  2008/09/04    1.5   H.Itou           �C��(PT 6-3_39�w�E#12 ���ISQL�̕ϐ����o�C���h�ϐ���)
 *  2008/09/11    1.6   T.Ohashi         �C��(PT 6-3_39�w�E74 �Ή�)
 *  2008/09/16    1.7   T.Ikehara        �C��(�s�ID7�Ή��F�d���폜�̓G���[�Ƃ��Ȃ�)
 *  2008/10/15    1.8   T.Ikehara        �C��(�s�ID8�Ή��F�d���폜�Ώۃf�[�^��
 *                                                           �Ó����`�F�b�N�ΏۊO�ɏC�� )
 *  2008/12/06    1.9   H.Itou           �C��(�{�ԏ�Q#510�Ή��F���t�͕ϊ����Ĕ�r)
 *  2008/12/08    1.10  K.Kumamoto       �C��(�{�ԏ�Q#570�Ή��F�I���A�Ԃ�TO_NUMBER)
 *  2008/12/11    1.11  H.Itou           �C��(�{�ԏ�Q#632�Ή��F#570�C���R��)
 *  2009/02/09    1.12  A.Shiina         �C��(�{�ԏ�Q#1117�Ή��F�݌ɃN���[�Y�`�F�b�N�ǉ�)
 *  2016/06/15    1.13  Y.Shoji          E_�{�ғ�_13563�Ή�
 *  2018/03/30    1.14  Y.Sekine         E_�{�ғ�_14953�Ή�
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
  gv_out_msg       VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg       VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user     VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name     VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status   VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt    NUMBER         DEFAULT 0;   -- �Ώی���
  gn_normal_cnt    NUMBER         DEFAULT 0;   -- ���팏��
  gn_error_cnt     NUMBER         DEFAULT 0;   -- �G���[����
  gn_warn_cnt      NUMBER         DEFAULT 0;   -- �X�L�b�v����
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
  lock_expt               EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);    -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxinv5300001c'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn                CONSTANT VARCHAR2(10) := 'XXCMN'; -- ���W���[�������́FXXCMN ����
  gv_xxinv                CONSTANT VARCHAR2(10) := 'XXINV'; -- ���W���[�������́FXXINV
--
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- WHO����
  gn_user_id              CONSTANT NUMBER := FND_GLOBAL.USER_ID;
  gd_sysdate              CONSTANT DATE   := SYSDATE;
  gn_last_update_login    CONSTANT NUMBER := FND_GLOBAL.LOGIN_ID;
  gn_request_id           CONSTANT NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
  gn_program_appl_id      CONSTANT NUMBER := FND_GLOBAL.PROG_APPL_ID;
  gn_program_id           CONSTANT NUMBER := FND_GLOBAL.CONC_PROGRAM_ID;
--
  -- �g�[�N��
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_tkn_value            CONSTANT VARCHAR2(15) := 'VALUE';
  gv_tkn_item             CONSTANT VARCHAR2(15) := 'ITEM';
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_profile       CONSTANT VARCHAR2(15) := 'NG_PROFILE';
--
  -- YES/NO
  gn_y                    CONSTANT NUMBER := 1;
  gn_n                    CONSTANT NUMBER := 0;
--
  -- ���i�敪
  gv_goods_classe_reaf    CONSTANT VARCHAR2(1) := '1';   -- ���i�敪�F1(���[�t)
  gv_goods_classe_drink   CONSTANT VARCHAR2(1) := '2';   -- ���i�敪�F2(�h�����N)
  -- ���i�敪
  gv_item_cls_prdct       CONSTANT VARCHAR2(1)  := '5';   -- �i�ڋ敪�F5(���i)
--
  gv_date                 CONSTANT VARCHAR2(10) := 'yyyy/mm/dd';
  gv_blank                CONSTANT VARCHAR2(2)  := ' ';
  gn_zero                 CONSTANT NUMBER       := 0;
--
  gv_item_typ             CONSTANT VARCHAR2(10) := '�i�ڋ敪';
  gv_prdct_typ            CONSTANT VARCHAR2(10) := '���i�敪';
  gv_profile_name         CONSTANT VARCHAR2(16) := '�I���폜�Ώۓ��t';
  gv_inv_hht_name         CONSTANT VARCHAR2(30) := 'HHT�I�����[�N�e�[�u��';
  gv_inv_result_name      CONSTANT VARCHAR2(30) := '�I�����ʃe�[�u��';
  gv_opm_item_name        CONSTANT VARCHAR2(30) := 'OPM�i�ڃ}�X�^';
  gv_opm_lot_name         CONSTANT VARCHAR2(30) := 'OPM���b�g�}�X�^';
  gv_invent_whse_name     CONSTANT VARCHAR2(30) := 'OPM�q�Ƀ}�X�^';
  gv_report_post_name     CONSTANT VARCHAR2(30) := '���Ə��}�X�^';
--
  gv_item_col             CONSTANT VARCHAR2(4)  := '�i��';
  gv_inv_whse_code_col    CONSTANT VARCHAR2(8)  := '�I���q��';
  gv_report_post_code_col CONSTANT VARCHAR2(8)  := '�񍐕���';
  gv_inv_whse_section_col CONSTANT VARCHAR2(20) := '�q�ɊǗ�����';
  gv_inv_whse_code        CONSTANT VARCHAR2(20) := '�q�ɃR�[�h';
--
  gv_lot_no_col           CONSTANT VARCHAR2(8)  := '���b�gNo';
  gv_maker_date_col       CONSTANT VARCHAR2(8)  := '������';
  gv_limit_date_col       CONSTANT VARCHAR2(8)  := '�ܖ�����';
  gv_proper_mark_col      CONSTANT VARCHAR2(8)  := '�ŗL�L��';
  gv_case_amt_col         CONSTANT VARCHAR2(10) := '�I���P�[�X';
  gv_content_col          CONSTANT VARCHAR2(4)  := '����';
  gv_num_of_cases_col     CONSTANT VARCHAR2(10) := '�P�[�X����';
  gv_loose_amt_col        CONSTANT VARCHAR2(8)  := '�I���o��';
  --�Ó����X�e�[�^�X
  gv_sts_ok               CONSTANT VARCHAR2(2)  := 'OK';   -- ����
  gv_sts_ng               CONSTANT VARCHAR2(2)  := 'NG';   -- �G���[
  gv_sts_hr               CONSTANT VARCHAR2(3)  := 'SKP';  -- �ۗ�
  gv_sts_del              CONSTANT VARCHAR2(3)  := 'DEL';  -- �폜
  gv_sts_ins              CONSTANT VARCHAR2(3)  := 'INS';  -- �o�^�Ώ�
--
  --�e�[�u����
  gv_xxcmn_del_table_name CONSTANT  VARCHAR2(50) := '�I���f�[�^�C���^�[�t�F�[�X�e�[�u��';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���b�Z�[�WPL/SQL�\�^
  TYPE msg_ttype   IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- �J�E���g
  gn_err_msg_cnt      NUMBER DEFAULT 0;   -- �x���G���[���b�Z�[�W�\�J�E���g
  gn_ins_tab_cnt      NUMBER DEFAULT 0;   -- �o�^�pPL/SQL�\�J�E���g
  gn_upd_tab_cnt      NUMBER DEFAULT 0;   -- �X�V�pPL/SQL�\�J�E���g
--
--
  -------------------------------------------------------------------------------------------------
  -- �u�I���f�[�^�C���^�[�t�F�[�X�e�[�u���v�\����
  -------------------------------------------------------------------------------------------------
  TYPE xxinv_stc_inv_if_rec IS RECORD(
    invent_if_id      xxinv_stc_inventory_interface.invent_if_id    %TYPE,    --�I���h�e_ID
    report_post_code  xxinv_stc_inventory_interface.report_post_code%TYPE,    --�񍐕���
    invent_date       xxinv_stc_inventory_interface.invent_date     %TYPE,    --�I����
    invent_whse_code  xxinv_stc_inventory_interface.invent_whse_code%TYPE,    --�I���q��
    invent_seq        xxinv_stc_inventory_interface.invent_seq      %TYPE,    --�I���A��
    item_code         xxinv_stc_inventory_interface.item_code       %TYPE,    --�i��
    lot_no            xxinv_stc_inventory_interface.lot_no          %TYPE,    --���b�gNo.
    maker_date        xxinv_stc_inventory_interface.maker_date      %TYPE,    --������
    limit_date        xxinv_stc_inventory_interface.limit_date      %TYPE,    --�ܖ�����
    proper_mark       xxinv_stc_inventory_interface.proper_mark     %TYPE,    --�ŗL�L��
    case_amt          xxinv_stc_inventory_interface.case_amt        %TYPE,    --�I���P�[�X��
    content           xxinv_stc_inventory_interface.content         %TYPE,    --����
    loose_amt         xxinv_stc_inventory_interface.loose_amt       %TYPE,    --�I���o��
    location          xxinv_stc_inventory_interface.location        %TYPE,    --���P�[�V����
    rack_no1          xxinv_stc_inventory_interface.rack_no1        %TYPE,    --���b�NNo�P
    rack_no2          xxinv_stc_inventory_interface.rack_no2        %TYPE,    --���b�NNo�Q
    rack_no3          xxinv_stc_inventory_interface.rack_no3        %TYPE,    --���b�NNo�R
    request_id        xxinv_stc_inventory_interface.request_id      %TYPE,    --�v��ID
--  A-4�擾��
    item_id           xxinv_stc_inventory_result.item_id            %TYPE,    --�i��ID
    lot_ctl           xxcmn_item_mst_v.lot_ctl                      %TYPE,    --���b�g�Ǘ��敪
    num_of_cases      xxcmn_item_mst_v.num_of_cases                 %TYPE,    --�P�[�X����
    item_type         xxcmn_item_categories2_v.segment1             %TYPE,    --�i�ڋ敪
    product_type      xxcmn_item_categories2_v.segment1             %TYPE,    --���i�敪
--
    lot_id            ic_lots_mst.lot_id                            %TYPE,    --���b�gID
    lot_no1           ic_lots_mst.lot_no                            %TYPE,    --���b�gNo
    maker_date1       ic_lots_mst.attribute1                        %TYPE,    --�����N����
    proper_mark1      ic_lots_mst.attribute2                        %TYPE,    --�ŗL�L��
    limit_date1       ic_lots_mst.attribute3                        %TYPE,    --�ܖ�����
    rowid_work        ROWID,                      -- ROWID
    sts               VARCHAR2(3));               --�Ó����`�F�b�N�X�e�[�^�X
  --���R�[�h�^����
  TYPE xxinv_stc_inventory_if_tab IS TABLE OF xxinv_stc_inv_if_rec;
   inv_if_rec xxinv_stc_inventory_if_tab;
--
  -- ============================
  -- ���[�U�[��`�O���[�o���ϐ� =
  -- ============================
  -- �x���f�[�^�_���vPL/SQL�\
  warn_dump_tab         msg_ttype;
--
  -- ����f�[�^�_���vPL/SQL�\
  normal_dump_tab      msg_ttype;
--
  -- *** �O���[�o���E�J�[�\�� ***
  TYPE cursor_rec IS REF CURSOR;--�I���f�[�^�C���^�[�t�F�[�X�e�[�u���̑Ώۃf�[�^�擾�p
--
  /***********************************************************************************
   * Procedure Name   : proc_put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���(A-4-5)
   ***********************************************************************************/
  PROCEDURE proc_put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'proc_put_dump_msg'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg      VARCHAR2(5000)  DEFAULT NULL;  -- ���b�Z�[�W
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
    --��؂蕶����o��
    IF (warn_dump_tab.COUNT != 0 ) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
  --
      -- �G���[�f�[�^�i���o���j
      lv_msg  := SUBSTRB(XXCMN_COMMON_PKG.GET_MSG(
                   gv_xxcmn
                  ,'APP-XXCMN-00006'
                  ),1,5000);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- �x���f�[�^�_���v
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
  /**********************************************************************************
   * Procedure Name   : proc_get_data_dump
   * Description      : �f�[�^�_���v�擾����(A-4-4)
   ***********************************************************************************/
  PROCEDURE proc_get_data_dump(
    if_rec        IN  xxinv_stc_inv_if_rec, -- 1.�I���C���^�[�t�F�[�X
    ov_dump       OUT VARCHAR2,             -- 2.�f�[�^�_���v������
    ov_errbuf     OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �f�[�^�_���v�쐬
    -- ===============================
    ov_dump := TO_CHAR(if_rec.invent_if_id)             || gv_msg_comma ||  --�I���h�e_ID
               if_rec.report_post_code                  || gv_msg_comma ||  --�񍐕���
               TO_CHAR(if_rec.invent_date, gv_date)     || gv_msg_comma ||  --�I����
               if_rec.invent_whse_code                  || gv_msg_comma ||  --�I���q��
               if_rec.invent_seq                        || gv_msg_comma ||  --�I���A��
               if_rec.item_code                         || gv_msg_comma ||  --�i��
               if_rec.lot_no                            || gv_msg_comma ||  --���b�gNo.
               if_rec.maker_date                        || gv_msg_comma ||  --������
               if_rec.limit_date                        || gv_msg_comma ||  --�ܖ�����
               if_rec.proper_mark                       || gv_msg_comma ||  --�ŗL�L��
               TO_CHAR(if_rec.case_amt)                 || gv_msg_comma ||  --�I���P�[�X��
               TO_CHAR(if_rec.content)                  || gv_msg_comma ||  --����
               TO_CHAR(if_rec.loose_amt)                || gv_msg_comma ||  --�I���o��
               if_rec.location                          || gv_msg_comma ||  --���P�[�V����
               if_rec.rack_no1                          || gv_msg_comma ||  --���b�NNo�P
               if_rec.rack_no2                          || gv_msg_comma ||  --���b�NNo�Q
               if_rec.rack_no3;                                             --���b�NNo�R
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
  END proc_get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : proc_duplication_chk
   * Description      : �d���f�[�^�`�F�b�N(A-4-3)
   * RETURN  true : OK(�d���Ȃ�)  false : NG(�d������)
   ***********************************************************************************/
  PROCEDURE proc_duplication_chk(
     if_rec        IN  xxinv_stc_inv_if_rec    -- 1.�I���C���^�[�t�F�[�X
    ,iv_item_typ   IN  VARCHAR2                -- 2.�i�ڋ敪
    ,ib_dup_sts    OUT BOOLEAN                 -- 3.�d���`�F�b�N����
    ,ib_dup_del_sts OUT BOOLEAN                -- 4.�قȂ�v��ID�ŏd�����A�ŐV�v��ID�łȂ�=TRUE
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_duplication_chk'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_sql        VARCHAR2(15000)   DEFAULT NULL;-- ���ISQL������
    ln_cnt        NUMBER            DEFAULT 0;   -- �d������
    ln_request_id xxinv_stc_inventory_interface.request_id%TYPE; -- �v��ID
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���ʏ�����
    ib_dup_sts     := TRUE;
    ib_dup_del_sts := FALSE;
--
    -- ���v��ID�z���ł̏d���`�F�b�N
    lv_sql  :=  'SELECT COUNT(xsi.report_post_code) cnt '  -- �J�E���g
      ||  'FROM  xxinv_stc_inventory_interface xsi '  -- 1.�I���f�[�^�C���^�t�F�[�X
-- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
--      ||  'WHERE xsi.request_id        = '    ||  if_rec.request_id                -- �v��ID
--      ||  '  AND xsi.report_post_code  = '''  ||  if_rec.report_post_code  || '''' -- �񍐕���
--      ||  '  AND xsi.invent_whse_code  = '''  ||  if_rec.invent_whse_code  || '''' -- �I���q��
--      ||  '  AND xsi.invent_seq        = '''  ||  if_rec.invent_seq        || '''' -- �I���A��
--      ||  '  AND xsi.item_code         = '''  ||  if_rec.item_code         || '''';-- �i��
      ||  'WHERE xsi.request_id        = :request_id        ' -- �v��ID
      ||  '  AND xsi.report_post_code  = :report_post_code  ' -- �񍐕���
      ||  '  AND xsi.invent_whse_code  = :invent_whse_code  ' -- �I���q��
--2008/12/08 mod start
--      ||  '  AND xsi.invent_seq        = :invent_seq        ' -- �I���A��
      ||  '  AND TO_NUMBER(xsi.invent_seq)        = TO_NUMBER(:invent_seq)        ' -- �I���A��
--2008/12/08 mod end
      ||  '  AND xsi.item_code         = :item_code         ';-- �i��
-- 2008/09/04 H.Itou Mod End
    --�i�ڋ敪�����i�̏ꍇ
    IF  (iv_item_typ   = gv_item_cls_prdct) THEN
      lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
---- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
----      ||  '  AND xsi.maker_date  = '''  ||  if_rec.maker_date   || ''''  --������
----      ||  '  AND xsi.limit_date  = '''  ||  if_rec.limit_date   || ''''  --�ܖ�����
----      ||  '  AND xsi.proper_mark = '''  ||  if_rec.proper_mark  || ''''  --�ŗL�L��
----      --2008/5/02(���r���[No2)
----      ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
----                          TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--�I����
--      ||  '  AND xsi.maker_date,  = :maker_date   '  -- ������
--      ||  '  AND xsi.limit_date  = :limit_date   '  -- �ܖ�����
--      ||  '  AND xsi.proper_mark = :proper_mark  '  -- �ŗL�L��
--      ||  '  AND xsi.invent_date = :invent_date  '; -- �I����
---- 2008/09/04 H.Itou Mod End
      ||  '  AND CASE '
      ||  '         WHEN xsi.maker_date IS NULL   THEN ''*'''
      ||  '         WHEN xsi.maker_date = ''0''   THEN ''0'''
      ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
      ||  '      END = :maker_date ' -- ������
      ||  '  AND CASE '
      ||  '         WHEN xsi.limit_date IS NULL   THEN ''*'''
      ||  '         WHEN xsi.limit_date = ''0''   THEN ''0'''
      ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
      ||  '      END = :limit_date '-- �ܖ�����
      ||  '  AND xsi.proper_mark = :proper_mark  ' -- �ŗL�L��
      ||  '  AND xsi.invent_date = :invent_date  ' -- �I����
      ;
-- 2008/12/06 H.Itou Mod End
    --�i�ڋ敪�����i�ȊO
    ELSE
      lv_sql  :=  lv_sql
-- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
--      ||  '  AND xsi.lot_no      = '''  ||  if_rec.lot_no  || '''' --���b�gNo
--      ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
--                          TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--�I����
      ||  '  AND xsi.lot_no      = :lot_no       '  --���b�gNo
      ||  '  AND xsi.invent_date = :invent_date  '; -- �I����
-- 2008/09/04 H.Itou Mod End
    END IF;
--
    lv_sql  :=  lv_sql
      ||  ' GROUP BY '
      ||  ' xsi.report_post_code  '    -- �񍐕���
      ||  ',xsi.invent_whse_code  '    -- �I���q��
--2008/12/08 mod start
--      ||  ',xsi.invent_seq  '          -- �I���A��
      ||  ',TO_NUMBER(xsi.invent_seq)  '          -- �I���A��
--2008/12/08 mod end
      ||  ',xsi.item_code  ';          -- �i��
--
    --�i�ڋ敪�����i�̏ꍇ
    IF  (iv_item_typ   = gv_item_cls_prdct) THEN
      lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
--      ||  ', xsi.maker_date  '     --������
--      ||  ', xsi.limit_date  '     --�ܖ�����
--      ||  ', xsi.proper_mark  '    --�ŗL�L��
--      ||  ', xsi.invent_date  ';   --�I����--2008/05/02
      ||  ', CASE '
      ||  '    WHEN xsi.maker_date IS NULL   THEN ''*'''
      ||  '    WHEN xsi.maker_date = ''0''   THEN ''0'''
      ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
      ||  '  END ' -- ������
      ||  ', CASE '
      ||  '    WHEN xsi.limit_date IS NULL   THEN ''*'''
      ||  '    WHEN xsi.limit_date = ''0''   THEN ''0'''
      ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
      ||  '  END ' -- �ܖ�����
      ||  ', xsi.proper_mark  '                                                                                          -- �ŗL�L��
      ||  ', xsi.invent_date  '                                                                                          -- �I����--2008/05/02
      ;
-- 2008/12/06 H.Itou Mod End
    ELSE
      lv_sql  :=  lv_sql
      ||  ', xsi.lot_no  '         --���b�gNo
      ||  ', xsi.invent_date  ';   --�I����
    END IF;
--
    BEGIN
-- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
--      EXECUTE  IMMEDIATE lv_sql INTO  ln_cnt;
      --�i�ڋ敪�����i�̏ꍇ
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        EXECUTE  IMMEDIATE lv_sql INTO  ln_cnt
        USING if_rec.request_id       -- �v��ID
             ,if_rec.report_post_code -- �񍐕���
             ,if_rec.invent_whse_code -- �I���q��
             ,if_rec.invent_seq       -- �I���A��
             ,if_rec.item_code        -- �i��
-- 2008/12/06 H.Itou Mod Start
--             ,if_rec.maker_date       -- ������
--             ,if_rec.limit_date       -- �ܖ�����
             ,CASE
                WHEN if_rec.maker_date IS NULL THEN '*'  -- NULL�Ȃ�_�~�[�R�[�h
                WHEN if_rec.maker_date = '0'   THEN '0'  -- 0�Ȃ�0�̂܂�
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.maker_date, gc_char_d_format), gc_char_d_format), if_rec.maker_date) -- �������t�H�[�}�b�g�̏ꍇ�A���t�ϊ����ă`�F�b�N
              END -- ������
             ,CASE
                WHEN if_rec.limit_date IS NULL THEN '*'  -- NULL�Ȃ�_�~�[�R�[�h
                WHEN if_rec.limit_date = '0'   THEN '0'  -- 0�Ȃ�0�̂܂�
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.limit_date, gc_char_d_format), gc_char_d_format), if_rec.limit_date) -- �������t�H�[�}�b�g�̏ꍇ�A���t�ϊ����ă`�F�b�N
              END -- �ܖ�����
-- 2008/12/06 H.Itou Mod End
             ,if_rec.proper_mark      -- �ŗL�L��
             ,if_rec.invent_date      -- �I����
        ;
--
      --�i�ڋ敪�����i�ȊO
      ELSE
        EXECUTE  IMMEDIATE lv_sql INTO  ln_cnt
        USING if_rec.request_id       -- �v��ID
             ,if_rec.report_post_code -- �񍐕���
             ,if_rec.invent_whse_code -- �I���q��
             ,if_rec.invent_seq       -- �I���A��
             ,if_rec.item_code        -- �i��
             ,if_rec.lot_no           -- ���b�gNo
             ,if_rec.invent_date      -- �I����
        ;
      END IF;
-- 2008/09/04 H.Itou Mod End
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_cnt :=  0;
    END;
    IF  (ln_cnt  > 1)  THEN
      ib_dup_sts := FALSE;
    END IF;
--
    -- �قȂ�v��ID�z���ł̏d���`�F�b�N
    IF  (ib_dup_sts != FALSE) THEN
      lv_sql  :=
        'SELECT '
        ||  'MAX(xsi.request_id)  maxt_id, ' -- �ŐV�v��ID
        ||  'COUNT(xsi.report_post_code) cnt '      -- �J�E���g
        ||  'FROM  xxinv_stc_inventory_interface xsi '  -- 1.�I���f�[�^�C���^�t�F�[�X
        ||  'WHERE '
-- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
--        ||  '      xsi.report_post_code  = '''  ||  if_rec.report_post_code  || '''' -- �񍐕���
--        ||  '  AND xsi.invent_whse_code  = '''  ||  if_rec.invent_whse_code  || '''' -- �I���q��
--        ||  '  AND xsi.invent_seq        = '''  ||  if_rec.invent_seq        || '''' -- �I���A��
--        ||  '  AND xsi.item_code         = '''  ||  if_rec.item_code         || '''';-- �i��
        ||  '      xsi.report_post_code  = :report_post_code  ' -- �񍐕���
        ||  '  AND xsi.invent_whse_code  = :invent_whse_code  ' -- �I���q��
--2008/12/11 mod start
--        ||  '  AND xsi.invent_seq        = :invent_seq        ' -- �I���A��
        ||  '  AND TO_NUMBER(xsi.invent_seq) = TO_NUMBER(:invent_seq) ' -- �I���A��
--2008/12/11 mod end
        ||  '  AND xsi.item_code         = :item_code         ';-- �i��
-- 2008/09/04 H.Itou Mod End
--
      --�i�ڋ敪�����i�̏ꍇ
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
---- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
----        ||  '  AND xsi.maker_date  = '''  ||  if_rec.maker_date   || ''''  --������
----        ||  '  AND xsi.limit_date  = '''  ||  if_rec.limit_date   || ''''  --�ܖ�����
----        ||  '  AND xsi.proper_mark = '''  ||  if_rec.proper_mark  || ''''  --�ŗL�L��
----        --2008/5/02(���r���[No2)
----        ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
----                            TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--�I����
--        ||  '  AND xsi.maker_date,  = :maker_date   '  -- ������
--        ||  '  AND xsi.limit_date  = :limit_date   '  -- �ܖ�����
--        ||  '  AND xsi.proper_mark = :proper_mark  '  -- �ŗL�L��
--        ||  '  AND xsi.invent_date = :invent_date  '; -- �I����
---- 2008/09/04 H.Itou Mod End
        ||  '  AND CASE '
        ||  '         WHEN xsi.maker_date IS NULL   THEN ''*'''
        ||  '         WHEN xsi.maker_date = ''0''   THEN ''0'''
        ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
        ||  '      END = :maker_date ' -- ������
        ||  '  AND CASE '
        ||  '         WHEN xsi.limit_date IS NULL   THEN ''*'''
        ||  '         WHEN xsi.limit_date = ''0''   THEN ''0'''
        ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
        ||  '      END = :limit_date '-- �ܖ�����
        ||  '  AND xsi.proper_mark = :proper_mark  '                                                                             -- �ŗL�L��
        ||  '  AND xsi.invent_date = :invent_date  '                                                                             -- �I����
        ;
-- 2008/12/06 H.Itou Mod End
      --�i�ڋ敪�����i�ȊO
      ELSE
        lv_sql  :=  lv_sql
-- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
--        ||  '  AND xsi.lot_no      = '''  ||  if_rec.lot_no  || '''' --���b�gNo
--        ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
--                            TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--�I����
        ||  '  AND xsi.lot_no      = :lot_no       '  --���b�gNo
        ||  '  AND xsi.invent_date = :invent_date  '; -- �I����
-- 2008/09/04 H.Itou Mod End
      END IF;
--
      lv_sql  :=  lv_sql
        ||  ' GROUP BY '
        ||  ' xsi.report_post_code  '    -- �񍐕���
        ||  ',xsi.invent_whse_code  '    -- �I���q��
--2008/12/11 mod start
--        ||  ',xsi.invent_seq  '          -- �I���A��
        ||  ',TO_NUMBER(xsi.invent_seq)  ' -- �I���A��
--2008/12/11 mod end
        ||  ',xsi.item_code  ';          -- �i��
--
      --�i�ڋ敪�����i�̏ꍇ
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
--        ||  ', xsi.maker_date  '     --������
--        ||  ', xsi.limit_date  '     --�ܖ�����
--        ||  ', xsi.proper_mark  '     --�ŗL�L��
--        ||  ', xsi.invent_date  ';   --�I����--2008/05/02
        ||  ', CASE '
        ||  '    WHEN xsi.maker_date IS NULL   THEN ''*'''
        ||  '    WHEN xsi.maker_date = ''0''   THEN ''0'''
        ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
        ||  '  END ' -- ������
        ||  ', CASE '
        ||  '    WHEN xsi.limit_date IS NULL   THEN ''*'''
        ||  '    WHEN xsi.limit_date = ''0''   THEN ''0'''
        ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
        ||  '  END ' -- �ܖ�����
        ||  ', xsi.proper_mark  '                                                             -- �ŗL�L��
        ||  ', xsi.invent_date  '                                                             -- �I����--2008/05/02
        ;
-- 2008/12/06 H.Itou Mod End
      ELSE
        lv_sql  :=  lv_sql
        ||  ', xsi.lot_no  '         --���b�gNo
        ||  ', xsi.invent_date  ';   --�I����
      END IF;
--
      BEGIN
-- 2008/09/04 H.Itou Mod Start PT 6-3_39�w�E#12 �o�C���h�ϐ��ɕύX
--        EXECUTE  IMMEDIATE lv_sql
--          INTO  ln_request_id, ln_cnt;
      --�i�ڋ敪�����i�̏ꍇ
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        EXECUTE  IMMEDIATE lv_sql INTO  ln_request_id, ln_cnt
        USING if_rec.report_post_code -- �񍐕���
             ,if_rec.invent_whse_code -- �I���q��
             ,if_rec.invent_seq       -- �I���A��
             ,if_rec.item_code        -- �i��
-- 2008/12/06 H.Itou Mod Start
--             ,if_rec.maker_date       -- ������
--             ,if_rec.limit_date       -- �ܖ�����
             ,CASE
                WHEN if_rec.maker_date IS NULL THEN '*'  -- NULL�Ȃ�_�~�[�R�[�h
                WHEN if_rec.maker_date = '0'   THEN '0'  -- 0�Ȃ�0�̂܂�
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.maker_date, gc_char_d_format), gc_char_d_format), if_rec.maker_date) -- �������t�H�[�}�b�g�̏ꍇ�A���t�ϊ����ă`�F�b�N
              END -- ������
             ,CASE
                WHEN if_rec.limit_date IS NULL THEN '*'  -- NULL�Ȃ�_�~�[�R�[�h
                WHEN if_rec.limit_date = '0'   THEN '0'  -- 0�Ȃ�0�̂܂�
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.limit_date, gc_char_d_format), gc_char_d_format), if_rec.limit_date) -- �������t�H�[�}�b�g�̏ꍇ�A���t�ϊ����ă`�F�b�N
              END -- �ܖ�����
-- 2008/12/06 H.Itou Mod End
             ,if_rec.proper_mark      -- �ŗL�L��
             ,if_rec.invent_date      -- �I����
        ;
--
      --�i�ڋ敪�����i�ȊO
      ELSE
        EXECUTE  IMMEDIATE lv_sql INTO  ln_request_id, ln_cnt
        USING if_rec.report_post_code -- �񍐕���
             ,if_rec.invent_whse_code -- �I���q��
             ,if_rec.invent_seq       -- �I���A��
             ,if_rec.item_code        -- �i��
             ,if_rec.lot_no           -- ���b�gNo
             ,if_rec.invent_date      -- �I����
        ;
      END IF;
-- 2008/09/04 H.Itou Mod End
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_request_id :=  0;
          ln_cnt :=  0;
      END;
--
      IF  (ln_cnt  > 1)  THEN
        --�i�ŐV�v��ID�ł͂Ȃ��j�폜�ΏۂƂȂ邪�G���[�Ƃ��Ȃ�
        If  (if_rec.request_id  <  ln_request_id)  THEN
          ib_dup_sts     := FALSE;
          ib_dup_del_sts := TRUE;
        END IF;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_duplication_chk;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_table_data
   * Description      : �Ώۃf�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE proc_del_table_data(
    lrec_data     IN  cursor_rec,
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
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt  NUMBER  DEFAULT 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ROWID PL/SQL�\�^
    TYPE work_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    work_rowid work_rowid_type;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- delete�f�[�^ROWID�擾
    <<delete_loop>>
    FOR i IN 1..inv_if_rec.COUNT LOOP
      --�ۗ��f�[�^�ȊO���ׂĒ��o
      IF  (inv_if_rec(i).sts != gv_sts_hr)  THEN
        ln_cnt  := ln_cnt  + 1;
        work_rowid(ln_cnt) := inv_if_rec(i).rowid_work;
        CASE (inv_if_rec(i).sts)
          WHEN (gv_sts_ng) THEN
            gn_error_cnt := gn_error_cnt + 1;    -- �G���[�������Z
          ELSE
            gn_normal_cnt := gn_normal_cnt + 1;  -- ����f�[�^�������Z
        END CASE;
      ELSE
        gn_warn_cnt := gn_warn_cnt + 1;   --�ۗ��f�[�^�������Z
      END IF;
    END LOOP delete_loop;
--
    -- ========================================
    -- �I���f�[�^�C���^�[�t�F�[�X�e�[�u���폜 =
    -- ========================================
    FORALL i IN 1..work_rowid.COUNT
      DELETE xxinv_stc_inventory_interface xsihw
      WHERE  ROWID = work_rowid(i);
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
  END proc_del_table_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_table_batch
   * Description      : �I�����ʓo�^����(A-6)
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
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_val        NUMBER DEFAULT 0;  -- �I������ID�̘A��
    ln_ins_cnt    NUMBER DEFAULT 0;  -- �o�^�����J�E���g
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
    <<insert_loop>>
    FOR i IN 1 .. inv_if_rec.COUNT LOOP
      --�X�e�[�^�X���o�^�iINS)�̂ݑΏۂƂ���
      IF  (inv_if_rec(i).sts = gv_sts_ins)  THEN
        ln_ins_cnt  := ln_ins_cnt  + 1;
--
        -- �I������ID�̘A�Ԏ擾
        SELECT xxinv_stc_invt_rslt_s1.NEXTVAL
        INTO   ln_val
        FROM   DUAL;
        -- �I������ID
        ltbl_xsir(ln_ins_cnt).invent_result_id := ln_val;
        -- �񍐕���
        ltbl_xsir(ln_ins_cnt).report_post_code := inv_if_rec(i).report_post_code;
        -- �I����
        ltbl_xsir(ln_ins_cnt).invent_date      := inv_if_rec(i).invent_date;
        -- �I���q��
        ltbl_xsir(ln_ins_cnt).invent_whse_code := inv_if_rec(i).invent_whse_code;
        -- �I���A��
        ltbl_xsir(ln_ins_cnt).invent_seq       := inv_if_rec(i).invent_seq;
        -- �i��ID
        ltbl_xsir(ln_ins_cnt).item_id          := inv_if_rec(i).item_id;
        -- �i��
        ltbl_xsir(ln_ins_cnt).item_code        := inv_if_rec(i).item_code;
        -- ���b�gID
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- ���i
            ltbl_xsir(ln_ins_cnt).lot_id := inv_if_rec(i).lot_id;
          ELSE
            -- ���i�ȊO
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ���b�g�Ǘ�
                ltbl_xsir(ln_ins_cnt).lot_id := inv_if_rec(i).lot_id;
              ELSE
                -- ���b�g�Ǘ��ΏۊO
                ltbl_xsir(ln_ins_cnt).lot_id := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- ���b�gNo
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- ���i
            ltbl_xsir(ln_ins_cnt).lot_no := inv_if_rec(i).lot_no1;
          ELSE
            -- ���i�ȊO
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ���b�g�Ǘ�
                ltbl_xsir(ln_ins_cnt).lot_no := inv_if_rec(i).lot_no;
              ELSE
                -- ���b�g�Ǘ��ΏۊO
                ltbl_xsir(ln_ins_cnt).lot_no := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- ������
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- ���i
-- 2008/12/06 H.Itou Add Start
--            ltbl_xsir(ln_ins_cnt).maker_date := inv_if_rec(i).maker_date;
            ltbl_xsir(ln_ins_cnt).maker_date := inv_if_rec(i).maker_date1;
-- 2008/12/06 H.Itou Add End
          ELSE
            -- ���i�ȊO
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ���b�g�Ǘ�
                ltbl_xsir(ln_ins_cnt).maker_date := inv_if_rec(i).maker_date1;
              ELSE
                -- ���b�g�Ǘ��ΏۊO
                ltbl_xsir(ln_ins_cnt).maker_date := NULL;--2008/05/08
             END CASE;
        END CASE;
        -- �ܖ�����
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- ���i
            ltbl_xsir(ln_ins_cnt).limit_date := inv_if_rec(i).limit_date;
          ELSE
            -- ���i�ȊO
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ���b�g�Ǘ�
                ltbl_xsir(ln_ins_cnt).limit_date := inv_if_rec(i).limit_date1;
              ELSE
                -- ���b�g�Ǘ��ΏۊO
                ltbl_xsir(ln_ins_cnt).limit_date := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- �ŗL�L��
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- ���i
            ltbl_xsir(ln_ins_cnt).proper_mark :=  inv_if_rec(i).proper_mark;
          ELSE
            -- ���i�ȊO
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ���b�g�Ǘ�
                ltbl_xsir(ln_ins_cnt).proper_mark :=  inv_if_rec(i).proper_mark1;
              ELSE
                -- ���b�g�Ǘ��ΏۊO
                ltbl_xsir(ln_ins_cnt).proper_mark := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- �I���P�[�X��
        ltbl_xsir(ln_ins_cnt).case_amt         := inv_if_rec(i).case_amt;
        -- ����
        ltbl_xsir(ln_ins_cnt).content          := inv_if_rec(i).content;
        -- �I���o��
        ltbl_xsir(ln_ins_cnt).loose_amt        := inv_if_rec(i).loose_amt;
        -- ���P�[�V����
        ltbl_xsir(ln_ins_cnt).location         := inv_if_rec(i).location;
        -- ���b�NNo�P
        ltbl_xsir(ln_ins_cnt).rack_no1         := inv_if_rec(i).rack_no1;
        -- ���b�NNo�Q
        ltbl_xsir(ln_ins_cnt).rack_no2         := inv_if_rec(i).rack_no2;
        -- ���b�NNo�R
        ltbl_xsir(ln_ins_cnt).rack_no3         := inv_if_rec(i).rack_no3;
-- 2008/12/06 H.Itou Add Start �{�ԏ�Q#510 ���t���������킹�邽�߁A��xTO_DATE����B
        -- ������
        IF (ltbl_xsir(ln_ins_cnt).maker_date <> '0') THEN
          ltbl_xsir(ln_ins_cnt).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_ins_cnt).maker_date, gc_char_d_format), gc_char_d_format);
        END IF;
--
        -- �ܖ�����
        IF (ltbl_xsir(ln_ins_cnt).limit_date <> '0') THEN
          ltbl_xsir(ln_ins_cnt).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_ins_cnt).limit_date, gc_char_d_format), gc_char_d_format);
        END IF;
-- 2008/12/06 H.Itou Add End
        -- WHO���
        ltbl_xsir(ln_ins_cnt).created_by             := gn_user_id;
        ltbl_xsir(ln_ins_cnt).creation_date          := gd_sysdate;
        ltbl_xsir(ln_ins_cnt).last_updated_by        := gn_user_id;
        ltbl_xsir(ln_ins_cnt).last_update_date       := gd_sysdate;
        ltbl_xsir(ln_ins_cnt).last_update_login      := gn_user_id;
        ltbl_xsir(ln_ins_cnt).request_id             := gn_request_id;
        ltbl_xsir(ln_ins_cnt).program_application_id := gn_program_appl_id;
        ltbl_xsir(ln_ins_cnt).program_id             := gn_program_id;
        ltbl_xsir(ln_ins_cnt).program_update_date    := gd_sysdate;
      END IF;
    END LOOP  insert_loopl;
--
    -- ===============================
    -- �I�����ʃe�[�u���ꊇ�}��
    -- ===============================
    FORALL i in 1..ltbl_xsir.COUNT
      INSERT INTO xxinv_stc_inventory_result VALUES ltbl_xsir(i);
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
  /**********************************************************************************
   * Procedure Name   : proc_upd_table_batch
   * Description      : �I�����ʍX�V����(A-5)
   ***********************************************************************************/
  PROCEDURE proc_upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_table_batch'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
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
    CURSOR lcur_xxinv_stc_inv_result_pt(
      if_rec xxinv_stc_inv_if_rec)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
      WHERE  xsir.invent_seq       = if_rec.invent_seq       -- �I���A��
      AND    xsir.invent_whse_code = if_rec.invent_whse_code -- �I���q��
      AND    xsir.report_post_code = if_rec.report_post_code -- �񍐕���
      AND    xsir.item_code        = if_rec.item_code        -- �i��
      AND    xsir.invent_date      = if_rec.invent_date      -- �I����
-- 2008/12/06 H.Itou Mod Start
--      AND    xsir.maker_date       = if_rec.maker_date       -- ������
--      AND    xsir.limit_date       = if_rec.limit_date       -- �ܖ�����
      AND    NVL(xsir.maker_date, '*') = NVL(if_rec.maker_date1, '*') -- ������
      AND    NVL(xsir.limit_date, '*') = NVL(if_rec.limit_date, '*')  -- �ܖ�����
-- 2008/12/06 H.Itou Mod End
      AND    xsir.proper_mark      = if_rec.proper_mark      -- �ŗL�L��
      FOR UPDATE NOWAIT;
--
    -- �I�����ʃe�[�u��(�i�ڋ敪�����i�ȊO)���b�g�Ǘ��Ώ�
    CURSOR lcur_xxinv_stc_inv_result_npt(
      if_rec xxinv_stc_inv_if_rec)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
      WHERE  xsir.invent_seq       = if_rec.invent_seq       -- �I���A��
      AND    xsir.invent_whse_code = if_rec.invent_whse_code -- �I���q��
      AND    xsir.report_post_code = if_rec.report_post_code -- �񍐕���
      AND    xsir.item_code        = if_rec.item_code        -- �i��
      AND    xsir.invent_date      = if_rec.invent_date      -- �I����
      AND    xsir.lot_id           = if_rec.lot_id           -- ���b�gID
      FOR UPDATE NOWAIT;
--
    -- �I�����ʃe�[�u��(�i�ڋ敪�����i�ȊO)���b�g�Ǘ��ΏۊO
    CURSOR lcur_xxinv_stc_inv_result_nnpt(
      if_rec xxinv_stc_inv_if_rec)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
      WHERE  xsir.invent_seq       = if_rec.invent_seq       -- �I���A��
      AND    xsir.invent_whse_code = if_rec.invent_whse_code -- �I���q��
      AND    xsir.report_post_code = if_rec.report_post_code -- �񍐕���
      AND    xsir.item_code        = if_rec.item_code        -- �i��
      AND    xsir.invent_date      = if_rec.invent_date      -- �I����
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
    FOR i IN 1 .. inv_if_rec.COUNT LOOP
--
      lr_rowid := NULL;
-- 2008/12/06 H.Itou Add Start �{�ԏ�Q#510 ���t���������킹�邽�߁A��xTO_DATE����B
      -- ������
      IF (inv_if_rec(i).maker_date <> '0') THEN
        inv_if_rec(i).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(inv_if_rec(i).maker_date, gc_char_d_format), gc_char_d_format);
      END IF;
--
      -- �ܖ�����
      IF (inv_if_rec(i).limit_date <> '0') THEN
        inv_if_rec(i).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format), gc_char_d_format);
      END IF;
-- 2008/12/06 H.Itou Add End
      BEGIN
        IF  (inv_if_rec(i).sts  = gv_sts_ok) THEN--����f�[�^�̂�
            -- �i�ڋ敪�����i
          IF (inv_if_rec(i).item_type = gv_item_cls_prdct) THEN
--
            OPEN  lcur_xxinv_stc_inv_result_pt(
              inv_if_rec(i));               -- ���b�N�擾�J�[�\��OPEN
            FETCH lcur_xxinv_stc_inv_result_pt INTO lr_rowid;
--
            IF (lcur_xxinv_stc_inv_result_pt%NOTFOUND) THEN
              inv_if_rec(i).sts := gv_sts_ins; -- ����f�[�^�}��
            ELSE
              ln_upd_cnt := ln_upd_cnt + 1;
              UPDATE xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
              SET    xsir.case_amt               = inv_if_rec(i).case_amt  -- �I���P�[�X��
                    ,xsir.content                = inv_if_rec(i).content   -- ����
                    ,xsir.loose_amt              = inv_if_rec(i).loose_amt -- �I���o��
                    ,xsir.location               = inv_if_rec(i).location  -- ���P�[�V����
                    ,xsir.rack_no1               = inv_if_rec(i).rack_no1  -- ���b�NNo�P
                    ,xsir.rack_no2               = inv_if_rec(i).rack_no2  -- ���b�NNo�Q
                    ,xsir.rack_no3               = inv_if_rec(i).rack_no3  -- ���b�NNo�R
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
            CLOSE lcur_xxinv_stc_inv_result_pt; -- ���b�N�擾�J�[�\��CLOSE
--
            -- �i�ڋ敪�����i�ȊO�����b�g�Ǘ��Ώ�
          ELSE
            IF (inv_if_rec(i).lot_ctl = gn_y )  THEN
--
              OPEN  lcur_xxinv_stc_inv_result_npt(
                inv_if_rec(i));        -- ���b�N�擾�J�[�\��OPEN
--
              FETCH lcur_xxinv_stc_inv_result_npt INTO lr_rowid;
--
              IF (lcur_xxinv_stc_inv_result_npt%NOTFOUND) THEN
                inv_if_rec(i).sts := gv_sts_ins; -- ����f�[�^�}��
              ELSE
                ln_upd_cnt := ln_upd_cnt + 1;
                UPDATE xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
                SET    xsir.case_amt               = inv_if_rec(i).case_amt  -- �I���P�[�X��
                      ,xsir.content                = inv_if_rec(i).content   -- ����
                      ,xsir.loose_amt              = inv_if_rec(i).loose_amt -- �I���o��
                      ,xsir.location               = inv_if_rec(i).location  -- ���P�[�V����
                      ,xsir.rack_no1               = inv_if_rec(i).rack_no1  -- ���b�NNo�P
                      ,xsir.rack_no2               = inv_if_rec(i).rack_no2  -- ���b�NNo�Q
                      ,xsir.rack_no3               = inv_if_rec(i).rack_no3  -- ���b�NNo�R
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
              CLOSE lcur_xxinv_stc_inv_result_npt; -- ���b�N�擾�J�[�\��CLOSE
            ELSE
              -- �i�ڋ敪�����i�ȊO�����b�g�Ǘ��ΏۊO
              OPEN  lcur_xxinv_stc_inv_result_nnpt(
                inv_if_rec(i));        -- ���b�N�擾�J�[�\��OPEN
--
              FETCH lcur_xxinv_stc_inv_result_nnpt INTO lr_rowid;
--
              IF (lcur_xxinv_stc_inv_result_nnpt%NOTFOUND) THEN
                inv_if_rec(i).sts := gv_sts_ins; -- ����f�[�^�}��
              ELSE
                ln_upd_cnt := ln_upd_cnt + 1;
                UPDATE xxinv_stc_inventory_result xsir -- �I�����ʃe�[�u��
                SET    xsir.case_amt               = inv_if_rec(i).case_amt  -- �I���P�[�X��
                      ,xsir.content                = inv_if_rec(i).content   -- ����
                      ,xsir.loose_amt              = inv_if_rec(i).loose_amt -- �I���o��
                      ,xsir.location               = inv_if_rec(i).location  -- ���P�[�V����
                      ,xsir.rack_no1               = inv_if_rec(i).rack_no1  -- ���b�NNo�P
                      ,xsir.rack_no2               = inv_if_rec(i).rack_no2  -- ���b�NNo�Q
                      ,xsir.rack_no3               = inv_if_rec(i).rack_no3  -- ���b�NNo�R
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
              CLOSE lcur_xxinv_stc_inv_result_nnpt; -- ���b�N�擾�J�[�\��CLOSE
            END IF;
          END IF;
        END IF;
--
      EXCEPTION
        WHEN lock_expt THEN -- ���b�N�擾�G���[ ***
          -- �J�[�\����CLOSE(���i)
          IF (lcur_xxinv_stc_inv_result_pt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_result_pt;
          END IF;
          -- �J�[�\����CLOSE(���i�ȊO)
          IF (lcur_xxinv_stc_inv_result_npt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_result_npt;
          END IF;
          -- �J�[�\����CLOSE(���i�ȊO)
          IF (lcur_xxinv_stc_inv_result_nnpt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_result_nnpt;
          END IF;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                         gv_xxcmn
                        ,'APP-XXCMN-10019'
                        ,'TABLE'
                        ,gv_inv_result_name
                        ),1,5000);
          RAISE global_api_expt;
      END;
--
    END LOOP upd_table_batch_loop;
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
      -- �J�[�\����CLOSE(���i)
      IF (lcur_xxinv_stc_inv_result_pt%ISOPEN) THEN
        CLOSE lcur_xxinv_stc_inv_result_pt;
      END IF;
      -- �J�[�\����CLOSE(���i�ȊO)
      IF (lcur_xxinv_stc_inv_result_npt%ISOPEN) THEN
        CLOSE lcur_xxinv_stc_inv_result_npt;
      END IF;
      -- �J�[�\����CLOSE(���i�ȊO)
      IF (lcur_xxinv_stc_inv_result_nnpt%ISOPEN) THEN
        CLOSE lcur_xxinv_stc_inv_result_nnpt;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : proc_master_data_chk
   * Description      : �Ó����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE proc_master_data_chk(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_master_data_chk'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_dupretcd VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h(�d���`�F�b�N�p)
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_item_id        xxcmn_item_mst_v.item_id          %TYPE DEFAULT NULL; --�i��ID
    ln_lot_ctl        xxcmn_item_mst_v.lot_ctl          %TYPE DEFAULT 0;    --���b�g
    lv_num_of_cases   xxcmn_item_mst_v.num_of_cases     %TYPE DEFAULT NULL; --�P�[�X����D
    ln_lot_id         ic_lots_mst.lot_id                %TYPE DEFAULT NULL; --���b�gID
    lv_lot_no         ic_lots_mst.lot_no                %TYPE DEFAULT NULL; --���b�g��
    lv_maker_date     ic_lots_mst.attribute1            %TYPE DEFAULT NULL; --������
    lv_proper_mark     ic_lots_mst.attribute2           %TYPE DEFAULT NULL; --�ŗL����
    lv_limit_date     ic_lots_mst.attribute3            %TYPE DEFAULT NULL; --�ܖ�����
    lv_item_type      xxcmn_item_categories2_v.segment1 %TYPE DEFAULT NULL; --�i�ڋ敪
    lv_product_type   xxcmn_item_categories2_v.segment1 %TYPE DEFAULT NULL; --���i�敪
    lv_whse_code      ic_whse_mst.whse_code             %TYPE DEFAULT NULL; --�q�ɃR�[�h
    lb_dump_flag                                        BOOLEAN DEFAULT FALSE; -- �G���[�t���O
    lv_dump                                             VARCHAR2(5000) DEFAULT NULL;--�f�[�^�_���v
    lv_msg_col                                          VARCHAR2(100)  DEFAULT NULL;--���ږ�����
    lb_dup_sts                                          BOOLEAN DEFAULT FALSE; -- �d���`�F�b�N����
    lb_dup_del_sts                                   BOOLEAN DEFAULT FALSE; -- �d���폜�`�F�b�N����
    ld_maker_date                                       DATE  DEFAULT NULL;--�������`�F�b�N�p
    ld_limit_date                                       DATE  DEFAULT NULL;--�ܖ������`�F�b�N�p
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
    lv_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<process_loop>>
    FOR i IN 1..inv_if_rec.COUNT LOOP
      --�f�[�^�_���v�t���O������
      lb_dump_flag  := FALSE;
--
-- 2008/12/06 H.Itou Del Start �i�ڋ敪���擾���Ă���d���`�F�b�N���s���̂ŁA�Ō�Ɉړ�
--      -- ===========================================
--      -- �d���`�F�b�N                              =
--      -- ===========================================
--      proc_duplication_chk(
--        if_rec      => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
--       ,iv_item_typ => lv_item_type   -- 2.�f�[�^�_���v������
--       ,ib_dup_sts  => lb_dup_sts     -- 3.�d���`�F�b�N����
--       ,ib_dup_del_sts => lb_dup_del_sts -- 4.�d���폜�`�F�b�N����
--       ,ov_errbuf   => lv_errbuf
--       ,ov_retcode  => lv_dupretcd
--       ,ov_errmsg   => lv_errmsg);
--      -- �G���[�̏ꍇ
--      IF (lv_dupretcd = gv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
----
--      IF  (lb_dup_sts  = FALSE) THEN
--        IF (lb_dup_del_sts = TRUE) THEN
--          inv_if_rec(i).sts  :=  gv_sts_del;  --�d���폜
--        ELSE
--          inv_if_rec(i).sts  :=  gv_sts_ng;  --�d���G���[ 4,6
--        END IF;
--        IF  ((lb_dump_flag  = FALSE) AND (lb_dup_del_sts = FALSE)) THEN -- �d���폜�̓G���[�Ƃ��Ȃ�
--          --�f�[�^�_���v�擾
--          proc_get_data_dump(
--            if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
--           ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
--           ,ov_errbuf  => lv_errbuf
--           ,ov_retcode => lv_retcode
--           ,ov_errmsg  => lv_errmsg);
--          -- �G���[�̏ꍇ
--          IF (lv_retcode = gv_status_error) THEN
--            RAISE global_api_expt;
--          ELSE
--            lv_retcode  := gv_status_warn;
--          END IF;
--          -- �x���f�[�^�_���vPL/SQL�\����
--          gn_err_msg_cnt := gn_err_msg_cnt + 1;
--          warn_dump_tab(gn_err_msg_cnt) := lv_dump;
--          lb_dump_flag :=  TRUE;
--        END IF;
----
--        IF (lb_dup_del_sts = FALSE) THEN -- �d���폜�̓G���[�Ƃ��Ȃ�
--          -- �x���G���[���b�Z�[�W�擾 (����t�@�C�����ɏd���f�[�^�����݂��܂��B)
--          lv_errmsg := xxcmn_common_pkg.get_msg(
--                        iv_application  => gv_xxinv,
--                        iv_name         => 'APP-XXINV-10101');
----
--          -- �x�����b�Z�[�WPL/SQL�\����
--          gn_err_msg_cnt := gn_err_msg_cnt + 1;
--          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--        END IF;
----
--      END IF;
-- 2008/12/06 H.Itou Del End
--
-- 2008/12/06 H.Itou Del Start
--      IF (lb_dup_del_sts != true) THEN
-- 2008/12/06 H.Itou Del End
        -- ===============================
        -- �i�ڃ}�X�^�`�F�b�N(OPM�i�ڃ}�X�^�ɑ��݂��邩�`�F�b�N���܂��B�j
        -- ===============================
        BEGIN
--
          SELECT  itm.item_id item_id,
                  itm.lot_ctl lot_ctl,
                  itm.num_of_cases  num_of_cases,
                  icmt.item_class_code item_type,
                  icmt.prod_class_code product_type
          INTO    ln_item_id,       --�i��ID
                  ln_lot_ctl,       --���b�g
                  lv_num_of_cases,  --�P�[�X����
                  lv_item_type,     --�i�ڋ敪
                  lv_product_type   --���i�敪
--
          FROM  xxcmn_item_mst_v itm,                   -- 1.OPM�i�ڃ}�X�^(�L�������̂�)
                xxcmn_item_categories5_v icmt           -- 5.�i�ڃJ�e�S���A�Z�b�g
--
          WHERE itm.item_no = inv_if_rec(i).item_code
            AND icmt.item_id = itm.item_id;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_item_id      :=  NULL;   --�i��ID
            ln_lot_ctl      :=  NULL;   --���b�g
            lv_num_of_cases :=  NULL;   --�P�[�X����
            lv_item_type    :=  NULL;   --�i�ڋ敪
            lv_product_type :=  NULL;   --���i�敪
            lb_dump_flag    :=  TRUE;
            inv_if_rec(i).sts  :=  gv_sts_ng;  --�i�ڃ}�X�^���o�^�G���[ 2
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
--
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
--
        -- �x���G���[���b�Z�[�W�擾(�Y���f�[�^���}�X�^�ɑ��݂��܂���B(�}�X�^�FTABLE�C���ځFOBJECT)
            lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxinv,
                          iv_name         => 'APP-XXINV-10102',
                          iv_token_name1  => 'TABLE',
                          iv_token_value1 => gv_opm_item_name,
                          iv_token_name2  => 'OBJECT',
                          iv_token_value2 => inv_if_rec(i).item_code);
--
            -- �x�����b�Z�[�WPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END;
--
        -- ============================================
        -- OPM�q�Ƀ}�X�^�ɑ��݂��邩�`�F�b�N���܂��B  =
        -- ============================================
        BEGIN
          SELECT  iwm.whse_code
          INTO    lv_whse_code  --�q�ɃR�[�h
          FROM  ic_whse_mst iwm -- 1.OPM�q�Ƀ}�X�^
          WHERE iwm.whse_code = inv_if_rec(i).invent_whse_code
-- [E_�{�ғ�_14953] SCSK Y.Sekine Add Start
            AND iwm.delete_mark = '0'
-- [E_�{�ғ�_14953] SCSK Y.Sekine Add End
            AND ROWNUM  = 1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            inv_if_rec(i).sts  :=  gv_sts_ng;  --�q�Ƀ}�X�^���o�^�G���[ 8
            --�f�[�^�_���v�擾
            IF  (lb_dump_flag  = FALSE)  THEN
              proc_get_data_dump(
                if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
               ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
               ,ov_errbuf  => lv_errbuf
               ,ov_retcode => lv_retcode
               ,ov_errmsg  => lv_errmsg);
              -- �G���[�̏ꍇ
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_api_expt;
              ELSE
                lv_retcode  := gv_status_warn;
              END IF;
              -- �x���f�[�^�_���vPL/SQL�\����
              gn_err_msg_cnt := gn_err_msg_cnt + 1;
              warn_dump_tab(gn_err_msg_cnt) := lv_dump;
              lb_dump_flag :=  TRUE;
            END IF;
--
        -- �x���G���[���b�Z�[�W�擾(�Y���f�[�^���}�X�^�ɑ��݂��܂���B(�}�X�^�FTABLE�C���ځFOBJECT)
            lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxinv,
                          iv_name         => 'APP-XXINV-10102',
                          iv_token_name1  => 'TABLE',
                          iv_token_value1 => gv_invent_whse_name,
                          iv_token_name2  => 'OBJECT',
                          iv_token_value2 => inv_if_rec(i).invent_whse_code);
            -- �x�����b�Z�[�WPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END;
--
--
    --  �i�ڃ}�X�^�����݂���ꍇ�̂݃`�F�b�N����(4-904-30)
        IF  (lv_item_type IS  NOT NULL) THEN
          -- ===============================
          -- ���b�g���}�X�^�ɑ��݂��邩�`�F�b�N
          -- ===============================
      --
          --�i�ڋ敪�����i�ȊO�̏ꍇ
          IF (lv_item_type != gv_item_cls_prdct) THEN
            --���b�g�Ǘ��Ώۂ̏ꍇ
            IF  (ln_lot_ctl  = 1) THEN
              -- ���b�g����'0'�̓G���[�Ƃ���B
              IF  (inv_if_rec(i).lot_no = '0' ) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --���b�g����'0'�̓G���[�Ƃ���B10
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0�ȊO���w�肵�Ă��������B(���ځFOBJECT�����b�g���j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_lot_no_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --���b�g�}�X�^�`�F�b�N
              BEGIN
                SELECT  lot.lot_id lot_id           --���b�gID
                        ,lot.attribute1 maker_date  --������
                        ,lot.attribute2 proper_mark --�ŗL�L��
                        ,lot.attribute3 limit_date  --�ܖ�����
                INTO     ln_lot_id
                        ,lv_maker_date
                        ,lv_proper_mark
                        ,lv_limit_date
                FROM  ic_lots_mst lot -- 1.OPM���b�g�}�X�^
                WHERE lot.lot_no = inv_if_rec(i).lot_no
                  AND lot.item_id = ln_item_id
                  AND ROWNUM  = 1;
--
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                    inv_if_rec(i).sts  :=  gv_sts_hr;  --���b�g�}�X�^���o�^�G���[(�ۗ�)  12
                  END IF;
                  --�f�[�^�_���v�擾
                  IF  (lb_dump_flag  = FALSE)  THEN
                    proc_get_data_dump(
                      if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                     ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                     ,ov_errbuf  => lv_errbuf
                     ,ov_retcode => lv_retcode
                     ,ov_errmsg  => lv_errmsg);
                    -- �G���[�̏ꍇ
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_api_expt;
                    ELSE
                      lv_retcode  := gv_status_warn;
                    END IF;
                    -- �x���f�[�^�_���vPL/SQL�\����
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                    lb_dump_flag :=  TRUE;
                  END IF;
--
            -- �x���G���[���b�Z�[�W�擾(OPM���b�g�}�X�^�ɊY���f�[�^�����݂��܂���B(���ځFOBJECT))
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10108',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_lot_no_col);
                  -- �x�����b�Z�[�WPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END;
            --���b�g�Ǘ��ΏۊO�̏ꍇ
            ELSIF (ln_lot_ctl  != 1)  THEN
              -- ���b�g����'0'�ȊO�̓G���[�Ƃ���B
              IF  (inv_if_rec(i).lot_no != '0' ) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --���b�g����'0'�ȊO�̓G���[�Ƃ���B14
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 ( 0���w�肵�Ă��������B(���ځFOBJECT) )
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_lot_no_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
            END IF;
          END IF;
--
          -- ==================================================
          -- �������A�ܖ������A�ŗL�L���A���b�g�}�X�^�`�F�b�N =
          -- ==================================================
--
          --�i�ڋ敪�����i�̏ꍇ
          IF (lv_item_type = gv_item_cls_prdct) THEN
            IF  (lv_product_type  = gv_goods_classe_drink)  THEN  --���i�敪���h�����N�̏ꍇ
              -- ��������'0'�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).maker_date  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  -- ��������'0'�̏ꍇ�̃G���[ 16
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0�ȊO���w�肵�Ă��������B(���ځFOBJECT���������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_maker_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- �ܖ�������'0'�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).limit_date  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  -- �ܖ�������'0'�̏ꍇ�̃G���[ 17
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0�ȊO���w�肵�Ă��������B(���ځFOBJECT���ܖ������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- �ŗL�L����'0'�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).proper_mark  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  -- �ŗL�L����'0'�̏ꍇ�̃G���[ 18
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0�ȊO���w�肵�Ă��������B(���ځFOBJECT���ŗL�L���j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --�����������t�^�G���[
              ld_maker_date := FND_DATE.STRING_TO_DATE(inv_if_rec(i).maker_date, gc_char_d_format);
              IF  (ld_maker_date IS NULL) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�����������t�^�G���[ 20
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (���t�`���G���[:�������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => gv_xxinv,
                               iv_name         => 'APP-XXINV-10105',
                               iv_token_name1  => 'OBJECT',
                               iv_token_value1 => gv_maker_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --�ܖ����������t�^�G���[
              ld_limit_date := FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format);
              IF  (ld_limit_date IS NULL) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�ܖ����������t�^�G���[ 21
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (���t�`���G���[:�ܖ������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => gv_xxinv,
                               iv_name         => 'APP-XXINV-10105',
                               iv_token_name1  => 'OBJECT',
                               iv_token_value1 => gv_limit_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --OPM���b�g�}�X�^�`�F�b�N
              BEGIN
                ln_lot_id :=  NULL;
                lv_lot_no :=  NULL;
                lv_limit_date :=  NULL;
-- 2008/12/06 H.Itou Add Start
                lv_maker_date  := NULL; -- ������
                lv_proper_mark := NULL; -- �ŗL�L��
-- 2008/12/06 H.Itou Add End
                SELECT
                  ilm.lot_id     AS lot_id     -- ���b�gID
                 ,ilm.lot_no     AS lot_no     -- ���b�gNO
                 ,ilm.attribute3 AS limit_date -- �ܖ�����
-- 2008/12/06 H.Itou Add Start
                 ,ilm.attribute1 AS maker_date  -- ������
                 ,ilm.attribute2 AS proper_mark -- �ŗL�L��
-- 2008/12/06 H.Itou Add End
                INTO
                  ln_lot_id
                 ,lv_lot_no
                 ,lv_limit_date
-- 2008/12/06 H.Itou Add Start
                 ,lv_maker_date  -- ������
                 ,lv_proper_mark -- �ŗL�L��
-- 2008/12/06 H.Itou Add End
                FROM   ic_lots_mst ilm
-- 2008/12/06 H.Itou Add Start
--                WHERE ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gc_char_d_format) || ''--������
                WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date --������
-- 2008/12/06 H.Itou Add End
                AND    ilm.attribute2 = inv_if_rec(i).proper_mark--�ŗL�L��
                AND    ilm.item_id = ln_item_id --�i��ID
-- 2016/06/15 Y.Shoji Mod Start
--                AND ROWNUM  = 1;
                ;
-- 2016/06/15 Y.Shoji Mod End
                --
                IF  (lv_limit_date IS NOT NULL) THEN
                  IF  (FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format) !=
                       FND_DATE.STRING_TO_DATE(lv_limit_date, gc_char_d_format))  THEN
                    IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                      inv_if_rec(i).sts  :=  gv_sts_hr;  --�ܖ���������v���Ȃ� (�ۗ�)  25
                    END IF;
                    --�f�[�^�_���v�擾
                    IF  (lb_dump_flag  = FALSE)  THEN
                      proc_get_data_dump(
                        if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                       ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                       ,ov_errbuf  => lv_errbuf
                       ,ov_retcode => lv_retcode
                       ,ov_errmsg  => lv_errmsg);
                      -- �G���[�̏ꍇ
                      IF (lv_retcode = gv_status_error) THEN
                        RAISE global_api_expt;
                      ELSE
                        lv_retcode  := gv_status_warn;
                      END IF;
                      -- �x���f�[�^�_���vPL/SQL�\����
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                      lb_dump_flag :=  TRUE;
                    END IF;
--
                  -- �x���G���[���b�Z�[�W�擾(�ܖ���������v���܂���B(���ځFCONTENT))
                      -- �ܖ������̕s��v(�ۗ�)
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10110',
                                    iv_token_name1  => 'OBEJCT',
                                    iv_token_value1 => gv_limit_date_col,
                                    iv_token_name2  => 'CONTENT',
                                    iv_token_value2 => gv_limit_date_col ||
                                      gv_msg_part || lv_limit_date);
                    -- �x�����b�Z�[�WPL/SQL�\����
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END IF;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                    inv_if_rec(i).sts  :=  gv_sts_hr;  --���b�g�}�X�^���o�^�G���[(�ۗ�)  23
                  END IF;
                  --�f�[�^�_���v�擾
                  IF  (lb_dump_flag  = FALSE)  THEN
                    proc_get_data_dump(
                      if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                     ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                     ,ov_errbuf  => lv_errbuf
                     ,ov_retcode => lv_retcode
                     ,ov_errmsg  => lv_errmsg);
                    -- �G���[�̏ꍇ
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_api_expt;
                    ELSE
                      lv_retcode  := gv_status_warn;
                    END IF;
                    -- �x���f�[�^�_���vPL/SQL�\����
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                    lb_dump_flag :=  TRUE;
                  END IF;
--
        -- �x���G���[���b�Z�[�W�擾(OPM���b�g�}�X�^�ɊY���f�[�^�����݂��܂���B(���ځFOBJECT))
                  lv_msg_col  :=  gv_maker_date_col || '�A' || gv_proper_mark_col;
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10108',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => lv_msg_col);
                  -- �x�����b�Z�[�WPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
-- 2016/06/15 Y.Shoji Add Start
                WHEN TOO_MANY_ROWS THEN
                  BEGIN
                    SELECT
                      ilm.lot_id     AS lot_id      -- ���b�gID
                     ,ilm.lot_no     AS lot_no      -- ���b�gNO
                     ,ilm.attribute3 AS limit_date  -- �ܖ�����
                     ,ilm.attribute1 AS maker_date  -- ������
                     ,ilm.attribute2 AS proper_mark -- �ŗL�L��
                    INTO
                      ln_lot_id               -- ���b�gID
                     ,lv_lot_no               -- ���b�gNO
                     ,lv_limit_date           -- �ܖ�����
                     ,lv_maker_date           -- ������
                     ,lv_proper_mark          -- �ŗL�L��
                    FROM   ic_lots_mst ilm
                    WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date             -- ������
                    AND    ilm.attribute2                                            = inv_if_rec(i).proper_mark -- �ŗL�L��
                    AND    ilm.item_id                                               = ln_item_id                -- �i��
                    AND    FND_DATE.STRING_TO_DATE(ilm.attribute3, gc_char_d_format) = ld_limit_date             -- �ܖ�����
                    ;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --���b�g�}�X�^���o�^�G���[(�ۗ�)
                      END IF;
                      --�f�[�^�_���v�擾
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                         ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- �G���[�̏ꍇ
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- �x���f�[�^�_���vPL/SQL�\����
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
--
                      -- �x���G���[���b�Z�[�W�擾(OPM���b�g�}�X�^�ɊY���f�[�^�����݂��܂���B(���ځFOBJECT))
                      lv_msg_col  :=  gv_maker_date_col || '�A' || gv_proper_mark_col || '�A' || gv_limit_date_col;
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10108',
                                    iv_token_name1  => 'OBJECT',
                                    iv_token_value1 => lv_msg_col);
                      -- �x�����b�Z�[�WPL/SQL�\����
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END;
-- 2016/06/15 Y.Shoji Add End
              END;
            END IF;--�h�����N�I��
--
            IF  (lv_product_type  = gv_goods_classe_reaf)  THEN  --���i�敪�����[�t�̏ꍇ
              -- �ܖ�������'0'�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).limit_date  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�ܖ�������'0'�̏ꍇ�̃G�� 27
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0�ȊO���w�肵�Ă��������B(���ځFOBJECT���ܖ������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- �ŗL�L����'0'�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).proper_mark  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�ŗL�L����'0'�̏ꍇ�̃G�� 28
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0�ȊO���w�肵�Ă��������B(���ځFOBJECT���ŗL�L���j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --�ܖ����������t�^�G���[
              ld_limit_date := FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format);
              IF  (ld_limit_date IS NULL) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�ܖ����������t�^�G���[  29
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (���t�`���G���[:�ܖ������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => gv_xxinv,
                               iv_name         => 'APP-XXINV-10105',
                               iv_token_name1  => 'OBJECT',
                               iv_token_value1 => gv_limit_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --OPM���b�g�}�X�^�`�F�b�N
              BEGIN
                ln_lot_id :=  NULL;
                lv_lot_no :=  NULL;
                lv_limit_date :=  NULL;
-- 2008/12/06 H.Itou Add Start
                lv_maker_date :=  NULL;
-- 2008/12/06 H.Itou Add End
                ld_maker_date :=
                          FND_DATE.STRING_TO_DATE(inv_if_rec(i).maker_date, gc_char_d_format);
                SELECT
                  ilm.lot_id     AS lot_id     -- ���b�gID
                 ,ilm.lot_no     AS lot_no     -- ���b�gNO
                 ,ilm.attribute3 AS limit_date -- �ܖ�����
-- 2008/12/06 H.Itou Add Start
                 ,ilm.attribute1 AS maker_date -- �����N����
-- 2008/12/06 H.Itou Add End
                INTO
                  ln_lot_id
                 ,lv_lot_no
                 ,lv_limit_date
-- 2008/12/06 H.Itou Add Start
                 ,lv_maker_date           -- �����N����
-- 2008/12/06 H.Itou Add End
                FROM   ic_lots_mst ilm
-- 2008/12/06 H.Itou Add Start
--                WHERE ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gc_char_d_format) || ''--������
                WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date --������
-- 2008/12/06 H.Itou Add End
                AND    ilm.attribute2 = inv_if_rec(i).proper_mark --�ŗL�L��
                AND    ilm.item_id = ln_item_id
-- 2016/06/15 Y.Shoji Mod Start
--                AND ROWNUM  = 1;
                ;
-- 2016/06/15 Y.Shoji Mod End
                --���b�g�}�X�^�����݂���ꍇ�ɏܖ��������s��v�̏ꍇ
                IF  (lv_limit_date IS NOT NULL) THEN
                  IF  (FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format) !=
                       FND_DATE.STRING_TO_DATE(lv_limit_date, gc_char_d_format))  THEN
                    IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                      inv_if_rec(i).sts  :=  gv_sts_hr;  --�ܖ��������s��v  (�ۗ�) 32
                    END IF;
                    --�f�[�^�_���v�擾
                    IF  (lb_dump_flag  = FALSE)  THEN
                      proc_get_data_dump(
                        if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                       ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                       ,ov_errbuf  => lv_errbuf
                       ,ov_retcode => lv_retcode
                       ,ov_errmsg  => lv_errmsg);
                      -- �G���[�̏ꍇ
                      IF (lv_retcode = gv_status_error) THEN
                        RAISE global_api_expt;
                      ELSE
                        lv_retcode  := gv_status_warn;
                      END IF;
                      -- �x���f�[�^�_���vPL/SQL�\����
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                      lb_dump_flag :=  TRUE;
                    END IF;
                  -- �x���G���[���b�Z�[�W�擾(�ܖ���������v���܂���B(���ځFCONTENT))
                      -- �ܖ������̕s��v(�ۗ�)
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10110',
                                    iv_token_name1  => 'OBEJCT',
                                    iv_token_value1 => gv_limit_date_col,
                                    iv_token_name2  => 'CONTENT',
                                    iv_token_value2 => gv_limit_date_col ||
                                      gv_msg_part || lv_limit_date);
                    -- �x�����b�Z�[�WPL/SQL�\����
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END IF;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  BEGIN
                    SELECT
                      ilm.lot_id     AS lot_id     -- ���b�gID
                     ,ilm.lot_no     AS lot_no     -- ���b�gNO
                     ,ilm.attribute1 AS maker_date -- ������
                    INTO
                      ln_lot_id
                     ,lv_lot_no
                     ,lv_maker_date
                    FROM   ic_lots_mst ilm
-- 2008/12/06 H.Itou Add Start
--                    WHERE ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gc_char_d_format) || ''--������
                    WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute3, gc_char_d_format) = ld_limit_date --�ܖ�����
-- 2008/12/06 H.Itou Add End
                    AND    ilm.attribute2 = inv_if_rec(i).proper_mark--�ŗL�L��
                    AND    ilm.item_id = ln_item_id; --�i��ID
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --���b�g�}�X�^���o�^�G���[(�ۗ�)  34
                      END IF;
                      --�f�[�^�_���v�擾
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                         ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- �G���[�̏ꍇ
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- �x���f�[�^�_���vPL/SQL�\����
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
              -- �x���G���[���b�Z�[�W�擾(OPM���b�g�}�X�^�ɊY���f�[�^�����݂��܂���(���ځFOBJECT))
                      lv_msg_col  :=  gv_limit_date_col || '�A' || gv_proper_mark_col;
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10108',
                                    iv_token_name1  => 'OBJECT',
                                    iv_token_value1 => lv_msg_col);
                      -- �x�����b�Z�[�WPL/SQL�\����
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                    WHEN TOO_MANY_ROWS THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --���b�g�}�X�^���o�^�G���[(�ۗ�)  35
                      END IF;
                      --�f�[�^�_���v�擾
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                         ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- �G���[�̏ꍇ
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- �x���f�[�^�_���vPL/SQL�\����
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
                      -- OPM���b�g�}�X�^�ɕ����o�^(�ۗ�)
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                        iv_application  => gv_xxinv,
                                        iv_name         => 'APP-XXINV-10109',
                                        iv_token_name1  => 'OBJECT',
                                        iv_token_value1 =>
                                          gv_proper_mark_col ||
                                          gv_msg_part || inv_if_rec(i).proper_mark ||
                                          gv_msg_comma ||
                                          gv_limit_date_col ||
                                          gv_msg_part || inv_if_rec(i).limit_date);
                      -- �x�����b�Z�[�WPL/SQL�\����
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END;
-- 2016/06/15 Y.Shoji Add Start
                WHEN TOO_MANY_ROWS THEN
                  BEGIN
                    SELECT
                      ilm.lot_id     AS lot_id     -- ���b�gID
                     ,ilm.lot_no     AS lot_no     -- ���b�gNO
                     ,ilm.attribute3 AS limit_date -- �ܖ�����
                     ,ilm.attribute1 AS maker_date -- �����N����
                    INTO
                      ln_lot_id               -- ���b�gID
                     ,lv_lot_no               -- ���b�gNO
                     ,lv_limit_date           -- �ܖ�����
                     ,lv_maker_date           -- �����N����
                    FROM   ic_lots_mst ilm
                    WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date             -- ������
                    AND    ilm.attribute2                                            = inv_if_rec(i).proper_mark -- �ŗL�L��
                    AND    ilm.item_id                                               = ln_item_id                -- �i��
                    AND    FND_DATE.STRING_TO_DATE(ilm.attribute3, gc_char_d_format) = ld_limit_date             -- �ܖ�����
                    ;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --���b�g�}�X�^���o�^�G���[(�ۗ�)
                      END IF;
                      --�f�[�^�_���v�擾
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                         ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- �G���[�̏ꍇ
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- �x���f�[�^�_���vPL/SQL�\����
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
                      -- �x���G���[���b�Z�[�W�擾(OPM���b�g�}�X�^�ɊY���f�[�^�����݂��܂���(���ځFOBJECT))
                      lv_msg_col  :=  gv_maker_date_col || '�A' || gv_proper_mark_col || '�A' || gv_limit_date_col;
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10108',
                                    iv_token_name1  => 'OBJECT',
                                    iv_token_value1 => lv_msg_col);
                      -- �x�����b�Z�[�WPL/SQL�\����
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END;
-- 2016/06/15 Y.Shoji Add End
              END;
            END IF;--���[�t�I��
          END IF;
--
          --�i�ڋ敪�����i�ȊO�̏ꍇ
          IF (lv_item_type != gv_item_cls_prdct) THEN
            --���b�g�Ǘ��ΏۊO�̏ꍇ
            IF  (ln_lot_ctl  != 1) THEN
              -- ��������'0'�ȊO�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).maker_date  != '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --��������'0'�ȊO�̏ꍇ�̃G���[   38
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0���w�肵�Ă��������B(���ځFOBJECT���������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_maker_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- �ܖ�������'0'�ȊO�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).limit_date  != '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�ܖ�������'0'�ȊO�̏ꍇ�̃G���[   39
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0���w�肵�Ă��������B(���ځFOBJECT���ܖ������j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- �ŗL�L����'0'�ȊO�̏ꍇ�̃G���[
              IF  (inv_if_rec(i).proper_mark  != '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --�ŗL�L����'0'�ȊO�̏ꍇ�̃G���[   40
                IF  (lb_dump_flag  = FALSE)  THEN
                  --�f�[�^�_���v�擾
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
                   ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- �G���[�̏ꍇ
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- �x���f�[�^�_���vPL/SQL�\����
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- �x���G���[���b�Z�[�W�擾 (0���w�肵�Ă��������B(���ځFOBJECT���ŗL�L���j
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
                -- �x�����b�Z�[�WPL/SQL�\����
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
            END IF;
          END IF;
--
        END IF;
--
        -- ======================
        -- �I���P�[�X���`�F�b�N =
        -- ======================
        --�I���P�[�X�� ���O�����̏ꍇ�̃G���[
        IF  (inv_if_rec(i).case_amt < 0 ) THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --�I���P�[�X�� ���O�����̏ꍇ�̃G���[  43
          IF  (lb_dump_flag  = FALSE)  THEN
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- �x���G���[���b�Z�[�W�擾 (0�ȏ�̒l���w�肵�Ă��������B(���ځFOBJECT���I���P�[�X�j
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10106',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_case_amt_col);
          -- �x�����b�Z�[�WPL/SQL�\����
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        ELSIF
        --�I���P�[�X�� �������łȂ��ꍇ�̃G���[
          (inv_if_rec(i).case_amt  -
            TRUNC(inv_if_rec(i).case_amt)  !=0)  THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --�I���P�[�X�� �������łȂ��ꍇ�̃G���[ 44
          IF  (lb_dump_flag  = FALSE)  THEN
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- �x���G���[���b�Z�[�W�擾 (�����l���w�肵�Ă��������B(���ځFOBJECT)T���I���P�[�X�j
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10107',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_case_amt_col);
          -- �x�����b�Z�[�WPL/SQL�\����
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END IF;
--
        -- ======================
        -- �I���o�����`�F�b�N =
        -- ======================
        --�I���o���� ���O�����̏ꍇ�̃G���[
        IF  (inv_if_rec(i).loose_amt < 0 ) THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --�I���o���� ���O�����̏ꍇ�̃G���[  46
          IF  (lb_dump_flag  = FALSE)  THEN
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- �x���G���[���b�Z�[�W�擾 (0�ȏ�̒l���w�肵�Ă��������B(���ځFOBJECT���I���o���j
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10106',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_loose_amt_col);
          -- �x�����b�Z�[�WPL/SQL�\����
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END IF;
        -- ======================
        -- �����`�F�b�N =
        -- ======================
        --���� ���O�����̏ꍇ�̃G���[
        IF  (inv_if_rec(i).content < 0 ) THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --���� ���O�����̏ꍇ�̃G���[ 48
          IF  (lb_dump_flag  = FALSE)  THEN
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- �x���G���[���b�Z�[�W�擾 (0�ȏ�̒l���w�肵�Ă��������B(���ځFOBJECT������)
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10106',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_content_col);
          -- �x�����b�Z�[�WPL/SQL�\����
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
              --�i�ڋ敪�����i�����i�敪���h�����N���������P�[�X����
        ELSIF (inv_if_rec(i).content != lv_num_of_cases) AND
              (lv_item_type = gv_item_cls_prdct)  AND          --�i�ڋ敪�����i     2008/05/02
              (lv_product_type  = gv_goods_classe_drink)  THEN  --���i�敪���h�����N 2008/05/02
          inv_if_rec(i).sts  :=  gv_sts_ng;  --�i�ڋ敪�����i���������P�[�X���� 50
          IF  (lb_dump_flag  = FALSE)  THEN
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- �x���G���[���b�Z�[�W�擾 (0�ȏ�̒l���w�肵�Ă��������B(���ځFOBJECT�������j
          lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxinv,
                        iv_name         => 'APP-XXINV-10110',
                        iv_token_name1  => 'OBEJCT',
                        iv_token_value1 => gv_content_col,
                        iv_token_name2  => 'CONTENT',
                        iv_token_value2 => gv_num_of_cases_col ||
                          gv_msg_part || lv_num_of_cases);
          -- �x�����b�Z�[�WPL/SQL�\����
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END IF;
--
-- 2008/12/06 H.Itou Add Start �ォ��ړ�
        -- ===========================================
        -- �d���`�F�b�N                              =
        -- ===========================================
        proc_duplication_chk(
          if_rec      => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
         ,iv_item_typ => lv_item_type   -- 2.�f�[�^�_���v������
         ,ib_dup_sts  => lb_dup_sts     -- 3.�d���`�F�b�N����
         ,ib_dup_del_sts => lb_dup_del_sts -- 4.�d���폜�`�F�b�N����
         ,ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_dupretcd
         ,ov_errmsg   => lv_errmsg);
        -- �G���[�̏ꍇ
        IF (lv_dupretcd = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        IF  (lb_dup_sts  = FALSE) THEN
          IF (lb_dup_del_sts = TRUE) THEN
            inv_if_rec(i).sts  :=  gv_sts_del;  --�d���폜
          ELSE
            inv_if_rec(i).sts  :=  gv_sts_ng;  --�d���G���[ 4,6
          END IF;
          IF  ((lb_dump_flag  = FALSE) AND (lb_dup_del_sts = FALSE)) THEN -- �d���폜�̓G���[�Ƃ��Ȃ�
            --�f�[�^�_���v�擾
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
--
          IF (lb_dup_del_sts = FALSE) THEN -- �d���폜�̓G���[�Ƃ��Ȃ�
            -- �x���G���[���b�Z�[�W�擾 (����t�@�C�����ɏd���f�[�^�����݂��܂��B)
            lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxinv,
                          iv_name         => 'APP-XXINV-10101');
--
            -- �x�����b�Z�[�WPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
          END IF;
--
        END IF;
-- 2008/12/06 H.Itou Add End �ォ��ړ�
-- 2009/02/09 v1.12 ADD START
--
        -- ===========================================
        -- �݌ɃN���[�Y�`�F�b�N                      =
        -- ===========================================
        -- �I�������݌ɃJ�����_�[�̃I�[�v���łȂ��ꍇ
        IF ( TO_CHAR(inv_if_rec(i).invent_date, 'YYYYMM') <= xxcmn_common_pkg.get_opminv_close_period() ) THEN
          -- �G���[���b�Z�[�W���擾
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxinv
                                              , 'APP-XXINV-10003'
                                              , 'ERR_MSG'
                                              , TO_CHAR(inv_if_rec(i).invent_date, gc_char_d_format));
          -- �x�����b�Z�[�WPL/SQL�\����
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
          inv_if_rec(i).sts  :=  gv_sts_ng;
--
          --�f�[�^�_���v�擾
          IF  (lb_dump_flag  = FALSE)  THEN
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.�I���C���^�[�t�F�[�X
             ,ov_dump    => lv_dump        -- 2.�f�[�^�_���v������
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- �G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- �x���f�[�^�_���vPL/SQL�\����
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
        END IF;
--
-- 2009/02/09 v1.12 ADD END
        --�}�X�^�`�F�b�N�Ŏ擾�������ڂ�z��֑ޔ�
        inv_if_rec(i).item_id      := ln_item_id;          --�i��ID
        inv_if_rec(i).lot_ctl      := ln_lot_ctl;          --���b�g�Ǘ��敪
        inv_if_rec(i).num_of_cases := lv_num_of_cases;     --�P�[�X����
        inv_if_rec(i).item_type    := lv_item_type;        --�i�ڋ敪
        inv_if_rec(i).product_type := lv_product_type ;    --���i�敪
--
        inv_if_rec(i).lot_id       := ln_lot_id;           --���b�gID
        inv_if_rec(i).lot_no1      := lv_lot_no;           --���b�gNo
        inv_if_rec(i).maker_date1  := lv_maker_date;       --�����N����
        inv_if_rec(i).proper_mark1 := lv_proper_mark;      --�ŗL�L��
        inv_if_rec(i).limit_date1  := lv_limit_date;       --�ܖ�����
--
-- 2008/12/06 H.Itou Del Start
--      END IF;
-- 2008/12/06 H.Itou Del En
--
    END LOOP process_loop;
--
    -- ===============================
    -- OUT�p�����[�^�Z�b�g
    -- ===============================
    ov_retcode := lv_retcode;
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
  END proc_master_data_chk;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_lock
   * Description      : �ΏۃC���^�[�t�F�[�X�f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_lock(
    iv_report_post_code IN  xxinv_stc_inventory_interface.report_post_code%TYPE,  --�񍐕���
    iv_whse_code        IN  ic_whse_mst.whse_code                         %TYPE,  --�q�ɃR�[�h
    iv_item_type        IN  xxcmn_categories2_v.segment1                  %TYPE,  --�i�ڋ敪
    lrec_data           OUT cursor_rec,                                           --�Ώۃf�[�^
    ov_errbuf           OUT VARCHAR2,         --   �G���[�E���b�Z�[�W
    ov_retcode          OUT VARCHAR2,         --   ���^�[���E�R�[�h
    ov_errmsg           OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_lock'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_xxwip_delivery_distance_if CONSTANT  VARCHAR2(50) := '�I���f�[�^�C���^�[�t�F�[�X';
--
    -- *** ���[�J���ϐ� ***
    lv_sql  VARCHAR2(15000) DEFAULT NULL;
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
    -- ==============================
    -- �r�p�k�g��
    -- ==============================
    lv_sql  :=
      'SELECT '
      ||  'xsi.invent_if_id      invent_if_id, '      --�I���h�e_ID
      ||  'xsi.report_post_code  report_post_code, '  --�񍐕���
      ||  'xsi.invent_date       invent_date, '       --�I����
      ||  'xsi.invent_whse_code  invent_whse_code, '  --�I���q��
--2008/12/08 mod start
--      ||  'xsi.invent_seq        invent_seq, '        --�I���A��
      ||  'TO_NUMBER(xsi.invent_seq) invent_seq, '    --�I���A��
--2008/12/08 mod end
      ||  'xsi.item_code         item_code, '         --�i��
      ||  'xsi.lot_no            lot_no, '            --���b�gNo.
      ||  'xsi.maker_date        maker_date, '        --������
      ||  'xsi.limit_date        limit_date, '        --�ܖ�����
      ||  'xsi.proper_mark       proper_mark, '       --�ŗL�L��
      ||  'xsi.case_amt          case_amt, '          --�I���P�[�X��
      ||  'xsi.content           content, '           --����
      ||  'xsi.loose_amt         loose_amt, '         --�I���o��
      ||  'xsi.location          location, '          --���P�[�V����
      ||  'xsi.rack_no1          rack_no1, '          --���b�NNo�P
      ||  'xsi.rack_no2          rack_no2, '          --���b�NNo�Q
      ||  'xsi.rack_no3          rack_no3, '          --���b�NNo�R
      ||  'xsi.request_id        request_id, '        --�v��ID
      ||  'NULL                  item_id, '           --�i��ID
      ||  'NULL                  lot_ctl, '           --���b�g�Ǘ��敪
      ||  'NULL                  num_of_cases, '      --�P�[�X����
      ||  'NULL                  item_type, '         --�i�ڋ敪
      ||  'NULL                  product_type, '      --���i�敪
      ||  'NULL                  lot_id, '            --���b�gID
      ||  'NULL                  lot_no1, '           --���b�gNo
      ||  'NULL                  maker_date1, '       --�����N����
      ||  'NULL                  proper_mark1, '      --�ŗL�L��
      ||  'NULL                  limit_date1, '       --�ܖ�����
      ||  'xsi.ROWID             rowid_work, '        --ROWID
      ||  '''OK''                sts '      ||        --�Ó����`�F�b�N�X�e�[�^�X
      'FROM '
      ||  'xxinv_stc_inventory_interface xsi '       -- 1.�I���f�[�^�C���^�t�F�[�X
      ||  ',xxcmn_locations_v xlv ';                  -- 2.���Ə��}�X�^
--
    --���̓p���F�q�ɃR�[�h�����͂���Ă���ꍇ
    IF  (iv_whse_code IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ',ic_whse_mst iwm ';                        -- 3.OPM�q�Ƀ}�X�^
    END IF;
--
    --���̓p���F�i�ڋ敪�����͂���Ă���ꍇ
    IF  (iv_item_type IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ',xxcmn_item_mst_v itm '                    -- 4.OPM�i�ڃ}�X�^(�L�������̂�)
      ||  ',xxcmn_item_categories5_v ictm ';          -- 5.OPM�i�ڃJ�e�S��VIW�S
    END IF;
--
    lv_sql  :=  lv_sql  ||
    'WHERE '
      ||  'xsi.report_post_code = ''' || iv_report_post_code || ''''
      ||  ' AND '
      ||  'xlv.location_code  = xsi.report_post_code ';
--
    --���̓p���F�q�ɃR�[�h�����͂���Ă���ꍇ
    IF  (iv_whse_code IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ' AND '
      ||  'iwm.whse_code = '''  ||  iv_whse_code  || ''''
      ||  ' AND '
      ||  'iwm.whse_code = xsi.invent_whse_code ';
    END IF;
--
--
    --���̓p���F�i�ڋ敪�����͂���Ă���ꍇ 2008/4/4
    IF  (iv_item_type IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ' AND '
      ||  'ictm.item_class_code = ''' ||  iv_item_type || '''' --���̓p���i�ڋ敪
      ||  ' AND '
      ||  'itm.item_no = xsi.item_code '
      ||  ' AND '
      ||  'ictm.item_id = itm.item_id ';
    END IF;
--
    lv_sql  :=  lv_sql  ||
    'ORDER BY '
      ||  ' xsi.invent_seq'       --�I���A��
      ||  ',xsi.invent_whse_code' --�I���q��
      ||  ',xsi.report_post_code' --�񍐕���
      ||  ',xsi.item_code'        --�i��
      ||  ',xsi.maker_date'       --������
      ||  ',xsi.limit_date'       --�ܖ�����
      ||  ',xsi.proper_mark'      --�ŗL�L��
      ||  ',xsi.lot_no'           --���b�gNo.
      ||  ',xsi.invent_date'      --�I����
      ||  ',xsi.request_id DESC '; --�v��ID
--
     lv_sql  :=  lv_sql  || 'FOR UPDATE OF xsi.invent_if_id NOWAIT';
--
    -- ====================================================================
    -- �I���f�[�^�C���^�[�t�F�[�X�e�[�u���̃��b�N���擾����уf�[�^�̎擾 =
    -- ====================================================================
    BEGIN
      OPEN  lrec_data FOR lv_sql;
      FETCH lrec_data BULK COLLECT INTO inv_if_rec;
      CLOSE lrec_data;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
        -- �J�[�\����CLOSE
        IF (lrec_data%ISOPEN) THEN
          CLOSE lrec_data;
        END IF;
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                       gv_xxcmn               -- ���W���[�������́FXXCMN ����
                      ,'APP-XXCMN-10019'      -- ���b�N���s
                      ,gv_tkn_table           -- �g�[�N��TABLE
                      ,gv_xxcmn_del_table_name-- �I���f�[�^�C���^�[�t�F�[�X�e�[�u��
                      ),1,5000);
        RAISE global_api_expt;
      WHEN OTHERS THEN
        -- �J�[�\����CLOSE
        IF (lrec_data%ISOPEN) THEN
          CLOSE lrec_data;
        END IF;
        RAISE;
--
    END;
--
--  �������O�G���[
    IF  (inv_if_rec.COUNT = 0 ) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                       gv_xxinv
                      ,'APP-XXINV-10054'      --�Ώۃf�[�^�Ȃ�
                      ,gv_tkn_table           -- �g�[�N��TABLE
                      ,gv_xxcmn_del_table_name-- �I���f�[�^�C���^�[�t�F�[�X�e�[�u��
                    );
      RAISE global_api_expt;
    END IF;
--
--  �Ώی����擾
    gn_target_cnt := inv_if_rec.COUNT;
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
  END proc_get_lock;
--
  /**********************************************************************************
   * Procedure Name   : proc_del_inventory_if
   * Description      : �f�[�^�p�[�W����(A-2)
   ***********************************************************************************/
  PROCEDURE proc_del_inventory_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_inventory_if'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �v���t�@�C���I�v�V�����F�I���폜�Ώۓ��t
    cv_xxcmn_del_date       CONSTANT  VARCHAR2(50) := 'XXINV_INVENTORY_PURGE_TERM';
    cv_xxcmn_del_date_name  CONSTANT  VARCHAR2(50) := '�I���폜�Ώۓ��t';
    -- *** ���[�J���ϐ� ***
    lv_inv_del_date fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;
    ld_del_date DATE  DEFAULT NULL;
    lr_rowid          ROWID;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �I���f�[�^�C���^�[�t�F�[�X�e�[�u��
    CURSOR xxinv_stc_inventory_if_cur(
      cd_del_date DATE -- �폜���t
      )
    IS
      SELECT stc.ROWID
      FROM   xxinv_stc_inventory_interface stc
      WHERE  stc.creation_date < cd_del_date
-- mod start ver1.6
--      FOR UPDATE NOWAIT
      FOR UPDATE
-- mod end ver1.6
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E���R�[�h ***
    TYPE ltbl_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    ltbl_rowid ltbl_rowid_type;
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
    lv_inv_del_date := FND_PROFILE.VALUE(cv_xxcmn_del_date);
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lv_inv_del_date IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- ���W���[�������́FXXCMN ����
                   ,'APP-XXCMN-10002'      -- �v���t�@�C���擾�G���[
                   ,gv_tkn_ng_profile      -- �g�[�N���FNG�v���t�@�C����
                   ,cv_xxcmn_del_date_name -- '�I���폜�Ώۓ��t'
                   ),1,5000);
--
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- �I���f�[�^�C���^�[�t�F�[�X�e�[�u���̍폜  =
    -- ===========================================
    BEGIN
      -- �폜���t�̍쐬
      ld_del_date := (TRUNC(SYSDATE) - TO_NUMBER(lv_inv_del_date));
--
      --  ���b�N�擾�J�[�\��OPEN
      OPEN xxinv_stc_inventory_if_cur(
        cd_del_date => ld_del_date);
--
      <<fetch_loop>>
      LOOP
        FETCH xxinv_stc_inventory_if_cur INTO lr_rowid;
        EXIT WHEN xxinv_stc_inventory_if_cur%NOTFOUND;
        -- �폜�Ώ�ROWID�̃Z�b�g
        ltbl_rowid(ltbl_rowid.COUNT + 1) := lr_rowid;
      END LOOP fetch_loop;
--
      -- �ꊇ�폜����
      FORALL i in 1..ltbl_rowid.COUNT
        DELETE xxinv_stc_inventory_interface stc
        WHERE  stc.ROWID = ltbl_rowid(i);
--
      -- ���b�N�擾�J�[�\����CLOSE
      CLOSE xxinv_stc_inventory_if_cur;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
        -- �J�[�\����CLOSE
        IF (xxinv_stc_inventory_if_cur%ISOPEN) THEN
          CLOSE xxinv_stc_inventory_if_cur;
        END IF;
-- 2008/09/04 H.Itou Del Start PT 6-3_39�w�E#12�Ή� �������s�����ꍇ�Ƀp�[�W�f�[�^�̃��b�N���擾�ł��Ȃ��Ă������𑱍s����B
--        -- �G���[���b�Z�[�W�擾
--        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
--                       gv_xxcmn               -- ���W���[�������́FXXCMN ����
--                      ,'APP-XXCMN-10019'      -- ���b�N���s
--                      ,gv_tkn_table           -- �g�[�N��TABLE
--                      ,gv_xxcmn_del_table_name-- �e�[�u�����F�I���f�[�^�C���^�[�t�F�[�X�e�[�u��
--                      ),1,5000);
--        RAISE global_api_expt;
-- 2008/09/04 H.Itou Del Start PT 6-3_39�w�E#12�Ή�
      WHEN OTHERS THEN
        -- �J�[�\����CLOSE
        IF (xxinv_stc_inventory_if_cur%ISOPEN) THEN
          CLOSE xxinv_stc_inventory_if_cur;
        END IF;
        RAISE;
--
    END;
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
  END proc_del_inventory_if;
--
--
   /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE proc_check_param(
    iv_report_post_code   IN      VARCHAR2,   -- �񍐕���
    iv_whse_code          IN      VARCHAR2,   -- �q�ɃR�[�h
    iv_item_type          IN      VARCHAR2,   -- �i�ڋ敪
    ov_errbuf             OUT     VARCHAR2,   -- �G���[�E���b�Z�[�W
    ov_retcode            OUT     VARCHAR2,   -- ���^�[���E�R�[�h
    ov_errmsg             OUT     VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check_param'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_xxpo_date_type       CONSTANT  VARCHAR2(30) := 'XXPO_DATE_TYPE';       -- ���t�^�C�v
    cv_xxpo_commodity_type  CONSTANT  VARCHAR2(30) := 'XXPO_COMMODITY_TYPE';  -- ���i�敪
    cv_xxpo_item_type       CONSTANT  VARCHAR2(30) := 'XXCMN_C01';            -- �i�ڋ敪
--
    -- *** ���[�J���ϐ� ***
    lv_lookup_code    xxcmn_lookup_values_v.lookup_code %TYPE  DEFAULT NULL;  -- ���b�N�A�b�v�R�[�h
    lv_location_code  xxcmn_locations_v.LOCATION_CODE   %TYPE  DEFAULT NULL;  --�����R�[�h
    lv_whse_code      ic_whse_mst.whse_code             %TYPE  DEFAULT NULL;  --�q�ɃR�[�h
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
    -- ==============================================================
    -- �񍐕��������͂���Ă��邩�`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_report_post_code IS NULL) THEN
      lv_errbuf  := xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxcmn,
                      iv_name         => 'APP-XXCMN-10010',
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_inv_whse_section_col,  -- '�q�ɊǗ�����'
                      iv_token_name2  => gv_tkn_value,
                      iv_token_value2 => NULL
                    );
      RAISE global_api_expt;
    END IF;
    -- ==============================================================
    -- �񍐕����������Ə��}�X�^�ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    BEGIN
      SELECT lc.location_code cd
      INTO   lv_location_code
      FROM   xxcmn_locations_v lc
      WHERE  lc.location_code = iv_report_post_code
      AND    ROWNUM      = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
      lv_errbuf  := xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxcmn,
                      iv_name         => 'APP-XXCMN-10010',
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_inv_whse_section_col,  -- '�q�ɊǗ�����'
                      iv_token_name2  => gv_tkn_value,
                      iv_token_value2 => iv_report_post_code
                    );
      RAISE global_api_expt;
      -- ���̑��G���[
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- �q�ɃR�[�h�����͂���Ă���ꍇ�A�q�Ƀ}�X�^�𑶍݃`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_whse_code IS NOT NULL) THEN
      BEGIN
        SELECT icmt.whse_code
        INTO   lv_whse_code
        FROM   ic_whse_mst icmt
        WHERE  icmt.whse_code = iv_whse_code
-- [E_�{�ғ�_14953] SCSK Y.Sekine Add Start
        AND    icmt.delete_mark = '0'
-- [E_�{�ғ�_14953] SCSK Y.Sekine Add End
        AND    ROWNUM      = 1;
      EXCEPTION
      -- �f�[�^���Ȃ��ꍇ�̓G���[
        WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => 'APP-XXCMN-10010',
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_inv_whse_code,      --�q�ɃR�[�h
                        iv_token_name2  => gv_tkn_value,
                        iv_token_value2 => iv_whse_code
                      );
        RAISE global_api_expt;
        -- ���̑��G���[
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
--
    -- ==============================================================
    -- �i�ڋ敪���J�e�S�����ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    IF (iv_item_type IS NOT NULL) THEN
      BEGIN
        SELECT xcv.segment1
        INTO   lv_lookup_code
        FROM   xxcmn_categories_v xcv             -- �i�ڃJ�e�S�����VIEW
        WHERE  xcv.category_set_name = gv_item_typ
        AND    xcv.segment1 = iv_item_type
        AND    ROWNUM                = 1;
      EXCEPTION
      -- �f�[�^���Ȃ��ꍇ�̓G���[
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxcmn,
                          iv_name         => 'APP-XXCMN-10010',
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => gv_item_typ,  --�i�ڋ敪
                          iv_token_name2  => gv_tkn_value,
                          iv_token_value2 => iv_item_type
                        );
          RAISE global_api_expt;
        -- ���̑��G���[
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
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
  END proc_check_param;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_report_post_code   IN  VARCHAR2,   -- �񍐕���
    iv_whse_code          IN  VARCHAR2,   -- �q�ɃR�[�h
    iv_item_type          IN  VARCHAR2,   -- �i�ڋ敪
    ov_errbuf             OUT VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count  NUMBER  DEFAULT 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    lrec_data cursor_rec;  -- �I���f�[�^�C���^�t�F�[�X�J�[�\��
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
    -- ===============================
    -- A-1.�p�����[�^�`�F�b�N
    -- ===============================
    proc_check_param(
       iv_report_post_code =>  iv_report_post_code   -- �񍐕���
      ,iv_whse_code        =>  iv_whse_code          -- �q�ɃR�[�h
      ,iv_item_type        =>  iv_item_type          -- �i�ڋ敪
      ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W
      ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h
      ,ov_errmsg           =>  lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�f�[�^�p�[�W����
    -- ===============================
    proc_del_inventory_if(
      ov_errbuf            =>  lv_errbuf            -- �G���[�E���b�Z�[�W
      ,ov_retcode          =>  lv_retcode           -- ���^�[���E�R�[�h
      ,ov_errmsg           =>  lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- A-3.�ΏۃC���^�[�t�F�[�X�f�[�^�擾 ==
    -- =====================================
    proc_get_lock(
       iv_report_post_code =>  iv_report_post_code --�񍐕���
      ,iv_whse_code        =>  iv_whse_code        --�q�ɃR�[�h
      ,iv_item_type        =>  iv_item_type        --�i�ڋ敪
      ,lrec_data           =>  lrec_data           --���b�N�擾���̑Ώۃf�[�^
      ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W
      ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h
      ,ov_errmsg           =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- A-4.�Ó����`�F�b�N =
    -- ====================
    proc_master_data_chk(
      ov_errbuf     =>  lv_errbuf            -- �G���[�E���b�Z�[�W
      ,ov_retcode   =>  lv_retcode           -- ���^�[���E�R�[�h
      ,ov_errmsg    =>  lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �x���̏ꍇ
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- �G���[�f�[�^�_���v�ꊇ�o�͏���(A-4-5)
    -- ===============================
    proc_put_dump_msg(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �x���̏ꍇ
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- A-5.�I�����ʍX�V����
    -- ===============================
    proc_upd_table_batch(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �x���̏ꍇ
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- A-6.�I�����ʓo�^����
    -- ===============================
     proc_ins_table_batch(
       ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �x���̏ꍇ
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- A-7.�f�[�^�폜����
    -- ===============================
    proc_del_table_data(
      lrec_data     => lrec_data          --���b�N�p�����̑Ώۃf�[�^
     ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf                OUT VARCHAR2,       --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,       --   ���^�[���E�R�[�h    --# �Œ� #
    iv_report_post_code   IN  VARCHAR2,   -- �񍐕���
    iv_whse_code          IN  VARCHAR2,   -- �q�ɃR�[�h
    iv_item_type          IN  VARCHAR2)   -- �i�ڋ敪
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
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',    --2008/05/09
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
      iv_report_post_code =>  iv_report_post_code, -- �񍐕���
      iv_whse_code        =>  iv_whse_code,        -- �q�ɃR�[�h
      iv_item_type        =>  iv_item_type,        -- �i�ڋ敪
      ov_errbuf           =>  lv_errbuf,           -- �G���[�E���b�Z�[�W
      ov_retcode          =>  lv_retcode,          -- ���^�[���E�R�[�h
      ov_errmsg           =>  lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    END IF;
    -- ==================================
    -- D-15.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
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
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
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
END xxinv530001c;
/
