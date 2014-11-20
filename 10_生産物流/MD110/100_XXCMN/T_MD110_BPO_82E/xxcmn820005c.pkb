CREATE OR REPLACE PACKAGE BODY xxcmn820005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820005c(body)
 * Description      : �����R�s�[����
 * MD.050           : �W�������}�X�^T_MD050_BPO_821
 * MD.070           : �����R�s�[����(82E) T_MD070_BPO_82E
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  parameter_check             �p�����[�^�`�F�b�N(E-2)
 *  get_other_data              �֘A�f�[�^�擾����(E-3)
 *  get_lock                    ���b�N�擾����(E-4)
 *  get_cmpntcls_mst            �R���|�[�l���g�敪�}�X�^�擾����(E-5)
 *  get_unit_price_summary      �P�����v�擾����(E-7)
 *  ins_cm_cmpt_dtl             �i�ڌ����}�X�^�o�^����(E-9)
 *  upd_cm_cmpt_dtl             �i�ڌ����}�X�^�X�V����(E-10)
 *  detail_rec_loop             ���׃��R�[�h�擾LOOP
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/07/01    1.0   H.Itou           �V�K�쐬
 *  2009/01/08    1.1   N.Yoshida        �{��#968�Ή�
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
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxcmn820005c';
--
  -- ���W���[��������
  gv_xxcmn                    CONSTANT VARCHAR2(100) := 'XXCMN';        -- ���W���[�������́FXXCMN
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn10019           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
  gv_msg_xxcmn10600           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10600'; -- ���b�Z�[�W�FAPP-XXCMN-10600 �召�`�F�b�N�G���[
  gv_msg_xxcmn10601           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10601'; -- ���b�Z�[�W�FAPP-XXCMN-10601 �召�`�F�b�N�G���[
  gv_msg_xxcmn10018           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10018'; -- ���b�Z�[�W�FAPP-XXCMN-10018 API�G���[(�R���J�����g)
--
  -- �g�[�N��
  gv_tkn_ng_profile           CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_table                CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_api_name             CONSTANT VARCHAR2(100) := 'API_NAME';
--
  -- IN�p�����[�^���{�ꖼ
  gv_calendar_code_name       CONSTANT VARCHAR2(100) := '��v�N�x�i�J�����_�R�[�h�j';
  gv_param_prod_class_name    CONSTANT VARCHAR2(100) := '���i�敪';
  gv_param_item_class_name    CONSTANT VARCHAR2(100) := '�i�ڋ敪';
  gv_param_item_code_name     CONSTANT VARCHAR2(100) := '�i��';
  gv_param_upd_date_from_name CONSTANT VARCHAR2(100) := '�X�V����FROM';
  gv_param_upd_date_to_name   CONSTANT VARCHAR2(100) := '�X�V����TO';
--
  -- ���t����
  gv_yyyymmddhh24miss         CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
  gv_yyyymm                   CONSTANT VARCHAR2(100) := 'YYYYMM';
-- 2009/01/08 v1.1 N.Yoshida add start
  gc_f_time                   CONSTANT VARCHAR2(100) := ' 00:00:00';
  gc_e_time                   CONSTANT VARCHAR2(100) := ' 23:59:59';
-- 2009/01/08 v1.1 N.Yoshida add end
--
  -- �v���t�@�C��
  gv_prf_cost_price_whse_code CONSTANT VARCHAR2(100) := 'XXCMN_COST_PRICE_WHSE_CODE';
  gv_prf_cost_div             CONSTANT VARCHAR2(100) := 'XXCMN_COST_DIV';
  gv_prf_raw_material_cost    CONSTANT VARCHAR2(100) := 'XXCMN_RAW_MATERIAL_COST';
  gv_prf_agein_cost           CONSTANT VARCHAR2(100) := 'XXCMN_AGEIN_COST';
  gv_prf_material_cost        CONSTANT VARCHAR2(100) := 'XXCMN_MATERIAL_COST';
  gv_prf_pack_cost            CONSTANT VARCHAR2(100) := 'XXCMN_PACK_COST';
  gv_prf_out_order_cost       CONSTANT VARCHAR2(100) := 'XXCMN_OUT_ORDER_COST';
  gv_prf_safekeep_cost        CONSTANT VARCHAR2(100) := 'XXCMN_SAFEKEEP_COST';
  gv_prf_other_expense_cost   CONSTANT VARCHAR2(100) := 'XXCMN_OTHER_EXPENSE_COST';
  gv_prf_spare1               CONSTANT VARCHAR2(100) := 'XXCMN_SPARE1';
  gv_prf_spare2               CONSTANT VARCHAR2(100) := 'XXCMN_SPARE2';
  gv_prf_spare3               CONSTANT VARCHAR2(100) := 'XXCMN_SPARE3';
--
  -- �v���t�@�C�����{�ꖼ
  gv_prf_whse_code_name       CONSTANT VARCHAR2(100) := 'XXCMN:�����q��';
  gv_prf_cost_div_name        CONSTANT VARCHAR2(100) := 'XXCMN:�������@';
  gv_prf_raw_mat_cost_name    CONSTANT VARCHAR2(100) := 'XXCMN:����';
  gv_prf_agein_cost_name      CONSTANT VARCHAR2(100) := 'XXCMN:�Đ���';
  gv_prf_material_cost_name   CONSTANT VARCHAR2(100) := 'XXCMN:���ޔ�';
  gv_prf_pack_cost_name       CONSTANT VARCHAR2(100) := 'XXCMN:���';
  gv_prf_out_order_cost_name  CONSTANT VARCHAR2(100) := 'XXCMN:�O�����H��';
  gv_prf_safekeep_cost_name   CONSTANT VARCHAR2(100) := 'XXCMN:�ۊǔ�';
  gv_prf_other_cost_name      CONSTANT VARCHAR2(100) := 'XXCMN:���̑��o��';
  gv_prf_spare1_name          CONSTANT VARCHAR2(100) := 'XXCMN:�\���P';
  gv_prf_spare2_name          CONSTANT VARCHAR2(100) := 'XXCMN:�\���Q';
  gv_prf_spare3_name          CONSTANT VARCHAR2(100) := 'XXCMN:�\���R';
--
  -- �N�C�b�N�R�[�h�^�C�v
  gv_expense_item_type        CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';  -- ��ڋ敪
  gv_cmpntcls_type            CONSTANT VARCHAR2(100) := 'XXCMN_D19';               -- ��������敪
--
  -- �e�[�u����
  gv_cm_cmpt_dtl              CONSTANT VARCHAR2(100) := '�i�ڌ����}�X�^';
--
  -- �}�X�^�敪
  gv_price_type_normal        CONSTANT VARCHAR2(100) := '2'; -- 2�F�W��
--
  -- �����Ǘ��敪
  gv_cost_manage_code_normal  CONSTANT VARCHAR2(100) := '1'; -- 1�F�W������
--
  -- �i�ڋ敪
  gv_item_class_code_prod     CONSTANT VARCHAR2(100) := '5'; -- 5�F���i
--
  -- API��
  gv_api_create_item_cost     CONSTANT VARCHAR2(100) := 'GMF_ITEMCOST_PUB.CREATE_ITEM_COST'; -- �i�ڌ����}�X�^�o�^API
  gv_api_update_item_cost     CONSTANT VARCHAR2(100) := 'GMF_ITEMCOST_PUB.UPDATE_ITEM_COST'; -- �i�ڌ����}�X�^�X�VAPI
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �R���|�[�l���g�敪�}�X�^�pPL/SQL�\
  TYPE cost_cmpntcls_id_ttype   IS TABLE OF  cm_cmpt_mst_tl.cost_cmpntcls_id  %TYPE INDEX BY BINARY_INTEGER;   -- �R���|�[�l���g�敪ID
  TYPE cost_cmpntcls_desc_ttype IS TABLE OF  cm_cmpt_mst_tl.cost_cmpntcls_desc%TYPE INDEX BY BINARY_INTEGER;   -- �R���|�[�l���g�敪��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- �R���|�[�l���g�敪�}�X�^�pPL/SQL�\
  cost_cmpntcls_id_tab          cost_cmpntcls_id_ttype;    -- �R���|�[�l���g�敪ID
  cost_cmpntcls_desc_tab        cost_cmpntcls_desc_ttype;  -- �R���|�[�l���g�敪��
--
  -- �v���t�@�C���I�v�V�����l
  gv_whse_code          VARCHAR2(100);  -- XXCMN:�����q��
  gv_cost_div           VARCHAR2(100);  -- XXCMN:�������@
  gv_raw_material_cost  VARCHAR2(100);  -- XXCMN:����
  gv_agein_cost         VARCHAR2(100);  -- XXCMN:�Đ���
  gv_material_cost      VARCHAR2(100);  -- XXCMN:���ޔ�
  gv_pack_cost          VARCHAR2(100);  -- XXCMN:���
  gv_out_order_cost     VARCHAR2(100);  -- XXCMN:�O�����H��
  gv_safekeep_cost      VARCHAR2(100);  -- XXCMN:�ۊǔ�
  gv_other_expense_cost VARCHAR2(100);  -- XXCMN:���̑��o��
  gv_spare1             VARCHAR2(100);  -- XXCMN:�\���P
  gv_spare2             VARCHAR2(100);  -- XXCMN:�\���Q
  gv_spare3             VARCHAR2(100);  -- XXCMN:�\���R
--
  -- IN�p�����[�^
  gv_calendar_code      VARCHAR2(100);  -- �J�����_�R�[�h
  gv_prod_class_code    VARCHAR2(100);  -- ���i�敪
  gv_item_class_code    VARCHAR2(100);  -- �i�ڋ敪
  gv_item_code          VARCHAR2(100);  -- �i��
  gd_update_date_from   DATE;           -- �X�V����FROM
  gd_update_date_to     DATE;           -- �X�V����TO
--
  gv_close_date         VARCHAR2(100);  -- �݌ɃN���[�Y�N��
  gt_period_code        cm_cldr_dtl.period_code%TYPE;    -- ����
  gt_start_date         cm_cldr_dtl.start_date %TYPE;    -- �J�n��
  gt_end_date           cm_cldr_dtl.end_date   %TYPE;    -- �I����
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(E-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    ov_errbuf  OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg  OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- �v���O������
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
    -- =========================================
    -- �X�V����FROM�E�X�V����TO�`�F�b�N
    -- =========================================
    IF  (gd_update_date_from IS NOT NULL)
    AND (gd_update_date_to IS NOT NULL)
    AND (gd_update_date_from > gd_update_date_to) THEN -- �X�V����FROM���X�V����TO���傫���ꍇ�̓G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10600)           -- ���b�Z�[�W:APP-XXCMN-10600 �召�`�F�b�N�G���[
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_other_data
   * Description      : �֘A�f�[�^�擾����(E-3)
   ***********************************************************************************/
  PROCEDURE get_other_data(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_data'; -- �v���O������
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
    -- �v���t�@�C���I�v�V����
--
    -- *** ���[�J���ϐ� ***
    lv_sysdate_yyyy VARCHAR2(4);  -- �V�X�e�����t�̔N
    lv_sysdate_mm   VARCHAR2(2);  -- �V�X�e�����t�̌�
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
    -- ===========================
    -- �v���t�@�C���I�v�V�����擾
    -- ===========================
    gv_whse_code          := FND_PROFILE.VALUE(gv_prf_cost_price_whse_code);  -- XXCMN:�����q��
    gv_cost_div           := FND_PROFILE.VALUE(gv_prf_cost_div);              -- XXCMN:�������@
    gv_raw_material_cost  := FND_PROFILE.VALUE(gv_prf_raw_material_cost);     -- XXCMN:����
    gv_agein_cost         := FND_PROFILE.VALUE(gv_prf_agein_cost);            -- XXCMN:�Đ���
    gv_material_cost      := FND_PROFILE.VALUE(gv_prf_material_cost);         -- XXCMN:���ޔ�
    gv_pack_cost          := FND_PROFILE.VALUE(gv_prf_pack_cost);             -- XXCMN:���
    gv_out_order_cost     := FND_PROFILE.VALUE(gv_prf_out_order_cost);        -- XXCMN:�O�����H��
    gv_safekeep_cost      := FND_PROFILE.VALUE(gv_prf_safekeep_cost);         -- XXCMN:�ۊǔ�
    gv_other_expense_cost := FND_PROFILE.VALUE(gv_prf_other_expense_cost);    -- XXCMN:���̑��o��
    gv_spare1             := FND_PROFILE.VALUE(gv_prf_spare1);                -- XXCMN:�\���P
    gv_spare2             := FND_PROFILE.VALUE(gv_prf_spare2);                -- XXCMN:�\���Q
    gv_spare3             := FND_PROFILE.VALUE(gv_prf_spare3);                -- XXCMN:�\���R
--
    -- =========================================
    -- �v���t�@�C���I�v�V�����擾�G���[�`�F�b�N
    -- =========================================
    IF (gv_whse_code IS NULL) THEN  -- XXCMN:�����q�Ƀv���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_whse_code_name)       -- XXCMN:�����q��
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_div IS NULL) THEN  -- XXCMN:�������@�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_cost_div_name)        -- XXCMN:�������@
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_raw_material_cost IS NULL) THEN  -- XXCMN:�����v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_raw_mat_cost_name)    -- XXCMN:����
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_agein_cost IS NULL) THEN  --  XXCMN:�Đ���v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_agein_cost_name)      --  XXCMN:�Đ���
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_material_cost IS NULL) THEN  -- XXCMN:���ޔ�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_material_cost_name)   -- XXCMN:���ޔ�
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_pack_cost IS NULL) THEN  -- XXCMN:���v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_pack_cost_name)       -- XXCMN:���
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_out_order_cost IS NULL) THEN  -- XXCMN:�O�����H��v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_out_order_cost_name)  -- XXCMN:�O�����H��
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_safekeep_cost IS NULL) THEN  -- XXCMN:�ۊǔ�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_safekeep_cost_name)   -- XXCMN:�ۊǔ�
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_other_expense_cost IS NULL) THEN  -- XXCMN:���̑��o��v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_other_cost_name)      -- XXCMN:���̑��o��
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_spare1 IS NULL) THEN  -- XXCMN:�\���P�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_spare1_name)          -- XXCMN:�\���P
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_spare2 IS NULL) THEN  -- XXCMN:�\���Q�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_spare2_name)          -- XXCMN:�\���Q
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_spare3 IS NULL) THEN  -- XXCMN:�\���R�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_prf_spare3_name)          -- XXCMN:�\���R
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- �݌ɃN���[�Y�N���擾
    -- ===========================
    gv_close_date := xxcmn_common_pkg.get_opminv_close_period;
--
    -- ===========================
    -- �����J�����_���擾
    -- ===========================
    -- IN�p�����[�^.�J�����_�R�[�h�ɓ��͂�����ꍇ
    IF (gv_calendar_code IS NOT NULL) THEN
      -- �J�����_�R�[�h�������Ɍ����J�����_�����擾
      SELECT ccd.calendar_code     calendar_code -- �J�����_�R�[�h
            ,TRUNC(ccd.start_date) start_date    -- �J�n��
            ,TRUNC(ccd.end_date)   end_date      -- �I����
            ,ccd.period_code       period_code   -- ����
      INTO   gv_calendar_code                -- �J�����_�R�[�h
            ,gt_start_date                   -- �J�n��
            ,gt_end_date                     -- �I����
            ,gt_period_code                  -- ����
      FROM   cm_cldr_dtl       ccd           -- �����J�����_
      WHERE  ccd.calendar_code = gv_calendar_code
      ;
--
    -- IN�p�����[�^.�J�����_�R�[�h�ɓ��͂Ȃ��̏ꍇ
    ELSE
      -- SYSDATE�������Ɍ����J�����_�����擾
      SELECT ccd.calendar_code     calendar_code -- �J�����_�R�[�h
            ,TRUNC(ccd.start_date) start_date    -- �J�n��
            ,TRUNC(ccd.end_date)   end_date      -- �I����
            ,ccd.period_code       period_code   -- ����
      INTO   gv_calendar_code                -- �J�����_�R�[�h
            ,gt_start_date                   -- �J�n��
            ,gt_end_date                     -- �I����
            ,gt_period_code                  -- ����
      FROM   cm_cldr_dtl       ccd           -- �����J�����_
      WHERE  ccd.start_date <= TRUNC(SYSDATE)
      AND    ccd.end_date   >= TRUNC(SYSDATE)
      ;
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
  END get_other_data;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾����(E-4)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf            OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- �i�ڌ����}�X�^(CM_CMPT_DTL)
    CURSOR cm_cmpt_dtl_cur IS
      SELECT 1
      FROM   cm_cmpt_dtl ccd  -- �i�ڌ����}�X�^
      WHERE  EXISTS (
               SELECT 1
               FROM   xxpo_price_headers         xph     -- �d��/�W���P���w�b�_
                     ,xxcmn_item_categories5_v   xicv    -- OPM�i�ڃJ�e�S���������VIEW
               WHERE  xph.item_id    = ccd.item_id
               AND    xph.item_id    = xicv.item_id
               AND    xph.price_type = gv_price_type_normal            -- �}�X�^�敪2�F�W��
               AND    ROWNUM = 1)
      AND    ccd.calendar_code  = gv_calendar_code      -- �J�����_�R�[�h
      FOR UPDATE NOWAIT
    ;
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
    -- ===========================
    -- �i�ڌ����}�X�^���b�N�擾
    -- ===========================
    BEGIN
       <<lock_loop>>
      FOR lr_cm_cmpt_dtl IN cm_cmpt_dtl_cur
      LOOP
        EXIT;
      END LOOP lock_loop;
--
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- ���W���[��������:XXCMN
                         ,gv_msg_xxcmn10019      -- ���b�Z�[�W:APP-XXCMN-10019 ���b�N�G���[
                         ,gv_tkn_table           -- �g�[�N��TABLE
                         ,gv_cm_cmpt_dtl)        -- �i�ڌ����}�X�^
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_cmpntcls_mst
   * Description      : �R���|�[�l���g�敪�}�X�^�擾����(E-5)
   ***********************************************************************************/
  PROCEDURE get_cmpntcls_mst(
    ov_errbuf          OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cmpntcls_mst'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER := 0;  -- ���[�v�J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �R���|�[�l���g�敪�J�[�\��
    CURSOR cmpnt_cur IS
      SELECT ccmt.cost_cmpntcls_id    cost_cmpntcls_id    -- �R���|�[�l���g�敪ID
            ,ccmt.cost_cmpntcls_desc  cost_cmpntcls_desc  -- �R���|�[�l���g�敪��
      FROM   cm_cmpt_mst_tl ccmt              -- �R���|�[�l���g�敪�}�X�^�|��
      WHERE  ccmt.language = userenv('LANG')  -- ����
      AND    ccmt.cost_cmpntcls_desc IN (     -- �R���|�[�l���g�敪��
               gv_raw_material_cost           -- XXCMN:����
              ,gv_agein_cost                  -- XXCMN:�Đ���
              ,gv_material_cost               -- XXCMN:���ޔ�
              ,gv_pack_cost                   -- XXCMN:���
              ,gv_out_order_cost              -- XXCMN:�O�����H��
              ,gv_safekeep_cost               -- XXCMN:�ۊǔ�
              ,gv_other_expense_cost          -- XXCMN:���̑��o��
              ,gv_spare1                      -- XXCMN:�\���P
              ,gv_spare2                      -- XXCMN:�\���Q
              ,gv_spare3                      -- XXCMN:�\���R
             )
    ;
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
    -- ===========================
    -- �R���|�[�l���g�敪�擾
    -- ===========================
    <<cmpnt_loop>>
    FOR lr_cmpnt IN cmpnt_cur
    LOOP
      ln_cnt := ln_cnt + 1;   -- �J�E���g
--
      -- �R���|�[�l���g�敪�擾
      cost_cmpntcls_id_tab(ln_cnt)   := lr_cmpnt.cost_cmpntcls_id;
      cost_cmpntcls_desc_tab(ln_cnt) := lr_cmpnt.cost_cmpntcls_desc;
--
    END LOOP cmpnt_loop;
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
  END get_cmpntcls_mst;
--
  /***********************************************************************************
   * Procedure Name   : get_unit_price_summary
   * Description      : �P�����v�擾����(E-7)
   ***********************************************************************************/
  PROCEDURE get_unit_price_summary(
    it_price_header_id     IN  xxpo_price_headers.price_header_id%TYPE  -- �w�b�_ID
   ,it_cost_cmpntcls_desc  IN  cm_cmpt_mst_tl.cost_cmpntcls_desc%TYPE   -- �R���|�[�l���g��
   ,ot_cmpnt_cost_price    OUT NOCOPY xxpo_price_lines.unit_price%TYPE  -- �P�����v
   ,ov_errbuf          OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_price_summary'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �R���|�[�l���g�敪���Ƃ̒P�����v�l�擾�B�擾�ł��Ȃ��ꍇ��0�B
    SELECT NVL(SUM(xpl.unit_price),0)   unit_price       -- �P�����v
    INTO   ot_cmpnt_cost_price
    FROM   xxpo_price_lines      xpl              -- �d��/�W����������
          ,xxcmn_lookup_values_v xlvv1            -- �N�C�b�N�R�[�h���VIEW  ��ڋ敪���
          ,xxcmn_lookup_values_v xlvv2            -- �N�C�b�N�R�[�h���VIEW  ��������敪���
    WHERE  -- *** �������� �d��/�W���������ׁE��ڋ敪��� *** --
           xpl.expense_item_type = xlvv1.attribute1
           -- *** �������� ��ڋ敪���E��������敪��� *** --
    AND    xlvv1.attribute2 = xlvv2.lookup_code
           -- *** ���o���� *** --
    AND    xpl.price_header_id = it_price_header_id     -- �w�b�_ID
    AND    xlvv1.lookup_type   = gv_expense_item_type   -- ��ڋ敪
    AND    xlvv2.lookup_type   = gv_cmpntcls_type       -- ��������敪
    AND    xlvv2.meaning       = it_cost_cmpntcls_desc  -- �R���|�[�l���g�敪��
    ;
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
  END get_unit_price_summary;
--
  /***********************************************************************************
   * Procedure Name   : ins_cm_cmpt_dtl
   * Description      : �i�ڌ����}�X�^�o�^����(E-9)
   ***********************************************************************************/
  PROCEDURE ins_cm_cmpt_dtl(
    ir_head_rec        IN  GMF_ITEMCOST_PUB.HEADER_REC_TYPE          -- �i�ڌ����}�X�^�w�b�_���R�[�h
   ,ir_this_tbl        IN  GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE  -- �������󃌃R�[�h
   ,ov_errbuf          OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cm_cmpt_dtl'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_api_ver        CONSTANT NUMBER := 2.0;
--
    -- *** ���[�J���ϐ� ***
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lr_ids_tbl        GMF_ITEMCOST_PUB.COSTCMPNT_IDS_TBL_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(5000);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
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
    -- ������
    FND_MSG_PUB.INITIALIZE(); -- API���b�Z�[�W
--
    -- �i�ڌ����}�X�^�o�^API
    GMF_ITEMCOST_PUB.CREATE_ITEM_COST(
      P_API_VERSION         => cv_api_ver
     ,P_INIT_MSG_LIST       => FND_API.G_FALSE
     ,P_COMMIT              => FND_API.G_FALSE
     ,X_RETURN_STATUS       => lv_return_status
     ,X_MSG_COUNT           => ln_msg_count
     ,X_MSG_DATA            => lv_msg_data
     ,P_HEADER_REC          => ir_head_rec
     ,P_THIS_LEVEL_DTL_TBL  => ir_this_tbl
     ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
     ,X_COSTCMPNT_IDS       => lr_ids_tbl
    );
--
    -- �i�ڌ����}�X�^�o�^API���G���[�̏ꍇ
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      -- �G���[���O�o��
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���O�o�͂Ɏ��s�����ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn            -- ���W���[��������
                       ,gv_msg_xxcmn10018   -- ���b�Z�[�W�FAPP-XXCMN-10018 API�G���[(�R���J�����g)
                       ,gv_tkn_api_name     -- �g�[�N��
                       ,gv_api_create_item_cost) -- GMF_ITEMCOST_PUB.CREATE_ITEM_COST
                     ,1,5000);
      lv_errbuf := lv_errmsg;
--
      RAISE global_process_expt;
--
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
  END ins_cm_cmpt_dtl;
--
--
  /***********************************************************************************
   * Procedure Name   : upd_cm_cmpt_dtl
   * Description      : �i�ڌ����}�X�^�X�V����(E-10)
   ***********************************************************************************/
  PROCEDURE upd_cm_cmpt_dtl(
    ir_head_rec        IN  GMF_ITEMCOST_PUB.HEADER_REC_TYPE          -- �i�ڌ����}�X�^�w�b�_���R�[�h
   ,ir_this_tbl        IN  GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE  -- �������󃌃R�[�h
   ,ov_errbuf          OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cm_cmpt_dtl'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_api_ver        CONSTANT NUMBER := 2.0;
--
    -- *** ���[�J���ϐ� ***
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(5000);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
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
    -- ������
    FND_MSG_PUB.INITIALIZE(); -- API���b�Z�[�W
--
    -- �i�ڌ����}�X�^�X�VAPI
    GMF_ITEMCOST_PUB.UPDATE_ITEM_COST(
      P_API_VERSION         => cv_api_ver
     ,P_INIT_MSG_LIST       => FND_API.G_FALSE
     ,P_COMMIT              => FND_API.G_FALSE
     ,X_RETURN_STATUS       => lv_return_status
     ,X_MSG_COUNT           => ln_msg_count
     ,X_MSG_DATA            => lv_msg_data
     ,P_HEADER_REC          => ir_head_rec
     ,P_THIS_LEVEL_DTL_TBL  => ir_this_tbl
     ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
    );
--
    -- �i�ڌ����}�X�^�X�VAPI���G���[�̏ꍇ
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      -- �G���[���O�o��
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���O�o�͂Ɏ��s�����ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn            -- ���W���[��������
                       ,gv_msg_xxcmn10018   -- ���b�Z�[�W�FAPP-XXCMN-10018 API�G���[(�R���J�����g)
                       ,gv_tkn_api_name     -- �g�[�N��
                       ,gv_api_update_item_cost)        -- GMF_ITEMCOST_PUB.UPDATE_ITEM_COST
                     ,1,5000);
      lv_errbuf := lv_errmsg;
--
      RAISE global_process_expt;
--
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
  END upd_cm_cmpt_dtl;
--
  /**********************************************************************************
   * Procedure Name   : detail_rec_loop
   * Description      : ���׃��R�[�h�擾LOOP
   ***********************************************************************************/
  PROCEDURE detail_rec_loop(
    it_item_id           IN  xxcmn_item_mst_v.item_id%TYPE            -- �i��ID
   ,it_cost_manage_code  IN  xxcmn_item_mst_v.cost_manage_code%TYPE   -- �����Ǘ��敪
   ,it_price_header_id   IN  xxpo_price_headers.price_header_id%TYPE  -- �w�b�_ID
   ,or_ins_this_tbl      OUT GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE -- �������󃌃R�[�h(�o�^)
   ,or_upd_this_tbl      OUT GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE -- �������󃌃R�[�h(�X�V)
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'detail_rec_loop'; -- �v���O������
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
    lr_ins_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- �������󃌃R�[�h(�o�^)
    lr_upd_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- �������󃌃R�[�h(�X�V)
    lt_master_receive_date cm_cmpt_dtl.attribute30%TYPE;   -- �}�X�^��M��
    lt_cmpntcost_id        cm_cmpt_dtl.cmpntcost_id%TYPE;  -- �����ڍ�ID
    ln_unit_price_ttl      NUMBER;                         -- �P�����v
    ln_update_flg          NUMBER;                         -- 1�̏ꍇ�A�X�V�B0�̏ꍇ�A�o�^�B
    ln_ins_cnt             NUMBER;                         -- �o�^�����J�E���g
    ln_upd_cnt             NUMBER;                         -- �X�V�����J�E���g
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
    ln_ins_cnt := 0;
    ln_upd_cnt := 0;
    lr_ins_this_tbl.DELETE;
    lr_upd_this_tbl.DELETE;
--
    -- �R���|�[�l���g�敪�̐�����LOOP
    <<cmpntcls_loop>>
    FOR loop_cnt IN 1..cost_cmpntcls_id_tab.COUNT
    LOOP
      -- ===============================
      -- E-7.�P�����v�擾����
      -- ===============================
      -- �R���|�[�l���g�敪���ƂɒP�����v���擾
      get_unit_price_summary(
        it_price_header_id    => it_price_header_id                -- �w�b�_ID
       ,it_cost_cmpntcls_desc => cost_cmpntcls_desc_tab(loop_cnt)  -- �R���|�[�l���g��
       ,ot_cmpnt_cost_price   => ln_unit_price_ttl                 -- �P�����v
       ,ov_errbuf             => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- E-8.�o�^�E�X�V���菈��
      -- ===============================
      -- �i�ڌ����}�X�^������
      BEGIN
        SELECT ccd.attribute30     master_receive_date   -- �}�X�^��M��
              ,ccd.cmpntcost_id    cmpntcost_id          -- �����ڍ�ID
        INTO   lt_master_receive_date                    -- �}�X�^��M��
              ,lt_cmpntcost_id                           -- �����ڍ�ID
        FROM   cm_cmpt_dtl         ccd                   -- �i�ڌ����}�X�^
        WHERE  ccd.item_id          = it_item_id         -- �i��ID
        AND    ccd.cost_cmpntcls_id = cost_cmpntcls_id_tab(loop_cnt) -- �R���|�[�l���g�敪ID
        AND    ccd.period_code      = gt_period_code      -- ����
        AND    ccd.whse_code        = gv_whse_code        -- �q��
        AND    ccd.calendar_code    = gv_calendar_code    -- �J�����_
        AND    ccd.cost_mthd_code   = gv_cost_div         -- �������@
        AND    ccd.delete_mark      = 0                   -- �폜�t���O
        AND    ROWNUM               = 1
        ;
--
        -- �f�[�^�����łɂ���̂ŁA�X�V
        ln_update_flg := 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^���Ȃ��̂ŁA�o�^
          ln_update_flg := 0;
      END;
--
      -- �ȉ��̏ꍇ�A�������󃌃R�[�h(�o�^)�ɒl���Z�b�g
      -- �L�[�ŕi�ڌ����}�X�^�������ł��Ȃ�
      IF (ln_update_flg = 0) THEN
        -- �o�^�����J�E���g
        ln_ins_cnt := ln_ins_cnt + 1;
--
        -- �������󃌃R�[�h(�o�^)�ɒl���Z�b�g
        lr_ins_this_tbl(ln_ins_cnt).cost_cmpntcls_id   := cost_cmpntcls_id_tab(loop_cnt); -- �R���|�[�l���g�敪ID
        lr_ins_this_tbl(ln_ins_cnt).cost_analysis_code := '0000'; -- �������͋敪
        lr_ins_this_tbl(ln_ins_cnt).burden_ind         := 0; -- 
        lr_ins_this_tbl(ln_ins_cnt).delete_mark        := 0; -- �폜�t���O
        lr_ins_this_tbl(ln_ins_cnt).cmpnt_cost         := ln_unit_price_ttl; -- �R���|�[�l���g����
--
      -- �ȉ��̏ꍇ�A�������󃌃R�[�h(�X�V)�ɒl���Z�b�g
      --   �E�L�[�ŕi�ڌ����}�X�^�������ł���
      --   �E�}�X�^��M���ɒl�Ȃ�
      ELSIF (ln_update_flg = 1) 
      AND   (lt_master_receive_date IS NULL) THEN
        -- �ȉ��̏ꍇ�A�x���B�X�V�������s�킸�ɏ������X�L�b�v����B
        --   �E�����Ǘ��敪��1�F�W���������A�J�n���̔N�����݌ɃN���[�Y��
        IF  ((it_cost_manage_code = gv_cost_manage_code_normal) AND (TO_CHAR(gt_start_date, gv_yyyymm) <= gv_close_date)) THEN
          -- �x��
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn            -- ���W���[��������
                           ,gv_msg_xxcmn10601)  -- ���b�Z�[�W�FAPP-XXCMN-10161 �݌ɃN���[�Y�G���[
                         ,1,5000);
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := lv_errmsg;
          ov_retcode := gv_status_warn;
--
        -- ��L�ȊO�̏ꍇ�A�X�V����
        ELSE
          -- �X�V�����J�E���g
          ln_upd_cnt := ln_upd_cnt + 1;
--
          -- �������󃌃R�[�h(�X�V)�ɒl���Z�b�g
          lr_upd_this_tbl(ln_upd_cnt).cmpntcost_id       := lt_cmpntcost_id;                         -- �����ڍ�ID
          lr_upd_this_tbl(ln_upd_cnt).cost_cmpntcls_id   := cost_cmpntcls_id_tab(loop_cnt); -- �R���|�[�l���g�敪ID
          lr_upd_this_tbl(ln_upd_cnt).cost_analysis_code := '0000'; -- �������͋敪
          lr_upd_this_tbl(ln_upd_cnt).burden_ind         := 0; -- 
          lr_upd_this_tbl(ln_upd_cnt).delete_mark        := 0; -- �폜�t���O
          lr_upd_this_tbl(ln_upd_cnt).cmpnt_cost         := ln_unit_price_ttl; -- �R���|�[�l���g����
--
        END IF;
--
      -- �ȉ��̏ꍇ�A�{�ЃC���^�t�F�[�X���ꂽ�i�ڂȂ̂ŁA�����ΏۊO�B
      --   �E�L�[�ŕi�ڌ����}�X�^�������ł���
      --   �E�}�X�^��M���ɒl����
      ELSE
        NULL;
--
      END IF;
--
    END LOOP cmpntcls_loop;
--
   -- OUT�p�����[�^�ɃZ�b�g
   or_ins_this_tbl := lr_ins_this_tbl;
   or_upd_this_tbl := lr_upd_this_tbl;
--
  EXCEPTION
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
  END detail_rec_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf            OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT NOCOPY VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   ,iv_calendar_code     IN  VARCHAR2    --   �J�����_�R�[�h
   ,iv_prod_class_code   IN  VARCHAR2    --   ���i�敪
   ,iv_item_class_code   IN  VARCHAR2    --   �i�ڋ敪
   ,iv_item_code         IN  VARCHAR2    --   �i��
   ,iv_update_date_from  IN  VARCHAR2    --   �X�V����FROM
   ,iv_update_date_to    IN  VARCHAR2    --   �X�V����TO
  )
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
    lr_head_rec            GMF_ITEMCOST_PUB.HEADER_REC_TYPE;         -- �i�ڌ����}�X�^�w�b�_���R�[�h
    lr_ins_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- �������󃌃R�[�h(�o�^)
    lr_upd_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- �������󃌃R�[�h(�X�V)

--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR main_cur IS
      SELECT xph.price_header_id         price_header_id   -- �w�b�_ID
            ,xph.item_id                 item_id           -- �i��ID
            ,ximv.cost_manage_code       cost_manage_code  -- �����Ǘ��敪
      FROM   xxpo_price_headers          xph               -- �d��/�W�������w�b�_
            ,xxcmn_item_mst_v            ximv              -- OPM�i�ڏ��VIEW
            ,xxcmn_item_categories5_v    xicv              -- OPM�i�ڃJ�e�S���������VIEW
            ,(
             SELECT xph1.item_id                item_id
                   ,MAX(xph1.start_date_active) start_date_active
             FROM   xxpo_price_headers         xph1
             WHERE ((xph1.start_date_active BETWEEN gt_start_date AND gt_end_date)  -- �K�p�J�n���������J�����_�J�n���͈͓��`�����J�����_�I�����͈͓�
             OR     (xph1.end_date_active   BETWEEN gt_start_date AND gt_end_date)  -- �K�p�I�����������J�����_�J�n���͈͓��`�����J�����_�I�����͈͓�
             OR     ((xph1.start_date_active < gt_start_date)                       -- �K�p�J�n���������J�����_�J�n�����O���A�K�p�I�����������J�����_�I��������
               AND   (xph1.end_date_active   > gt_end_date)))
             AND    xph1.price_type = gv_price_type_normal  -- �}�X�^�敪2�F�W��
             GROUP BY xph1.item_id)       subsql            -- �͈͓��ōŐV�̃f�[�^
      WHERE  -- *** �������� �d��/�W�������w�b�_�EOPM�i�ڏ��VIEW *** --
             xph.item_id = ximv.item_id
             -- *** �������� �d��/�W�������w�b�_�EOPM�i�ڃJ�e�S���������VIEW *** --
      AND    xph.item_id = xicv.item_id
             -- *** �������� �d��/�W�������w�b�_�E�T�u�N�G�� *** --
      AND    xph.item_id           = subsql.item_id
      AND    xph.start_date_active = subsql.start_date_active
             -- *** ���o���� *** --
      AND    xicv.prod_class_code   = NVL(gv_prod_class_code,  xicv.prod_class_code) -- ���i�敪�ɓ��͂�����ꍇ�A�����ɒǉ�
      AND    xicv.item_class_code   = NVL(gv_item_class_code,  xicv.item_class_code) -- �i�ڋ敪�ɓ��͂�����ꍇ�A�����ɒǉ�
      AND    xph.item_code          = NVL(gv_item_code,        xph.item_code)        -- �i�ڂɓ��͂�����ꍇ�A�����ɒǉ�
      AND    xph.last_update_date  >= NVL(gd_update_date_from, xph.last_update_date) -- �X�V����FROM�ɓ��͂�����ꍇ�A�����ɒǉ�
      AND    xph.last_update_date  <= NVL(gd_update_date_to,   xph.last_update_date) -- �X�V����TO�ɓ��͂�����ꍇ�A�����ɒǉ�
      AND    xph.price_type         = gv_price_type_normal                           -- �}�X�^�敪2�F�W��
      AND    ((xph.start_date_active BETWEEN gt_start_date AND gt_end_date)          -- �K�p�J�n���������J�����_�J�n���͈͓��`�����J�����_�I�����͈͓�
        OR    (xph.end_date_active   BETWEEN gt_start_date AND gt_end_date)          -- �K�p�I�����������J�����_�J�n���͈͓��`�����J�����_�I�����͈͓�
        OR    ((xph.start_date_active < gt_start_date)                               -- �K�p�J�n���������J�����_�J�n�����O���A�K�p�I�����������J�����_�I��������
          AND  (xph.end_date_active   > gt_end_date)))
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- E-1.���̓p�����[�^�o�͏���
    -- ===============================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_calendar_code_name       || gv_msg_part || iv_calendar_code);    -- �J�����_�R�[�h
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_prod_class_name    || gv_msg_part || iv_prod_class_code);  -- ���i�敪
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_item_class_name    || gv_msg_part || iv_item_class_code);  -- �i�ڋ敪
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_item_code_name     || gv_msg_part || iv_item_code);        -- �i��
-- 2009/01/08 v1.1 N.Yoshida mod start
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_from_name || gv_msg_part || iv_update_date_from); -- �X�V����FROM
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_to_name   || gv_msg_part || iv_update_date_to);   -- �X�V����TO
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_from_name || gv_msg_part || iv_update_date_from || gc_f_time); -- �X�V����FROM
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_to_name   || gv_msg_part || iv_update_date_to || gc_e_time);   -- �X�V����TO
-- 2009/01/08 v1.1 N.Yoshida mod end
--
    gv_calendar_code    := iv_calendar_code;    -- �J�����_�R�[�h
    gv_prod_class_code  := iv_prod_class_code;  -- ���i�敪
    gv_item_class_code  := iv_item_class_code;  -- �i�ڋ敪
    gv_item_code        := iv_item_code;        -- �i��
-- 2009/01/08 v1.1 N.Yoshida mod start
--    gd_update_date_from := FND_DATE.STRING_TO_DATE(iv_update_date_from, gv_yyyymmddhh24miss); -- �X�V����FROM
--    gd_update_date_to   := FND_DATE.STRING_TO_DATE(iv_update_date_to, gv_yyyymmddhh24miss);   -- �X�V����TO
    gd_update_date_from := FND_DATE.STRING_TO_DATE(iv_update_date_from || gc_f_time, gv_yyyymmddhh24miss); -- �X�V����FROM
    gd_update_date_to   := FND_DATE.STRING_TO_DATE(iv_update_date_to || gc_e_time, gv_yyyymmddhh24miss);   -- �X�V����TO
-- 2009/01/08 v1.1 N.Yoshida mod end
--
    -- ===============================
    -- E-2.�p�����[�^�`�F�b�N
    -- ===============================
    parameter_check(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-3.�֘A�f�[�^�擾����
    -- ===============================
    get_other_data(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-4.���b�N�擾����
    -- ===============================
    get_lock(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-5.�R���|�[�l���g�敪�擾����
    -- ===============================
    get_cmpntcls_mst(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-6.�Ώۃf�[�^�擾����
    -- ===============================
    <<main_loop>>
    FOR lr_main IN main_cur
    LOOP
      -- ���׃��R�[�h������
      lr_ins_this_tbl.DELETE;
      lr_upd_this_tbl.DELETE;
      --
      -- �i�ڌ����}�X�^�w�b�_���R�[�h�ɒl���Z�b�g
      lr_head_rec.item_id        := lr_main.item_id;      -- �i��ID
      lr_head_rec.whse_code      := gv_whse_code;         -- XXCMN:�����q��
      lr_head_rec.period_code    := gt_period_code;       -- ����
      lr_head_rec.calendar_code  := gv_calendar_code;     -- �J�����_�R�[�h
      lr_head_rec.cost_mthd_code := gv_cost_div;          -- XXCMN:�������@
      lr_head_rec.user_name      := FND_GLOBAL.USER_NAME; -- ���[�U�[��
--
      -- ===============================
      -- ���׃��R�[�h�擾LOOP
      -- ===============================
      detail_rec_loop(
        it_item_id           => lr_main.item_id           -- �i��ID
       ,it_cost_manage_code  => lr_main.cost_manage_code  -- �����Ǘ��敪
       ,it_price_header_id   => lr_main.price_header_id   -- �w�b�_ID
       ,or_ins_this_tbl      => lr_ins_this_tbl -- �������󃌃R�[�h(�o�^)
       ,or_upd_this_tbl      => lr_upd_this_tbl -- �������󃌃R�[�h(�X�V)
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���I���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- �x���J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
        -- OUT�p�����[�^�Z�b�g
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
      END IF;
--
      -- ===============================
      -- E-9.�i�ڌ����}�X�^�o�^����
      -- ===============================
      IF (lr_ins_this_tbl.COUNT > 0) THEN
        ins_cm_cmpt_dtl(
          ir_head_rec        => lr_head_rec      -- �i�ڌ����}�X�^�w�b�_���R�[�h
         ,ir_this_tbl        => lr_ins_this_tbl  -- �������󃌃R�[�h(�o�^)
         ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
     END IF;
--
      -- ===============================
      -- E-10.�i�ڌ����}�X�^�X�V����
      -- ===============================
      IF (lr_upd_this_tbl.COUNT > 0) THEN
        upd_cm_cmpt_dtl(
          ir_head_rec        => lr_head_rec      -- �i�ڌ����}�X�^�w�b�_���R�[�h
         ,ir_this_tbl        => lr_upd_this_tbl  -- �������󃌃R�[�h(�X�V)
         ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ���������J�E���g
      IF ((lr_ins_this_tbl.COUNT > 0) OR (lr_upd_this_tbl.COUNT > 0)) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP main_loop;
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
    errbuf               OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,retcode              OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,iv_calendar_code     IN  VARCHAR2    --   �J�����_�R�[�h
   ,iv_prod_class_code   IN  VARCHAR2    --   ���i�敪
   ,iv_item_class_code   IN  VARCHAR2    --   �i�ڋ敪
   ,iv_item_code         IN  VARCHAR2    --   �i��
   ,iv_update_date_from  IN  VARCHAR2    --   �X�V����FROM
   ,iv_update_date_to    IN  VARCHAR2    --   �X�V����TO
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
      lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_calendar_code     --   �J�����_�R�[�h
     ,iv_prod_class_code   --   ���i�敪
     ,iv_item_class_code   --   �i�ڋ敪
     ,iv_item_code         --   �i��
     ,iv_update_date_from  --   �X�V����FROM
     ,iv_update_date_to    --   �X�V����TO
    );
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
    -- E-15.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
END xxcmn820005c;
/
