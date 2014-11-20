CREATE OR REPLACE PACKAGE BODY xxcmn890001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn890001c(body)
 * Description      : �����\���A�h�I���C���|�[�g
 * MD.050           : �����\���}�X�^ T_MD050_BPO_890
 * MD.070           : �����\���A�h�I���C���|�[�g T_MD070_BPO_89B
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  disp_report            ���|�[�g�p�f�[�^�o�̓v���V�[�W��
 *  delete_sr_lines_if     �����\���A�h�I���C���^�t�F�[�X�e�[�u���폜(B-10)�v���V�[�W��
 *  insert_sr_rules        �����\���A�h�I���}�X�^�}��(B-9)�v���V�[�W��
 *  check_whse_data        �q�ɏd���`�F�b�N(B-8)�v���V�[�W��  
 *  check_whse_data2       �q�ɏd���`�F�b�N2(B-11)�v���V�[�W��  
 *  modify_end_date        �K�p�I�����ҏW(B-7)�t�@���N�V����
 *  delete_sourcing_rules  �����\���A�h�I���}�X�^�폜(B-6)�v���V�[�W��
 *  set_table_data         �o�^�Ώۃ��R�[�h�ҏW(B-5)�v���V�[�W��
 *  check_data             ���ڃ`�F�b�N(B-2)(B-3)(B-4)�v���V�[�W��
 *  get_profile            MAX���t�擾�v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/10    1.0   ORACLE �ؗS��  main�V�K�쐬
 *  2008/04/17    1.1   ORACLE �ۉ�����  ���_�A�z���悪�w��Ȃ��̏ꍇ���݃`�F�b�N�����{���Ȃ�
 *  2008/05/23    1.2   ORACLE �Ŗ����\  �����ύX�v��#110�Ή�
 *  2008/06/09    1.3   ORACLE �Ŗ����\  �d����z����`�F�b�N�̕s��C��
 *  2008/10/29    1.4   ORACLE �g������  �����w�E#251�Ή�
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_sub_main_expt         EXCEPTION;     -- �T�u���C���̃G���[
  check_data_expt             EXCEPTION;     -- �`�F�b�N�����G���[
  check_lock_expt             EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn890001c'; -- �p�b�P�[�W��
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  -- �����󋵂�����킷�X�e�[�^�X
  gn_data_status_normal CONSTANT NUMBER := 0; -- ����
  gn_data_status_error CONSTANT NUMBER := 1; -- ���s
  gn_data_status_warn  CONSTANT NUMBER := 2; -- �x��
  --�v���t�@�C��
  gv_prf_max_date      CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';
  --�g�[�N��
  gv_tkn_ng_profile           CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_table                CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_item_code         CONSTANT VARCHAR2(15) := 'NG_ITEM_CODE';
  gv_tkn_ng_base_code         CONSTANT VARCHAR2(15) := 'NG_BASE_CODE';
  gv_tkn_ng_ship_to_code      CONSTANT VARCHAR2(15) := 'NG_SHIP_TO_CODE';
  gv_tkn_ng_whse_code         CONSTANT VARCHAR2(15) := 'NG_WHSE_CODE';
  gv_tkn_ng_whse_code1        CONSTANT VARCHAR2(15) := 'NG_WHSE_CODE1';
  gv_tkn_ng_whse_code2        CONSTANT VARCHAR2(15) := 'NG_WHSE_CODE2';
  gv_tkn_ng_whse1             CONSTANT VARCHAR2(15) := 'NG_WHSE_1';
  gv_tkn_ng_whse2             CONSTANT VARCHAR2(15) := 'NG_WHSE_2';
  gv_tkn_ng_vendor_site_code1 CONSTANT VARCHAR2(20) := 'NG_VENDOR_SITE_CODE1';
  gv_tkn_ng_vendor_site_code2 CONSTANT VARCHAR2(20) := 'NG_VENDOR_SITE_CODE2';
  gv_tkn_s_date_act           CONSTANT VARCHAR2(15) := 'S_DATE_ACT';
  gv_tkn_e_date_act           CONSTANT VARCHAR2(15) := 'E_DATE_ACT';
  gv_tkn_ng_table_name        CONSTANT VARCHAR2(15) := 'NG_TABLE_NAME';
-- 2008/10/29 v1.4 T.Yoshimoto Add Start ����#251
  gv_tkn_object1              CONSTANT VARCHAR2(15) := 'OBJECT1';
  gv_tkn_object2              CONSTANT VARCHAR2(15) := 'OBJECT2';
-- 2008/10/29 v1.4 T.Yoshimoto Add End ����#251
  --���b�Z�[�W�ԍ�
  gv_msg_data_normal      CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005'; -- �����f�[�^(���o��)
  gv_msg_data_error       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006'; -- �G���[�f�[�^(���o��)
  gv_msg_data_warn        CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007'; -- �X�L�b�v�f�[�^(���o��)
  gv_msg_no_profile       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
  gv_msg_ng_lock          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019'; -- ���b�N�G���[
  gv_msg_ng_item          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10098'; -- �i�ڑ���NG
  gv_msg_ng_d_item        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10124'; -- �i�ړK�p��NG
  gv_msg_ng_base          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10125'; -- ���_����NG
  gv_msg_ng_d_base        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10126'; -- ���_�K�p��NG
  gv_msg_ng_ship_to       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10085'; -- �z���摶��NG
  gv_msg_ng_d_ship_to     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10127'; -- �z����K�p��NG
  gv_msg_ng_whse          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10079'; -- �o�ɑq�ɑ���NG
  gv_msg_ng_input_whse1   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10131'; -- �ړ����q�ɖ�����NG
  gv_msg_ng_whse1         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10057'; -- �ړ����q��1����NG
  gv_msg_ng_whse2         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10058'; -- �ړ����q��2����NG
  gv_msg_ng_vendor_site1  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10077'; -- �d���T�C�g1����NG
  gv_msg_ng_vendor_site2  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10078'; -- �d���T�C�g2����NG
  gv_msg_ng_plan_item_flg CONSTANT VARCHAR2(15) := 'APP-XXCMN-10129'; -- �v�揤�i�t���O����NG
  gv_msg_ng_date_act      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10130'; -- �K�p���tNG
  gv_msg_rep_key          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10055'; -- ��L�[�d��NG
  gv_msg_rep_whse         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10128'; -- �q�ɏd��NG
-- 2008/10/29 v1.4 T.Yoshimoto Add Start ����#251
  gv_msg_rep_whse2        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10158'; -- �q�ɏd��2NG
-- 2008/10/29 v1.4 T.Yoshimoto Add End ����#251
  gv_msg_ng_base_ship_to  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10132'; -- ���_�^�z����NG
--
  -- �Ώ�DB��
  gv_xxcmn_sr_lines_if CONSTANT VARCHAR2(100) := '�����\���A�h�I���C���^�t�F�[�X';
-- 2008/10/29 v1.4 T.Yoshimoto Add Start ����#251
  -- �ΏۃJ������
  gv_colmun1           CONSTANT VARCHAR2(100) := '�o�ɑq��';
  gv_colmun2           CONSTANT VARCHAR2(100) := '�ړ����q��1';
  gv_colmun3           CONSTANT VARCHAR2(100) := '�ړ����q��2';
-- 2008/10/29 v1.4 T.Yoshimoto Add End ����#251
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �����\���A�h�I���}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE sr_line_rec IS RECORD(
    -- �����\���A�h�I���C���^�t�F�[�X
    sourcing_rules_id    xxcmn_sourcing_rules.sourcing_rules_id%TYPE,    -- �����\���A�h�I��ID
    item_code            xxcmn_sourcing_rules.item_code%TYPE,            -- �i�ڃR�[�h
    base_code            xxcmn_sourcing_rules.base_code%TYPE,            -- ���_�R�[�h
    ship_to_code         xxcmn_sourcing_rules.ship_to_code%TYPE,         -- �z����R�[�h
    start_date_active    xxcmn_sourcing_rules.start_date_active%TYPE,    -- �K�p�J�n��
    end_date_active      xxcmn_sourcing_rules.end_date_active%TYPE,      -- �K�p�I����
    delivery_whse_code   xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- �o�ɑq�ɃR�[�h
    move_from_whse_code1 xxcmn_sourcing_rules.move_from_whse_code1%TYPE, -- �ړ����q�ɃR�[�h1
    move_from_whse_code2 xxcmn_sourcing_rules.move_from_whse_code2%TYPE, -- �ړ����q�ɃR�[�h2
    vendor_site_code1    xxcmn_sourcing_rules.vendor_site_code1%TYPE,    -- �d����T�C�g�R�[�h1
    vendor_site_code2    xxcmn_sourcing_rules.vendor_site_code2%TYPE,    -- �d����T�C�g�R�[�h2
    plan_item_flag       xxcmn_sourcing_rules.plan_item_flag%TYPE,       -- �v�揤�i�t���O
--
    row_level_status     NUMBER,                                         -- 0.����,1.���s,2.�x��
    message              VARCHAR2(1000)                                  -- �\���p���b�Z�[�W
--
  );
--
  TYPE sr_line_tbl IS TABLE OF sr_line_rec INDEX BY PLS_INTEGER;
--
  -- �����\���A�h�I���C���^�t�F�[�X�����i�[����e�[�u���^�̒�`
  TYPE request_id_tbl IS TABLE OF xxcmn_sourcing_rules.request_id%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_max_date            VARCHAR2(10); -- �ő���t
  gn_data_status         NUMBER := 0;  -- �f�[�^�`�F�b�N�X�e�[�^�X
  gn_request_id_cnt      NUMBER := 0;  -- ���N�G�X�gID��
  gt_sr_line_tbl         sr_line_tbl;
  gt_request_id_tbl      request_id_tbl;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���|�[�g�p�f�[�^�o�̓v���V�[�W��
   ***********************************************************************************/
  PROCEDURE disp_report(
    disp_kbn       IN         NUMBER,       -- �\���Ώۋ敪(0:����,1:�ُ�,2:�x��)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_report_rec sr_line_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ###############################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ����
    IF (disp_kbn = gn_data_status_normal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_normal);
--
    -- �G���[
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_error);
--
    -- �x��
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_warn);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �ݒ肳��Ă��郌�|�[�g�̏o��
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 1..gn_target_cnt LOOP
      lr_report_rec := gt_sr_line_tbl(ln_disp_cnt);
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
--
        --���̓f�[�^�̍č\��
        lv_dspbuf := lr_report_rec.item_code||gv_msg_pnt
                    ||lr_report_rec.base_code||gv_msg_pnt
                    ||lr_report_rec.ship_to_code||gv_msg_pnt
                    ||TO_CHAR(lr_report_rec.start_date_active,'YYYY/MM/DD')||gv_msg_pnt
                    ||TO_CHAR(lr_report_rec.end_date_active,'YYYY/MM/DD')||gv_msg_pnt
                    ||lr_report_rec.delivery_whse_code||gv_msg_pnt
                    ||lr_report_rec.move_from_whse_code1||gv_msg_pnt
                    ||lr_report_rec.move_from_whse_code2||gv_msg_pnt
                    ||lr_report_rec.vendor_site_code1||gv_msg_pnt
                    ||lr_report_rec.vendor_site_code2||gv_msg_pnt
                    ||TO_CHAR(lr_report_rec.plan_item_flag);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
        -- ����ȊO
        IF (disp_kbn > gn_data_status_normal) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
--
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
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
--#####################################  �Œ蕔 END   ############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : delete_sr_lines_if
   * Description      : �����\���A�h�I���C���^�t�F�[�X�e�[�u���폜(B-10)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE delete_sr_lines_if(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_sr_lines_if'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    <<request_id_loop>>
    FORALL ln_count IN 1..gn_request_id_cnt
      DELETE xxcmn_sr_lines_if xsli             -- �����\���A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xsli.request_id = gt_request_id_tbl(ln_count)  -- �v��ID
      ;
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
  END delete_sr_lines_if;
--
  /**********************************************************************************
   * Procedure Name   : insert_sr_rules
   * Description      : �����\���A�h�I���}�X�^�}��(B-9)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE insert_sr_rules(
    ir_sr_line                IN sr_line_rec,       -- 1.���R�[�h
    in_insert_user_id         IN NUMBER,            -- 2.���[�U�[ID  
    id_insert_date            IN DATE,              -- 3.�X�V��
    in_insert_login_id        IN NUMBER,            -- 4.���O�C��ID
    in_insert_request_id      IN NUMBER,            -- 5.�v��ID
    in_insert_program_appl_id IN NUMBER,            -- 6.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
    in_insert_program_id      IN NUMBER,            -- 7.�R���J�����g�E�v���O����ID
    ov_errbuf                 OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sr_rules'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- �o�^����
    INSERT INTO xxcmn_sourcing_rules -- �����\���A�h�I���}�X�^
    (sourcing_rules_id,
     item_code,
     base_code,
     ship_to_code,
     start_date_active,
     end_date_active,
     delivery_whse_code,
     move_from_whse_code1,
     move_from_whse_code2,
     vendor_site_code1,
     vendor_site_code2,
     plan_item_flag,
     created_by,
     creation_date,
     last_updated_by,
     last_update_date,
     last_update_login,
     request_id,
     program_application_id,
     program_id,
     program_update_date
    )
    VALUES (
      ir_sr_line.sourcing_rules_id,
      ir_sr_line.item_code,
      ir_sr_line.base_code,
      ir_sr_line.ship_to_code,
      ir_sr_line.start_date_active,
      ir_sr_line.end_date_active,
      ir_sr_line.delivery_whse_code,
      ir_sr_line.move_from_whse_code1,
      ir_sr_line.move_from_whse_code2,
      ir_sr_line.vendor_site_code1,
      ir_sr_line.vendor_site_code2,
      ir_sr_line.plan_item_flag,
      in_insert_user_id,
      id_insert_date,
      in_insert_user_id,
      id_insert_date,
      in_insert_login_id,
      in_insert_request_id,
      in_insert_program_appl_id,
      in_insert_program_id,
      id_insert_date
    );
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
  END insert_sr_rules;
--
  /**********************************************************************************
   * Procedure Name   : check_whse_data
   * Description      : �q�ɏd���`�F�b�N(B-8)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE check_whse_data(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_whse_data'; -- �v���O������
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
    ln_count NUMBER := 0;
    ld_max_date DATE ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    ld_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
--
    -- �����\���A�h�I���}�X�^�q�ɏd���`�F�b�N
    SELECT COUNT(xsr.sourcing_rules_id)
    INTO ln_count
    FROM xxcmn_sourcing_rules xsr -- �����\���A�h�I���}�X�^
    WHERE xsr.item_code = ir_sr_line.item_code                       -- �i�ڃR�[�h
      AND xsr.delivery_whse_code = ir_sr_line.delivery_whse_code     -- �o�ɑq�ɃR�[�h
      AND xsr.move_from_whse_code1 = ir_sr_line.move_from_whse_code1 -- �ړ����q�ɃR�[�h1
      AND xsr.move_from_whse_code2 = ir_sr_line.move_from_whse_code2 -- �ړ����q�ɃR�[�h2
      AND xsr.vendor_site_code1 = ir_sr_line.vendor_site_code1       -- �d����T�C�g�R�[�h1
      AND((
      xsr.start_date_active <= ir_sr_line.start_date_active
      AND NVL(xsr.end_date_active, ld_max_date)  >= NVL(ir_sr_line.end_date_active, ld_max_date)
      )OR(
      xsr.start_date_active >= ir_sr_line.start_date_active
      AND xsr.start_date_active  <= NVL(ir_sr_line.end_date_active, ld_max_date)
      )OR(
      NVL(xsr.end_date_active, ld_max_date) >= ir_sr_line.start_date_active
      AND NVL(xsr.end_date_active, ld_max_date)  <= NVL(ir_sr_line.end_date_active, ld_max_date)
      ))
      AND ROWNUM = 1;
--
    IF (ln_count = 1 ) THEN
      -- �q�ɏd���`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_whse,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code,ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code,ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'),
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code,
                              gv_tkn_ng_whse1, ir_sr_line.move_from_whse_code1,
                              gv_tkn_ng_whse2, ir_sr_line.move_from_whse_code2,
                              gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1);
      RAISE check_data_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�`�F�b�N�����G���[ ***
    WHEN check_data_expt THEN
      ir_sr_line.row_level_status := gn_data_status_warn;
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;
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
  END check_whse_data;
  --
-- 2008/10/29 v1.4 T.Yoshimoto Add Start ����#251
  /**********************************************************************************
   * Procedure Name   : check_whse_data2
   * Description      : �q�ɏd���`�F�b�N2(B-11)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE check_whse_data2(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_whse_data2'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- �ړ����q��1���ݒ肳��Ă���ꍇ���A�o�ɑq�ɂƓ����ꍇ
    IF ( ( ir_sr_line.delivery_whse_code IS NOT NULL )
      AND ( ir_sr_line.move_from_whse_code1 IS NOT NULL )
      AND ( ir_sr_line.delivery_whse_code = ir_sr_line.move_from_whse_code1 ) ) THEN
--
      -- �q�ɏd���`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_whse2,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code,ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code,ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'),
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code,
                              gv_tkn_ng_whse1, ir_sr_line.move_from_whse_code1,
                              gv_tkn_ng_whse2, ir_sr_line.move_from_whse_code2,
                              gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1,
                              gv_tkn_object1, gv_colmun1,
                              gv_tkn_object2, gv_colmun2 );
--
      RAISE check_data_expt;
--
    END IF;
--
--
    -- �ړ����q��2���ݒ肳��Ă���ꍇ���A�ړ����q��1�Ɠ����ꍇ
    IF ( ( ir_sr_line.move_from_whse_code1 IS NOT NULL )
      AND ( ir_sr_line.move_from_whse_code2 IS NOT NULL )
      AND ( ir_sr_line.move_from_whse_code1 = ir_sr_line.move_from_whse_code2 ) ) THEN
--
      -- �q�ɏd���`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_whse2,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code,ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code,ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'),
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code,
                              gv_tkn_ng_whse1, ir_sr_line.move_from_whse_code1,
                              gv_tkn_ng_whse2, ir_sr_line.move_from_whse_code2,
                              gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1,
                              gv_tkn_object1, gv_colmun2,
                              gv_tkn_object2, gv_colmun3 );
--
      RAISE check_data_expt;
--
    END IF;
--
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�`�F�b�N�����G���[ ***
    WHEN check_data_expt THEN
      ir_sr_line.row_level_status := gn_data_status_warn;
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;
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
  END check_whse_data2;
-- 2008/10/29 v1.4 T.Yoshimoto Add End ����#251
--
  /**********************************************************************************
   * Function Name    : modify_end_date
   * Description      : �K�p�I�����ҏW(B-7)�t�@���N�V����
   ***********************************************************************************/
  FUNCTION modify_end_date(
    ir_sr_line_rec            IN sr_line_rec,       -- 1.���R�[�h
    in_insert_user_id         IN NUMBER,            -- 2.���[�U�[ID  
    id_insert_date            IN DATE,              -- 3.�X�V��
    in_insert_login_id        IN NUMBER,            -- 4.���O�C��ID
    in_insert_request_id      IN NUMBER,            -- 5.�v��ID
    in_insert_program_appl_id IN NUMBER,            -- 6.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
    in_insert_program_id      IN NUMBER             -- 7.�R���J�����g�E�v���O����ID
  )
    RETURN DATE
    IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'modify_end_date'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_sr_id      NUMBER;
    ld_end_date   DATE ;
    ld_start_date DATE ;
--
--
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
--
--
    BEGIN
      -- �O���̕����\���A�h�I��ID���擾
      SELECT xsr.sourcing_rules_id
      INTO ln_sr_id
      FROM xxcmn_sourcing_rules xsr,
        (SELECT xsr.item_code AS item_code,
                xsr.base_code  AS base_code,
                xsr.ship_to_code AS ship_to_code,
                MAX(xsr.start_date_active) AS start_date
        FROM xxcmn_sourcing_rules xsr -- �����\���A�h�I���}�X�^
        WHERE xsr.item_code = ir_sr_line_rec.item_code
          AND xsr.base_code = ir_sr_line_rec.base_code
          AND xsr.ship_to_code = ir_sr_line_rec.ship_to_code
          AND xsr.start_date_active < ir_sr_line_rec.start_date_active
        GROUP BY xsr.item_code,xsr.base_code,xsr.ship_to_code) max_data
      WHERE max_data.item_code   = xsr.item_code
        AND max_data.base_code   = xsr.base_code
        AND max_data.ship_to_code = xsr.ship_to_code
        AND max_data.start_date   = xsr.start_date_active 
        AND ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      NULL;
    END ;
--
    -- ����̓K�p�J�n�����擾
    SELECT MIN(xsr.start_date_active) AS start_date
    INTO ld_start_date
    FROM xxcmn_sourcing_rules xsr -- �����\���A�h�I���}�X�^
    WHERE xsr.item_code = ir_sr_line_rec.item_code
      AND xsr.base_code = ir_sr_line_rec.base_code
      AND xsr.ship_to_code = ir_sr_line_rec.ship_to_code
      AND xsr.start_date_active > ir_sr_line_rec.start_date_active;
--
    -- �K�p�I�����̕ҏW
    -- �o�^�Ώۃf�[�^�ɓK�p�J�n�������݂��Ă���ꍇ
    IF(ir_sr_line_rec.start_date_active IS NOT NULL)THEN
    -- �O��K�p�I�������A�o�^�Ώۃf�[�^�̓K�p�J�n�������ɐݒ肷��
      ld_end_date := ir_sr_line_rec.start_date_active -1;
    END IF;
    -- �o�^�Ώۃf�[�^�̓K�p�I�������擾����
    IF(ld_start_date IS NULL) THEN
      -- �ő�K�p����ݒ肷��
      ld_start_date:= FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
    ELSE
      -- �擾��������̓K�p�I���������ɐݒ肷��
      ld_start_date := ld_start_date-1;
    END IF;
--
    -- �O��K�p�I�����̍X�V�i�O�����擾�ł��Ȃ������ꍇ�s�v�j
    IF(ln_sr_id IS NOT NULL) THEN
--
      UPDATE xxcmn_sourcing_rules xsr -- �����\���A�h�I���}�X�^
      SET xsr.end_date_active         = ld_end_date
          ,xsr.last_updated_by        = in_insert_user_id
          ,xsr.last_update_date       = id_insert_date
          ,xsr.last_update_login      = in_insert_login_id
          ,xsr.request_id             = in_insert_request_id
          ,xsr.program_application_id = in_insert_program_appl_id
          ,xsr.program_id             = in_insert_program_id
          ,xsr.program_update_date    = id_insert_date          
      WHERE xsr.sourcing_rules_id = ln_sr_id;
--
    END IF;
--
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
--
    RETURN ld_start_date;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   ############################################
--
  END modify_end_date;
--
  /**********************************************************************************
   * Procedure Name   : delete_sourcing_rules
   * Description      : �����\���A�h�I���}�X�^�폜(B-6)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE delete_sourcing_rules(
    in_sr_rules_id    IN         NUMBER,   -- �����\���A�h�I��ID
    ov_errbuf         OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_sourcing_rules'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
      DELETE xxcmn_sourcing_rules xsr                -- �����\���A�h�I���}�X�^
      WHERE  xsr.sourcing_rules_id = in_sr_rules_id  -- �����\���A�h�I��ID
      ;
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
  END delete_sourcing_rules;
--
  /**********************************************************************************
   * Procedure Name   : set_table_data
   * Description      : �o�^�Ώۃ��R�[�h�ҏW(B-5)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE set_table_data(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_table_data'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����\���A�h�I��ID���V�[�P���X���擾
    SELECT xxcmn_sourcing_rules_s1.NEXTVAL 
    INTO ir_sr_line.sourcing_rules_id
    FROM dual;
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
  END set_table_data;
--
  /**********************************************************************************
   * Procedure Name   : check_data
   * Description      : ���ڃ`�F�b�N(B-2)(B-3)(B-4)�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE check_data(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- �v���O������
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
    cv_obsolete_handling CONSTANT VARCHAR2(1) := '0';         -- �p�~�敪�i�戵���j
    cv_customer_base     CONSTANT VARCHAR2(1) := '1';         -- �ڋq�敪�i���_�j
    cv_customer_supply   CONSTANT VARCHAR2(2) := '11';        -- �ڋq�敪�i�x����j
    cv_z_item_code       CONSTANT VARCHAR2(7) := 'ZZZZZZZ';   -- �i�ڃR�[�h�iZZZZZZZ�j
    cv_no_base_code      CONSTANT VARCHAR2(4) := '0000';      -- ���_�R�[�h�i�w��Ȃ��j
    cv_no_ship_to_code   CONSTANT VARCHAR2(9) := '000000000'; -- �z����R�[�h�i�w��Ȃ��j
--
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER := 0;
    ld_max_date DATE ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- �i�ڑ��݃`�F�b�N
    SELECT COUNT(ximv.item_id)
    INTO ln_count
    FROM xxcmn_item_mst2_v ximv    -- OPM�i�ڏ��VIEW
    WHERE ximv.item_no = ir_sr_line.item_code
      AND ximv.obsolete_date IS NULL
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
    -- �i�ڑ��݃`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_item,
                              gv_tkn_ng_item_code, ir_sr_line.item_code);
      RAISE check_data_expt;
    END IF;
--
    -- �i�ړK�p���t�`�F�b�N
    SELECT COUNT(ximv.item_id)
    INTO ln_count
    FROM xxcmn_item_mst_v ximv    -- OPM�i�ڏ��VIEW
    WHERE ximv.item_no = ir_sr_line.item_code
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
    -- �i�ړK�p���t�`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_d_item,
                              gv_tkn_ng_item_code, ir_sr_line.item_code);
      RAISE check_data_expt;
    END IF;
--
    IF (ir_sr_line.base_code <> cv_no_base_code) THEN
      --���_���݃`�F�b�N
      SELECT COUNT(xcav.party_id)
      INTO ln_count
      FROM xxcmn_cust_accounts2_v xcav        -- �ڋq���VIEW
      WHERE xcav.party_number = ir_sr_line.base_code
        AND xcav.customer_class_code = cv_customer_base
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- ���_���݃`�F�b�NNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_base,
                                gv_tkn_ng_base_code, ir_sr_line.base_code);
        RAISE check_data_expt;
      END IF;
  --
      -- ���_�K�p���t�`�F�b�N
      SELECT COUNT(xcav.party_id)
      INTO ln_count
      FROM xxcmn_cust_accounts_v xcav        -- �ڋq���VIEW
      WHERE xcav.party_number = ir_sr_line.base_code
        AND xcav.customer_class_code = cv_customer_base
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- ���_�K�p���t�`�F�b�NNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_d_base,
                                gv_tkn_ng_base_code, ir_sr_line.base_code);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    IF (ir_sr_line.ship_to_code <> cv_no_ship_to_code) THEN
      -- �z���摶�݃`�F�b�N
      SELECT COUNT(xpsv.party_id)
      INTO ln_count
      FROM xxcmn_party_sites2_v xpsv     -- �p�[�e�B�T�C�g�}�X�^VIEW
          ,xxcmn_cust_accounts2_v xcav   -- �ڋq�}�X�^VIEW
      WHERE xpsv.ship_to_no = ir_sr_line.ship_to_code
        AND xpsv.party_id = xcav.party_id
        AND xcav.customer_class_code <>cv_customer_supply
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- �z���摶�݃`�F�b�N
        SELECT COUNT(xvv.vendor_id)
        INTO ln_count
        FROM xxcmn_vendors2_v xvv    -- �d����VIEW
        WHERE xvv.segment1 = ir_sr_line.ship_to_code
          AND xvv.vendor_div = cv_customer_supply
          AND ROWNUM = 1;
  --
        IF (ln_count = 0) THEN
          -- �z���摶�݃`�F�b�NNG
          ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_ship_to,
                                  gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code);
          RAISE check_data_expt;
        END IF;
      END IF;
--
      -- �z����K�p���`�F�b�N
      SELECT COUNT(xpsv.party_id)
      INTO ln_count
      FROM xxcmn_party_sites_v xpsv     -- �p�[�e�B�T�C�g�}�X�^VIEW
          ,xxcmn_cust_accounts_v xcav   -- �ڋq�}�X�^VIEW
      WHERE xpsv.ship_to_no = ir_sr_line.ship_to_code
        AND xpsv.party_id = xcav.party_id
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- �z����K�p���`�F�b�N
        SELECT COUNT(xvv.vendor_id)
        INTO ln_count
        FROM xxcmn_vendors_v xvv    -- �d����VIEW
        WHERE xvv.segment1 = ir_sr_line.ship_to_code
          AND xvv.vendor_div = cv_customer_supply
          AND ROWNUM = 1;
  --
        IF (ln_count = 0) THEN
        -- �z����K�p���`�F�b�NNG
          ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_d_ship_to,
                                  gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code);
          RAISE check_data_expt;
        END IF;
      END IF;
    END IF;
--
    --�o�ɑq�ɑ��݃`�F�b�N
    SELECT COUNT(xil.mtl_organization_id)
    INTO ln_count
    FROM xxcmn_item_locations_v xil -- �q�Ƀ}�X�^VIEW
    WHERE xil.segment1 = ir_sr_line.delivery_whse_code
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
    -- �o�ɑq�ɑ��݃`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_whse,
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code);
      RAISE check_data_expt;
    END IF;
--
    -- �ړ����q��1���݃`�F�b�N
    IF (ir_sr_line.move_from_whse_code1 IS NOT NULL)THEN
      SELECT COUNT(xil.mtl_organization_id)
      INTO ln_count
      FROM xxcmn_item_locations_v xil -- �q�Ƀ}�X�^VIEW
      WHERE xil.segment1 = ir_sr_line.move_from_whse_code1
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- �ړ����q��1���݃`�F�b�NNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn,gv_msg_ng_whse1,
                                gv_tkn_ng_whse_code1, ir_sr_line.move_from_whse_code1);
        RAISE check_data_expt;
      END IF;
      -- �ړ����q�ɖ����̓`�F�b�N
    ELSIF (ir_sr_line.move_from_whse_code2 IS NOT NULL) THEN
      -- �ړ����q�ɖ�����NG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_input_whse1,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'));
        RAISE check_data_expt;
    END IF;
--
    -- �ړ����q��2���݃`�F�b�N
    IF (ir_sr_line.move_from_whse_code2 IS NOT NULL)THEN
      SELECT COUNT(xil.mtl_organization_id)
      INTO ln_count
      FROM xxcmn_item_locations_v xil -- �q�Ƀ}�X�^VIEW
      WHERE xil.segment1 = ir_sr_line.move_from_whse_code2
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- �ړ����q��2���݃`�F�b�NNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_whse2,
                                gv_tkn_ng_whse_code2, ir_sr_line.move_from_whse_code2);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- �d���T�C�g1���݃`�F�b�N
    IF (ir_sr_line.vendor_site_code1 IS NOT NULL)THEN
      SELECT COUNT(xvv.vendor_id)
      INTO ln_count
      FROM xxcmn_vendors_v xvv    -- �d����VIEW
      WHERE xvv.segment1 = ir_sr_line.vendor_site_code1
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- �d���T�C�g1���݃`�F�b�NNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_vendor_site1,
                                gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- �d���T�C�g2���݃`�F�b�N
    IF (ir_sr_line.vendor_site_code2 IS NOT NULL)THEN
      SELECT COUNT(xvv.vendor_id)
      INTO ln_count
      FROM xxcmn_vendors_v xvv    -- �d����VIEW
      WHERE xvv.segment1 = ir_sr_line.vendor_site_code2
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- �d���T�C�g2���݃`�F�b�NNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_vendor_site2,
                                gv_tkn_ng_vendor_site_code2, ir_sr_line.vendor_site_code2);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- �v�揤�i�t���O���݃`�F�b�N
    IF (ir_sr_line.plan_item_flag = 1)
        AND ((ir_sr_line.item_code = cv_z_item_code) 
        OR ( (ir_sr_line.base_code = cv_no_base_code) 
          OR (ir_sr_line.ship_to_code <> cv_no_ship_to_code))) THEN
          -- �v�揤�i�t���O���݃`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_plan_item_flg,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active,'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
--
    ld_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
    -- �K�p���t�`�F�b�N 
    IF (ir_sr_line.start_date_active > NVL(ir_sr_line.end_date_active, ld_max_date)) THEN
      -- �K�p���t�`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_date_act,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act, 
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
--
    -- �d���`�F�b�N(B-3)
    -- ��L�[�d���`�F�b�N
    SELECT COUNT(xsli.item_code)
    INTO ln_count
    FROM xxcmn_sr_lines_if xsli -- �����\���A�h�I���C���^�t�F�[�X
    WHERE xsli.item_code = ir_sr_line.item_code                  --�i�ڃR�[�h
      AND xsli.base_code = ir_sr_line.base_code                  --���_�R�[�h
      AND xsli.ship_to_code = ir_sr_line.ship_to_code            --�z����R�[�h
      AND xsli.start_date_active = ir_sr_line.start_date_active; --�K�p�J�n��
-- 
    IF (ln_count > 1 ) THEN
      -- ��L�[�d���`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_key,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
--
    END IF ;
--
    -- ���_�^�z����`�F�b�N(B-4)
    IF ((ir_sr_line.base_code = cv_no_base_code)
        AND (ir_sr_line.ship_to_code = cv_no_ship_to_code))
      OR
        ((ir_sr_line.base_code <> cv_no_base_code)
        AND (ir_sr_line.ship_to_code <> cv_no_ship_to_code)) THEN
          -- ���_�^�z����`�F�b�NNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_base_ship_to,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
    ir_sr_line.row_level_status := gn_data_status_normal;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�`�F�b�N�����G���[ ***
    WHEN check_data_expt THEN
      ir_sr_line.row_level_status := gn_data_status_warn;
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;
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
  END check_data;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : MAX���t�擾�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_max_pro_date CONSTANT VARCHAR2(20) := 'MAX���t';
--
    -- *** ���[�J���ϐ� ***
    lv_max_date  VARCHAR2(10);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ő���t�擾
    lv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_no_profile,
                                            gv_tkn_ng_profile, cv_max_pro_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gv_max_date := lv_max_date; -- �ő���t�ɐݒ�
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
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
--#####################################  �Œ蕔 END   ############################################
--
  END get_profile;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_end_date  DATE ;
    lr_sr_line_rec sr_line_rec;
    ln_sourcing_rule_id NUMBER;
    -- �}���p�f�[�^�i�[�p
    ln_insert_user_id         NUMBER(15,0);
    ld_insert_date            DATE;
    ln_insert_login_id        NUMBER(15,0);
    ln_insert_request_id      NUMBER(15,0);
    ln_insert_prog_appl_id    NUMBER(15,0);
    ln_insert_program_id      NUMBER(15,0);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �v��ID�J�[�\�� xsli_request
    CURSOR xsli_request_id_cur IS
    SELECT fcr.request_id 
    FROM fnd_concurrent_requests fcr
    WHERE EXISTS (
          SELECT 1
          FROM xxcmn_sr_lines_if xsl
          WHERE xsl.request_id = fcr.request_id
          AND ROWNUM = 1
        );
--
    -- �O���{����̃��b�N�J�[�\�� xsr_lock_start_end_cur
    CURSOR xsr_lock_start_end_cur IS
      SELECT xsr.item_code
            ,xsr.base_code
            ,xsr.ship_to_code
      FROM xxcmn_sr_lines_if xsli  -- �����\���A�h�I���C���^�t�F�[�X
          ,xxcmn_sourcing_rules xsr 
      WHERE  xsli.item_code         = xsr.item_code
      AND    xsli.base_code         = xsr.base_code
      AND    xsli.ship_to_code      = xsr.ship_to_code
      FOR UPDATE OF xsr.item_code
                    ,xsr.base_code
                    ,xsr.ship_to_code
                    ,xsr.start_date_active 
      NOWAIT;
--
    -- �����\���A�h�I���C���^�t�F�[�X�擾�J�[�\�� get_sr_line_cur
    CURSOR get_sr_line_cur IS
    SELECT xsli.item_code            -- �i�ڃR�[�h
          ,xsli.base_code            -- ���_�R�[�h
          ,xsli.ship_to_code         -- �z����R�[�h
          ,xsli.start_date_active    -- �K�p�J�n��
          ,xsli.end_date_active      -- �K�p�I����
          ,xsli.delivery_whse_code   -- �o�ɑq�ɃR�[�h
          ,xsli.move_from_whse_code1 -- �ړ����q�ɃR�[�h1
          ,xsli.move_from_whse_code2 -- �ړ����q�ɃR�[�h2
          ,xsli.vendor_site_code1    -- �d����T�C�g�R�[�h1
          ,xsli.vendor_site_code2    -- �d����T�C�g�R�[�h2
          ,xsli.plan_item_flag       -- �v�揤�i�t���O
          ,xsr.sourcing_rules_id     -- �����\���A�h�I��ID
    FROM xxcmn_sr_lines_if xsli      -- �����\���A�h�I���C���^�t�F�[�X�e�[�u��
        ,xxcmn_sourcing_rules xsr    -- �����\���A�h�I���}�X�^
    WHERE xsli.item_code = xsr.item_code(+)
      AND xsli.base_code = xsr.base_code(+)
      AND xsli.ship_to_code = xsr.ship_to_code(+)
      AND xsli.start_date_active = xsr.start_date_active(+)
    ORDER BY xsli.item_code
            ,xsli.base_code
            ,xsli.ship_to_code
            ,xsli.start_date_active
    FOR UPDATE OF xsli.item_code
                  ,xsli.base_code
                  ,xsli.ship_to_code
                  ,xsli.start_date_active
    NOWAIT;
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
    -- �C���T�[�g�f�[�^�̏�����
    ln_insert_user_id      := FND_GLOBAL.USER_ID;
    ld_insert_date         := SYSDATE;
    ln_insert_login_id     := FND_GLOBAL.LOGIN_ID;
    ln_insert_request_id   := FND_GLOBAL.CONC_REQUEST_ID;
    ln_insert_prog_appl_id := FND_GLOBAL.PROG_APPL_ID;
    ln_insert_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  get_profile �v���t�@�C�����MAX���t���擾���܂��B
    -- ===============================
--
    get_profile(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ��O����
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    --  �����Ώۗv��ID�擾
    -- ===============================
--
    <<get_request_id_loop>>
    FOR get_req_data IN xsli_request_id_cur  LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1;
      gt_request_id_tbl(gn_request_id_cnt) := get_req_data.request_id;
    END LOOP get_request_id_loop;
--
    -- ===============================
    --  �O���{����̃��b�N�擾
    -- ===============================
    BEGIN
--
      <<get_start_end_loop>>
      FOR ln_count IN  xsr_lock_start_end_cur  LOOP
        EXIT;
      END LOOP get_start_end_loop;
    -- ��O����
    EXCEPTION
      WHEN check_lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_lock,
                                              gv_tkn_table, gv_xxcmn_sr_lines_if);
        lv_errbuf := lv_errmsg;
        RAISE check_sub_main_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    --
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    -- ===============================
    --  �����\���A�h�I���C���^�t�F�[�X�擾(B-1)
    -- ===============================
    BEGIN
--
      -- �Z�[�u�|�C���g���擾
      SAVEPOINT spoint;
--
      <<get_srl_loop>>
      FOR get_srl_data IN get_sr_line_cur
      LOOP
        -- ���������̃J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
        -- ���R�[�h�ϐ��Ɋi�[
        lr_sr_line_rec.item_code := get_srl_data.item_code;
        lr_sr_line_rec.base_code := get_srl_data.base_code;
        lr_sr_line_rec.ship_to_code := get_srl_data.ship_to_code;
        lr_sr_line_rec.start_date_active := get_srl_data.start_date_active;
        lr_sr_line_rec.end_date_active := get_srl_data.end_date_active;
        lr_sr_line_rec.delivery_whse_code := get_srl_data.delivery_whse_code;
        lr_sr_line_rec.move_from_whse_code1 := get_srl_data.move_from_whse_code1;
        lr_sr_line_rec.move_from_whse_code2 := get_srl_data.move_from_whse_code2;
        lr_sr_line_rec.vendor_site_code1 := get_srl_data.vendor_site_code1;
        lr_sr_line_rec.vendor_site_code2 := get_srl_data.vendor_site_code2;
        lr_sr_line_rec.plan_item_flag := get_srl_data.plan_item_flag;
        -- �폜�p�����\���A�h�I��ID�i�[
        ln_sourcing_rule_id := get_srl_data.sourcing_rules_id;
--
        -- ===============================
        --  ���ڃ`�F�b�N(B-2)(B-3)(B-4)
        -- ===============================    
        check_data(
          lr_sr_line_rec, -- 1.���R�[�h
          lv_errbuf,      --   �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,     --   ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- ��O����
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- ===============================
        --  �o�^�Ώۃ��R�[�h�ҏW(B-5)
        -- ===============================    
        IF (gn_data_status = gn_data_status_normal) THEN
          set_table_data(
            lr_sr_line_rec,                -- 1.���R�[�h
            lv_errbuf,                     --   �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    --   ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        END IF;
--
          -- ��O����
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        IF (gn_data_status = gn_data_status_normal)
          AND (gn_target_cnt > 0)  THEN
          -- ===============================
          --  �����\���A�h�I���}�X�^�폜(B-6)
          -- ===============================    
          IF (ln_sourcing_rule_id IS NOT NULL) THEN
            delete_sourcing_rules(
              ln_sourcing_rule_id,            -- �����\���A�h�I��ID
              lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            -- ��O����
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
--
          -- ===============================
          --  �K�p�I�����ҏW(B-7)
          -- ===============================    
          lr_sr_line_rec.end_date_active  := modify_end_date(
            lr_sr_line_rec,         -- 1.���R�[�h
            ln_insert_user_id,      -- 2.���[�U�[ID  
            ld_insert_date,         -- 3.�X�V��
            ln_insert_login_id,     -- 4.���O�C��ID
            ln_insert_request_id,   -- 5.�v��ID
            ln_insert_prog_appl_id, -- 6.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
            ln_insert_program_id);   -- 7.�R���J�����g�E�v���O����ID
--
          -- ��O����
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          -- ===============================
          --  �q�ɏd���`�F�b�N(B-8)
          -- ===============================    
          check_whse_data(
            lr_sr_line_rec, -- 1.���R�[�h
            lv_errbuf,      --   �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,     --   ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  --
            -- ��O����
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
-- 2008/10/29 v1.4 T.Yoshimoto Add Start ����#251
          -- ===============================
          --  �q�ɏd���`�F�b�N2(B-11)
          -- ===============================    
          check_whse_data2(
            lr_sr_line_rec, -- 1.���R�[�h
            lv_errbuf,      --   �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,     --   ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  --
            -- ��O����
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
-- 2008/10/29 v1.4 T.Yoshimoto Add End ����#251
--
          -- ===============================
          --  �����\���A�h�I���}�X�^�}��(B-9)
          -- ===============================    
          -- �o�^����
          insert_sr_rules(
            lr_sr_line_rec,         -- 1.���R�[�h
            ln_insert_user_id,      -- 2.���[�U�[ID  
            ld_insert_date,         -- 3.�X�V��
            ln_insert_login_id,     -- 4.���O�C��ID
            ln_insert_request_id,   -- 5.�v��ID
            ln_insert_prog_appl_id, -- 6.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
            ln_insert_program_id,   -- 7.�R���J�����g�E�v���O����ID
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- ��O����
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--
        gt_sr_line_tbl(gn_target_cnt) := lr_sr_line_rec;
--
        IF (lr_sr_line_rec.row_level_status = gn_data_status_normal) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSIF (lr_sr_line_rec.row_level_status = gn_data_status_warn) THEN
          gn_warn_cnt   := gn_warn_cnt + 1;
        ELSE 
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
--
      END LOOP get_srl_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
    EXCEPTION
      WHEN check_lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_lock,
                                              gv_tkn_table, gv_xxcmn_sr_lines_if);
        lv_errbuf := lv_errmsg;
        RAISE check_sub_main_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- �x��������ꍇ�̓Z�[�u�|�C���g�փ��[���o�b�N
    IF (gn_warn_cnt > 0) THEN
      ROLLBACK TO spoint;
    END IF;
--
    -- ���킩�x���̏ꍇ������������1���ȏ�̏ꍇ
    IF ((gn_data_status <> gn_data_status_error)
         AND ( gn_target_cnt > 0 )) THEN
        -- ===============================
        --  �����\���A�h�I���C���^�t�F�[�X�e�[�u���폜(B-10)
        -- ===============================    
      delete_sr_lines_if(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ��O����
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_normal_cnt > 0) THEN
      -- ���O�o�͏���(����:0)
      disp_report(gn_data_status_normal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      -- ��O����
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ���O�o�͏���(���s:1)
      disp_report(gn_data_status_error,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      -- ��O����
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ���O�o�͏���(�x��:2)
      disp_report(gn_data_status_warn,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      -- ��O����
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END IF;
--
    IF (gn_data_status = gn_data_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
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
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
--###########################  �Œ蕔 START   ####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
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
--###########################  �Œ蕔 START   ####################################################
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
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
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
--###########################  �Œ蕔 END   ######################################################
--
END xxcmn890001c;
/
