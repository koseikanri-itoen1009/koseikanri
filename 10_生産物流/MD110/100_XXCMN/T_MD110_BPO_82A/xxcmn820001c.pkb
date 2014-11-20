CREATE OR REPLACE PACKAGE BODY xxcmn820001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820001c(body)
 * Description      : �W�������捞
 * MD.050           : �W�������}�X�^ T_MD050_BPO_820
 * MD.070           : �W�������捞   T_MD070_BPO_82A
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  disp_report            ���|�[�g�p�f�[�^�o�̓v���V�[�W��
 *  delete_standard_if     �C���^�t�F�[�X�e�[�u���폜�v���V�[�W��(A-6)
 *  modify_end_date        �K�p�I�����ҏW�v���V�[�W��(A-5)
 *  insert_xp_lines        �d���^�W���P�����ב}���v���V�[�W��(A-4)
 *  insert_xp_headers      �d���^�W���P���w�b�_�}���v���V�[�W��(A-4)
 *  get_price_line_id      �d���^�W���P������ID�擾�v���V�[�W��(A-3)
 *  get_price_h_id         �d���^�W���P���w�b�_ID�擾�v���V�[�W��(A-3)
 *  check_data             ���o�f�[�^�`�F�b�N�����v���V�[�W��(A-2)
 *  get_standard_if_lock   ���b�N�擾�v���V�[�W��
 *  get_profile            �v���t�@�C���擾�v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/11    1.0   ORACLE �ؗS��  main�V�K�쐬
 *  2008/06/23    1.1   ORACLE �Ŗ����\  �K�p�I�����X�V�s��C��
 *  2008/07/09    1.2   Oracle �R����_  I_S_192�Ή�
 *  2008/09/10    1.3   Oracle �R����_  PT 2-2_18 �w�E62�Ή�
 *  2009/04/09    1.4   SCS�ۉ�          �{�ԏ�Q1395 �N�x�֑ؑΉ�
 *  2009/04/27    1.5   SCS �Ŗ�         �{�ԏ�Q1407�Ή�
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
  gv_pkg_name           CONSTANT VARCHAR2(100) := 'xxcmn820001c'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gv_msg_kbn            CONSTANT VARCHAR2(5)   := 'XXCMN';
  -- �����󋵂�����킷�X�e�[�^�X
  gn_data_status_normal CONSTANT NUMBER := 0; -- ����
  gn_data_status_error  CONSTANT NUMBER := 1; -- ���s
  gn_data_status_warn   CONSTANT NUMBER := 2; -- �x��
  --�v���t�@�C��
  gv_prf_max_date       CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';
--
  --�g�[�N��
  gv_tkn_ng_profile     CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_item_value     CONSTANT VARCHAR2(15) := 'ITEM_VALUE';
  gv_tkn_item_code_p    CONSTANT VARCHAR2(15) := 'ITEM_CODE_P';
  gv_tkn_item_code_c    CONSTANT VARCHAR2(15) := 'ITEM_CODE_C';
--
  --���b�Z�[�W�ԍ�
  -- �����f�[�^(���o��)
  gv_msg_data_normal    CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';
  -- �G���[�f�[�^(���o��)
  gv_msg_data_error     CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';
  -- �X�L�b�v�f�[�^(���o��)
  gv_msg_data_warn      CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';
  -- �v���t�@�C���擾�G���[
  gv_msg_no_profile     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';
  -- ���݃`�F�b�N�G���[
  gv_msg_ng_item        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10141';
  -- �i�ڋ敪�`�F�b�N�G���[
  gv_msg_ng_product     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10045';
  -- �K�p�J�n�����_���݃`�F�b�N�G���[
  gv_msg_ng_s_time      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10142';
  -- �K�p�J�n���`�F�b�N�G���[1
  gv_msg_ng_s_date1     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10046';
  -- �K�p�J�n���`�F�b�N�G���[2
  gv_msg_ng_s_date2     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10047';
  -- ��ڃ`�F�b�N�G���[
  gv_msg_ng_exp_type    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10143';
  -- ���ڃ`�F�b�N�G���[
  gv_msg_ng_exp_de_type CONSTANT VARCHAR2(15) := 'APP-XXCMN-10144';
  -- ���o�f�[�^�d���`�F�b�N�G���[
  gv_msg_ng_repetition  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10145';
  -- �o�^�σ`�F�b�N�G���[
  gv_msg_ng_registered  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10051';
  -- �P���`�F�b�N�G���[
  gv_msg_ng_unit_price  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10048';
  -- �e�i�ڎ擾�G���[
  gv_msg_ng_itemcode_p  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10042';
  -- �q�i�ڎ擾�G���[1
  gv_msg_ng_itemcode_c1 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10043';
  -- �q�i�ڎ擾�G���[2
  gv_msg_ng_itemcode_c2 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10044';
  -- �e�i�ڒP���G���[
  gv_msg_ng_unitprice_p CONSTANT VARCHAR2(15) := 'APP-XXCMN-10049';
  -- ���b�N�擾�G���[
  gv_msg_ng_get_lock    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10146';
--
  -- �Ώ�DB��
  gv_xxcmn_standard_cost_if CONSTANT VARCHAR2(100) := '�W�������C���^�t�F�[�X';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���|�[�g�̏�ԁA�o�̓��b�Z�[�W���i�[���郌�R�[�h
  TYPE out_report_rec IS RECORD(
    -- �W�������C���^�t�F�[�X.�v��ID
    request_id         xxcmn_standard_cost_if.request_id%TYPE,
    -- �W�������C���^�t�F�[�X.�i��
    item_code          xxcmn_standard_cost_if.item_code%TYPE,
    -- �W�������C���^�t�F�[�X.�K�p�J�n��
    s_date_active      xxcmn_standard_cost_if.start_date_active%TYPE,
    -- �W�������C���^�t�F�[�X.���
    e_item_type        xxcmn_standard_cost_if.expence_item_type%TYPE,
    -- �W�������C���^�t�F�[�X.����
    e_item_detail_type xxcmn_standard_cost_if.expence_item_detail_type%TYPE,
    -- �W�������C���^�t�F�[�X.����i��
    item_code_detail   xxcmn_standard_cost_if.item_code_detail%TYPE,
    -- �W�������C���^�t�F�[�X.�P��
    unit_price         xxcmn_standard_cost_if.unit_price%TYPE,
--
    row_level_status NUMBER,         -- 0.����,1.���s,2.�x��
    skip_message     VARCHAR2(1000), -- �\���p���b�Z�[�W
    message1         VARCHAR2(1000), -- �\���p���b�Z�[�W
    message2         VARCHAR2(1000), -- �\���p���b�Z�[�W
    message3         VARCHAR2(1000), -- �\���p���b�Z�[�W
    message4         VARCHAR2(1000), -- �\���p���b�Z�[�W
    message5         VARCHAR2(1000), -- �\���p���b�Z�[�W
    message6         VARCHAR2(1000), -- �\���p���b�Z�[�W
    message7         VARCHAR2(1000)  -- �\���p���b�Z�[�W
  );
--
  -- ���|�[�g�����i�[����e�[�u���^�̒�`
  TYPE out_report_tbl IS
    TABLE OF out_report_rec INDEX BY BINARY_INTEGER;
--
  -- �W�������C���^�t�F�[�X �폜�p �v��ID
  TYPE request_id_tbl    IS
    TABLE OF xxcmn_standard_cost_if.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P���w�b�_ �}���p �w�b�_ID
  TYPE price_header_id_tbl IS
    TABLE OF xxpo_price_headers.price_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P���w�b�_ �}���p �i��ID
  TYPE item_id_tbl       IS
    TABLE OF xxpo_price_headers.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P���w�b�_ �}���p �i��
  TYPE item_code_tbl       IS
    TABLE OF xxpo_price_headers.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P���w�b�_ �}���p �K�p�J�n��
  TYPE s_date_tbl          IS
    TABLE OF xxpo_price_headers.start_date_active%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P���w�b�_ �}���p ���󍇌v
  TYPE total_amount_tbl    IS
    TABLE OF xxpo_price_headers.total_amount%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P������ �}���p ����ID
  TYPE price_line_id_tbl   IS
    TABLE OF xxpo_price_lines.price_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P������ �}���p �w�b�_ID
  TYPE price_header_line_id_tbl IS
    TABLE OF xxpo_price_lines.price_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P������ �}���p ���
  TYPE exp_item_tbl        IS
    TABLE OF xxpo_price_lines.expense_item_type%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P������ �}���p ����
  TYPE exp_item_det_tbl    IS
    TABLE OF xxpo_price_lines.expense_item_detail_type%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P������ �}���p ����i��
  TYPE item_code_det_tbl   IS
    TABLE OF xxpo_price_lines.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- �d���^�W���P������ �}���p �P��
  TYPE unit_price_tbl      IS
    TABLE OF xxpo_price_lines.unit_price%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_max_date                 VARCHAR2(10); -- �ő���t
  gn_data_status              NUMBER := 0;  -- �f�[�^�`�F�b�N�X�e�[�^�X
  gn_request_id_cnt           NUMBER := 0;  -- ���N�G�X�gID��
  gt_out_report_tbl           out_report_tbl;
  gt_request_id_tbl           request_id_tbl;
  -- �d���^�W���P���w�b�_ �}���p �w�b�_ID
  gt_price_header_id_tbl      price_header_id_tbl;
  -- �d���^�W���P���w�b�_ �}���p �i��ID
  gt_item_id_tbl            item_id_tbl;
  -- �d���^�W���P���w�b�_ �}���p �i��
  gt_item_code_tbl            item_code_tbl;
  -- �d���^�W���P���w�b�_ �}���p �K�p�J�n��
  gt_s_date_tbl               s_date_tbl;
  -- �d���^�W���P���w�b�_ �}���p ���󍇌v
  gt_total_amount_tbl         total_amount_tbl;
  -- �d���^�W���P������ �}���p �w�b�_ID
  gt_price_header_line_id_tbl price_header_line_id_tbl;
  -- �d���^�W���P������ �}���p ����ID
  gt_price_line_id_tbl        price_line_id_tbl;
  -- �d���^�W���P������ �}���p ���
  gt_exp_item_tbl             exp_item_tbl;
  -- �d���^�W���P������ �}���p ����
  gt_exp_item_det_tbl         exp_item_det_tbl;
  -- �d���^�W���P������ �}���p ����i��
  gt_item_code_det_tbl        item_code_det_tbl;
  -- �d���^�W���P������ �}���p �P��
  gt_unit_price_tbl           unit_price_tbl;
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
    lr_report_rec out_report_rec;
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
      lr_report_rec := gt_out_report_tbl(ln_disp_cnt);
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
--
        --���̓f�[�^�̍č\��
        lv_dspbuf := lr_report_rec.request_id
          || gv_msg_pnt || lr_report_rec.item_code
          || gv_msg_pnt || TO_CHAR(lr_report_rec.s_date_active,'YYYY/MM/DD')
          || gv_msg_pnt || lr_report_rec.e_item_type
          || gv_msg_pnt || lr_report_rec.e_item_detail_type
          || gv_msg_pnt || lr_report_rec.item_code_detail
          || gv_msg_pnt || lr_report_rec.unit_price;
--
        -- ���|�[�g�f�[�^�̏o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- ���b�Z�[�W�f�[�^�̏o��
        IF (lr_report_rec.message1 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message1);
        END IF;
        IF (lr_report_rec.message2 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message2);
        END IF;
        IF (lr_report_rec.message3 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message3);
        END IF;
        IF (lr_report_rec.message4 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message4);
        END IF;
        IF (lr_report_rec.message5 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message5);
        END IF;
        IF (lr_report_rec.message6 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message6);
        END IF;
        IF (lr_report_rec.message7 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message7);
        END IF;
        IF (lr_report_rec.skip_message IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.skip_message);
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
   * Procedure Name   : delete_standard_if
   * Description      : �C���^�t�F�[�X�e�[�u���폜�v���V�[�W��(A-6)
   ***********************************************************************************/
  PROCEDURE delete_standard_if(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_standard_if'; -- �v���O������
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
    FORALL ln_count IN 1..gn_request_id_cnt
      DELETE xxcmn_standard_cost_if xsci             -- �W�������C���^�t�F�[�X
      WHERE  xsci.request_id = gt_request_id_tbl(ln_count);  -- �v��ID
--
    -- ==============================================================
    -- ���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    -- ==============================================================
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
  END delete_standard_if;
--
  /**********************************************************************************
   * Function Name    : modify_end_date
   * Description      : �K�p�I�����ҏW�v���V�[�W��(A-5)
   ***********************************************************************************/
  PROCEDURE modify_end_date(
    in_insert_user_id         IN NUMBER,            -- 1.���[�U�[ID
    id_insert_date            IN DATE,              -- 2.�X�V��
    in_insert_login_id        IN NUMBER,            -- 3.���O�C��ID
    in_insert_request_id      IN NUMBER,            -- 4.�v��ID
    in_insert_program_appl_id IN NUMBER,            -- 5.�R���J�����g�E�v���O�����A�v���P�[�V����ID
    in_insert_program_id      IN NUMBER,            -- 6.�R���J�����g�E�v���O����ID
    ov_errbuf                 OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'modify_end_date'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cd_max_date         CONSTANT DATE := FND_DATE.CANONICAL_TO_DATE( gv_max_date );   -- MAX���t
    cv_price_standard   CONSTANT VARCHAR2(1) := '2';    -- �}�X�^�敪�i�W���j
--
    -- *** ���[�J���ϐ� ***
    ld_past_s_date_active DATE;   -- �O���̓K�p�J�n��
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  get_insert_data_cur IS
    SELECT  xph.item_code                                                AS item_code
           ,xph.start_date_active                                        AS s_date_active
           ,MAX(xph.start_date_active) over (PARTITION BY xph.item_code) AS MAX_START_DATE_ACTIVE
    FROM    xxpo_price_headers      xph,    -- �d���^�W���P���w�b�_
            xxcmn_standard_cost_if  xsci    -- �W�������C���^�t�F�[�X
    WHERE   xph.item_code           =  xsci.item_code
    AND     xph.price_type          = cv_price_standard
    ORDER BY xph.item_code, xph.start_date_active DESC;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
--
    <<get_parnet_price_loop>>
    FOR get_history_data IN  get_insert_data_cur  LOOP
      -- �K�p�J�n�� = MAX_START_DATE_ACTIVE�̏ꍇ�͂��̃��R�[�h�̓K�p�I������9999/12/31�ɍX�V����
      IF (get_history_data.s_date_active = get_history_data.MAX_START_DATE_ACTIVE) THEN
        UPDATE  xxpo_price_headers xph      -- �d���^�W���P���w�b�_
        SET     xph.end_date_active         = cd_max_date
               ,xph.last_updated_by         = in_insert_user_id
               ,xph.last_update_date        = id_insert_date
               ,xph.last_update_login       = in_insert_login_id
               ,xph.request_id              = in_insert_request_id
               ,xph.program_application_id  = in_insert_program_appl_id
               ,xph.program_id              = in_insert_program_id
               ,xph.program_update_date     = id_insert_date
        WHERE   xph.item_code               = get_history_data.item_code
        AND     xph.start_date_active       = get_history_data.s_date_active
        AND     xph.price_type              = cv_price_standard;
--
      END IF;
--
      -- ���[�J���ϐ��̏�����
      ld_past_s_date_active := NULL;  -- �O���̓K�p�J�n��
--
      -- �O�����擾����
      SELECT  MAX(xph.start_date_active)  AS s_date_active
      INTO    ld_past_s_date_active
      FROM    xxpo_price_headers xph      -- �d���^�W���P���w�b�_
      WHERE   xph.item_code               = get_history_data.item_code
      AND     xph.start_date_active       < get_history_data.s_date_active
      AND     xph.price_type              = cv_price_standard;
--
      -- �O���̓K�p�J�n����NULL�łȂ��ꍇ�͑O���̓K�p�I�������X�V����
      IF (ld_past_s_date_active IS NOT NULL) THEN
        UPDATE  xxpo_price_headers xph      -- �d���^�W���P���w�b�_
        SET     xph.end_date_active         = get_history_data.s_date_active - 1
               ,xph.last_updated_by         = in_insert_user_id
               ,xph.last_update_date        = id_insert_date
               ,xph.last_update_login       = in_insert_login_id
               ,xph.request_id              = in_insert_request_id
               ,xph.program_application_id  = in_insert_program_appl_id
               ,xph.program_id              = in_insert_program_id
               ,xph.program_update_date     = id_insert_date
        WHERE   xph.item_code               = get_history_data.item_code
        AND     xph.start_date_active       = ld_past_s_date_active
        AND     xph.price_type              = cv_price_standard;
--
      END IF;
--
    END LOOP get_parnet_price_loop;
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
  END modify_end_date;
--
  /**********************************************************************************
   * Procedure Name   : insert_xp_lines
   * Description      : �d���^�W���P�����ב}���v���V�[�W��(A-4)
   ***********************************************************************************/
  PROCEDURE insert_xp_lines(
    in_insert_user_id         IN NUMBER,            -- 1.���[�U�[ID
    id_insert_date            IN DATE,              -- 2.�X�V��
    in_insert_login_id        IN NUMBER,            -- 3.���O�C��ID
    in_insert_request_id      IN NUMBER,            -- 4.�v��ID
    in_insert_program_appl_id IN NUMBER,            -- 5.�R���J�����g�E�v���O�����A�v���P�[�V����ID
    in_insert_program_id      IN NUMBER,            -- 6.�R���J�����g�E�v���O����ID
    ov_errbuf                 OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xp_lines'; -- �v���O������
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
    FORALL ln_cnt_loop IN 1 .. gt_price_line_id_tbl.COUNT
      INSERT INTO xxpo_price_lines xpl(   -- �d���^�W���P������
        xpl.price_line_id            -- ����ID
        ,xpl.price_header_id          -- �w�b�_ID
        ,xpl.item_code                -- ����i��
        ,xpl.expense_item_type        -- ��ڋ敪
        ,xpl.expense_item_detail_type -- ���ڋ敪
        ,xpl.unit_price               -- �P��
        ,xpl.created_by               -- �쐬��
        ,xpl.creation_date            -- �쐬��
        ,xpl.last_updated_by          -- �ŏI�X�V��
        ,xpl.last_update_date         -- �ŏI�X�V��
        ,xpl.last_update_login        -- �ŏI�X�V���O�C��
        ,xpl.request_id               -- �v��ID
        ,xpl.program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xpl.program_id               -- �R���J�����g�E�v���O����ID
        ,xpl.program_update_date)     -- �v���O�����X�V��
      VALUES(
        gt_price_line_id_tbl(ln_cnt_loop)        -- ����ID
        ,gt_price_header_line_id_tbl(ln_cnt_loop) -- �w�b�_ID
        ,gt_item_code_det_tbl(ln_cnt_loop)        -- ����i��
        ,gt_exp_item_tbl(ln_cnt_loop)             -- ��ڋ敪
        ,gt_exp_item_det_tbl(ln_cnt_loop)         -- ���ڋ敪
        ,gt_unit_price_tbl(ln_cnt_loop)           -- �P��
        ,in_insert_user_id                        -- �쐬��
        ,id_insert_date                           -- �쐬��
        ,in_insert_user_id                        -- �ŏI�X�V��
        ,id_insert_date                           -- �ŏI�X�V��
        ,in_insert_login_id                       -- �ŏI�X�V���O�C��
        ,in_insert_request_id                     -- �v��ID
        ,in_insert_program_appl_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,in_insert_program_id                     -- �R���J�����g�E�v���O����ID
        ,id_insert_date);                         -- �v���O�����X�V��
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
  END insert_xp_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_xp_headers
   * Description      : �d���^�W���P���w�b�_�}���v���V�[�W��(A-4)
   ***********************************************************************************/
  PROCEDURE insert_xp_headers(
    in_insert_user_id         IN NUMBER,            -- 1.���[�U�[ID
    id_insert_date            IN DATE,              -- 2.�X�V��
    in_insert_login_id        IN NUMBER,            -- 3.���O�C��ID
    in_insert_request_id      IN NUMBER,            -- 4.�v��ID
    in_insert_program_appl_id IN NUMBER,            -- 5.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
    in_insert_program_id      IN NUMBER,            -- 6.�R���J�����g�E�v���O����ID
    ov_errbuf                 OUT NOCOPY  VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xp_headers'; -- �v���O������
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
    cv_price_standard     CONSTANT VARCHAR2(1) := '2';    -- �}�X�^�敪�i�W���j
    cv_not_change         CONSTANT VARCHAR2(1) := 'N';    -- �ύX�����t���O�i�ύX�Ȃ��j
--
    -- *** ���[�J���ϐ� ***
    ld_end_date DATE := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
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
    FORALL ln_cnt_loop IN 1 .. gt_price_header_id_tbl.COUNT
      INSERT INTO xxpo_price_headers  xph(   -- �d���^�W���P���w�b�_
        xph.price_header_id         -- �w�b�_ID
        ,xph.price_type             -- �}�X�^�敪
        ,xph.item_id                -- �i��ID
        ,xph.item_code              -- �i��
        ,xph.start_date_active      -- �K�p�J�n��
        ,xph.end_date_active        -- �K�p�I����
        ,xph.total_amount           -- ���󍇌v
        ,xph.record_change_flg      -- �ύX�����t���O
        ,xph.created_by             -- �쐬��
        ,xph.creation_date          -- �쐬��
        ,xph.last_updated_by        -- �ŏI�X�V��
        ,xph.last_update_date       -- �ŏI�X�V��
        ,xph.last_update_login      -- �ŏI�X�V���O�C��
        ,xph.request_id             -- �v��ID
        ,xph.program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xph.program_id             -- �R���J�����g�E�v���O����ID
        ,xph.program_update_date)    -- �v���O�����X�V��
      VALUES(
        gt_price_header_id_tbl(ln_cnt_loop)  -- �w�b�_ID
        ,cv_price_standard                   -- �}�X�^�敪
        ,gt_item_id_tbl(ln_cnt_loop)         -- �i��ID
        ,gt_item_code_tbl(ln_cnt_loop)       -- �i��
        ,gt_s_date_tbl(ln_cnt_loop)          -- �K�p�J�n��
        ,ld_end_date                         -- �K�p�I����
        ,gt_total_amount_tbl(ln_cnt_loop)    -- ���󍇌v
        ,cv_not_change                       -- �ύX�����t���O
        ,in_insert_user_id                   -- �쐬��
        ,id_insert_date                      -- �쐬��
        ,in_insert_user_id                   -- �ŏI�X�V��
        ,id_insert_date                      -- �ŏI�X�V��
        ,in_insert_login_id                  -- �ŏI�X�V���O�C��
        ,in_insert_request_id                -- �v��ID
        ,in_insert_program_appl_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,in_insert_program_id                -- �R���J�����g�E�v���O����ID
        ,id_insert_date);                    -- �v���O�����X�V��
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
  END insert_xp_headers;
--
  /**********************************************************************************
   * Procedure Name   : get_price_line_id
   * Description      : �d���^�W���P������ID�擾�v���V�[�W��(A-3)
   ***********************************************************************************/
  PROCEDURE get_price_line_id(
    in_price_l_id IN OUT NOCOPY NUMBER,   -- 1.���R�[�h
    ov_errbuf     OUT NOCOPY    VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY    VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY    VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price_line_id'; -- �v���O������
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
    -- �d���^�W���P������ID���V�[�P���X���擾
    SELECT xxpo_price_lines_s1.NEXTVAL
    INTO in_price_l_id
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
  END get_price_line_id;
--
  /**********************************************************************************
   * Procedure Name   : get_price_h_id
   * Description      : �d���^�W���P���w�b�_ID�擾�v���V�[�W��(A-3)
   ***********************************************************************************/
  PROCEDURE get_price_h_id(
    in_price_h_id IN OUT NOCOPY NUMBER,   -- 1.���R�[�h
    ov_errbuf     OUT NOCOPY    VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY    VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY    VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price_h_id'; -- �v���O������
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
    -- �d���^�W���P���w�b�_ID���V�[�P���X���擾
    SELECT xxpo_price_headers_all_s1.NEXTVAL
    INTO in_price_h_id
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
  END get_price_h_id;
--
/**********************************************************************************
   * Procedure Name   : check_data
   * Description      : ���o�f�[�^�`�F�b�N�����v���V�[�W��(A-2)
   ***********************************************************************************/
  PROCEDURE check_data(
    ir_report_rec   IN OUT NOCOPY out_report_rec, -- 1.���R�[�h
    in_total_amount IN OUT NOCOPY NUMBER,         -- 2.�P�����v
    in_item_id      IN OUT NOCOPY NUMBER,         -- 3.�i��ID
    ov_errbuf       OUT NOCOPY VARCHAR2,          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,          --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_obsolete_handling   CONSTANT VARCHAR2(1) := '0';     -- �p�~�敪�i�戵���j
    cv_obsolete_abolition  CONSTANT VARCHAR2(1) := '1';     -- �p�~�敪�i�p�~�j
    cv_year_start_date     CONSTANT VARCHAR2(5) := '05/01'; -- �N�x�J�n��
    cv_item_product        CONSTANT VARCHAR2(1) := '5';     -- �i�ڋ敪�i���i�j
    cv_price_standard      CONSTANT VARCHAR2(1) := '2';    -- �}�X�^�敪�i�W���j
    -- ��ڃR�[�h�^�C�v
    cv_expense_type        CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';
    -- ���ڃR�[�h�^�C�v
    cv_expense_detail_type CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_DETAIL_TYPE';
--
    -- *** ���[�J���ϐ� ***
    ln_count            NUMBER := 0;
    ln_price            NUMBER := 0;
    ln_price_trunc      NUMBER := 0;
    ln_parent_item_id   NUMBER;
    ln_parent_price     NUMBER;
    ld_start_date       DATE;
    lv_sys_year         VARCHAR2(4);
    lv_sys_date         VARCHAR2(20);
    lv_item_year        VARCHAR2(4);
    lv_item_date        VARCHAR2(20);
    lv_parent_item_code VARCHAR2(10);
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �q�P���擾�J�[�\�� xsli_request
    CURSOR parent_price_cur(iv_item_code VARCHAR2
                            ,in_parent_item_id NUMBER
                            ,id_start_date DATE)IS
      SELECT ximv.item_no item_code
            ,ximv.obsolete_class obsolete_class
      FROM xxcmn_item_mst2_v ximv -- OPM�i�ڏ��VIEW2
      WHERE ximv.parent_item_id = in_parent_item_id
        AND ximv.item_no <> iv_item_code
        AND ximv.start_date_active <= id_start_date
        AND ximv.end_date_active >= id_start_date;
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
    -- �i�ڑ��݃`�F�b�N �Ώەi�ڂ��o�^����Ă��邱��
    BEGIN
      SELECT ximv.item_id
      INTO in_item_id
      FROM xxcmn_item_mst2_v ximv    -- OPM�i�ڏ��VIEW2
      WHERE ximv.item_no = ir_report_rec.item_code
-- 2009/04/27 v1.5 DELETE START
--        AND ximv.obsolete_class = cv_obsolete_handling
--        AND ximv.obsolete_date IS NULL
-- 2009/04/27 v1.5 DELETE END
        AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �i�ڑ��݃`�F�b�NNG
        ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
          gv_msg_kbn, gv_msg_ng_item,
          gv_tkn_item_value, ir_report_rec.item_code);
        RAISE check_data_expt;
    END;
--
    -- ����i�ڂ�NULL�̏ꍇ�ɂ͕s�v
    IF (ir_report_rec.item_code_detail IS NOT NULL) THEN
      -- ����i�ڑ��݃`�F�b�N �Ώۓ���i�ڂ��o�^����Ă��邱��
      SELECT COUNT(ximv.item_id)
      INTO ln_count
      FROM xxcmn_item_mst2_v ximv    -- OPM�i�ڏ��VIEW2
      WHERE ximv.item_no = ir_report_rec.item_code_detail
-- 2009/04/27 v1.5 DELETE START
--        AND ximv.obsolete_class = cv_obsolete_handling
--        AND ximv.obsolete_date IS NULL
-- 2009/04/27 v1.5 DELETE END
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
        -- ����i�ڑ��݃`�F�b�NNG
        ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
          gv_msg_kbn, gv_msg_ng_item,
          gv_tkn_item_value, ir_report_rec.item_code_detail);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- �i�ڋ敪�`�F�b�N �i�ڋ敪���u���i�v�ł��邱��
    SELECT COUNT(ximv.item_id)
    INTO ln_count
    FROM xxcmn_item_mst2_v ximv    -- OPM�i�ڏ��VIEW2
        ,xxcmn_item_categories3_v xicv --OPM�J�e�S�����VIEW3
    WHERE ximv.item_no = ir_report_rec.item_code
      AND ximv.item_id = xicv.item_id
      AND xicv.item_class_code = cv_item_product
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- �i�ڋ敪�`�F�b�NNG
      ir_report_rec.message1 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_product,
        gv_tkn_item_value, ir_report_rec.item_code);
    END IF;
--
    -- �K�p�J�n�����_���݃`�F�b�N �K�p�J�n�����_�œo�^����Ă��邱��
    SELECT COUNT(ximv.item_id)
    INTO ln_count
    FROM xxcmn_item_mst2_v ximv    -- OPM�i�ڏ��VIEW2
    WHERE ximv.item_no = ir_report_rec.item_code
      AND ximv.start_date_active <= ir_report_rec.s_date_active
      AND ximv.end_date_active >= ir_report_rec.s_date_active
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- �K�p�J�n�����_���݃`�F�b�NNG
      ir_report_rec.message2 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_s_time,
        gv_tkn_item_value, ir_report_rec.item_code);
    END IF;
--
    -- ����i�ڂ�NULL�̏ꍇ�ɂ͕s�v
    IF (ir_report_rec.item_code_detail IS NOT NULL) THEN
      -- �K�p�J�n�����_���݃`�F�b�N
      SELECT COUNT(ximv.item_id)
      INTO ln_count
      FROM xxcmn_item_mst2_v ximv    -- OPM�i�ڏ��VIEW
      WHERE ximv.item_no = ir_report_rec.item_code_detail
        AND ximv.start_date_active <= ir_report_rec.s_date_active
        AND ximv.end_date_active >= ir_report_rec.s_date_active
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
        -- �K�p�J�n�����_���݃`�F�b�NNG
        ir_report_rec.message3 := xxcmn_common_pkg.get_msg(
          gv_msg_kbn, gv_msg_ng_s_time,
          gv_tkn_item_value, ir_report_rec.item_code_detail);
      END IF;
    END IF;
--
    lv_sys_year := TO_CHAR(SYSDATE,'YYYY');
--
    lv_item_date := TO_CHAR(ir_report_rec.s_date_active,'MM/DD');
--
    ld_start_date :=
      FND_DATE.STRING_TO_DATE((lv_sys_year || '/' || cv_year_start_date),'YYYY/MM/DD');
--
-- 2009/04/09 DEL START
/*
    -- �K�p�J�n���`�F�b�N1 �K�p�J�n���N�x���V�X�e���N�x�ȍ~�ł��邱��
    IF (ir_report_rec.s_date_active < ld_start_date) THEN
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_s_date1,
        gv_tkn_item_value, TO_CHAR(ir_report_rec.s_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
*/
-- 2009/04/09 DEL END
--
    -- �K�p�J�n���`�F�b�N2 �K�p�J�n����5��1���ł��邱��
    IF (lv_item_date <> cv_year_start_date) THEN
      ir_report_rec.message4 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_s_date2,
        gv_tkn_item_value, TO_CHAR(ir_report_rec.s_date_active, 'YYYY/MM/DD'));
    END IF;
--
    -- ��ڃ`�F�b�N ��ڂ����݂��Ă��邱��
    SELECT COUNT(xlvv.lookup_code)
    INTO ln_count
    FROM xxcmn_lookup_values_v xlvv -- �N�C�b�N�R�[�h���VIEW
    WHERE xlvv.lookup_type = cv_expense_type
      AND xlvv.attribute1 = ir_report_rec.e_item_type
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- ��ڃ`�F�b�NNG
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_exp_type,
        gv_tkn_item_value, ir_report_rec.e_item_type);
      RAISE check_data_expt;
    END IF;
--
    -- ���ڃ`�F�b�N ���ڂ����݂��Ă��邱��
    SELECT COUNT(xlvv.lookup_code)
    INTO ln_count
    FROM xxcmn_lookup_values_v xlvv -- �N�C�b�N�R�[�h���VIEW
    WHERE xlvv.lookup_type = cv_expense_detail_type
      AND xlvv.attribute1 = ir_report_rec.e_item_detail_type
      AND xlvv.attribute2 = ir_report_rec.e_item_type
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- ���ڃ`�F�b�NNG
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_exp_de_type,
        gv_tkn_item_value, ir_report_rec.e_item_detail_type);
      RAISE check_data_expt;
    END IF;
--
    -- ���o�f�[�^�d���`�F�b�N ����f�[�^�����݂��Ă��Ȃ�����
    SELECT COUNT(xsci.item_code)
    INTO ln_count
    FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
    WHERE xsci.start_date_active = ir_report_rec.s_date_active
      AND xsci.item_code = ir_report_rec.item_code
      AND xsci.expence_item_type = ir_report_rec.e_item_type
      AND xsci.expence_item_detail_type = ir_report_rec.e_item_detail_type
      AND xsci.item_code_detail = ir_report_rec.item_code_detail
      AND xsci.request_id = ir_report_rec.request_id;
--
    IF (ln_count >= 2) THEN
      -- ���o�f�[�^�d���`�F�b�NNG
      ir_report_rec.message5 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_repetition);
    END IF;
--
    -- �o�^�σ`�F�b�N �w�b�_�ɓ����񂪓o�^����Ă��Ȃ�����
    SELECT COUNT(xph.price_header_id)
    INTO ln_count
    FROM xxpo_price_headers xph -- �d���^�W�������w�b�_
    WHERE xph.price_type = cv_price_standard
      AND xph.item_code = ir_report_rec.item_code
      AND xph.start_date_active >= ir_report_rec.s_date_active
      AND ROWNUM = 1;
--
    IF (ln_count = 1) THEN
      -- �o�^�σ`�F�b�NNG
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_registered,
        gv_tkn_item_value, ir_report_rec.item_code);
      RAISE check_data_expt;
    END IF;
--
    -- �P���`�F�b�N �P���ɏ����_���܂܂�Ă��Ȃ�����
    SELECT SUM(xsci.unit_price)
    INTO ln_price
    FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
    WHERE xsci.start_date_active = ir_report_rec.s_date_active
      AND xsci.item_code = ir_report_rec.item_code;
--
    ln_price_trunc := TRUNC(ln_price);
--
    IF (ln_price <> ln_price_trunc) THEN
      -- �P���`�F�b�NNG
      ir_report_rec.message6 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_unit_price,
        gv_tkn_item_value, ln_price);
    END IF;
    -- �P�����v�i�[
    in_total_amount := ln_price;
--
    -- �e�q�֌W�`�F�b�N
    BEGIN
      SELECT ximv1.item_no
            ,ximv2.parent_item_id
      INTO lv_parent_item_code
          ,ln_parent_item_id
      FROM xxcmn_item_mst2_v ximv1           -- OPM�i�ڏ��VIEW
          ,xxcmn_item_mst2_v ximv2           -- OPM�i�ڏ��VIEW
      WHERE ximv1.item_id = ximv2.parent_item_id
        AND ximv2.item_no = ir_report_rec.item_code
        AND ximv2.start_date_active <= ld_start_date
        AND ximv2.end_date_active >= ld_start_date
        AND ROWNUM = 1;
--
      -- ���o�f�[�^�Ɛe�i�ڃf�[�^����v���Ȃ��ꍇ�i�e�i�ڏ����擾�j
      IF (lv_parent_item_code <> ir_report_rec.item_code) THEN
        SELECT COUNT(xsci.item_code)
        INTO ln_count
        FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
        WHERE xsci.item_code = lv_parent_item_code;
        IF (ln_count = 0) THEN
          ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
            gv_msg_kbn, gv_msg_ng_itemcode_p,
            gv_tkn_item_code_p, lv_parent_item_code,
            gv_tkn_item_code_c, ir_report_rec.item_code);
          RAISE check_data_expt;
        END IF;
--
        SELECT SUM(xsci.unit_price)
        INTO ln_parent_price
        FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
        WHERE xsci.item_code = lv_parent_item_code;
--
        -- �e�i�ڒP���Ǝq�i�ڒP������v���Ȃ��ꍇ
        IF ((ln_price IS NULL) AND (ln_parent_price IS NOT NULL)) OR
            ((ln_price IS NOT NULL) AND (ln_parent_price IS NULL)) OR
            (ln_price <> ln_parent_price) THEN
          ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
            gv_msg_kbn, gv_msg_ng_unitprice_p,
            gv_tkn_item_code_p, lv_parent_item_code,
            gv_tkn_item_code_c, ir_report_rec.item_code);
          RAISE check_data_expt;
        END IF;
      -- ���o�f�[�^�Ɛe�i�ڃf�[�^����v����ꍇ�i�q�i�ڏ����擾�j
      ELSE
--
        <<get_parnet_price_loop>>
        FOR get_srl_data IN parent_price_cur(
          ir_report_rec.item_code,
          ln_parent_item_id,
          ld_start_date)  LOOP
          BEGIN
            SELECT SUM(xsci.unit_price)
            INTO ln_parent_price
            FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
            WHERE xsci.item_code = get_srl_data.item_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_parent_price := NULL;
          END;
          -- �q�i�ڏ�񂪎擾�ł��Ȃ��ꍇ
          IF (ln_parent_price IS  NULL) THEN
            -- �p�~�敪���u0�i�戵���j�v�̏ꍇ
            IF (get_srl_data.obsolete_class = cv_obsolete_handling) THEN
              ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
                gv_msg_kbn, gv_msg_ng_itemcode_c1,
                gv_tkn_item_code_p, ir_report_rec.item_code,
                gv_tkn_item_code_c, get_srl_data.item_code);
              RAISE check_data_expt;
            -- �p�~�敪���u1�i�p�~�j�v�̏ꍇ
            ELSIF (get_srl_data.obsolete_class = cv_obsolete_abolition)THEN
              ir_report_rec.message7 := xxcmn_common_pkg.get_msg(
                gv_msg_kbn, gv_msg_ng_itemcode_c2,
                gv_tkn_item_code_p, ir_report_rec.item_code,
                gv_tkn_item_code_c, get_srl_data.item_code);
            END IF;
          ELSE
            -- �e�i�ڒP���Ǝq�i�ڒP������v���Ȃ��ꍇ
            IF ((ln_price IS NULL) AND (ln_parent_price IS NOT NULL)) OR
                ((ln_price IS NOT NULL) AND (ln_parent_price IS NULL)) OR
                (ln_price <> ln_parent_price) THEN
              ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
                gv_msg_kbn, gv_msg_ng_unitprice_p,
                gv_tkn_item_code_p, ir_report_rec.item_code,
                gv_tkn_item_code_c, get_srl_data.item_code);
              RAISE check_data_expt;
            END IF;
          END IF;
        END LOOP get_parnet_price_loop;
--
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_parent_item_id := NULL;
        lv_parent_item_code := NULL;
    END;
--
    -- �X�e�[�^�X�ɐ�����i�[
    ir_report_rec.row_level_status := gn_data_status_normal;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_data_expt THEN
      -- ���|�[�g�̃X�e�[�^�X���x���Ɛݒ�
      ir_report_rec.row_level_status  := gn_data_status_warn;
      -- �`�F�b�N�������x���Ɛݒ�(�}����������)
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;                                            --# �C�� #
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
   * Procedure Name   : get_standard_if_lock
   * Description      : ���b�N�擾�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE get_standard_if_lock(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_standard_if_lock'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_standard_if_cur(in_request_id NUMBER) IS
      SELECT xsci.request_id
      FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
      WHERE xsci.request_id = in_request_id
      FOR UPDATE NOWAIT;
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
    BEGIN
       <<request_id_loop>>
      FOR ln_count IN 1..gt_request_id_tbl.COUNT
      LOOP
        -- ���b�N�擾����
        OPEN get_standard_if_cur(gt_request_id_tbl(ln_count));
        CLOSE get_standard_if_cur;
      END LOOP request_id_loop;
    EXCEPTION
      -- ���b�N�擾�G���[
      WHEN check_lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_get_lock);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_standard_if_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C���擾�v���V�[�W��
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
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_no_profile,
        gv_tkn_ng_profile, cv_max_pro_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gv_max_date := lv_max_date; -- �ő���t�ɐݒ�
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
    lr_report_rec             out_report_rec;
    ln_request_id             NUMBER;
    -- �O���R�[�h�w�b�_��r�p�ϐ�
    lv_former_item_code       VARCHAR2(10);
    ld_former_s_date          DATE;
    -- �w�b�_���J�E���g�p�ϐ�
    ln_head_count             NUMBER := 0;
    -- �w�b�_ID�擾�p�ϐ�
    ln_head_id                NUMBER;
    -- ����ID�J�E���g�p�ϐ�
    ln_line_count             NUMBER := 0;
    -- ����ID�擾�p�ϐ�
    ln_line_id                NUMBER;
    -- �i��ID�i�[�p�ϐ�
    ln_item_id                NUMBER;
    -- �P�����v�i�[�p�ϐ�
    ln_total_amount           NUMBER := 0;
    -- �}��,�X�V���[�U�[�f�[�^�i�[�p
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
--
    -- �W�������C���^�t�F�[�X�v��ID�擾�J�[�\��
-- 2008/09/10 Mod ��
/*
    CURSOR get_request_id_cur IS
    SELECT fcr.request_id
    FROM fnd_concurrent_requests fcr
    WHERE EXISTS (
          SELECT 1
          FROM xxcmn_standard_cost_if xsci
          WHERE xsci.request_id = fcr.request_id
            AND ROWNUM = 1
        )
    ORDER BY fcr.request_id; -- �v��ID������
*/
    CURSOR get_request_id_cur IS
    SELECT fcr.request_id
    FROM fnd_concurrent_requests fcr
    WHERE fcr.request_id IN (
          SELECT xsci.request_id
          FROM xxcmn_standard_cost_if xsci
        )
    ORDER BY fcr.request_id; -- �v��ID������
-- 2008/09/10 Mod ��
--
    -- �W�������C���^�t�F�[�X�擾�J�[�\��
    CURSOR get_standard_if_cur(in_request_id NUMBER) IS
      SELECT xsci.request_id
            ,xsci.item_code
            ,xsci.start_date_active
            ,xsci.expence_item_type
            ,xsci.expence_item_detail_type
            ,xsci.item_code_detail
            ,xsci.unit_price
      FROM xxcmn_standard_cost_if xsci -- �W�������C���^�t�F�[�X
      WHERE xsci.request_id = in_request_id
      ORDER BY xsci.request_id
              ,xsci.item_code
              ,xsci.start_date_active
              ,xsci.expence_item_type
              ,xsci.expence_item_detail_type
              ,xsci.item_code_detail;
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
    -- ���[�U�[�f�[�^�̊i�[
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
    -- �v���t�@�C���擾
    -- ===============================
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
    -- �����Ώۗv��ID�擾
    -- ===============================
    <<get_request_id_loop>>
    FOR get_req_data IN get_request_id_cur  LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1;
      gt_request_id_tbl(gn_request_id_cnt) := get_req_data.request_id;
    END LOOP get_request_id_loop;
--
   -- ===============================
    -- ���b�N�擾
    -- ===============================
    get_standard_if_lock(
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
    -- �C���^�t�F�[�X�f�[�^���o����(A-1)
    -- ===============================
    <<get_req_count_loop>>
    FOR ln_req_count IN 1..gt_request_id_tbl.COUNT
    LOOP
      -- �O��擾�w�b�_�p�ϐ���������
      lv_former_item_code := NULL;
      ld_former_s_date := NULL;
      -- �J�E���g������
      ln_head_count := 0;
      ln_line_count := 0;
--
-- 2009/04/27 v1.5 ADD START
      ----------------------
      -- �Ώۃf�[�^�폜����
      ----------------------
      -- ���ׂ��폜
      DELETE
      FROM xxpo_price_lines xpl
      WHERE EXISTS
      (
        SELECT 'X'
        FROM  xxcmn_standard_cost_if xsci,
              xxpo_price_headers xph
        WHERE xsci.item_code        = xph.item_code
        AND   xph.price_type        = '2' -- �W������
        AND   xph.start_date_active = xsci.start_date_active
        AND   xph.price_header_id   = xpl.price_header_id
        AND   xsci.request_id       = gt_request_id_tbl(ln_req_count)
      );
--
      -- �w�b�_���폜
      DELETE
      FROM  xxpo_price_headers xph
      WHERE xph.price_type = '2' -- �W������
      AND EXISTS
      (
        SELECT 'X'
        FROM  xxcmn_standard_cost_if xsci
        WHERE xsci.item_code         = xph.item_code
        AND   xsci.start_date_active = xph.start_date_active
        AND   xsci.request_id        = gt_request_id_tbl(ln_req_count)
      );
--
-- 2009/04/27 v1.5 ADD END
      <<get_standard_if_loop>>
      FOR get_stand_data IN get_standard_if_cur(gt_request_id_tbl(ln_req_count))
      LOOP
        -- ���������̃J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
        -- ���R�[�h�ϐ��Ɋi�[
        lr_report_rec.request_id := get_stand_data.request_id;
        lr_report_rec.item_code := get_stand_data.item_code;
        lr_report_rec.s_date_active := get_stand_data.start_date_active;
        lr_report_rec.e_item_type := get_stand_data.expence_item_type;
        lr_report_rec.e_item_detail_type := get_stand_data.expence_item_detail_type;
        lr_report_rec.item_code_detail := get_stand_data.item_code_detail;
        lr_report_rec.unit_price := get_stand_data.unit_price;
--
        -- ���|�[�g������
        lr_report_rec.message1 := NULL;
        lr_report_rec.message2 := NULL;
        lr_report_rec.message3 := NULL;
        lr_report_rec.message4 := NULL;
        lr_report_rec.message5 := NULL;
        lr_report_rec.message6 := NULL;
        lr_report_rec.message7 := NULL;
        lr_report_rec.skip_message := NULL;
--
        -- ===============================
        -- ���o�f�[�^�`�F�b�N����(A-2)
        -- ===============================
        check_data(
          lr_report_rec,          -- 1.���R�[�h
          ln_total_amount,        -- 2.�P�����v
          ln_item_id,             -- 3.�i��ID
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- ��O����
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- ����A�X�L�b�v�A�G���[�����W�v����
        IF (lr_report_rec.row_level_status = gn_data_status_normal) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSIF (lr_report_rec.row_level_status = gn_data_status_warn) THEN
          gn_warn_cnt   := gn_warn_cnt + 1;
        ELSE
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
--
        -- ���|�[�g�ϐ��Ɋi�[
        gt_out_report_tbl(gn_target_cnt) := lr_report_rec;
--
        -- ===============================
        -- �o�^�Ώۃf�[�^�ҏW����(A-3)
        -- ===============================
        IF (gn_data_status = gn_data_status_normal) THEN
          IF ((lv_former_item_code IS NULL)
              OR (lv_former_item_code <> lr_report_rec.item_code)
            OR ((ld_former_s_date IS NULL)
              OR (ld_former_s_date <> lr_report_rec.s_date_active))) THEN
            -- �w�b�_�J�E���g����
            ln_head_count := ln_head_count + 1;
--
            -- ===============================
            -- �o�^�Ώۃw�b�_�f�[�^�ҏW����
            -- ===============================
            get_price_h_id(
              ln_head_id,    -- 1.�w�b�_ID
              lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            -- ��O����
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
--
            -- �w�b�_�����o���N�ϐ��Ɋi�[
            gt_price_header_id_tbl(ln_head_count) := ln_head_id;
            gt_item_id_tbl(ln_head_count) := ln_item_id;
            gt_item_code_tbl(ln_head_count) := lr_report_rec.item_code;
            gt_s_date_tbl(ln_head_count) := lr_report_rec.s_date_active;
            gt_total_amount_tbl(ln_head_count) := ln_total_amount;
            lv_former_item_code := lr_report_rec.item_code;
            ld_former_s_date := lr_report_rec.s_date_active;
--
          END IF;
          -- ���׃J�E���g����
          ln_line_count := ln_line_count + 1;
--
          -- ===============================
          -- �o�^�Ώۖ��׃f�[�^�ҏW����
          -- ===============================
          get_price_line_id(
            ln_line_id,    -- 1.����ID
            lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- ��O����
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          -- ���׏����o���N�ϐ��Ɋi�[
          gt_price_header_line_id_tbl(ln_line_count) := ln_head_id;
          gt_price_line_id_tbl(ln_line_count) := ln_line_id;
          gt_exp_item_tbl(ln_line_count) := lr_report_rec.e_item_type;
          gt_exp_item_det_tbl(ln_line_count) := lr_report_rec.e_item_detail_type;
          gt_item_code_det_tbl(ln_line_count) := lr_report_rec.item_code_detail;
          gt_unit_price_tbl(ln_line_count) := lr_report_rec.unit_price;
--
        END IF;
--
      END LOOP get_standard_if_loop;
--
      IF (gn_data_status = gn_data_status_normal)
        AND ( gn_target_cnt > 0 )  THEN
        -- ===============================
        -- �W���P���w�b�_�o�^����(A-4)
        -- ===============================
        insert_xp_headers(
          ln_insert_user_id,      -- 1.���[�U�[ID
          ld_insert_date,         -- 2.�X�V��
          ln_insert_login_id,     -- 3.���O�C��ID
          ln_insert_request_id,   -- 4.�v��ID
          ln_insert_prog_appl_id, -- 5.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
          ln_insert_program_id,   -- 6.�R���J�����g�E�v���O����ID
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- ��O����
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- ===============================
        -- �W���P�����דo�^����(A-4)
        -- ===============================
        insert_xp_lines(
          ln_insert_user_id,      -- 1.���[�U�[ID
          ld_insert_date,         -- 2.�X�V��
          ln_insert_login_id,     -- 3.���O�C��ID
          ln_insert_request_id,   -- 4.�v��ID
          ln_insert_prog_appl_id, -- 5.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
          ln_insert_program_id,   -- 6.�R���J�����g�E�v���O����ID
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- ��O����
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
      END IF;
--
    END LOOP get_req_count_loop;
--
    -- 2008/07/09 Add ��
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/09 Add ��
--
    -- �x���f�[�^�����݂���ꍇ
    IF (gn_data_status = gn_data_status_warn) THEN
      -- ���[���o�b�N�����s
      ROLLBACK;
--
      -- ===============================
      -- ���b�N�擾
      -- ===============================
      get_standard_if_lock(
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
    -- �K�p�I�����ҏW
    -- ===============================
    ELSIF (gn_data_status = gn_data_status_normal)
      AND ( gn_target_cnt > 0 )  THEN
      modify_end_date(
        ln_insert_user_id,      -- 1.���[�U�[ID
        ld_insert_date,         -- 2.�X�V��
        ln_insert_login_id,     -- 3.���O�C��ID
        ln_insert_request_id,   -- 4.�v��ID
        ln_insert_prog_appl_id, -- 5.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
        ln_insert_program_id,   -- 6.�R���J�����g�E�v���O����ID
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ��O����
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �C���^�t�F�[�X�f�[�^�폜(A-5)
    -- ===============================
    IF ( gn_target_cnt > 0 )  THEN
      delete_standard_if(
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
    -- ===============================
    -- ���|�[�g�p�f�[�^�o��
    -- ===============================
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
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
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
    retcode       OUT NOCOPY VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
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
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn820001c;
/
